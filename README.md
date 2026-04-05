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

### Prerequisites

- [Claude Code](https://claude.ai/code) installed (`npm install -g @anthropic-ai/claude-code`)
- Claude Code version **≥ 1.0** (Agent Teams require a recent release)
- A Claude Max or API subscription
- [jcodemunch MCP server](https://github.com/jcodemunch/jcodemunch) configured — used by the Orchestrator for indexed code navigation (see [Code Navigation](#code-navigation) below)

### Installation

```bash
git clone https://github.com/your-org/agent-team-blueprint.git
cd agent-team-blueprint
```

No dependencies to install — the blueprint is pure Claude Code configuration.

Agent Teams are already enabled via `.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

### Starting a session

**First time only:**
1. Open Claude Code in the repo root
2. Run `/setup` — answers 3 questions about your project, selects which skills (superpowers) the Planner can assign to Builder tasks, writes `SKILLS.md`

**Every session:**
1. Run `/prime-dev` — loads principles, declares team structure, confirms protocol checklist
2. Describe what you want to build
3. Claude creates the team and runs the pipeline — you are only involved in Phase 0 (approve the blueprint) and Phase 4 (review the result)

## Slash Commands (Skills)

Slash commands in `.claude/commands/` are **repo-portable superpowers** — they ship with the repo and are instantly available to anyone who clones it, with no extra setup. They are plain Markdown files that Claude Code picks up automatically. When you type `/prime-dev`, Claude reads `.claude/commands/prime-dev.md` and executes the instructions inside.

This blueprint ships with two commands:

| Command | File | When to run |
|---|---|---|
| `/setup` | `.claude/commands/setup.md` | **Once, when you first clone the repo.** Asks which skills you want, writes `SKILLS.md`. |
| `/prime-dev` | `.claude/commands/prime-dev.md` | **Every build session.** Loads principles, declares team, confirms checklist. |

Run `/setup` first — it configures which skills the Planner is allowed to assign. Then `/prime-dev` before every session.

### The Skills system — superpowers for your pipeline

Claude Code ships with a built-in **Skills system**: a set of Anthropic-provided slash commands that give agents specialized capabilities mid-task. These are distinct from your repo's own commands — they are always available globally, no setup required.

The blueprint supports two skill sources — pick whichever fits:

| Path | How | When |
|---|---|---|
| **Built-in only** | Select from the 4 built-in Claude Code skills during `/setup` | Fastest start, no extra repo needed |
| **Private skills repo** | Point `/setup` at your own `github.com/you/agent-skills` registry | You have domain-specific skills beyond the built-ins |

Both paths produce the same `SKILLS.md` output — `/setup` asks which path you want upfront.

The blueprint is designed to use them. When the Planner writes a `## Task Breakdown`, the `**Skills:**` field on each task is where it assigns these superpowers to Builders:

```markdown
### Task 2: Refactor auth module
- **Skills:** simplify
- **Input:** `src/auth.ts`
- **Output:** `src/auth.ts` (rewritten)
- **Criteria:** No functions longer than 30 lines, no duplicate logic
- **Blocked by:** Task 1
```

The Builder reads that field and invokes `/simplify` mid-execution — not at the end, but as part of producing the output. The skill runs, reviews the code, and fixes issues before the `TaskCompleted` hook fires.

**Useful skills to assign in the `Skills:` field:**

| Skill | When the Planner should assign it |
|---|---|
| `simplify` | Any task producing new code — reviews for reuse, quality, and efficiency, then fixes |
| `excalidraw-diagram` | Architecture or data-flow tasks that benefit from a visual artifact |
| `claude-api` | Tasks that integrate with the Anthropic SDK or Claude API |

The Planner should assign skills based on task complexity — not globally, and not by default. A simple file write needs no skill. A complex refactor or AI integration task should always get one.

### When to use superpowers skills

Skills are the bookends around the blueprint. One skill per phase — the blueprint owns everything in between.

| Phase | Skill |
|---|---|
| New feature or behavior change | `superpowers:brainstorming` — hard gate, no code without approved design |
| Multi-step implementation | `superpowers:writing-plans` — produces the plan |
| **Blueprint executes** | TeamCreate → Builder → Validator → TeamDelete |
| Before claiming done | `superpowers:verification-before-completion` — evidence before assertions |
| After major task | `superpowers:requesting-code-review` |
| Receiving review feedback | `superpowers:receiving-code-review` |
| Ready to integrate | `superpowers:finishing-a-development-branch` |
| Hitting a bug | `superpowers:systematic-debugging` — root cause before any fix |

See [`docs/superpowers-skills-integration.md`](docs/superpowers-skills-integration.md) for the full reference.

### Adding your own commands

Copy `.claude/commands/prime-dev.md` as a template and write any workflow as a Markdown file. Examples of commands teams commonly add:

| Command idea | What it would do |
|---|---|
| `/start-feature` | Read the task, prime context, spawn Planner with the feature brief |
| `/review-pr` | Run Validator against a PR diff and write a review report |
| `/prime-bug` | Load only the bug-specific files + test runner context before debugging |

Commands are committed to the repo — your whole team gets the same workflow, no individual configuration needed.

## Project Structure

```
.claude/
  settings.json              # Agent Teams enabled + hook configuration
  commands/
    setup.md                 # One-time setup wizard — selects skills, writes SKILLS.md
    prime-dev.md             # Pre-build ritual slash command
  agents/
    planner.md               # Opus — blueprint author and task decomposer
    builder.md               # Sonnet — implementation agent
    validator.md             # Sonnet — read-only acceptance gate
  hooks/validators/
    teammate-idle.sh         # Blueprint completeness gate (Planner)
    task-completed.sh        # Linter/type check gate with circuit breaker (Builders)
docs/
  agent-design-principles.md # Disler/Stripe foundation principles
  specs/                     # Design specs
templates/
  blueprint.md               # Template the Planner fills out
```

## Code Navigation

The Primary Orchestrator uses **jcodemunch** — an MCP server that indexes the codebase and exposes structured symbol navigation. This is a Context Engineering requirement: the orchestrator must understand scope before delegating, without polluting its context window by reading full files.

| Task | Tool to use |
|---|---|
| Find where a function is defined | `search_symbols` |
| See all functions/classes in a file | `get_file_outline` |
| Full symbol map of the codebase | `get_repo_outline` |
| Jump straight to a function body | `get_symbol` |
| Text search across indexed files | `search_text` |

**Rule:** Orchestrators use indexed navigation. Raw grep/cat/read is a fallback only — for config files, markdown, or data files not covered by the index.

After cloning, run `index_folder` once to build the index. Re-run after significant file additions.

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
