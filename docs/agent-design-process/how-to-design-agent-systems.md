# How to Design an Agent System

A process guide for designing agent pipelines from first principles. Use this when the mission involves building or modifying agents — not as a session ritual, but as a thinking framework before any design decisions are made.

Read `docs/agent-boundary-principles.md` alongside this document. The boundary doc states the rules; this doc is the process for applying them.

---

## Step 1 — Define the Intelligence Work

List every task in the system that requires reasoning, language, or judgment. These become your agents.

For each one, answer all three:

```
Agent: [name]
Input:  [exact files or data it receives — typed and named]
Output: [exact files or data it produces — typed and named]
Gate:   [deterministic check that proves the output is correct]
```

**A task with no answer to "Gate" is not ready to design yet.** Go back and define what correct output looks like before proceeding.

---

## Step 2 — Define the Infrastructure Work

List every task that can be expressed as a rule, formula, or deterministic function. These become your code.

For each one, answer:

```
Code: [function name]
Does: [one sentence]
Test: [what the unit test asserts]
Fails with: [exception type — never silent wrong output]
```

If you cannot write a unit test for it — it belongs in Step 1, not here.

---

## Step 3 — Draw the Boundary

State the complete pipeline as a labelled sequence:

```
[CODE]  validate inputs
[AGENT] component-a → assessment output
[CODE]  route based on assessment result
[AGENT] component-b → synthesis output
[CODE]  schema check (quality gate)
[CODE]  pattern check (quality gate)
...
```

**Check every step against these rules before proceeding:**

- Every routing, sequencing, retry, and arithmetic step → CODE
- Every reasoning, language, and judgment step → AGENT
- Every AGENT must be followed by at least one CODE quality gate
- No agent may own its own retry loop — code owns retry logic
- No agent may route work to another agent — code owns routing

Flag any violation before continuing. Do not design around violations — fix the boundary.

---

## Step 4 — Define the Quality Gates

For every AGENT in the pipeline, define its gate:

```
Agent:  [name]
Gate:   [what code checks]
Checks: [schema / pattern / arithmetic / cross-reference]
Fails:  [exit code 2 — never silent pass]
```

Gates are always deterministic code. The only exception: prose quality, which can be a critic agent. Everything else is code.

---

## Step 5 — Declare the Team

State which model handles which role for this build:

- **Orchestrator: Opus** — designs and reviews, does not implement
- **Builder(s): Sonnet** — implements agents and code functions
- **Validator: Sonnet** — verifies output against spec and quality gates

If this is design-only (no code being written this session), state that explicitly.

---

## Step 6 — State Done

One sentence: what agent flow will be built or modified, and what "done" looks like.

Done means:
- [ ] All agents have typed inputs, typed outputs, and a wired quality gate
- [ ] All orchestration, routing, and retry logic is in code — not agent instructions
- [ ] Every agent output is validated by a deterministic gate before the next step
- [ ] The pipeline can be stated as a sequence of AGENT and CODE boxes with no ambiguous steps

---

## Common Violations

| Violation | Symptom | Fix |
|---|---|---|
| Orchestration in markdown | Pipeline described in a `.md` file an LLM follows | Extract to code — `asyncio.gather()`, not prose |
| Agent-owned retry | Agent instructions say "try again up to 3 times" | Move retry counter and circuit breaker to code |
| Gate-free agent | Agent produces output, next step starts immediately | Add schema or pattern check between them |
| Agent routing | Agent decides what runs next based on its output | Code reads the output and routes deterministically |
| Keyword classifier as "intelligence" | Rule-based classifier replaces agent judgment | Code suggests, agent validates and owns final call |
