# Blueprint: [Project Name]

## Mission
<!-- 1-3 sentences. What are we building and why. -->

## Stack
<!-- Exact tech choices. Prevents agents from hallucinating frameworks. -->
- Language:
- Frontend:
- Backend:
- Database:
- Package manager:

## Deliverables
<!-- Exact files/paths this project must produce. The Validator checks these exist. -->
- [ ] `src/...`
- [ ] `tests/...`

## Acceptance Criteria
<!-- What does "done" look like? Machine-checkable where possible. -->
1.
2.
3.

## Constraints
<!-- What NOT to do. Prevents drift and over-engineering. -->
- DO NOT:
- DO NOT:

## Context Files
<!-- What the Builder must read before writing any code. Nothing else. -->
- `path/to/relevant/file`

## Task Breakdown
<!-- Planner decomposes the mission into discrete, ordered tasks. Each task gets assigned skills based on complexity. -->
<!-- BOUNDARY RULE: Builder runs as a background agent with Read/Write/Edit/Glob/Grep only — NO Bash. Every Criteria entry must be checkable by re-reading the produced files. Anything that requires running tests, linters, builds, or scripts goes into the Verify (orchestrator runs) field, never into Criteria. The TeammateIdle gate enforces this. -->

### Task 1: [name]
- **Skills:** [none | list of skills assigned by Planner]
- **Input:** exact files to read — nothing outside this list
- **Output:** exact files to produce — nothing outside this list
- **Feeds into:** [next task / Validator / final deliverable]
- **Context:** one sentence — why this task exists and what depends on it
- **Criteria:** static checks the Builder can verify by re-reading its output (file exists, contains substring X, defines function Y, balanced syntax, no forbidden tokens). NO "tests pass", "lint passes", "builds successfully" — those go below.
- **Verify (orchestrator runs):** exact shell commands the lead session will run after the Builder reports done — `pytest -q`, `ruff check .`, `npm run build`, etc. Write `none` only for pure-text deliverables that need no execution.
- **Blocked by:** nothing | Task N

### Task 2: [name]
- **Skills:**
- **Input:**
- **Output:**
- **Feeds into:**
- **Context:**
- **Criteria:**
- **Verify (orchestrator runs):**
- **Blocked by:**
