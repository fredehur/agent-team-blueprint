# Agent Team Blueprint

Reusable blueprint for building apps autonomously with Claude Code Agent Teams. You describe what you want to build — a Planner, Builders, and Validator do the rest.

## How It Works

You open a session, describe what you want, and tell Claude to create a team following the pipeline. Only two phases involve you — kicking it off and reviewing the result.

```
Phase 0: Intake          You describe → Planner asks ≤3 questions → writes blueprint → you approve
Phase 1: Planning        Planner decomposes blueprint into tasks with dependencies
Phase 2: Execution       Builders claim tasks in parallel, quality-gated by hooks
Phase 3: Validation      Validator checks deliverables against acceptance criteria
Phase 4: Completion      You review → commit/PR → team is deleted (hard context reset)
```

## Team Structure

| Role | Model | Purpose |
|---|---|---|
| **Planner** | Opus | Refines your idea into a structured blueprint. Decomposes into tasks. |
| **Builder(s)** | Sonnet | Claims tasks, writes code, runs local checks. 2-3 run in parallel. |
| **Validator** | Sonnet | Verifies deliverables against blueprint. Read-only — cannot edit code. |

## Quality Gates

Deterministic hooks enforce quality via exit codes — the walls matter more than the model.

| Hook | Target | What it does |
|---|---|---|
| `TeammateIdle` | Planner | Validates `blueprint.md` has all required sections filled. Blocks until complete. |
| `TaskCompleted` | Builders | Runs linter + type check on output files. Circuit breaker at 3 retries → escalates to you. |

Auto-detected tooling: ESLint, TypeScript, Ruff, Flake8, Mypy, `go vet`, Cargo/Clippy — based on whatever the project uses.

## Quick Start

1. Clone this repo (or use it as a template)
2. Open a Claude Code session in the repo
3. Describe what you want to build
4. Tell Claude to create a team and follow the CLAUDE.md pipeline

Agent Teams must be enabled — this is already set in `.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

## Project Structure

```
.claude/
  settings.json              # Agent Teams enabled + hook configuration
  hooks/validators/
    teammate-idle.sh         # Blueprint completeness gate (Planner)
    task-completed.sh        # Linter/type check gate with circuit breaker (Builders)
docs/
  agent-design-principles.md # Disler/Stripe foundation principles
  specs/                     # Design spec
templates/
  blueprint.md               # Template the Planner fills out
```

## Core Principles

Built on Disler's Agentic Engineering framework and Stripe's Minions architecture:

- **Filesystem as State** — every handoff is a file, never a conversation
- **The walls matter more than the model** — deterministic gates enforce quality via exit codes
- **Scoped context per agent** — each teammate reads ONLY what its task lists
- **Builder/Validator separation** — the agent that writes code never validates its own code
- **Bounded escalation** — hard retry caps, then surface to human
- **Team deletion after mission** — hard context reset, no stale context

## Blueprint Template

The Planner produces a `blueprint.md` with these required sections:

- **Mission** — what and why (1-3 sentences)
- **Stack** — exact tech choices (prevents framework hallucination)
- **Deliverables** — exact files/paths (Validator checks these exist)
- **Acceptance Criteria** — what "done" looks like
- **Constraints** — what NOT to do
- **Context Files** — what Builders must read
- **Task Breakdown** — ordered tasks with Input, Output, Criteria, Blocked-by, and assigned Skills

See [`templates/blueprint.md`](templates/blueprint.md) for the full template.

## References

- [Claude Code Agent Teams](https://code.claude.com/docs/en/agent-teams)
- [Stripe Minions Part 1](https://stripe.dev/blog/minions-stripes-one-shot-end-to-end-coding-agents)
- [Stripe Minions Part 2](https://stripe.dev/blog/minions-stripes-one-shot-end-to-end-coding-agents-part-2)
