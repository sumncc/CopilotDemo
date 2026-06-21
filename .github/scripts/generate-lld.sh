#!/usr/bin/env bash
# generate-lld.sh
#
# Generates one LLD file per input HLD Markdown file.
# Each LLD includes a Mermaid Sequence Diagram and a Mermaid Flow Diagram
# derived from the HLD content.
#
# Usage:
#   generate-lld.sh <output-dir> <pr-number> <pr-title> <hld-file> [<hld-file> ...]
#
# Arguments:
#   output-dir   Directory where LLD files are written (e.g. "doc/lld")
#   pr-number    Pull-request number           (e.g. "42")
#   pr-title     Pull-request title            (e.g. "Add payment flow")
#   hld-file...  One or more HLD Markdown files to process
#
# Output naming:
#   doc/hld/payment-flow-hld.md        -> doc/lld/payment-flow-lld.md
#   doc/hld/user-authentication-hld.md -> doc/lld/user-authentication-lld.md

set -euo pipefail

LLD_OUTPUT_DIR="${1:?Usage: generate-lld.sh <output-dir> <pr-number> <pr-title> <hld-file> [...]}"
PR_NUMBER="${2:-unknown}"
PR_TITLE="${3:-unknown}"
shift 3

if [ "$#" -eq 0 ]; then
  echo "No HLD files specified. LLD not generated."
  exit 0
fi

echo "Generating LLD file(s) in '${LLD_OUTPUT_DIR}' from $# HLD file(s):"
printf '  %s\n' "$@"

# ── Ensure output directory exists ───────────────────────────────────────────
mkdir -p "$LLD_OUTPUT_DIR"

# ── Convert a basename (hyphen-separated) to Title Case ──────────────────────
to_title() {
  echo "$1" | sed 's/-/ /g' \
    | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1'
}

# ── Convert a basename to a valid Mermaid node ID (no hyphens/spaces) ────────
to_node_id() {
  echo "$1" | sed 's/[-_]//g' \
    | awk '{print toupper(substr($0,1,1)) substr($0,2)}'
}

# ── Extract the first non-blank paragraph after "## Overview" ────────────────
# Excludes markdown horizontal rules (---) that may appear as section separators.
get_overview() {
  awk '/^## Overview/{found=1; next} found && /^## /{exit} found && NF && !/^---/{print}' "$1" \
    | head -5
}

# ── Extract bullet lines from "## Assumptions" ───────────────────────────────
# Excludes markdown horizontal rules (---) that may appear as section separators.
get_assumptions() {
  awk '/^## Assumptions/{found=1; next} found && /^## /{exit} found && /^-/ && !/^---/{print}' "$1"
}

# ── Detect components from file content ──────────────────────────────────────
detect_has_user() {
  grep -qi '\buser\b\|\bclient\b\|\bbrowser\b' "$1" && echo true || echo false
}

detect_has_db() {
  grep -qi '\bdatabase\b\|\bdata store\b\|\bstorage\b\|\bpersist\b\|\bsession\b' "$1" \
    && echo true || echo false
}

detect_has_cache() {
  grep -qi '\bcache\b\|\bredis\b' "$1" && echo true || echo false
}

detect_has_auth() {
  grep -qi '\bauth\b\|authentication\|identity\|\boauth\b\|\bsso\b' "$1" \
    && echo true || echo false
}

detect_has_payment() {
  grep -qi '\bpayment\b\|\bpayment gateway\b\|\bcheckout\b' "$1" \
    && echo true || echo false
}

detect_has_api() {
  grep -qi '\bapi\b\|\brest\b\|\bhttp\b\|\bendpoint\b\|\bservice\b' "$1" \
    && echo true || echo false
}

# ── Emit a Mermaid sequenceDiagram derived from the HLD content ───────────────
generate_sequence_diagram() {
  local file="$1"
  local basename="$2"
  local title node_id
  title=$(to_title "$basename")
  node_id=$(to_node_id "$basename")

  local has_user has_db has_cache has_auth has_payment has_api
  has_user=$(detect_has_user "$file")
  has_db=$(detect_has_db "$file")
  has_cache=$(detect_has_cache "$file")
  has_auth=$(detect_has_auth "$file")
  has_payment=$(detect_has_payment "$file")
  has_api=$(detect_has_api "$file")

  echo "sequenceDiagram"

  # Declare participants
  $has_user    && echo "  participant User"
  echo "  participant UI[UI / Frontend]"
  echo "  participant API[${title} API]"
  $has_auth    && echo "  participant Auth[Auth Service]"
  $has_db      && echo "  participant DB[(Data Store)]"
  $has_cache   && echo "  participant Cache[(Cache)]"
  $has_payment && echo "  participant PaymentGW[Payment Gateway]"

  echo ""

  # Emit representative interactions
  if $has_auth; then
    $has_user && echo "  User->>UI: Submit request"
    echo "  UI->>Auth: Authenticate"
    echo "  Auth-->>UI: Token"
    echo "  UI->>API: Request + Token"
  else
    $has_user && echo "  User->>UI: Submit request"
    echo "  UI->>API: POST /request"
  fi

  if $has_cache; then
    echo "  API->>Cache: Check cache"
    echo "  Cache-->>API: Cache miss"
  fi

  $has_db && echo "  API->>DB: Read / Write data"
  $has_db && echo "  DB-->>API: Result"

  if $has_payment; then
    echo "  API->>PaymentGW: Process payment"
    echo "  PaymentGW-->>API: Payment result"
  fi

  echo "  API-->>UI: Response"
  $has_user && echo "  UI-->>User: Display result"
}

# ── Emit a Mermaid flowchart derived from the HLD content ────────────────────
generate_flow_diagram() {
  local file="$1"
  local basename="$2"
  local title node_id
  title=$(to_title "$basename")
  node_id=$(to_node_id "$basename")

  local has_user has_db has_cache has_auth has_payment has_api
  has_user=$(detect_has_user "$file")
  has_db=$(detect_has_db "$file")
  has_cache=$(detect_has_cache "$file")
  has_auth=$(detect_has_auth "$file")
  has_payment=$(detect_has_payment "$file")
  has_api=$(detect_has_api "$file")

  echo "flowchart LR"
  echo ""
  echo "  subgraph System[\"${title}\"]"
  echo "    ${node_id}API[${title} API]"
  $has_db    && echo "    DB[(Data Store)]"
  $has_cache && echo "    Cache[(Cache)]"
  echo "  end"
  echo ""

  # Actors / entry points
  $has_user && echo "  User([User]) --> UI[UI / Frontend]"
  $has_user && echo "  UI --> ${node_id}API" || echo "  Client --> ${node_id}API"

  # Internal flows
  $has_cache && echo "  ${node_id}API --> Cache"
  $has_db    && echo "  ${node_id}API --> DB"

  # External services
  local externals=()
  $has_auth    && externals+=("AuthSvc[Auth Service]")
  $has_payment && externals+=("PaymentGW[Payment Gateway]")

  if [ "${#externals[@]}" -gt 0 ]; then
    echo ""
    echo "  subgraph Ext[\"External Services\"]"
    for ext in "${externals[@]}"; do
      echo "    ${ext}"
    done
    echo "  end"
    echo ""
    for ext in "${externals[@]}"; do
      local ext_id
      ext_id=$(echo "$ext" | sed 's/\[.*//')
      echo "  ${node_id}API --> ${ext_id}"
    done
  fi
}

# ── Generate one LLD file per HLD file ───────────────────────────────────────
for HLD_FILE in "$@"; do
  # Strip "-hld" suffix and derive LLD basename
  # e.g. "doc/hld/payment-flow-hld.md" -> "payment-flow"
  HLD_BASENAME=$(basename "$HLD_FILE" .md)
  FEATURE_BASENAME="${HLD_BASENAME%-hld}"
  OUTPUT_FILE="${LLD_OUTPUT_DIR}/${FEATURE_BASENAME}-lld.md"

  echo "Writing: ${HLD_FILE} -> ${OUTPUT_FILE}"

  OVERVIEW=$(get_overview "$HLD_FILE")
  [ -z "$OVERVIEW" ] && OVERVIEW="Auto-generated LLD for \`${FEATURE_BASENAME}\`. See source HLD file for details."

  ASSUMPTIONS=$(get_assumptions "$HLD_FILE")
  TITLE=$(to_title "$FEATURE_BASENAME")

  {
    echo "# Low-Level Design: ${TITLE}"
    echo ""
    echo "> **Auto-generated** from \`${HLD_FILE}\`"
    echo "> triggered by PR #${PR_NUMBER}: *${PR_TITLE}*"
    echo ">"
    echo "> Generated: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo ""
    echo "---"
    echo ""
    echo "## Overview"
    echo ""
    echo "${OVERVIEW}"
    echo ""
    echo "---"
    echo ""
    echo "## Sequence Diagram"
    echo ""
    echo '```mermaid'
    generate_sequence_diagram "$HLD_FILE" "$FEATURE_BASENAME"
    echo '```'
    echo ""
    echo "---"
    echo ""
    echo "## Flow Diagram"
    echo ""
    echo '```mermaid'
    generate_flow_diagram "$HLD_FILE" "$FEATURE_BASENAME"
    echo '```'
    echo ""
    echo "---"
    echo ""
    echo "## Components / Modules"
    echo ""
    echo "| Component | Responsibility | Technology |"
    echo "|-----------|----------------|------------|"
    echo "| <!-- TODO: fill in components --> | | |"
    echo ""
    echo "---"
    echo ""
    echo "## Assumptions"
    echo ""
    if [ -n "$ASSUMPTIONS" ]; then
      echo "${ASSUMPTIONS}"
    else
      echo "<!-- TODO: list assumptions -->"
    fi
    echo ""
    echo "---"
    echo ""
    echo "## Open Questions"
    echo ""
    echo "<!-- TODO: list open questions or decisions still needed. -->"
  } > "$OUTPUT_FILE"

  echo "LLD written to: ${OUTPUT_FILE}"
done
