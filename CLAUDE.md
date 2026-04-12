# CLAUDE.md

## Project Overview

Reusable agent team blueprint for building apps autonomously. You describe what you want to build, the lead creates a team with a Planner, Builders, and Validator as native Claude Code teammates. The Planner refines your idea into a structured blueprint, Builders execute with deterministic quality gates, the Validator verifies against acceptance criteria.

Uses native Claude Code Agent Teams — teammates are full Claude Code instances with shared task lists and direct inter-agent messaging.

## Core Principles

See `docs/agent-design-principles.md` for the full Disler/Stripe foundation.

- **Filesystem as State** — every handoff is a file, never a conversation
- **The walls matter more than the model** — deterministic gates enforce quality via exit codes
- **Scoped context per agent** — each teammate reads ONLY what its task lists
- **Skills per task, not global** — Planner assigns skills based on task complexity
- **Bounded escalation** — hard retry caps, then surface to human
- **Team deletion after mission** — hard context reset, no stale context

## Team Structure

You are the lead session. You create the team and spawn teammates.

| Role | Model | Spawn mode | Tools | Purpose |
|---|---|---|---|---|
| Planner | Opus | Plan approval | All | Refine rough input → blueprint. Decompose into tasks. |
| Builder(s) | Sonnet | Full autonomy | Read, Write, Edit, Glob, Grep — **NO Bash** | Claim tasks, write code, report verify commands. |
| Validator | Sonnet | Full autonomy, read-only | Read, Glob, Grep — **NO Bash** | Verify deliverables against blueprint. Cannot edit code. |

**Bash boundary:** The orchestrator (lead session) owns ALL shell execution. Builders and Validators run as background agents where Bash permission blocks indefinitely — their `tools:` frontmatter excludes it structurally. When a task requires runnable verification, the Builder writes the files and reports `Verify by running:` commands; the orchestrator runs them after the Builder completes.

## Pipeline

1. **Phase 0 — Intake:** You describe what to build → spawn Planner → Planner asks up to 3 questions → writes `blueprint.md` → you approve
2. **Phase 1 — Planning:** Planner decomposes blueprint into tasks → creates shared task list with dependencies
3. **Phase 2 — Execution:** Spawn Builders → they self-claim tasks → `TaskCompleted` hook gates quality → circuit breaker at 3 retries
4. **Phase 3 — Validation:** Spawn Validator → checks deliverables against acceptance criteria → writes `validation_report.md` → messages Builders on failures → max 2 rounds
5. **Phase 4 — Completion:** Review results → commit/PR/cleanup → shut down teammates → clean up team

Only Phase 0 and Phase 4 involve you. See `docs/specs/2026-03-12-agent-team-blueprint-design.md` for full spec.

## Quality Gates (Hooks)

| Hook | Target | Action |
|---|---|---|
| `TeammateIdle` | Planner | Validate blueprint completeness + enforce Criteria/Verify boundary (rejects shell verbs in Criteria). `exit(2)` if failing. |
| `TaskCompleted` | Builders | Run linter + type check on output files. `exit(2)` if failing. Circuit breaker at 3. |

**Task field contract:** Every blueprint task requires 8 fields, including the **Criteria** / **Verify (orchestrator runs)** split. Criteria must be statically verifiable by re-reading output (no "tests pass", "lint passes", "builds successfully"). Shell commands go in Verify, which the orchestrator runs.

## Code Exploration Policy

Always use jCodemunch-MCP tools for code navigation. Never fall back to Read, Grep, Glob, or Bash for code exploration.

```
Read / Grep / Glob / Bash  →  last resort only (markdown, JSON data files)
jcodemunch-mcp             →  default for ALL code navigation
```

**Start any session:**
1. `list_repos` — confirm the project is indexed. If not: `index_folder { "path": "." }`

**Finding code:**
- symbol by name → `search_symbols` (add `kind=`, `language=`, `file_pattern=` to narrow)
- string, comment, config value → `search_text` (supports regex, `context_lines`)

**Reading code:**
- before opening any file → `get_file_outline` first
- one symbol → `get_symbol`
- multiple symbols → `get_symbols` (batch)

**Repo structure:**
- `get_repo_outline` → dirs, languages, symbol counts
- `get_file_tree` → file layout, filter with `path_prefix`

**After editing/adding a file:** `index_folder { "path": ".", "incremental": true }` to keep the index fresh.
**After deleting a file:** `invalidate_cache { "repo": "local/<repo-name>" }` — incremental does NOT prune stale symbols for deleted files.

**Enforcement:** Prompt policy (this section) + tool hooks in `~/.claude/settings.json`. Full details: `docs/tools/jcodemunch-mcp.md`

## Project Structure

```
.claude/
  settings.json           # CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS enabled
  agents/                 # planner.md, builder.md, validator.md
  commands/prime-dev.md   # Pre-build ritual — load before every session (also at ~/.claude/commands/ for cross-repo use)
  hooks/validators/       # TeammateIdle + TaskCompleted gate scripts
docs/
  agent-design-principles.md    # Disler/Stripe agentic engineering blueprint
  skill-contract-principles.md  # Skill contracts, task ancestry, skill refinement (universal)
  agent-boundary-principles.md  # Agent vs. code boundary rules — Planner reads this
  agent-design-process/         # How to design agent systems — process guides, build upon over time
    how-to-design-agent-systems.md
  specs/                        # Design specs (per-project, dated)
templates/
  blueprint.md                  # Blueprint template the Planner fills out
```
