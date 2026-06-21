#!/usr/bin/env bash
# generate-hld.sh
#
# Generates one HLD file per input requirement Markdown file.
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

# ── Generate one HLD file per requirement file ────────────────────────────────
for REQ_FILE in "$@"; do
  BASENAME=$(basename "$REQ_FILE" .md)
  OUTPUT_FILE="${HLD_OUTPUT_DIR}/${BASENAME}-hld.md"

  echo "Writing: ${REQ_FILE} -> ${OUTPUT_FILE}"

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

    # ── Table of Contents ──────────────────────────────────────────────────
    echo "## Table of Contents"
    echo ""
    echo "1. [System Overview](#system-overview)"
    # Derive GitHub-flavoured anchor: lowercase, spaces→hyphens, strip non-alnum/hyphen
    ANCHOR=$(echo "$BASENAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
    echo "2. [${BASENAME}](#${ANCHOR})"
    echo "3. [Components](#components)"
    echo "4. [Data and Control Flow](#data-and-control-flow)"
    echo "5. [Assumptions](#assumptions)"
    echo "6. [Open Questions](#open-questions)"
    echo ""
    echo "---"
    echo ""

    # ── System Overview placeholder ────────────────────────────────────────
    echo "## System Overview"
    echo ""
    echo "<!-- TODO: provide a concise summary of the overall system."
    echo "     A cloud agent or developer should replace this section with a"
    echo "     narrative derived from the source Markdown file listed below. -->"
    echo ""
    echo "---"
    echo ""

    # ── Inline source Markdown file ────────────────────────────────────────
    echo "## ${BASENAME}"
    echo ""
    echo "<!-- Source: ${REQ_FILE} -->"
    echo ""
    cat "$REQ_FILE"
    echo ""
    echo "---"
    echo ""

    # ── Structural HLD sections (stubs for human/agent review) ────────────
    echo "## Components"
    echo ""
    echo "<!-- TODO: list the main components or services identified in the"
    echo "     source document above, e.g.:"
    echo ""
    echo "| Component | Responsibility | Technology |"
    echo "|-----------|---------------|------------|"
    echo "| API       | REST endpoint  | Spring Boot|"
    echo "-->"
    echo ""
    echo "---"
    echo ""
    echo "## Data and Control Flow"
    echo ""
    echo "<!-- TODO: describe or diagram the data and control flow."
    echo "     Example Mermaid sequence diagram:"
    echo ""
    echo '```mermaid'
    echo "sequenceDiagram"
    echo "    participant Client"
    echo "    participant API"
    echo "    participant DB"
    echo "    Client->>API: HTTP Request"
    echo "    API->>DB: Query"
    echo "    DB-->>API: Result"
    echo "    API-->>Client: HTTP Response"
    echo '```'
    echo "-->"
    echo ""
    echo "---"
    echo ""
    echo "## Assumptions"
    echo ""
    echo "<!-- TODO: list assumptions, e.g.:"
    echo "- The API is stateless."
    echo "- Authentication is handled externally."
    echo "-->"
    echo ""
    echo "---"
    echo ""
    echo "## Open Questions"
    echo ""
    echo "<!-- TODO: list open questions or decisions still needed. -->"

  } > "$OUTPUT_FILE"

  echo "HLD written to: ${OUTPUT_FILE}"
done
