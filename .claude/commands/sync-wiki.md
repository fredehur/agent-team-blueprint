---
name: sync-wiki
description: Push Blueprint project knowledge changes to the Obsidian wiki vault.
tools: Bash, Read, Write, Glob, Grep
model: sonnet
---

You are syncing the Agent Team Blueprint project to the Obsidian wiki vault.

## Configuration

WIKI_PATH: c:\Users\frede\Desktop\Projects
PROJECT_KEY: blueprint
PROJECT_NAME: agent-team-blueprint

## Preview Mode

If the user invoked this as `/sync-wiki preview`, execute ONLY Steps 1-4 below. Do NOT write any files. Instead, report what would be created, updated, and skipped. Then stop.

## Step 1: Determine Baseline

Read `{WIKI_PATH}/wiki/log.md`. Search for the most recent entry matching:

```
## [YYYY-MM-DD] sync | agent-team-blueprint
```

If found, extract the date as BASELINE_DATE.
If no match, this is a first sync — set BASELINE_DATE to "never" (treat all key files as changed).

## Step 2: Detect What Changed

If BASELINE_DATE is a date, run:

```bash
git log --oneline --since="{BASELINE_DATE}" --stat
```

Review the output. Identify which of the following file sets were touched:

| File set | What to look for |
|----------|-----------------|
| `.claude/agents/*.md` | Agent definition changes (model, role, hooks) |
| `docs/*.md` | Principle and process doc changes |
| `docs/agent-design-process/*.md` | Design methodology changes |
| `docs/tools/*.md` | Tool reference doc changes |
| `templates/*.md` | Blueprint template changes |
| `CLAUDE.md` | Project conventions, engineering protocol |
| `README.md` | Architecture, team structure, pipeline phases |
| `docs/specs/*.md` | New design specs |

If BASELINE_DATE is "never", read all files in the above sets.

## Step 3: Read Wiki State

Read `{WIKI_PATH}/wiki/index.md` to see what pages exist.

For each changed file from Step 2, check if a corresponding wiki page exists:
- Agent `.claude/agents/foo.md` → `{WIKI_PATH}/wiki/agents/foo-agent.md`
- Principle doc `docs/bar.md` → check `{WIKI_PATH}/wiki/concepts/` for matching concept
- Design spec → `{WIKI_PATH}/wiki/sources/` (by spec name)

Read existing wiki pages and check their `updated` frontmatter date. If the wiki page is already up to date, skip it.

## Step 4: Apply Scope Rules

**CREATE a new wiki page when:**
- A new file in `.claude/agents/` has no corresponding wiki page → create in `wiki/agents/`
- A new principle doc in `docs/` introduces a concept not yet in the wiki → create in `wiki/concepts/`
- A new design spec in `docs/specs/` → create source page in `wiki/sources/`
- A new concept is explicitly named in a design spec or CLAUDE.md, appears in multiple files, and is not a synonym for an existing concept page → create in `wiki/concepts/`

**UPDATE an existing wiki page when:**
- Agent definition's model, role, or system prompt changed
- A principle doc was revised (new sections, changed rules)
- README.md or CLAUDE.md changed meaningfully (architecture, conventions — not typos)
- Blueprint template structure changed

**SKIP when:**
- Bug fixes, formatting, test changes
- Changes to hook scripts (implementation detail, unless the hook interface changed)
- Typo corrections

**When uncertain, skip.**

If this is a preview run, report the CREATE/UPDATE/SKIP lists and stop here.

## Step 5: Write Updates

For each page to create or update, read the wiki schema at `{WIKI_PATH}/CLAUDE.md` and follow its conventions:

**Frontmatter:**

```yaml
---
type: agent | concept | source
project: blueprint
applied: []
updated: {today's date}
sources: [relevant source references]
tags: [relevant tags]
---
```

For framework concepts: `project: blueprint`. Add `applied: [crq-agent]` if the concept is known to be used in CRQ.

**Templates by type:**
- agent: Role, Model, Inputs, Outputs, Hooks/Gates, Belongs To
- concept: Definition, Where It Appears, Why It Matters, Related Concepts
- source: Citation, Summary, Key Takeaways, Pages Updated

**Linking:** Use `[[wikilinks]]`. First mention of an entity/concept gets a link, subsequent mentions plain text.

Write files to `{WIKI_PATH}/wiki/{category}/{page-name}.md`.

## Step 6: Update Index and Log

**Index** — read `{WIKI_PATH}/wiki/index.md`:
- Add entries for new pages under the correct category section
- Framework concepts go under "### Framework Principles"
- Update descriptions if content changed significantly
- Only rewrite the Synthesis paragraph if a major new entity or concept was added

**Log** — read `{WIKI_PATH}/wiki/log.md`, then prepend a new entry after the `---` separator:

```
## [{today's date}] sync | agent-team-blueprint
{Summary of what changed}. Created: [[page1]], [[page2]].
Updated: [[page3]], [[page4]].
Pages created: N. Pages updated: M.
```

## Step 7: Commit

```bash
git -C "{WIKI_PATH}" add wiki/
git -C "{WIKI_PATH}" commit -m "sync(blueprint): {one-line summary}"
```

If no pages were created or updated, report "Wiki is up to date — no changes to sync." and do not commit.
