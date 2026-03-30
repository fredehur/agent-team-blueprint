# /prime-dev — Pre-Build Ritual

Run this at the start of any development session. I must respond to each checkpoint before touching code.

## Step 1 — Load Principles

Read these docs in full:

1. `docs/agent-design-principles.md` — Disler agentic engineering blueprint
2. `docs/skill-contract-principles.md` — skill contracts, task ancestry, skill refinement

Confirm with: "Principles loaded — [Disler blueprint / Skill contracts]."

Note: `docs/agent-boundary-principles.md` is loaded by the Planner agent, not here. It governs task decomposition decisions, not session protocol.

## Step 2 — Declare Team Structure

Model assignments are fixed. Do not deviate without stating a reason.

- **Orchestrator: Opus** — coordinate, define contracts, validate final output. Never writes implementation code.
- **Builder(s): Sonnet** — one sub-agent per independent workstream. State what each will build.
- **Validator: Sonnet** — cross-checks all builder output against the spec before the orchestrator accepts it.
- **Parallelizable tasks:** [list tasks that can run concurrently, or "none"]

If the task is trivial (single file, <3 steps), state why a team is not warranted. Trivial tasks may use Sonnet directly — no Opus required.

## Step 3 — Confirm Protocol Checklist

Answer each line:

- [ ] Teams enabled: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` confirmed
- [ ] Orchestrator will NOT write implementation code
- [ ] Builder output will be verified by a Validator before acceptance
- [ ] Independent tasks will run in parallel (`run_in_background: true`)
- [ ] Stop hooks are wired for self-validation
- [ ] TeamDelete will be called after task completes
- [ ] Context discipline: token-heavy work delegated to sub-agents

## Step 4 — State the Mission

One sentence: what will be built or fixed this session, and what "done" looks like.

---

Only after completing all four steps: begin work.
