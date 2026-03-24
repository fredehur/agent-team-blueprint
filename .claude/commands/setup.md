# /setup — Blueprint Configuration Wizard

Run this once when you first clone the repo. I will ask you a few questions and configure the blueprint for your project.

---

## Step 0 — Check superpowers

Run this bash command to check if the superpowers plugin is installed:

```bash
ls ~/.claude/plugins/cache/claude-plugins-official/superpowers 2>/dev/null && echo "INSTALLED" || echo "NOT_FOUND"
```

**If output is `INSTALLED`:** Continue to Step 1.

**If output is `NOT_FOUND`:** Tell the user:

> "The **superpowers** plugin is not installed. It's required for Builder agents to use skills mid-task (TDD, code review, simplify, etc.)."
>
> "Install it now by running this in your terminal:"
>
> ```
> claude plugins install superpowers
> ```
>
> "Once installed, restart Claude Code and re-run `/setup`."

Stop here and do not proceed until superpowers is confirmed installed.

---

## Step 1 — Project type

Ask the user:

> "What are you building? Give me one sentence."

Wait for the answer. Do not proceed until you have it.

---

## Step 2 — Stack detection

Read the current directory for any of these files and note what you find:
- `package.json` → JavaScript/TypeScript project
- `pyproject.toml` or `requirements.txt` → Python project
- `go.mod` → Go project
- `Cargo.toml` → Rust project
- Nothing found → ask the user: "What language/framework are you using?"

---

## Step 3 — Skills selection

Tell the user:

> "Claude Code has a set of built-in skills (superpowers) your Builder agents can use mid-task. Which would you like available in your pipeline?"

Present each option and ask the user to confirm yes or no:

1. **`simplify`** — Reviews any code a Builder writes for quality, reuse, and efficiency, then fixes issues before marking the task complete. Recommended for most projects.
   > "Include `simplify`? (yes / no)"

2. **`excalidraw-diagram`** — Creates visual architecture or data-flow diagrams as Excalidraw files. Useful if your project has complex structure worth mapping.
   > "Include `excalidraw-diagram`? (yes / no)"

3. **`claude-api`** — Specialized guidance for tasks that integrate with the Anthropic SDK or Claude API. Only relevant if your project calls Claude directly.
   > "Include `claude-api`? (yes / no)"

Wait for a yes/no on each before continuing.

---

## Step 4 — Write configuration

Based on the user's answers, write a file called `SKILLS.md` in the current directory:

```markdown
# Skills Configuration

Skills selected for this project. The Planner assigns these in `## Task Breakdown` based on task complexity.

## Available Skills

<!-- List only the skills the user selected, one per line -->
- `simplify` — assign to any task producing new or refactored code
- `excalidraw-diagram` — assign to architecture or data-flow design tasks
- `claude-api` — assign to tasks integrating with the Anthropic SDK

## When to assign

The Planner decides per task — not globally. A simple file write gets `none`.
A complex refactor or AI integration task gets the appropriate skill.
```

Only include the skills the user said yes to.

Then create `.claude/commands/prime-dev.md` in the current directory with this exact content:

```markdown
# /prime-dev — Pre-Build Ritual

Run this at the start of any development session. I must respond to each checkpoint before touching code.

## Step 1 — Read Principles

Read `docs/agent-design-principles.md` in full. Confirm with: "Principles loaded."

## Step 2 — Declare Team Structure

State the team I will use for this session:

- **Orchestrator:** [model] — role
- **Builder(s):** [model] — what they will build
- **Validator(s):** [model] — what they will verify
- **Parallelizable tasks:** [list or "none"]

If the task is trivial (single file, <3 steps), state why a team is not warranted.

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
```

---

## Step 5 — Confirm

Tell the user:

> "Setup complete."
>
> - Superpowers plugin: **installed**
> - Skills saved to: `SKILLS.md`
> - `/prime-dev` command created at `.claude/commands/prime-dev.md`
>
> "Run `/prime-dev` to start your first build session."
