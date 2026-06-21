#!/usr/bin/env bash
# generate-hld.sh
#
# Generates one HLD file per input requirement Markdown file.
# Each HLD includes a Mermaid-based Solution Architecture Diagram derived
# from the requirement content.
#
# Usage:
#   generate-hld.sh <output-dir> <pr-number> <pr-title> <req-file> [<req-file> ...]
#
# Arguments:
#   output-dir   Directory where HLD files are written (e.g. "doc/hld")
#   pr-number    Pull-request number           (e.g. "42")
#   pr-title     Pull-request title            (e.g. "Add payment flow")
#   req-file...  One or more requirement Markdown files to process
#
# Output naming:
#   doc/requirements/payment-flow.md        -> doc/hld/payment-flow-hld.md
#   doc/requirements/user-authentication.md -> doc/hld/user-authentication-hld.md

set -euo pipefail

HLD_OUTPUT_DIR="${1:?Usage: generate-hld.sh <output-dir> <pr-number> <pr-title> <req-file> [...]}"
PR_NUMBER="${2:-unknown}"
PR_TITLE="${3:-unknown}"
shift 3

if [ "$#" -eq 0 ]; then
  echo "No requirement files specified. HLD not generated."
  exit 0
fi

echo "Generating HLD file(s) in '${HLD_OUTPUT_DIR}' from $# requirement file(s):"
printf '  %s\n' "$@"

# ── Ensure output directory exists ───────────────────────────────────────────
mkdir -p "$HLD_OUTPUT_DIR"

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

# ── Return file content with "Out of scope" section stripped ─────────────────
active_content() {
  awk '
    /^## Out of scope/{skip=1; next}
    /^## / && skip { skip=0 }
    !skip { print }
  ' "$1"
}

# ── Extract the first non-blank paragraph after "## Overview" ────────────────
# Limit to 5 lines to keep the overview concise in the generated HLD;
# the full requirement file is available via the source reference in the header.
get_overview() {
  awk '/^## Overview/{found=1; next} found && /^## /{exit} found && NF{print}' "$1" \
    | head -5
}

# ── Extract bullet lines from "## Assumptions" ───────────────────────────────
get_assumptions() {
  awk '/^## Assumptions/{found=1; next} found && /^## /{exit} found && /^-/{print}' "$1"
}

# ── Emit a Mermaid flowchart derived from the requirement content ─────────────
generate_mermaid() {
  local file="$1"
  local basename="$2"
  local title node_id content

  title=$(to_title "$basename")
  node_id=$(to_node_id "$basename")
  # Use only "active" content (excludes Out of scope) for component detection
  content=$(active_content "$file")

  # ── Detect actors ──────────────────────────────────────────────────────────
  local has_user=false
  echo "$content" | grep -qi '\buser\b\|\bclient\b\|\bbrowser\b' && has_user=true

  # ── Detect internal components ─────────────────────────────────────────────
  local has_db=false has_cache=false
  echo "$content" | grep -qi '\bdatabase\b\|\bdata store\b\|\bstorage\b\|\bpersist\b\|\bsession\b' \
    && has_db=true
  echo "$content" | grep -qi '\bcache\b\|\bredis\b' && has_cache=true

  # ── Detect external / upstream services ────────────────────────────────────
  local externals=()
  echo "$content" | grep -qi 'product catalog\|catalog service\|catalog data' \
    && externals+=("CatalogSvc[Product Catalog]")
  echo "$content" | grep -qi '\bpricing\b\|\bdiscount\b' \
    && externals+=("PricingSvc[Pricing Service]")
  echo "$content" | grep -qi '\bpayment\b\|\bpayment gateway\b' \
    && externals+=("PaymentGW[Payment Gateway]")
  echo "$content" | grep -qi '\bauth\b\|authentication\|identity\|\boauth\b\|\bsso\b' \
    && externals+=("AuthSvc[Auth Service]")
  echo "$content" | grep -qi 'notification\|email service\|\bsms\b\|push notification' \
    && externals+=("NotifSvc[Notification Service]")
  echo "$content" | grep -qi '\binventory\b\|\bstock\b\|\bwarehouse\b' \
    && externals+=("InvSvc[Inventory Service]")

  # ── Emit the flowchart ─────────────────────────────────────────────────────
  echo "flowchart LR"
  echo ""
  echo "  subgraph System[\"${title}\"]"
  echo "    ${node_id}[${title} Service]"
  $has_db    && echo "    DB[(Data Store)]"
  $has_cache && echo "    Cache[(Cache)]"
  echo "  end"
  echo ""

  $has_user && echo "  User([User]) --> ${node_id}"
  $has_db   && echo "  ${node_id} --> DB"
  $has_cache && echo "  ${node_id} --> Cache"

  if [ "${#externals[@]}" -gt 0 ]; then
    echo ""
    echo "  subgraph Ext[\"External Services\"]"
    for ext in "${externals[@]}"; do
      echo "    ${ext}"
    done
    echo "  end"
    echo ""
    for ext in "${externals[@]}"; do
      # Each entry in externals is in the format "NodeId[Label]" (set above);
      # strip everything from the first '[' to extract the node ID.
      local ext_id
      ext_id=$(echo "$ext" | sed 's/\[.*//')
      echo "  ${node_id} --> ${ext_id}"
    done
  fi
}

# ── Generate one HLD file per requirement file ────────────────────────────────
for REQ_FILE in "$@"; do
  BASENAME=$(basename "$REQ_FILE" .md)
  OUTPUT_FILE="${HLD_OUTPUT_DIR}/${BASENAME}-hld.md"

  echo "Writing: ${REQ_FILE} -> ${OUTPUT_FILE}"

  OVERVIEW=$(get_overview "$REQ_FILE")
  [ -z "$OVERVIEW" ] && OVERVIEW="Auto-generated HLD for \`${BASENAME}\`. See source requirement file for details."

  ASSUMPTIONS=$(get_assumptions "$REQ_FILE")

  {
    echo "# High-Level Design: ${BASENAME}"
    echo ""
    echo "> **Auto-generated** from \`${REQ_FILE}\`"
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
    echo "## Solution Architecture Diagram"
    echo ""
    echo '```mermaid'
    generate_mermaid "$REQ_FILE" "$BASENAME"
    echo '```'
    echo ""
    echo "---"
    echo ""
    echo "## Components"
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

  echo "HLD written to: ${OUTPUT_FILE}"
done
