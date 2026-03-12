# Design Spec: App Builder Agent Team Blueprint

**Date:** 2026-03-12
**Status:** Approved

## Overview

A reusable agent team blueprint that instantiates fresh for each new project. You drop a rough idea, a Planner refines it into a structured blueprint, then Builders execute autonomously with deterministic quality gates at every handoff.

## Core Principles

Derived from Disler's Agentic Engineering framework and Stripe's Minions architecture:

1. **Filesystem as State** — every handoff between agents is a file, never a conversation. Files are auditable, replayable, and don't decay.
2. **The walls matter more than the model** — deterministic gates (hooks, exit codes) enforce quality, not LLM judgment. A well-constrained Sonnet beats an unconstrained Opus.
3. **Scoped context per agent** — each agent reads ONLY what it needs. No global context dumps. R&D Framework: Reduce context, Delegate to sub-agents.
4. **Skills assigned per task, not globally** — the Planner decides which skills each task requires. Trivial tasks stay lean. Complex tasks get full process enforcement.
5. **Bounded escalation** — agents fix their own problems up to a hard cap, then surface to you with specific context. Never infinite loops.
6. **Builder/Validator separation** — the agent that writes code NEVER validates its own code. 2x compute, 10x trust.
7. **Team deletion after mission** — hard context reset after every completed mission. Prevents stale context from polluting future work.

## Team Roles

### Planner (Opus)

- **Purpose:** Refine rough input into an approved Blueprint. Decompose into tasks. Highest reasoning model because this is where ambiguity lives.
- **Reads:** User's rough idea, project context files
- **Writes:** `blueprint.md`
- **Autonomy:** Interactive — asks up to 3 targeted questions, then writes the blueprint and stops. Waits for human approval.
- **Always-on skills:** `brainstorming`, `writing-plans`
- **Gate:** Deterministic check — all blueprint sections filled, no empty fields. `exit(2)` if incomplete.

### Builder (Sonnet)

- **Purpose:** Execute one task from the blueprint. Write code, run local checks, stop.
- **Reads:** ONLY the task definition from the blueprint + the files listed in that task's Input field
- **Writes:** ONLY the files listed in that task's Output field
- **Autonomy:** Full. No human interaction. Executes, self-checks with local linters/tests, stops.
- **Always-on skills:** None — assigned per task by Planner
- **Gate:** Stop hook runs linter + type check. `exit(2)` = forced rewrite. Circuit breaker at 3 retries, then escalate.
- **Parallel:** Multiple Builders can run simultaneously on non-blocked tasks.

### Validator (Sonnet)

- **Purpose:** Verify Builder output against the blueprint. Does NOT read the Builder's reasoning — only the blueprint's acceptance criteria and the produced files.
- **Reads:** `blueprint.md` acceptance criteria + deliverable files
- **Writes:** `validation_report.md` — pass/fail per deliverable with evidence
- **Autonomy:** Full. Read-only access to source files. Cannot edit code.
- **Always-on skills:** `verification-before-completion`
- **Gate:** If any deliverable fails, sends specific failure back to the relevant Builder for rewrite. Max 2 rounds (Stripe pattern), then escalate to human.

### Orchestrator (slash command)

- **Purpose:** Manages the pipeline phases. Spawns agents, reads dependency graph from blueprint, gates transitions between phases.
- **Does NOT:** Write code, make architectural decisions, or reason about the problem. It's a deterministic conductor.
- **Always-on skills:** `dispatching-parallel-agents`, `finishing-a-development-branch`
- **Owns:** Phase transitions, task fan-out, circuit breaker enforcement, team deletion on completion.

## Pipeline Phases

### Phase 0: Intake (human-interactive)

1. User drops a rough idea — text, a file, even a sentence
2. Planner (Opus) invokes `brainstorming` skill
3. Asks up to 3 targeted questions, one at a time
4. Writes `blueprint.md` with all sections filled
5. **Gate:** Deterministic validator checks all required sections present and non-empty. `exit(2)` if incomplete → Planner rewrites
6. Planner stops. User reviews and approves the blueprint
7. **Nothing happens until user approves.**

### Phase 1: Planning (autonomous)

1. Planner invokes `writing-plans` skill
2. Reads approved blueprint, decomposes into ordered tasks with dependencies
3. Assigns skills per task based on complexity
4. Writes task breakdown back into the blueprint
5. **Gate:** Every task must have Input, Output, Criteria, and Blocked-by filled. Deterministic check. `exit(2)` if incomplete.

### Phase 2: Execution (autonomous, parallel where possible)

1. Orchestrator reads task dependency graph
2. Fans out unblocked tasks to Builder agents via `dispatching-parallel-agents`
3. Each Builder receives ONLY: its task definition + listed input files + assigned skills
4. Builder executes, invokes assigned skills, writes output files
5. **Gate:** Stop hook runs linter + type check. `exit(2)` = rewrite. Circuit breaker at 3 retries → escalate to human.
6. As tasks complete, newly unblocked tasks get dispatched

### Phase 3: Validation (autonomous)

1. Validator reads `blueprint.md` acceptance criteria + all deliverable files
2. Invokes `verification-before-completion` — must show evidence, not claims
3. Writes `validation_report.md`: pass/fail per deliverable with proof
4. **Gate:** Any failure → specific feedback sent to the relevant Builder. Max 2 validation rounds (Stripe pattern). Then escalate.

### Phase 4: Completion

1. Orchestrator invokes `finishing-a-development-branch`
2. Presents options: commit, PR, or cleanup
3. Archives blueprint + outputs
4. Deletes the team (hard context reset)

## Escalation Rules

**When agents stop and ask you:**

1. Blueprint gate fails 3 times → Planner asks you what's unclear
2. Builder circuit breaker hits 3 → you see the error and decide
3. Validator fails 2 rounds on same deliverable → you see both the criteria and the output
4. Any agent at any time can raise exactly ONE blocking question if it genuinely can't proceed

**What's never escalated:**

- Linter errors (Builder fixes them or circuit breaks)
- Missing files (Builder creates them or task definition was wrong)
- Test failures (Builder rewrites or circuit breaks)

## Blueprint Template

The structured markdown file that the Planner produces and every downstream agent reads from. See `templates/blueprint.md` for the template.

Required sections (deterministic gate checks these):

- **Mission** — 1-3 sentences. What and why.
- **Stack** — Exact tech choices. Prevents agents from hallucinating frameworks.
- **Deliverables** — Exact files/paths. Validator checks these exist.
- **Acceptance Criteria** — What "done" looks like. Machine-checkable where possible.
- **Constraints** — What NOT to do. Negative instructions are more reliable for LLMs.
- **Context Files** — What the Builder must read. Nothing else.
- **Task Breakdown** — Ordered tasks with Input, Output, Criteria, Blocked-by, and assigned Skills.

## Key Boundaries

- Only Phase 0 and Phase 4 involve you
- Builders never validate their own output
- Validators never edit code
- Skills load per task, not globally
- Team is deleted after every mission

## References

- Disler's Agentic Engineering principles: `docs/agent-design-principles.md`
- [Stripe Minions Part 1](https://stripe.dev/blog/minions-stripes-one-shot-end-to-end-coding-agents)
- [Stripe Minions Part 2](https://stripe.dev/blog/minions-stripes-one-shot-end-to-end-coding-agents-part-2)
