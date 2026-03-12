# Design Spec: App Builder Agent Team Blueprint

**Date:** 2026-03-12
**Status:** Approved (v2 — updated for native Agent Teams)

## Overview

A reusable agent team blueprint that instantiates fresh for each new project. You drop a rough idea, the lead session creates a team with a Planner, Builders, and Validator as teammates. The Planner refines your idea into a structured blueprint, Builders execute autonomously with deterministic quality gates, and the Validator verifies deliverables.

**Implementation mechanism:** Claude Code native Agent Teams (experimental). The lead session (you) creates the team. Teammates are full Claude Code instances with shared task list and direct inter-agent messaging.

## Core Principles

Derived from Disler's Agentic Engineering framework and Stripe's Minions architecture:

1. **Filesystem as State** — every handoff between agents is a file, never a conversation. Files are auditable, replayable, and don't decay.
2. **The walls matter more than the model** — deterministic gates (hooks, exit codes) enforce quality, not LLM judgment. A well-constrained Sonnet beats an unconstrained Opus.
3. **Scoped context per agent** — each agent reads ONLY what it needs. No global context dumps. R&D Framework: Reduce context, Delegate to sub-agents.
4. **Skills assigned per task, not globally** — the Planner decides which skills each task requires. Trivial tasks stay lean. Complex tasks get full process enforcement.
5. **Bounded escalation** — agents fix their own problems up to a hard cap, then surface to you with specific context. Never infinite loops.
6. **Builder/Validator separation** — the agent that writes code NEVER validates its own code. 2x compute, 10x trust.
7. **Team deletion after mission** — hard context reset after every completed mission. Prevents stale context from polluting future work.

## Team Structure (Native Agent Teams)

You are the **lead session**. You create the team and spawn teammates. Teammates work independently, each in their own context window, and communicate directly with each other.

### Planner (teammate, Opus)

- **Purpose:** Refine rough input into an approved Blueprint. Decompose into tasks.
- **Spawn mode:** Plan approval required — lead must approve the blueprint before Planner proceeds to task decomposition.
- **Reads:** User's rough idea, project context files
- **Writes:** `blueprint.md`
- **Autonomy:** Asks up to 3 targeted questions via messages to the lead, then writes the blueprint and sends it for approval.
- **Always-on skills:** `brainstorming`, `writing-plans`
- **Gate:** `TeammateIdle` hook validates blueprint completeness — all required sections filled. `exit(2)` if incomplete → Planner continues working.

### Builder (teammate(s), Sonnet)

- **Purpose:** Execute tasks from the blueprint. Write code, run local checks, stop.
- **Spawn mode:** Full autonomy. Multiple Builders can run simultaneously.
- **Reads:** ONLY the task definition from the blueprint + the files listed in that task's Input field
- **Writes:** ONLY the files listed in that task's Output field
- **Autonomy:** Full. Claims tasks from the shared task list. Executes, self-checks with local linters/tests, marks task complete.
- **Always-on skills:** None — assigned per task by Planner in the blueprint
- **Gate:** `TaskCompleted` hook runs linter + type check. `exit(2)` = rewrite, task stays open. Circuit breaker at 3 retries → escalate to lead.

### Validator (teammate, Sonnet)

- **Purpose:** Verify Builder output against the blueprint. Does NOT read the Builder's reasoning — only the blueprint's acceptance criteria and the produced files.
- **Spawn mode:** Full autonomy. Read-only — does not edit code.
- **Reads:** `blueprint.md` acceptance criteria + deliverable files
- **Writes:** `validation_report.md` — pass/fail per deliverable with evidence
- **Autonomy:** Full. Spawned after all Builder tasks complete. Messages specific Builders directly with failure feedback.
- **Always-on skills:** `verification-before-completion`
- **Gate:** If any deliverable fails, messages the relevant Builder with specific feedback. Max 2 validation rounds (Stripe pattern). Then escalates to lead.

## Pipeline Phases

### Phase 0: Intake (lead + Planner teammate)

1. You describe what you want to build (text, a file, even a sentence)
2. Lead creates the team and spawns Planner teammate (Opus, plan-approval mode)
3. Planner asks up to 3 targeted questions via messages to the lead
4. Planner writes `blueprint.md` with all sections filled
5. **Gate:** `TeammateIdle` hook validates blueprint completeness. `exit(2)` if incomplete → Planner keeps working
6. Planner sends blueprint for plan approval. Lead reviews and approves.
7. **Nothing proceeds until lead approves the blueprint.**

### Phase 1: Planning (Planner teammate, autonomous)

1. After blueprint approval, Planner decomposes into ordered tasks with dependencies
2. Assigns skills per task based on complexity
3. Writes task breakdown back into the blueprint
4. Creates tasks in the shared task list with proper dependencies (blocked-by)
5. **Gate:** Every task must have Input, Output, Criteria, and Blocked-by filled. `TeammateIdle` hook validates. `exit(2)` if incomplete.
6. Planner messages lead: "Tasks ready. Spawn Builders."

### Phase 2: Execution (Builder teammates, autonomous, parallel)

1. Lead spawns Builder teammates (Sonnet) — 1 per parallel workstream, typically 2-3
2. Each Builder's spawn prompt includes: "Read `blueprint.md`, claim tasks from the shared task list. Read ONLY files listed in each task's Input field. Write ONLY files listed in Output field. Invoke skills listed per task."
3. Builders self-claim unblocked tasks from the shared task list
4. Builder executes, invokes assigned skills, writes output files, marks task complete
5. **Gate:** `TaskCompleted` hook runs linter + type check. `exit(2)` = task stays open, Builder rewrites. Circuit breaker at 3 retries → escalate to lead.
6. As tasks complete, blocked tasks auto-unblock. Builders claim next available work.
7. When all tasks complete, Builders go idle. Lead proceeds to validation.

### Phase 3: Validation (Validator teammate, autonomous)

1. Lead spawns Validator teammate (Sonnet)
2. Validator's spawn prompt: "Read `blueprint.md` acceptance criteria. Check every deliverable exists and meets criteria. Write `validation_report.md` with pass/fail per deliverable and evidence. DO NOT edit any source files."
3. Validator reads deliverables, invokes `verification-before-completion`
4. Writes `validation_report.md`: pass/fail per deliverable with proof
5. **Gate:** Any failure → Validator messages the relevant Builder directly with specific feedback. Builder rewrites. Max 2 validation rounds. Then escalate to lead.

### Phase 4: Completion (lead)

1. Lead reviews `validation_report.md`
2. Decides: commit, PR, or cleanup
3. Shuts down all teammates gracefully
4. Cleans up the team (hard context reset)

## Escalation Rules

**When teammates stop and ask the lead:**

1. Blueprint `TeammateIdle` hook fails 3 times → Planner messages lead asking what's unclear
2. Builder `TaskCompleted` hook circuit breaker hits 3 → lead sees the error and decides
3. Validator fails 2 rounds on same deliverable → lead sees both the criteria and the output
4. Any teammate can raise exactly ONE blocking question if it genuinely can't proceed

**What's never escalated:**

- Linter errors (Builder fixes them or circuit breaks)
- Missing files (Builder creates them or task definition was wrong)
- Test failures (Builder rewrites or circuit breaks)

## Hook Configuration

### TeammateIdle hook

Runs when a teammate is about to go idle. Used to validate work quality before accepting idle state.

**For Planner:** Validates `blueprint.md` has all required sections filled (Mission, Stack, Deliverables, Acceptance Criteria, Constraints, Context Files, Task Breakdown). `exit(2)` with feedback if incomplete.

**For Builders:** No-op (Builders are gated by TaskCompleted instead).

### TaskCompleted hook

Runs when a task is being marked complete. Used to enforce code quality.

**For Builder tasks:** Runs linter and type checker on output files. `exit(2)` with error details if checks fail. Tracks retry count per task — circuit breaker at 3.

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
- No nested teams — teammates cannot spawn their own teams

## Settings Required

```json
// .claude/settings.json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

## References

- Disler's Agentic Engineering principles: `docs/agent-design-principles.md`
- [Claude Code Agent Teams docs](https://code.claude.com/docs/en/agent-teams)
- [Stripe Minions Part 1](https://stripe.dev/blog/minions-stripes-one-shot-end-to-end-coding-agents)
- [Stripe Minions Part 2](https://stripe.dev/blog/minions-stripes-one-shot-end-to-end-coding-agents-part-2)
