#!/usr/bin/env bash
# generate-hld.sh
#
# Assembles a High-Level Design (HLD) document from all Markdown files
# found inside the watched folder.
#
# Usage:
#   generate-hld.sh <watched-folder> <output-file> <pr-number> <pr-title>
#
# Arguments:
#   watched-folder  Folder that was changed in the merged PR (e.g. "docs")
#   output-file     Destination HLD file          (e.g. "docs/HLD.md")
#   pr-number       Pull-request number           (e.g. "42")
#   pr-title        Pull-request title            (e.g. "Add API design notes")

set -euo pipefail

WATCHED_FOLDER="${1:?Usage: generate-hld.sh <watched-folder> <output-file> <pr-number> <pr-title>}"
OUTPUT_FILE="${2:?Usage: generate-hld.sh <watched-folder> <output-file> <pr-number> <pr-title>}"
PR_NUMBER="${3:-unknown}"
PR_TITLE="${4:-unknown}"

# ── Discover .md files ────────────────────────────────────────────────────────
mapfile -t MD_FILES < <(find "$WATCHED_FOLDER" -name "*.md" | sort)

if [ "${#MD_FILES[@]}" -eq 0 ]; then
  echo "No Markdown files found in '${WATCHED_FOLDER}'. HLD not generated."
  exit 0
fi

echo "Generating HLD from ${#MD_FILES[@]} Markdown file(s):"
printf '  %s\n' "${MD_FILES[@]}"

# ── Ensure output directory exists ───────────────────────────────────────────
mkdir -p "$(dirname "$OUTPUT_FILE")"

# ── Write HLD document ───────────────────────────────────────────────────────
{
  echo "# High-Level Design (HLD)"
  echo ""
  echo "> **Auto-generated** from Markdown files in \`${WATCHED_FOLDER}\`"
  echo "> triggered by PR #${PR_NUMBER}: *${PR_TITLE}*"
  echo ">"
  echo "> Generated: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo ""
  echo "---"
  echo ""

  # ── Table of Contents ────────────────────────────────────────────────────
  echo "## Table of Contents"
  echo ""
  echo "1. [System Overview](#system-overview)"
  idx=2
  for f in "${MD_FILES[@]}"; do
    fname=$(basename "$f" .md)
    # GitHub-flavoured anchor: lower-case, spaces → hyphens, strip non-alnum/hyphen,
    # collapse consecutive hyphens, trim leading/trailing hyphens
    anchor=$(echo "$fname" \
      | tr '[:upper:]' '[:lower:]' \
      | tr ' ' '-' \
      | tr -cd '[:alnum:]-' \
      | sed 's/-\{2,\}/-/g; s/^-//; s/-$//')
    echo "${idx}. [${fname}](#${anchor})"
    idx=$((idx + 1))
  done
  echo "$((idx)). [Components](#components)"
  echo "$((idx + 1)). [Data and Control Flow](#data-and-control-flow)"
  echo "$((idx + 2)). [Assumptions](#assumptions)"
  echo "$((idx + 3)). [Open Questions](#open-questions)"
  echo ""
  echo "---"
  echo ""

  # ── System Overview placeholder ──────────────────────────────────────────
  echo "## System Overview"
  echo ""
  echo "<!-- TODO: provide a concise summary of the overall system."
  echo "     A cloud agent or developer should replace this section with a"
  echo "     narrative derived from the source Markdown files listed below. -->"
  echo ""
  echo "---"
  echo ""

  # ── Inline each source Markdown file ─────────────────────────────────────
  for f in "${MD_FILES[@]}"; do
    fname=$(basename "$f" .md)
    echo "## ${fname}"
    echo ""
    echo "<!-- Source: ${f} -->"
    echo ""
    cat "$f"
    echo ""
    echo "---"
    echo ""
  done

  # ── Structural HLD sections (stubs for human/agent review) ───────────────
  echo "## Components"
  echo ""
  echo "<!-- TODO: list the main components or services identified in the"
  echo "     source documents above, e.g.:"
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

echo "HLD document written to: ${OUTPUT_FILE}"
