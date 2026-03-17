# /setup — Blueprint Configuration Wizard

Run this once when you first clone the repo. I will ask you a few questions and configure the blueprint for your project.

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

---

## Step 5 — Confirm

Tell the user:

> "Setup complete. Your selected skills are saved in `SKILLS.md`. The Planner will reference this file when decomposing tasks. Run `/prime-dev` to start your first build session."
