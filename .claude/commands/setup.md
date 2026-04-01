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

## Step 3 — Skills source

Ask the user:

> "Do you have a private skills repo? (yes / no)
> — If yes, paste the GitHub repo path (e.g. `yourname/agent-skills`).
> — If no, I'll use the built-in Claude Code skills only."

Wait for the answer.

**If yes — private repo:**

Fetch the registry:

```bash
gh api repos/<their-repo>/contents/REGISTRY.md --jq '.content' | base64 -d
```

If the fetch fails, tell the user:
> "Could not access `<repo>` — check that it exists and `gh` is authenticated. Falling back to built-in skills only."
> Then continue as if they said no.

If successful, present the skills from the registry grouped by category. For each skill, ask:
> "Include `<skill-name>` — <one-line description>? (yes / no)"

Wait for a yes/no on each before continuing.

**If no — built-in skills only:**

Present the following skills that are always available in Claude Code (no repo needed):

| Skill | When to assign |
|---|---|
| `simplify` | Any task producing new code — reviews for quality and efficiency |
| `excalidraw-diagram` | Architecture or data-flow tasks needing a visual artifact |
| `claude-api` | Tasks integrating with the Anthropic SDK or Claude API |
| `frontend-design` | UI tasks requiring polished, production-grade components |

Ask for yes/no on each. These are always available — no additional setup required.

---

## Step 4 — Write SKILLS.md

Write `SKILLS.md` in the current directory with only the skills the user approved:

```markdown
# SKILLS.md

Skills approved for this project. The Planner assigns these per task — not globally.
A simple file write gets `none`. A complex task gets the appropriate skill.

<!-- Source: private repo / built-in Claude Code skills -->

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