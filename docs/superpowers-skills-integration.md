# Superpowers Skills — Integration Guide

Which skills from [obra/superpowers](https://github.com/obra/superpowers/tree/main/skills) complement this blueprint, and which ones overlap with it.

---

## The Overlap Rule

The blueprint already owns:

- **Parallel execution** — `run_in_background: true` is a mandatory default, not a choice
- **Subagent dispatch** — Builder/Validator pairing + PITER pipeline owns task delegation
- **Execution orchestration** — TeamCreate, task_create, send_message, TeamDelete is the protocol

Any superpowers skill that re-solves one of these three things creates a competing layer. Don't use it.

---

## Skills That Overlap — Do Not Use

| Skill | Why it overlaps |
|---|---|
| `dispatching-parallel-agents` | Blueprint mandates parallel-by-default. This skill plans what the protocol already enforces. |
| `subagent-driven-development` | Builder/Validator pairing + PITER is the blueprint's execution model. Same pattern, different wrapper. |
| `executing-plans` | Explicitly defers to `subagent-driven-development` when subagents are available — which is always in this setup. Dead skill. |

---

## Skills That Complement — Use These

These cover phases the blueprint is silent on.

| Skill | When to invoke |
|---|---|
| `brainstorming` | Before any new feature, component, or behavior change. Hard gate: no code without approved design. |
| `writing-plans` | Before any multi-step implementation. Produces the plan document the blueprint then executes. |
| `systematic-debugging` | Before proposing any fix. Root cause must be named before a solution is written. |
| `verification-before-completion` | Before claiming any task done. Evidence before assertions — complements stop hooks but applies to Claude itself too. |
| `finishing-a-development-branch` | When implementation is complete and you need to decide how to merge, PR, or clean up. |
| `requesting-code-review` | After completing a major task or feature. Dispatches a focused reviewer with crafted context. |
| `receiving-code-review` | Before implementing review feedback. Requires technical evaluation, not performative agreement. |

---

## Situational

| Skill | When it applies |
|---|---|
| `test-driven-development` | Projects with a test suite. Write the failing test first. |
| `using-git-worktrees` | Parallel feature branches needing isolation from the main workspace. |

---

## Sequence in Practice

```
brainstorming → approved design
writing-plans → plan document
[blueprint takes over: TeamCreate, Builder/Validator, PITER, TeamDelete]
verification-before-completion → evidence gathered
requesting-code-review → review dispatched
receiving-code-review (if feedback arrives) → evaluate before implementing
finishing-a-development-branch → merge/PR/cleanup
```

The blueprint is the execution engine. The superpowers skills are the bookends around it.