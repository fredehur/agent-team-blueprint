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

| Role | Model | Spawn mode | Purpose |
|---|---|---|---|
| Planner | Opus | Plan approval | Refine rough input → blueprint. Decompose into tasks. |
| Builder(s) | Sonnet | Full autonomy | Claim tasks, write code, local checks, mark complete. |
| Validator | Sonnet | Full autonomy, read-only | Verify deliverables against blueprint. Cannot edit code. |

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
| `TeammateIdle` | Planner | Validate blueprint completeness. `exit(2)` if sections missing. |
| `TaskCompleted` | Builders | Run linter + type check on output files. `exit(2)` if failing. Circuit breaker at 3. |

## Project Structure

```
.claude/
  settings.json        # CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS enabled
  hooks/validators/    # TeammateIdle + TaskCompleted gate scripts
docs/
  agent-design-principles.md    # Disler/Stripe foundation principles
  specs/                        # Design specs
templates/
  blueprint.md                  # Blueprint template the Planner fills out
```
