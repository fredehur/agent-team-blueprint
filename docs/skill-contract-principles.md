# Skill Contract Principles

> These principles govern how skills are designed, how tasks carry context, and how agent knowledge compounds over time.
> They are universal — applicable to any agentic system.

---

## The Three Laws

### 1. Skills Are Files With Typed Contracts

A skill is a markdown document. Not a Python class, not a function wrapper, not a prompt string inside application code.

Every skill must define exactly five things:

| Field | Description |
|---|---|
| **Purpose** | One sentence. What judgment work does this skill perform? |
| **Inputs** | Typed. What files, data, or context does it receive? |
| **Outputs** | Typed. What does it write, return, or produce? |
| **Dependencies** | What runtime resources must exist before this skill can run — API keys, external services, database connections, environment variables. These are not data inputs; they are infrastructure preconditions. |
| **Quality gate** | What must be true before this skill exits and returns control? |

A skill missing any of these five fields is not a skill — it is a prompt. Prompts are not auditable, not portable, and not improvable without touching application code.

**The completeness test:** Hand a fresh agent only this file and the declared inputs. If it cannot produce the same quality output as the original, the contract is incomplete. Fix the contract, not the agent.

---

### 2. Tasks Carry Goal Ancestry

Every task handed to an agent must include not just *what to do* but *why it exists*.

A task without ancestry:
```
Write the synthesis report.
```

A task with ancestry:
```
Write the synthesis report.
Depends on: source_data.json, analysis_clusters.json (all present)
Feeds into: report_builder → final_output.json
Context: Component A was flagged in the previous run — this report will be cross-checked for drift
```

**Why ancestry?**
- Validators reason about *intent*, not just *output*. A report that is technically correct but ignores known drift is a validator failure.
- Builders make fewer wrong assumptions when they know what depends on their output.
- Agents stop treating tasks as isolated requests and start treating them as nodes in a flow.

**Required ancestry fields for any task:**
- `depends_on` — inputs this task requires to exist before starting
- `feeds_into` — what consumes this task's output
- `context` — one sentence of why this specific execution matters

Note: do not include orchestration metadata (which pipeline phase, which trigger, what ran before). That is the orchestrator's concern. The agent receives only what shapes its judgment.

---

### 3. Correction Is the Refinement Trigger

A skill is stale when it produces output that requires correction. Correction — not time, not intuition — is the signal.

**The rule:** When an orchestrator or validator overrides, patches, or rejects a skill's output, that event must be logged against the skill file. Three logged corrections against the same skill = mandatory refinement pass before the skill runs again.

Logging format:
```markdown
<!-- correction — YYYY-MM-DD: Validator rejected output. Brief description of what failed
     and why. Fix: what instruction needs to be added or changed in the skill. -->
```

**Why correction as the trigger?**
- Correction is observable and unambiguous. "Something felt off" is not a trigger. A validator rejection is.
- Three corrections create a forcing function. One might be noise. Three is a pattern.
- Logging against the skill file keeps the audit trail with the skill, not in a separate system.

**The refinement pass:** Update the skill's instructions to encode what the corrections revealed. Version the change. The skill runs again clean.

---

## Relationship to the Agent Boundary

These three laws operate *within* agent territory — they govern how agents are structured and how their work compounds.

They do not change the boundary:

- Orchestration, retry logic, state management, arithmetic → still code
- Judgment, language, interpretation, synthesis → still agents

Skill contracts make the agent side more reliable. They do not expand agent responsibility into code territory.

---

## Quick Reference

| Principle | Rule | Violation |
|---|---|---|
| Skills are files | Five fields: purpose, inputs, outputs, dependencies, quality gate | Prompt string in application code |
| Tasks carry ancestry | `depends_on`, `feeds_into`, `context` | "Write the report" with no context |
| Correction triggers refinement | Three validator rejections = mandatory refinement pass | Skill that runs indefinitely without updating |