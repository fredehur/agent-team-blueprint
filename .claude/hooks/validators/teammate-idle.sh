#!/bin/bash
# TeammateIdle hook — validates blueprint completeness when Planner goes idle.
# exit 0 = pass (teammate may go idle)
# exit 2 = block (teammate keeps working, stderr becomes feedback)

set -euo pipefail

INPUT=$(cat)
TEAMMATE=$(echo "$INPUT" | jq -r '.teammate_name // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Only gate the Planner. Builders are gated by TaskCompleted instead.
if [[ "$TEAMMATE" != *planner* && "$TEAMMATE" != *Planner* ]]; then
  exit 0
fi

BLUEPRINT="${CWD}/blueprint.md"

if [[ ! -f "$BLUEPRINT" ]]; then
  echo "Blueprint file not found at ${BLUEPRINT}. You must write blueprint.md before going idle." >&2
  exit 2
fi

CONTENT=$(cat "$BLUEPRINT")

MISSING=()

# Required sections from the spec
SECTIONS=(
  "## Mission"
  "## Stack"
  "## Deliverables"
  "## Acceptance Criteria"
  "## Constraints"
  "## Context Files"
  "## Task Breakdown"
)

for section in "${SECTIONS[@]}"; do
  if ! echo "$CONTENT" | grep -q "^${section}"; then
    MISSING+=("$section")
  fi
done

# Check sections aren't just the template placeholder — must have content after the heading
for section in "${SECTIONS[@]}"; do
  # Skip if already missing entirely
  if [[ " ${MISSING[*]:-} " == *" $section "* ]]; then
    continue
  fi

  section_name="${section## }"
  # Extract content between this heading and the next ## heading (or EOF)
  section_content=$(echo "$CONTENT" | sed -n "/^${section}/,/^## /p" | tail -n +2 | head -n -1)

  # Strip HTML comments and whitespace
  stripped=$(echo "$section_content" | sed 's/<!--.*-->//g' | sed '/^\s*$/d' | tr -d '[:space:]')

  if [[ -z "$stripped" ]]; then
    MISSING+=("$section (empty — still has template placeholder only)")
  fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "Blueprint is incomplete. The following sections are missing or empty:" >&2
  for m in "${MISSING[@]}"; do
    echo "  - $m" >&2
  done
  echo "" >&2
  echo "Fill all required sections before completing your work." >&2
  exit 2
fi

# Validate Task Breakdown has at least one task with required fields
TASK_FIELDS=("Skills:" "Input:" "Output:" "Feeds into:" "Context:" "Criteria:" "Verify (orchestrator runs):" "Blocked by:")
TASK_SECTION=$(echo "$CONTENT" | sed -n '/^## Task Breakdown/,//p')

if ! echo "$TASK_SECTION" | grep -q "^### Task"; then
  echo "Task Breakdown section has no tasks defined. Add at least one '### Task N: [name]' entry." >&2
  exit 2
fi

MISSING_FIELDS=()
for field in "${TASK_FIELDS[@]}"; do
  if ! echo "$TASK_SECTION" | grep -q "\\*\\*${field}\\*\\*"; then
    MISSING_FIELDS+=("$field")
  fi
done

if [[ ${#MISSING_FIELDS[@]} -gt 0 ]]; then
  echo "Tasks in blueprint are missing required fields:" >&2
  for f in "${MISSING_FIELDS[@]}"; do
    echo "  - **${f}**" >&2
  done
  echo "" >&2
  echo "Every task must have: Skills, Input, Output, Feeds into, Context, Criteria, Verify (orchestrator runs), Blocked by." >&2
  exit 2
fi

# --- Criteria boundary scan: reject shell-dependent Criteria ---
# Builders cannot run Bash. Any Criteria entry that depends on executing
# code (tests, linters, builds, scripts) belongs in Verify (orchestrator runs),
# not in Criteria. Scan each Criteria block for forbidden execution verbs.
#
# Forbidden phrases — case-insensitive substring match:
FORBIDDEN_PATTERNS=(
  "tests? pass"
  "all tests passing"
  "pytest passes"
  "npm test passes"
  "lint passes"
  "ruff passes"
  "eslint passes"
  "no lint errors"
  "type[- ]?check passes"
  "mypy passes"
  "tsc passes"
  "builds successfully"
  "compiles"
  "npm run build succeeds"
  "the script runs"
  "the command outputs"
  "the server starts"
)

# Extract the content of every **Criteria:** field block. A Criteria block
# starts at "**Criteria:**" and ends at the next "**" field (e.g.
# "**Verify" or "**Blocked"). We collect all of them into one buffer for
# pattern matching.
CRITERIA_BUFFER=$(echo "$TASK_SECTION" | awk '
  /\*\*Criteria:\*\*/ { in_block=1; next }
  in_block && /^\*\*[A-Z]/ { in_block=0 }
  in_block { print }
')

VIOLATIONS=()
for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
  if echo "$CRITERIA_BUFFER" | grep -Eqi "$pattern"; then
    # Capture the offending line(s) for the error message
    matched_lines=$(echo "$CRITERIA_BUFFER" | grep -Ei "$pattern" | head -3)
    VIOLATIONS+=("Forbidden phrase \"${pattern}\" found in a Criteria field:")
    while IFS= read -r line; do
      [[ -n "$line" ]] && VIOLATIONS+=("    ${line}")
    done <<< "$matched_lines"
  fi
done

if [[ ${#VIOLATIONS[@]} -gt 0 ]]; then
  echo "Blueprint Criteria contain shell-dependent verbs. Builders cannot run Bash —" >&2
  echo "those checks belong in **Verify (orchestrator runs):**, not **Criteria:**." >&2
  echo "" >&2
  for v in "${VIOLATIONS[@]}"; do
    echo "  ${v}" >&2
  done
  echo "" >&2
  echo "Fix: rewrite each offending Criteria as a STATIC check (file existence, content" >&2
  echo "substring, function presence, balanced syntax) and move the execution check to" >&2
  echo "the task's Verify (orchestrator runs) field. The lead will run those commands." >&2
  exit 2
fi

exit 0
