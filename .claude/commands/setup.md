# /setup — Project Setup

Run this once when you first clone the blueprint. Configures skills and confirms the project is ready.

---

## Step 0 — Check superpowers

Run this bash command to check if the superpowers plugin is installed:

```bash
ls ~/.claude/plugins/cache/claude-plugins-official/superpowers 2>/dev/null && echo "INSTALLED" || echo "NOT_FOUND"
```

**If `INSTALLED`:** Continue to Step 1.

**If `NOT_FOUND`:** Tell the user:

> "The **superpowers** plugin is required for Builder agents to invoke skills mid-task."
>
> "Install it by running: `claude plugins install superpowers`"
>
> "Restart Claude Code, then re-run `/setup`."

Stop and do not proceed until superpowers is confirmed installed.

---

## Step 1 — Project type

Ask the user:

> "What are you building? One sentence."

Wait for the answer.

---

## Step 2 — Stack detection

Read the current directory for any of these files:
- `package.json` → JavaScript/TypeScript
- `pyproject.toml` or `requirements.txt` → Python
- `go.mod` → Go
- `Cargo.toml` → Rust
- Nothing found → ask: "What language/framework are you using?"

---

## Step 3 — Fetch and select skills

Fetch the skill registry from GitHub:

```bash
gh api repos/fredehur/agent-skills/contents/REGISTRY.md --jq '.content' | base64 -d
```

If the fetch fails (repo not accessible), tell the user and skip to Step 4 with an empty skills list.

If successful, present the skills from the registry grouped by category. For each skill, ask:

> "Include `<skill-name>` — <one-line description>? (yes / no)"

Wait for a yes/no on each before continuing.

---

## Step 4 — Write SKILLS.md

Write `SKILLS.md` in the current directory with only the skills the user approved:

```markdown
# SKILLS.md

Skills approved for this project. The Planner assigns these per task — not globally.
A simple file write gets `none`. A complex task gets the appropriate skill.

Source: https://github.com/fredehur/agent-skills

## Approved Skills

<!-- one line per approved skill: name — description -->
- `<skill>` — <description>

## Assignment rules

- Assign skills based on task complexity, not by default
- One skill per task unless the task genuinely requires two
- Simple file writes, data transforms, config changes → `none`
```

Only include skills the user said yes to.

---

## Step 5 — Confirm

Tell the user:

> "Setup complete."
>
> - Superpowers: **installed**
> - Skills saved to: `SKILLS.md`
> - Principles docs: `docs/` (already present in this repo)
>
> "Run `/prime-dev` to start your first build session."