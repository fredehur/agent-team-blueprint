# CLAUDE.md

## Project Overview

Reusable agent team blueprint for building apps autonomously. Drop a rough idea, a Planner refines it into a structured blueprint, Builders execute with deterministic quality gates, a Validator verifies against acceptance criteria.

## Core Principles

See `docs/agent-design-principles.md` for the full Disler/Stripe foundation.

- **Filesystem as State** — every handoff is a file, never a conversation
- **The walls matter more than the model** — deterministic gates enforce quality via exit codes
- **Scoped context per agent** — each agent reads ONLY what its task lists
- **Skills per task, not global** — Planner assigns skills based on task complexity
- **Bounded escalation** — hard retry caps, then surface to human
- **Team deletion after mission** — hard context reset, no stale context

## Team Roles

| Role | Model | Purpose |
|---|---|---|
| Planner | Opus | Refine rough input → blueprint. Decompose into tasks. |
| Builder | Sonnet | Execute one task. Write code, local checks, stop. |
| Validator | Sonnet | Verify deliverables against blueprint. Read-only. |
| Orchestrator | Slash command | Phase transitions, fan-out, gates, team lifecycle. |

## Pipeline

Phase 0 (Intake) → Phase 1 (Planning) → Phase 2 (Execution) → Phase 3 (Validation) → Phase 4 (Completion)

Only Phase 0 and Phase 4 involve the human. See `docs/specs/2026-03-12-agent-team-blueprint-design.md` for full pipeline spec.

## Project Structure

```
.claude/
  commands/          # Orchestrator slash command
  agents/            # Planner, Builder, Validator agent definitions
  hooks/validators/  # Deterministic gates (blueprint completeness, linting)
docs/
  agent-design-principles.md    # Disler/Stripe foundation principles
  specs/                        # Design specs
templates/
  blueprint.md                  # Blueprint template the Planner fills out
```

## Commands

| Command | Description |
|---|---|
| `/build` | Main entry point — spins up the team, starts Phase 0 intake |
