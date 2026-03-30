# Agent Boundary Principles: What Agents Should and Should Not Do

> The most common mistake in agentic systems is using an agent to do what code should do.
> The second most common is using code to do what an agent should do.

---

## The Core Rule

**Agents own reasoning. Code owns correctness.**

Every decision in an agent flow falls into one of two categories:

| Category | Owner | Why |
|----------|-------|-----|
| Requires judgment, language, or interpretation | **Agent** | Deterministic code cannot do it |
| Can be expressed as a rule or formula | **Code** | Agents cannot be trusted to do it reliably |

If you can write a unit test for it, code should own it.
If you cannot write a unit test for it, an agent should own it.

---

## What Agents Own

These are tasks where the output is genuinely non-deterministic — where reasonable people (or models) could produce different valid results, and where quality comes from judgment, not rules.

**Analysis and assessment**
- Reading inputs and forming an assessment
- Judging the credibility and relevance of a source
- Classifying an item as one type vs. another
- Determining what is most important from a large context

**Language generation**
- Translating structured data into natural language
- Adapting tone to audience (technical vs. executive)
- Applying language discipline (knowing what *not* to say)
- Constructing a coherent narrative from disparate inputs

**Judgment under ambiguity**
- Deciding whether a weak signal is worth escalating
- Resolving a conflict between two data sources
- Inferring intent from incomplete information
- Deciding which category best fits an edge case

**Test:** Could you write a deterministic function that reliably produces the same quality output as an agent for this task? If no — it is agent territory.

---

## What Code Owns

These are tasks where correctness is binary — either the output is right or it's wrong — and where an agent introducing non-determinism is a liability, not a feature.

**Orchestration and sequencing**
- What runs next
- Which components to process (in what order, in what parallel structure)
- Fan-out and fan-in logic
- Phase transitions (Phase 1 complete → start Phase 2)

**Retry logic and circuit breakers**
- How many retries are allowed
- What happens when all retries are exhausted
- Whether to fail hard or degrade gracefully

**State management**
- Tracking which tasks are complete
- Recording which files have been written
- Knowing which components are done vs. pending

**Arithmetic and aggregation**
- Summing figures
- Counting items by status
- Computing deltas

**Schema validation**
- Is this JSON well-formed?
- Does this object have the required fields?
- Are field values within expected ranges?

**Error handling and failure modes**
- What happens when a data source returns empty results?
- What happens when a file is missing?
- How to surface failures to the operator

**Test:** Could a deterministic function do this with 100% reliability? If yes — code should own it.

---

## The Failure Modes

### Using an agent for what code should own

**Symptom:** Your orchestration lives in a markdown file that an LLM reads and follows.

**What goes wrong:**
- The agent usually does the right thing, but not always
- When it fails, there is no stack trace — only wrong output
- You cannot unit test the orchestration logic
- Retry counts and circuit breakers are described in prose, not enforced
- A human is required to babysit the pipeline

**Example:** A 7-phase pipeline described in a markdown file, executed by an LLM following instructions. Works 90% of the time. The other 10% is invisible.

**Fix:** Extract the orchestration into code. Keep the agent prompts. The pipeline becomes `asyncio.gather()` calls, not prose instructions.

---

### Using code for what an agent should own

**Symptom:** Your "intelligence" output is a keyword match or a rule-based classifier.

**What goes wrong:**
- The output is technically correct but lacks judgment
- Edge cases produce nonsense because no rule covers them
- The system flags obvious noise and misses subtle signals
- You spend weeks writing rules that an agent handles naturally

**Example:** Using a keyword matcher alone to determine which category applies to an input. A keyword match can suggest the category. Only an agent can validate it against full context.

**Fix:** Use code for the initial hint. Use an agent to validate and own the final determination.

---

## Designing an Agent Flow: The Right Questions

Before writing any agent or code, answer these questions in order:

### 1. What is the intelligence work?

List every task in the flow that requires reasoning, language, or judgment.
These become your agents. Each agent should have:
- A single, focused responsibility
- Clear typed inputs (what files/data does it receive?)
- Clear typed outputs (what does it write?)
- A quality gate (stop hook that proves the output is correct)

### 2. What is the infrastructure work?

List every task that could be expressed as a rule or formula.
These become your functions. Each function should have:
- A unit test
- A clear failure mode (exception, not wrong output)
- No LLM calls

### 3. Map the boundary explicitly

Draw the pipeline as a sequence of boxes. Label each box as either **AGENT** or **CODE**. If you find yourself writing agent instructions that describe routing, retrying, or counting — move those to code. If you find yourself writing code that tries to classify or judge — move those to agents.

### 4. Wire the quality gates

Every agent output needs a deterministic quality gate before the next step begins:
- **Schema check** → code (parse/validate)
- **Arithmetic check** → code (sum validation)
- **Pattern check** → code (regex/word list)
- **Prose quality check** → agent (can only be judged by reasoning)

The gate is always code except for prose quality, which can be an agent acting as a critic.

---

## The Golden Rule

> An agent that controls its own retry loop is an agent that can get stuck forever.
> An agent that does arithmetic is an agent that will eventually hallucinate a number.
> An agent that routes work is an agent that will eventually skip a step.

Put the agent in charge of what it's good at. Put code in charge of everything else.

---

## Quick Reference: Agent vs. Code Decision Table

| Task | Owner | Reason |
|------|-------|--------|
| Write an executive summary | Agent | Language + judgment |
| Classify an input into a category | Agent | Interpretation |
| Validate JSON schema | Code | Binary correct/wrong |
| Sum figures across inputs | Code | Arithmetic |
| Run N tasks in parallel | Code | Orchestration |
| Retry a failed agent (up to N times) | Code | Control flow |
| Assess credibility of a source | Agent | Judgment |
| Check if a file exists | Code | Deterministic |
| Detect a pattern in text (word list) | Code | Pattern match |
| Judge whether prose meets a quality bar | Agent | Nuanced judgment |
| Fan-out to N workers, fan-in when done | Code | Orchestration |
| Decide which category best fits an input | Agent | Classification |
| Validate that output matches expected schema | Code | Cross-check |
| Adapt tone for different audiences | Agent | Language |
| Count items by status | Code | Arithmetic |
| Write a synthesis from N inputs | Agent | Synthesis + language |
| Check that synthesis covers all required items | Code | Validation |