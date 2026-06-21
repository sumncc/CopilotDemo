#!/usr/bin/env bash
# generate-stories.sh
#
# Generates one implementation-ready story file per input LLD Markdown file.
# Each story file correlates requirement, HLD, and LLD content and emits an
# ordered backlog that preserves delivery dependency order.
#
# Usage:
#   generate-stories.sh <output-dir> <pr-number> <pr-title> <lld-file> [<lld-file> ...]
#
# Arguments:
#   output-dir   Directory where story files are written (e.g. "doc/stories")
#   pr-number    Pull-request number that triggered generation
#   pr-title     Pull-request title that triggered generation
#   lld-file...  One or more LLD Markdown files to process
#
# Output naming:
#   doc/lld/payment-flow-lld.md        -> doc/stories/payment-flow-stories.md
#   doc/lld/user-authentication-lld.md -> doc/stories/user-authentication-stories.md

set -euo pipefail

STORY_OUTPUT_DIR="${1:?Usage: generate-stories.sh <output-dir> <pr-number> <pr-title> <lld-file> [...]}"
PR_NUMBER="${2:-unknown}"
PR_TITLE="${3:-unknown}"
shift 3

if [ "$#" -eq 0 ]; then
  echo "No LLD files specified. Stories not generated."
  exit 0
fi

echo "Generating story file(s) in '${STORY_OUTPUT_DIR}' from $# LLD file(s):"
printf '  %s\n' "$@"

mkdir -p "$STORY_OUTPUT_DIR"

# Clear previously generated story outputs so each run starts from a clean set
# while preserving the checked-in README for guidance.
find "$STORY_OUTPUT_DIR" -mindepth 1 -maxdepth 1 ! -name 'README.md' -delete

to_title() {
  echo "$1" | sed 's/-/ /g' \
    | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1'
}

to_story_prefix() {
  echo "$1" | tr '[:lower:]-' '[:upper:]_' | sed 's/[^A-Z0-9_]/_/g'
}

read_if_exists() {
  local file="$1"
  if [ -f "$file" ]; then
    cat "$file"
  fi
}

active_requirement_content() {
  local file="$1"
  awk '
    /^## Out of scope/{skip=1; next}
    /^## / && skip { skip=0 }
    !skip { print }
  ' "$file"
}

contains_pattern() {
  local text="$1"
  local pattern="$2"
  printf '%s' "$text" | grep -Eiq "$pattern"
}

markdown_escape() {
  echo "$1" | sed 's/|/\\|/g'
}

append_story() {
  local rows_file="$1"
  local criteria_file="$2"
  local story_prefix="$3"
  local title="$4"
  local jira_level="$5"
  local priority="$6"
  local depends_on="$7"
  local description="$8"
  local criteria="$9"

  STORY_SEQ=$((STORY_SEQ + 1))
  LAST_STORY_SEQ="${STORY_SEQ}"

  local story_id
  story_id=$(printf "%s-%02d" "$story_prefix" "$STORY_SEQ")

  if [ -z "$depends_on" ]; then
    depends_on="None"
  fi

  printf '| %s | %s | %s | %s | %s | %s | %s | %s |\n' \
    "$STORY_SEQ" \
    "$story_id" \
    "$(markdown_escape "$title")" \
    "$jira_level" \
    "$priority" \
    "$STORY_SEQ" \
    "$(markdown_escape "$depends_on")" \
    "$(markdown_escape "$description")" \
    >> "$rows_file"

  {
    echo "### ${STORY_SEQ}. ${title}"
    IFS='|' read -r -a criteria_items <<< "$criteria"
    for item in "${criteria_items[@]}"; do
      printf -- '- %s\n' "$item"
    done
    echo ""
  } >> "$criteria_file"
}

add_integration_story() {
  local rows_file="$1"
  local criteria_file="$2"
  local story_prefix="$3"
  local feature_title="$4"
  local integration_name="$5"
  local depends_on="$6"

  append_story \
    "$rows_file" \
    "$criteria_file" \
    "$story_prefix" \
    "Integrate ${integration_name} with ${feature_title}" \
    "Story" \
    "High" \
    "$depends_on" \
    "Implement the ${integration_name} touchpoints, request/response handling, and failure paths described across the requirement, HLD, and LLD documents for ${feature_title}." \
    "${integration_name} request and response mappings are documented and implemented|Retry, timeout, and failure handling are defined for ${integration_name}|Integration points align with the generated HLD and LLD diagrams"
}

for LLD_FILE in "$@"; do
  LLD_BASENAME=$(basename "$LLD_FILE" .md)
  FEATURE_BASENAME="${LLD_BASENAME%-lld}"
  FEATURE_TITLE=$(to_title "$FEATURE_BASENAME")
  STORY_PREFIX=$(to_story_prefix "$FEATURE_BASENAME")
  OUTPUT_FILE="${STORY_OUTPUT_DIR}/${FEATURE_BASENAME}-stories.md"

  REQUIREMENT_FILE="doc/requirements/${FEATURE_BASENAME}.md"
  HLD_FILE="doc/hld/${FEATURE_BASENAME}-hld.md"

  if [ -f "$REQUIREMENT_FILE" ]; then
    REQUIREMENT_TEXT="$(active_requirement_content "$REQUIREMENT_FILE")"
  else
    REQUIREMENT_TEXT=""
  fi
  HLD_TEXT="$(read_if_exists "$HLD_FILE")"
  LLD_TEXT="$(read_if_exists "$LLD_FILE")"
  COMBINED_CONTEXT=$(printf '%s\n%s\n%s\n' "$REQUIREMENT_TEXT" "$HLD_TEXT" "$LLD_TEXT")

  echo "Writing: ${LLD_FILE} -> ${OUTPUT_FILE}"

  HAS_USER=false
  HAS_DB=false
  HAS_API=false
  HAS_UI=false
  HAS_AUTH=false
  HAS_PAYMENT=false
  HAS_CATALOG=false
  HAS_PRICING=false
  HAS_NOTIFICATION=false
  HAS_INVENTORY=false
  HAS_CACHE=false

  contains_pattern "$COMBINED_CONTEXT" '\buser\b|\bclient\b|\bbrowser\b' && HAS_USER=true
  contains_pattern "$COMBINED_CONTEXT" '\bapi\b|\brest\b|\bhttp\b|\bendpoint\b|\bservice\b' && HAS_API=true
  contains_pattern "$COMBINED_CONTEXT" '\bui\b|\bfrontend\b|page|screen|workflow' && HAS_UI=true
  contains_pattern "$COMBINED_CONTEXT" '\bdatabase\b|\bdata store\b|\bstorage\b|\bpersist\b|\bsession\b|\bentity\b|\bschema\b' && HAS_DB=true
  contains_pattern "$COMBINED_CONTEXT" '\bauth\b|authentication|identity|oauth|sso|token' && HAS_AUTH=true
  contains_pattern "$COMBINED_CONTEXT" '\bpayment\b|\bgateway\b' && HAS_PAYMENT=true
  contains_pattern "$COMBINED_CONTEXT" 'product catalog|catalog service|catalog data|\bcatalog\b' && HAS_CATALOG=true
  contains_pattern "$COMBINED_CONTEXT" '\bpricing\b|\bdiscount\b|\btax\b' && HAS_PRICING=true
  contains_pattern "$COMBINED_CONTEXT" 'notification|email service|\bsms\b|push notification|alert' && HAS_NOTIFICATION=true
  contains_pattern "$COMBINED_CONTEXT" '\binventory\b|\bstock\b|\bwarehouse\b' && HAS_INVENTORY=true
  contains_pattern "$COMBINED_CONTEXT" '\bcache\b|\bredis\b' && HAS_CACHE=true

  TMP_DIR=$(mktemp -d /tmp/story-generator.XXXXXX)
  ROWS_FILE="${TMP_DIR}/rows.md"
  CRITERIA_FILE="${TMP_DIR}/criteria.md"
  SIGNALS_FILE="${TMP_DIR}/signals.md"
  trap 'rm -rf "$TMP_DIR"' EXIT

  if [ -n "$REQUIREMENT_TEXT" ]; then
    echo "- Requirement context loaded from \`${REQUIREMENT_FILE}\`" >> "$SIGNALS_FILE"
  else
    echo "- Requirement context not found at \`${REQUIREMENT_FILE}\`; stories were derived from HLD and LLD only" >> "$SIGNALS_FILE"
  fi
  if [ -n "$HLD_TEXT" ]; then
    echo "- HLD diagram and component context loaded from \`${HLD_FILE}\`" >> "$SIGNALS_FILE"
  else
    echo "- HLD context not found at \`${HLD_FILE}\`" >> "$SIGNALS_FILE"
  fi
  echo "- LLD sequence and flow context loaded from \`${LLD_FILE}\`" >> "$SIGNALS_FILE"
  $HAS_DB && echo "- Persistence or session management was detected in the design context" >> "$SIGNALS_FILE"
  $HAS_API && echo "- Service/API responsibilities were detected in the design context" >> "$SIGNALS_FILE"
  $HAS_USER && echo "- User-facing behavior was detected in the design context" >> "$SIGNALS_FILE"
  $HAS_CACHE && echo "- Cache-related behavior was detected in the design context" >> "$SIGNALS_FILE"

  STORY_SEQ=0
  LAST_STORY_SEQ=0

  append_story \
    "$ROWS_FILE" \
    "$CRITERIA_FILE" \
    "$STORY_PREFIX" \
    "Establish ${FEATURE_TITLE} implementation baseline" \
    "Epic" \
    "Highest" \
    "" \
    "Set up the implementation boundaries, module ownership, and shared configuration required to build ${FEATURE_TITLE} in line with the requirement, HLD, and LLD documents." \
    "Implementation modules and ownership align with the HLD and LLD structure|Shared configuration and environment assumptions for ${FEATURE_TITLE} are identified|Delivery scope and sequencing are confirmed before downstream work begins"
  setup_seq="$LAST_STORY_SEQ"

  domain_depends="$setup_seq"
  if $HAS_DB; then
    append_story \
      "$ROWS_FILE" \
      "$CRITERIA_FILE" \
      "$STORY_PREFIX" \
      "Model ${FEATURE_TITLE} domain data and persistence" \
      "Story" \
      "Highest" \
      "$domain_depends" \
      "Define the core entities, persistence/session model, and lifecycle rules required by ${FEATURE_TITLE}, using the requirement terminology and the data flow described in the design documents." \
      "Core entities or session objects for ${FEATURE_TITLE} are defined|Persistence boundaries and data lifecycle rules are documented|Required validation or state-transition rules are identified before service implementation"
  else
    append_story \
      "$ROWS_FILE" \
      "$CRITERIA_FILE" \
      "$STORY_PREFIX" \
      "Define ${FEATURE_TITLE} core domain contracts" \
      "Story" \
      "Highest" \
      "$domain_depends" \
      "Capture the core domain objects, business rules, and internal contracts for ${FEATURE_TITLE} from the combined requirement, HLD, and LLD context." \
      "Core business objects for ${FEATURE_TITLE} are named and bounded|Invariants and state transitions are identified from the design content|Downstream implementation work can rely on a stable domain contract"
  fi
  domain_seq="$LAST_STORY_SEQ"

  if $HAS_API || $HAS_USER || $HAS_UI; then
    append_story \
      "$ROWS_FILE" \
      "$CRITERIA_FILE" \
      "$STORY_PREFIX" \
      "Define ${FEATURE_TITLE} service and API contracts" \
      "Story" \
      "High" \
      "$domain_seq" \
      "Specify the service boundaries, API contracts, validation rules, and error handling required to expose ${FEATURE_TITLE} to its callers and user-facing flows." \
      "Endpoints or service entry points are identified from the design context|Input, output, and validation rules are documented|Error handling and contract expectations are clear for downstream integration work"
    api_seq="$LAST_STORY_SEQ"
  else
    api_seq="$domain_seq"
  fi

  integration_dependency="$api_seq"
  if [ "$integration_dependency" = "$domain_seq" ]; then
    integration_dependency="$domain_seq"
  fi

  INTEGRATION_SEQS=()
  if $HAS_AUTH; then
    add_integration_story "$ROWS_FILE" "$CRITERIA_FILE" "$STORY_PREFIX" "$FEATURE_TITLE" "authentication and identity services" "$integration_dependency"
    INTEGRATION_SEQS+=("$LAST_STORY_SEQ")
  fi
  if $HAS_CATALOG; then
    add_integration_story "$ROWS_FILE" "$CRITERIA_FILE" "$STORY_PREFIX" "$FEATURE_TITLE" "product catalog services" "$integration_dependency"
    INTEGRATION_SEQS+=("$LAST_STORY_SEQ")
  fi
  if $HAS_PRICING; then
    add_integration_story "$ROWS_FILE" "$CRITERIA_FILE" "$STORY_PREFIX" "$FEATURE_TITLE" "pricing and discount services" "$integration_dependency"
    INTEGRATION_SEQS+=("$LAST_STORY_SEQ")
  fi
  if $HAS_PAYMENT; then
    add_integration_story "$ROWS_FILE" "$CRITERIA_FILE" "$STORY_PREFIX" "$FEATURE_TITLE" "payment processing services" "$integration_dependency"
    INTEGRATION_SEQS+=("$LAST_STORY_SEQ")
  fi
  if $HAS_INVENTORY; then
    add_integration_story "$ROWS_FILE" "$CRITERIA_FILE" "$STORY_PREFIX" "$FEATURE_TITLE" "inventory services" "$integration_dependency"
    INTEGRATION_SEQS+=("$LAST_STORY_SEQ")
  fi
  if $HAS_NOTIFICATION; then
    add_integration_story "$ROWS_FILE" "$CRITERIA_FILE" "$STORY_PREFIX" "$FEATURE_TITLE" "notification services" "$integration_dependency"
    INTEGRATION_SEQS+=("$LAST_STORY_SEQ")
  fi
  if $HAS_CACHE; then
    add_integration_story "$ROWS_FILE" "$CRITERIA_FILE" "$STORY_PREFIX" "$FEATURE_TITLE" "cache and performance layers" "$integration_dependency"
    INTEGRATION_SEQS+=("$LAST_STORY_SEQ")
  fi

  workflow_depends="$api_seq"
  if [ "${#INTEGRATION_SEQS[@]}" -gt 0 ]; then
    workflow_depends=$(printf '%s,' "${INTEGRATION_SEQS[@]}")
    workflow_depends="${workflow_depends%,}"
  fi

  append_story \
    "$ROWS_FILE" \
    "$CRITERIA_FILE" \
    "$STORY_PREFIX" \
    "Implement ${FEATURE_TITLE} orchestration workflow" \
    "Story" \
    "Medium" \
    "$workflow_depends" \
    "Implement the end-to-end application workflow for ${FEATURE_TITLE}, including control flow, state transitions, and coordination between internal components and any dependent services." \
    "Happy-path workflow follows the sequence and flow diagrams from the design docs|State transitions and coordination rules are implemented in dependency order|Failure paths and recovery behavior are identified for the main workflow"
  workflow_seq="$LAST_STORY_SEQ"

  if $HAS_USER || $HAS_UI; then
    append_story \
      "$ROWS_FILE" \
      "$CRITERIA_FILE" \
      "$STORY_PREFIX" \
      "Deliver ${FEATURE_TITLE} user-facing workflow" \
      "Task" \
      "Medium" \
      "$workflow_seq" \
      "Connect the user-facing interaction flow, screen behavior, and response handling required to make ${FEATURE_TITLE} usable from the documented entry points." \
      "UI or user interaction flow matches the requirement and LLD sequence|User-visible validation and error states are defined|User journey remains consistent with the documented workflow"
    ux_seq="$LAST_STORY_SEQ"
  else
    ux_seq="$workflow_seq"
  fi

  append_story \
    "$ROWS_FILE" \
    "$CRITERIA_FILE" \
    "$STORY_PREFIX" \
    "Validate and operationalize ${FEATURE_TITLE}" \
    "Task" \
    "Medium" \
    "$ux_seq" \
    "Add the testing, observability, and release-readiness work needed to verify ${FEATURE_TITLE} once the implementation flow is complete." \
    "Unit, integration, or workflow-level test coverage is identified for the critical path|Monitoring, logging, or support diagnostics are defined for the implemented flow|Acceptance checks confirm the delivered behavior matches the source design documents"

  {
    echo "# Stories: ${FEATURE_BASENAME}"
    echo ""
    echo "> **Auto-generated** from \`${LLD_FILE}\`"
    echo "> triggered by PR #${PR_NUMBER}: *${PR_TITLE}*"
    echo ">"
    echo "> Generated: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo ""
    echo "## Generation Context"
    echo ""
    echo "- Requirement source: \`${REQUIREMENT_FILE}\`"
    echo "- HLD source: \`${HLD_FILE}\`"
    echo "- LLD source: \`${LLD_FILE}\`"
    echo ""
    echo "## Design Signals Used"
    echo ""
    cat "$SIGNALS_FILE"
    echo ""
    echo "## Ordered Jira Stories"
    echo ""
    echo "| Seq | Story ID | Jira Title | Jira Level | Priority | Execution Order | Depends On | Description |"
    echo "|-----|----------|------------|------------|----------|-----------------|------------|-------------|"
    cat "$ROWS_FILE"
    echo ""
    echo "## Acceptance Criteria"
    echo ""
    cat "$CRITERIA_FILE"
  } > "$OUTPUT_FILE"

  rm -rf "$TMP_DIR"
  trap - EXIT

  echo "Stories written to: ${OUTPUT_FILE}"
done
