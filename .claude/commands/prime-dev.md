# /prime-dev — Pre-Build Ritual

> **INLINE EXECUTION ONLY.** Do NOT spawn agents, do NOT call TeamCreate, do NOT run in background. Read the three principle files directly with the Read tool and respond to each checkpoint inline. Teams are declared here in text only — TeamCreate happens when the actual build task starts.

Run this at the start of any development session. I must respond to each checkpoint before touching code.

---

## Bootstrap Note (read first)

This is a **universal command** — used on every project, not specific to any one codebase.

The principles docs live in the **agent-team-blueprint repository** — the single source of truth:

```
C:/Users/frede/agent-team-blueprint/docs/agent-design-principles.md   ← Disler agentic engineering blueprint
C:/Users/frede/agent-team-blueprint/docs/agent-boundary-principles.md ← Agent vs. code boundary rules
C:/Users/frede/agent-team-blueprint/docs/skill-contract-principles.md ← Skill contracts, task ancestry, skill evolution
```

---

## Step 1 — Load Principles

Read all three docs in full from the blueprint repo:

1. `C:/Users/frede/agent-team-blueprint/docs/agent-design-principles.md`
2. `C:/Users/frede/agent-team-blueprint/docs/agent-boundary-principles.md`
3. `C:/Users/frede/agent-team-blueprint/docs/skill-contract-principles.md`

Confirm with: "Principles loaded — [Disler blueprint / Boundary rules / Skill contracts]."

---

## Step 2 — Declare Team Structure

Model assignments are fixed. Do not deviate without stating a reason.

- **Orchestrator: Opus** — coordinate, define contracts, validate final output. Never writes implementation code. **Owns ALL Bash execution** — runs every test, linter, build, and script after Builders/Validators report done.
- **Builder(s): Sonnet** — one sub-agent per independent workstream. Tools: **Read, Write, Edit, Glob, Grep — NO Bash.** Builders write files and report what they changed plus the exact commands the orchestrator should run to verify. State what each will build.
- **Validator: Sonnet** — cross-checks all builder output against the spec before the orchestrator accepts it. Tools: **Read, Glob, Grep — NO Bash, read-only.** Recommends commands; orchestrator runs them.
- **Parallelizable tasks:** [list tasks that can run concurrently, or "none"]

> **Permission rule:** Every Agent tool call that runs in the background MUST include `mode: "bypassPermissions"`. Without it, background agents block on tool approvals with no user to respond — they will appear to hang silently.
>
> **Bash boundary:** Background agents (Builders, Validators) cannot reliably execute Bash. The permission gate blocks indefinitely with no user present. This is enforced by their `tools:` frontmatter — Bash is intentionally absent. When a task involves runnable code, the Builder writes the files and reports `Verify by running:` commands; the orchestrator runs them. See `agent-boundary-principles.md` § Tool Permission Model.

If the task is trivial (single file, <3 steps), state why a team is not warranted. Trivial tasks may use Sonnet directly — no Opus required.

---

## Step 3 — Confirm Protocol Checklist

Answer each line:

- [ ] Teams enabled: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` confirmed
- [ ] jcodemunch will be used for all code navigation (`get_file_outline`, `search_symbols`, `get_symbol`, `get_symbols`) — Read/Grep only for non-indexed files
- [ ] Orchestrator will NOT write implementation code
- [ ] Orchestrator owns ALL Bash — every test, lint, build, script runs in the lead session
- [ ] Builder/Validator have NO Bash in their `tools:` frontmatter — enforced structurally
- [ ] Blueprint tasks use the **Criteria** (static, re-readable) / **Verify (orchestrator runs)** (shell) split — `teammate-idle.sh` rejects shell verbs in Criteria
- [ ] Builder output will be verified by a Validator before acceptance
- [ ] Every Builder Report Format includes a `files_written: [abs paths]` field — orchestrator reads it to confirm files changed
- [ ] Orchestrator will call `index_folder { path: ".", incremental: true }` once after each Builder round — never a full re-index
- [ ] Independent tasks will run in parallel (`run_in_background: true`)
- [ ] All background Agent calls use `mode: "bypassPermissions"` — no exceptions
- [ ] Stop hooks are wired for self-validation
- [ ] TeamDelete will be called after task completes
- [ ] Context discipline: token-heavy work delegated to sub-agents
- [ ] Tasks will carry goal ancestry (`depends_on`, `feeds_into`, `context`)

---

## Step 4 — State the Mission

One sentence: what will be built or fixed this session, and what "done" looks like.

---

## Step 5 — Select Skills

One skill per phase. The blueprint owns execution — skills are the bookends around it.

| Phase | Skill |
|---|---|
| New feature or behavior change | `superpowers:brainstorming` — hard gate, no code without approved design |
| Multi-step implementation | `superpowers:writing-plans` — produces the plan |
| **Blueprint executes** | TeamCreate → Builder → Validator → TeamDelete |
| Before claiming done | `superpowers:verification-before-completion` — **orchestrator** runs the `Verify (orchestrator runs)` commands listed in each Builder's report. Builders cannot self-verify runnable code. |
| After major task | `superpowers:requesting-code-review` |
| Receiving review feedback | `superpowers:receiving-code-review` |
| Ready to integrate | `superpowers:finishing-a-development-branch` |
| Hitting a bug | `superpowers:systematic-debugging` — root cause before any fix |

---

---

## Execution (after all five steps)

**Do NOT ask "which execution approach." There is no choice.**

The execution pattern is fixed by the blueprint:

```
TeamCreate → spawn Builders (Agent tool, bypassPermissions, no Bash) → Validator → Incremental index refresh → TeamDelete
```

Proceed directly to `TeamCreate`. The team was declared in Step 2. Build it now.

**Incremental index refresh (between Validator pass and TeamDelete):**

After the Validator accepts the build, the orchestrator calls `index_folder { path: ".", incremental: true }` once. This re-indexes only files that changed since the last index — not a full re-index. This is a deterministic state-management operation — code territory, owned by the orchestrator, never delegated to a Builder or Validator.

Rules:
- **After writes/edits:** `index_folder { path: ".", incremental: true }` — one call covering all changed files. Never a full re-index. Full re-indexes are a one-time onboarding cost, not a routine step.
- **After deletes:** `invalidate_cache { repo: "local/<repo-name>" }` — incremental does NOT prune stale symbols for deleted files.
- **Skip if no files changed** — read-only sessions (debugging, exploration) don't touch the index.
- **If a Builder's report is missing `files_written`, treat the build as incomplete** and send it back for revision. The field confirms at least one file was written (so index refresh is warranted).

The blueprint owns execution. No skill invocation needed for this step.
