# jCodeMunch MCP — Structured Code Retrieval

> Index once. Query cheaply. Keep moving.  
> Precision context beats brute-force context.

jCodeMunch replaces file-opening with structured symbol retrieval. It indexes a codebase once via tree-sitter, stores metadata + byte offsets, and returns exact implementations on demand. Token savings are 90–98% in retrieval-heavy workflows versus brute-force file reading.

**Repo:** [jgravelle/jcodemunch-mcp](https://github.com/jgravelle/jcodemunch-mcp)  
**Full reference:** `USER_GUIDE.md` · `AGENT_HOOKS.md` · `CONTEXT_PROVIDERS.md` · `LANGUAGE_SUPPORT.md`

---

## Core rule

Never open a file to find one function. Search the index first, pull only what you need.

```
Read / Grep / Glob / Bash  →  last resort only
                               (markdown, JSON data files, surrounding context not in index)
jCodeMunch                 →  default for all code navigation
```

Installing the MCP makes tools available. It does **not** change agent behavior. The agent needs an explicit instruction (CLAUDE.md policy) or enforced hooks to actually use it. See [Enforcement](#enforcement-via-hooks-claude-code) below.

---

## How it works (mental model)

Each symbol is indexed with:
- `signature`, `kind`, `qualified_name`, one-line `summary`
- byte offsets into the original source file

Retrieval later uses byte offsets — no re-parsing the whole file. That is why it is fast and token-efficient.

### Symbol ID format

```
{file_path}::{qualified_name}#{kind}

src/main.py::UserService#class
src/main.py::UserService.login#method
src/utils.py::authenticate#function
config.py::MAX_RETRIES#constant
```

IDs are stable across re-indexing as long as path, qualified name, and kind stay the same.

---

## Installation

```bash
pip install jcodemunch-mcp
# or
uvx jcodemunch-mcp      # preferred in MCP client config
```

### Claude Code (fastest)

```bash
claude mcp add jcodemunch uvx jcodemunch-mcp
# project-only:
claude mcp add --scope project jcodemunch uvx jcodemunch-mcp
```

Manual — `~/.claude.json` (user) or `.claude/settings.json` (project):

```json
{
  "mcpServers": {
    "jcodemunch": {
      "command": "uvx",
      "args": ["jcodemunch-mcp"],
      "env": {
        "GITHUB_TOKEN": "ghp_...",
        "ANTHROPIC_API_KEY": "sk-ant-..."
      }
    }
  }
}
```

Restart Claude Code after any config change.

### Index storage

Indexes live at `~/.code-index/` by default:

```
~/.code-index/
├── owner-repo.json        # metadata, hashes, symbol records
└── owner-repo/
    └── src/main.py        # raw file snapshots for byte-offset retrieval
```

---

## Session startup ritual

**Every session on a known project:**

```json
resolve_repo: { "path": "." }
```

`resolve_repo` is an O(1) lookup — use it instead of `list_repos` to confirm the project is indexed.

**On a new or unfamiliar repo:**

```json
resolve_repo: { "path": "." }        // → if not indexed:
index_folder: { "path": "." }        // → then:
suggest_queries: { "repo": "..." }   // surface useful entry points
```

**After editing a file:**

```json
index_file: { "path": "/abs/path/to/file" }
```

`index_file` is surgical and faster than re-running `index_folder`.

---

## Decision tree

```
New / unfamiliar repo?
  → suggest_queries → get_repo_outline → get_file_tree

Symbol by name?
  → search_symbols  (kind=, language=, file_pattern= to narrow)

Typo / partial name?
  → search_symbols(fuzzy=true)

Concept search ("database connection" when code says "db_pool")?
  → search_symbols(semantic=true)          (requires embedding provider)

Most architecturally important symbols?
  → get_symbol_importance                  (PageRank on import graph)

Best-fit context for a task within token budget?
  → get_ranked_context(query, token_budget)

String / comment / config value?
  → search_text                            (supports regex + context_lines)

See all functions/classes in a file before reading?
  → get_file_outline                       (always do this before get_symbol_source)

Read a function or class body?
  → get_symbol_source

Symbol + its imports in one shot?
  → get_context_bundle                     (token_budget= to cap size)

Batch-read multiple related symbols?
  → get_symbol_source(symbol_ids=[...])    (flat batch, one call)

What imports this file?
  → find_importers

Where is an identifier used?
  → find_references                        (or check_references for quick yes/no)

What breaks if I change this symbol?
  → get_blast_radius(include_depth_scores=true) → find_importers

What symbols changed since last commit?
  → get_changed_symbols(include_blast_radius=true)

Dead / unreachable code?
  → find_dead_code                         (or check_references for a single identifier)

Class inheritance chain?
  → get_class_hierarchy

File dependency graph?
  → get_dependency_graph

Two repo snapshots diffed?
  → get_symbol_diff

Database columns (dbt / SQLMesh)?
  → search_columns

CLAUDE.md / agent config bloat, stale symbol refs, dead file paths?
  → audit_agent_config
```

---

## Full tool reference

### Indexing & repository management

| Tool | What it does | Key parameters |
|---|---|---|
| `index_repo` | Index a GitHub repo | `url`, `incremental`, `use_ai_summaries`, `extra_ignore_patterns` |
| `index_folder` | Index a local folder | `path`, `incremental`, `use_ai_summaries`, `follow_symlinks`, `extra_ignore_patterns` |
| `index_file` | Re-index one file — surgical, faster than `index_folder` | `path`, `use_ai_summaries`, `context_providers` |
| `embed_repo` | Precompute and cache all symbol embeddings for semantic search (optional warm-up; also computed lazily on first query) | `repo`, `batch_size`, `force` |
| `list_repos` | List all indexed repos | — |
| `resolve_repo` | Resolve a filesystem path to repo ID — O(1), preferred over `list_repos` | `path` |
| `invalidate_cache` | Delete cached index, force full re-index | `repo` |
| `audit_agent_config` | Scan CLAUDE.md / .cursorrules / copilot-instructions.md etc. for: per-file token cost, stale symbol refs cross-checked against live index, dead file paths, redundancy between global and project configs, bloat, scope leaks | `repo`, `project_path` |

### Discovery & outlines

| Tool | What it does | Key parameters |
|---|---|---|
| `suggest_queries` | Surface useful entry-point files, keywords, and example queries for an unfamiliar repo | `repo` |
| `get_repo_outline` | High-level: dirs, file counts, language breakdown, symbol counts | `repo` |
| `get_file_tree` | File layout, filterable by path prefix | `repo`, `path_prefix`, `include_summaries` |
| `get_file_outline` | All symbols in a file with full signatures + summaries; supports batch via `file_paths` | `repo`, `file_path`, `file_paths` |

### Retrieval

| Tool | What it does | Key parameters |
|---|---|---|
| `get_symbol_source` | Fetch exact symbol source — single: `symbol_id` → flat object; batch: `symbol_ids[]` → `{symbols, errors}` | `repo`, `symbol_id`, `symbol_ids`, `verify`, `context_lines` |
| `get_context_bundle` | Symbol + its imports + optional callers in one bundle; Markdown output; token-budgeted with budget strategy | `repo`, `symbol_id`, `symbol_ids`, `include_callers`, `output_format`, `token_budget`, `budget_strategy` (`most_relevant`/`core_first`/`compact`), `include_budget_report` |
| `get_ranked_context` | Query-driven token-budgeted context assembler — best-fit symbols for a task, ranked by relevance + centrality, greedily packed to budget | `repo`, `query`, `token_budget`, `strategy`, `include_kinds`, `scope` |
| `get_file_content` | Read cached file content, optionally sliced to a line range — **last resort** | `repo`, `file_path`, `start_line`, `end_line` |

### Search

| Tool | What it does | Key parameters |
|---|---|---|
| `search_symbols` | Search by name/signature/summary/docstring; kind/language/file_pattern filters; fuzzy; centrality-aware ranking; semantic/hybrid | `repo`, `query`, `kind`, `language`, `file_pattern`, `max_results`, `token_budget`, `detail_level`, `fuzzy`, `fuzzy_threshold`, `max_edit_distance`, `sort_by` (`relevance`/`centrality`/`combined`), `semantic`, `semantic_weight`, `semantic_only` |
| `search_text` | Full-text search across indexed file contents; regex; context lines; optional semantic | `repo`, `query`, `is_regex`, `file_pattern`, `max_results`, `context_lines`, `semantic` |
| `search_columns` | Column metadata across dbt / SQLMesh / database catalog models | `repo`, `query`, `model_pattern`, `max_results` |

### Relationship & impact analysis

| Tool | What it does | Key parameters |
|---|---|---|
| `find_importers` | What files import a given file; batch via `file_paths`; `has_importers` flag for transitive dead-code chains | `repo`, `file_path`, `file_paths`, `max_results` |
| `find_references` | Where an identifier is imported or referenced; batch via `identifiers` | `repo`, `identifier`, `identifiers`, `max_results` |
| `check_references` | Quick yes/no dead-code check — is this identifier referenced anywhere? Combines import + content search | `repo`, `identifier`, `identifiers`, `search_content`, `max_content_results` |
| `get_dependency_graph` | File-level dependency graph up to 3 hops; direction = imports / importers / both | `repo`, `file`, `direction`, `depth` |
| `get_blast_radius` | What files break if this symbol changes? Returns confirmed/potential impacted files, `overall_risk_score`, `direct_dependents_count`; `include_depth_scores=true` → `impact_by_depth` grouped by BFS layer | `repo`, `symbol`, `depth`, `include_depth_scores` |
| `get_symbol_importance` | Rank symbols by architectural centrality (PageRank or in-degree on import graph) — surfaces load-bearing symbols | `repo`, `top_n`, `algorithm`, `scope` |
| `find_dead_code` | Symbols and files unreachable from any entry point via import graph; entry points auto-detected (main, `__init__`, CLI decorators, etc.) | `repo`, `granularity`, `min_confidence`, `include_tests`, `entry_point_patterns` |
| `get_changed_symbols` | Map a git diff to affected symbols — added/modified/removed/renamed; optional blast radius per changed symbol | `repo`, `since_sha`, `until_sha`, `include_blast_radius`, `max_blast_depth` |
| `get_class_hierarchy` | Full inheritance chain (ancestors + descendants) across Python, TS, Java, C#, and more | `repo`, `class_name` |
| `get_related_symbols` | Symbols related via co-location, shared importers, and name-token overlap | `repo`, `symbol_id`, `max_results` |
| `get_symbol_diff` | Diff symbol sets of two indexed repo snapshots — detects added, removed, changed | `repo_a`, `repo_b` |

### Utilities

| Tool | What it does |
|---|---|
| `get_session_stats` | Token savings, cost avoided, per-tool breakdown for current session |

---

## How search works

`search_symbols` uses weighted BM25 scoring across: exact name match, name substring, word overlap, signature terms, summary terms, docstring + keyword matches. Zero-score results are discarded. Filters (`kind`, `language`, `file_pattern`) narrow the field before scoring.

### Fuzzy matching

`fuzzy=true` enables a trigram Jaccard + Levenshtein fallback when BM25 confidence is low. Use for typos or partial names (`conn` → `connection_pool`). Results include `match_type`, `fuzzy_similarity`, `edit_distance`.

### Centrality-aware ranking

`sort_by="centrality"` ranks by PageRank on the import graph. `sort_by="combined"` blends BM25 + PageRank. Default is `"relevance"` (pure BM25).

### Semantic / hybrid search

`semantic=true` enables embedding-based search alongside BM25. Requires an embedding provider (see [Semantic search](#semantic-search-opt-in)). `semantic_weight` controls the BM25/embedding blend (default 0.5). `semantic_only=true` skips BM25 entirely. Zero performance impact when `semantic=false`.

### Practical guidance

| Situation | Flag |
|---|---|
| Know the symbol name | precise query, no flags |
| Know kind (function/class/etc) | `kind=` |
| Large or polyglot repo | `file_pattern=` or `language=` |
| Typo or partial name | `fuzzy=true` |
| Concept-level query ("auth logic") | `semantic=true` |
| Most important symbols first | `sort_by="centrality"` |

---

## Structural queries grep cannot answer

These are not "faster grep" — they answer questions grep fundamentally cannot:

| Query | Tool |
|---|---|
| What imports this file? | `find_importers` (with `has_importers` for transitive dead-code chains) |
| What breaks if I change this symbol? | `get_blast_radius(include_depth_scores=true)` — BFS layers, risk scores |
| What symbols did this git diff touch? | `get_changed_symbols` — symbol-level, not file-level |
| What code is unreachable? | `find_dead_code` — walks import graph from entry points |
| Which symbols are load-bearing? | `get_symbol_importance` — PageRank on import graph |
| Full class inheritance chain? | `get_class_hierarchy` |
| Does CLAUDE.md reference a renamed function? | `audit_agent_config` — cross-checks agent config against live index |

---

## Token budget tools

When context must fit a limit:

```json
// Best-fit symbols for a task, packed to 4k tokens
get_ranked_context: { "repo": "...", "query": "auth flow", "token_budget": 4000 }

// Symbol + imports, capped at 2k tokens
get_context_bundle: {
  "repo": "...",
  "symbol_id": "src/auth.py::login#function",
  "token_budget": 2000,
  "budget_strategy": "most_relevant",
  "include_budget_report": true
}

// search_symbols also respects a budget
search_symbols: { "repo": "...", "query": "authenticate", "token_budget": 1000 }
```

Budget strategies: `most_relevant` (relevance-ranked), `core_first` (symbol first, then imports), `compact` (smallest footprint).

---

## Context providers

Context providers enrich the index with **business metadata** from ecosystem tools. They self-detect during `index_folder` — no config required.

### dbt provider

Detects: `dbt_project.yml` (scanned up to 2 directory levels deep).

Loads:
- **Doc blocks** from `{% docs name %}...{% enddocs %}` in `.md` files
- **Model metadata** from `schema.yml` — descriptions, tags, column names/descriptions
- Doc references (`{{ doc('name') }}`) resolved automatically

Enriches:
- **AI summaries** — business context injected into summarization prompts
- **`search_symbols`** — tags and column names become searchable keywords
- **`search_columns`** — enables column-level discovery across models
- **`get_file_outline`** — model description + tags + property count in file summary

Install with PyYAML for full YAML metadata (doc blocks still parsed without it):

```bash
pip install jcodemunch-mcp[dbt]
```

Disable all context providers:

```
JCODEMUNCH_CONTEXT_PROVIDERS=0
```

---

## Language support

Full symbol extraction (functions, classes, methods, constants, types) for 40+ languages via tree-sitter:

**Tier 1 (full extraction + docstrings + decorators):** Python, JavaScript, TypeScript, TSX, Go, Rust, Java, PHP, Dart, C#, C, C++, Swift, Elixir, Ruby, Kotlin, Scala, Lua, Erlang, Fortran, SQL, CSS, SCSS, Vue, Groovy, Nix, GDScript, Gleam, Perl, Objective-C, Protocol Buffers, HCL/Terraform, GraphQL, Bash

**Specialized:** YAML/Ansible (path-detected), OpenAPI/Swagger, XML/XUL, EJS, Blade (Laravel), Assembly (multi-dialect), AutoHotkey v2, AL (Business Central), Verse (UEFN)

**Text search only (symbol extraction planned):** Haskell, Julia, R, TOML

`.h` files: C++ parsing first, fallback to C if no C++ symbols extracted.

---

## Semantic search (opt-in)

No mandatory dependencies. Three embedding options:

```bash
# Local — no API cost
pip install jcodemunch-mcp[semantic]
JCODEMUNCH_EMBED_MODEL=all-MiniLM-L6-v2

# OpenAI
OPENAI_EMBED_MODEL=text-embedding-3-small   # also requires OPENAI_API_KEY

# Gemini
GOOGLE_EMBED_MODEL=models/text-embedding-004  # also requires GOOGLE_API_KEY
```

Then: `search_symbols(semantic=true)`, `search_text(semantic=true)`, or `search_symbols(semantic_only=true)`.

Warm up embeddings in one pass: `embed_repo: { "repo": "..." }` (otherwise computed lazily on first query).

---

## Cross-machine portability

Index built on one machine, reused on another — no re-indexing:

```
JCODEMUNCH_PATH_MAP=/home/user/Dev=C:\Users\user\Dev
```

Format: `orig_prefix=new_prefix`, comma-separated pairs. First matching prefix wins — list more-specific prefixes before broader ones.

---

## AI summaries (optional)

Summaries are generated during indexing. Provider auto-detected by API keys in order: Anthropic → Gemini → OpenAI-compatible → MiniMax → GLM-5.

Override provider:

```json
"env": { "JCODEMUNCH_SUMMARIZER_PROVIDER": "anthropic" }
```

Local LLM (LM Studio etc.):

```json
"env": {
  "OPENAI_API_BASE": "http://127.0.0.1:1234/v1",
  "OPENAI_MODEL": "qwen/qwen3-8b",
  "OPENAI_API_KEY": "local-llm"
}
```

Tuning knobs: `OPENAI_CONCURRENCY`, `OPENAI_BATCH_SIZE`, `OPENAI_MAX_TOKENS`.

For hosted OpenAI-compatible providers, set `allow_remote_summarizer: true` in `config.jsonc` (default is `false`, localhost only).

---

## Enforcement (two layers)

Installing makes tools available. It does **not** guarantee use. The common failure mode isn't forgetting — it's skipping. The agent sees the rule in CLAUDE.md and reaches for Read or Grep anyway because native tools feel faster under pressure. A prompt policy can't stop this. Hooks intercept at the tool-call level before the bypass happens.

### Layer 1: Prompt policy (soft — CLAUDE.md)

Add to CLAUDE.md. This tells the agent *which* tool to reach for — routing guidance.

```markdown
## Code Exploration Policy

Always use jCodemunch-MCP tools for code navigation. Never fall back to Read, Grep, Glob, or Bash for code exploration.

Start any session:
1. resolve_repo { "path": "." } — confirm indexed. If not: index_folder { "path": "." }
2. suggest_queries — when the repo is unfamiliar

Finding code:
- symbol by name → search_symbols (kind=, language=, file_pattern= to narrow)
- string, comment, config value → search_text (supports regex, context_lines)

Reading code:
- before opening any file → get_file_outline first
- one or more symbols → get_symbol_source (single ID → flat object; array → batch)
- symbol + its imports → get_context_bundle
- specific line range only → get_file_content (last resort)

Repo structure:
- get_repo_outline → dirs, languages, symbol counts
- get_file_tree → file layout, filter with path_prefix

Relationships & impact:
- what imports this file → find_importers
- where is this name used → find_references
- is this identifier used anywhere → check_references
- file dependency graph → get_dependency_graph
- what breaks if I change X → get_blast_radius (include_depth_scores=true, include_source=true)
- what symbols changed since last commit → get_changed_symbols
- find unreachable/dead code → find_dead_code
- most important symbols by architecture → get_symbol_importance
- class hierarchy → get_class_hierarchy
- callers/callees of a symbol → get_call_hierarchy
- high-risk symbols (complexity × churn) → get_hotspots
- related symbols → get_related_symbols
- diff two snapshots → get_symbol_diff
- symbols by decorator → search_symbols(decorator="...") or get_blast_radius(decorator_filter="...")

Session awareness:
- starting a task → plan_turn (confidence + recommended symbols/files)
- session history → get_session_context
- after editing → register_edit (invalidates caches)

Retrieval with token budget:
- best-fit context for a task → get_ranked_context (query + token_budget)
- bounded symbol bundle → get_context_bundle (add token_budget= to cap size)

After editing a file: index_file { "path": "/abs/path/to/file" } to keep the index fresh.
After a major refactor: audit_agent_config to catch stale symbol refs in CLAUDE.md.
```

### Layer 2: Tool hooks (hard — Claude Code)

Hooks intercept at the tool-call level and fire *before* the native tool executes.

| Hook | Event | Script | What it does |
|---|---|---|---|
| Read Guard | `PreToolUse` on Bash/Grep/Glob | `jcodemunch_read_guard.ps1` | Blocks code-exploration calls (exit 2), passes builds/tests/git |
| Edit Guard | `PreToolUse` on Edit/Write | `jcodemunch_edit_guard.ps1` | Soft warning by default; hard block with `JCODEMUNCH_HARD_BLOCK=1` |
| Index Hook | `PostToolUse` on Edit/Write | `jcodemunch_index_hook.ps1` | Auto re-indexes modified files via `uvx jcodemunch-mcp index_file` |

All hooks share `JcmHooks.psm1` (JSON parsing, logging, repo-root discovery).

**Install:** Scripts live in `~/.claude/hooks/`. Wire into `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash|Grep|Glob",
        "hooks": [{"type": "command", "command": "pwsh -NoProfile ~/.claude/hooks/jcodemunch_read_guard.ps1"}]
      },
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [{"type": "command", "command": "pwsh -NoProfile ~/.claude/hooks/jcodemunch_edit_guard.ps1"}]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [{"type": "command", "command": "pwsh -NoProfile ~/.claude/hooks/jcodemunch_index_hook.ps1"}]
      }
    ]
  }
}
```

**Debug logging:** Set `JCODEMUNCH_DEBUG=1` — logs to `~/.claude/hooks/jcodemunch_*.log`.

**Full hook source and bash variants:** [AGENT_HOOKS.md](https://github.com/jgravelle/jcodemunch-mcp/blob/main/AGENT_HOOKS.md)

---

## Best practices

1. `suggest_queries` → `get_repo_outline` on any unfamiliar repo before anything else.
2. `get_file_outline` before pulling source — see API surface before reading code.
3. `search_symbols` before `get_file_content` whenever possible.
4. Batch related symbols: `get_symbol_source(symbol_ids=[...])` or `get_context_bundle` instead of repeated single calls.
5. `search_text` for comments, strings, and config values — not for code symbols.
6. `verify: true` in `get_symbol_source` when freshness matters.
7. `index_file` after any edit. `index_folder` when the codebase changes materially.
8. Run `audit_agent_config` after refactors — catches stale symbol and file references in CLAUDE.md that native tools cannot detect.
9. Tell the agent explicitly to use jCodeMunch — or install hooks. Without one of these, it defaults to old habits.

### Prompting examples

**Good:**
- "Use jcodemunch to locate the authentication flow."
- "Start with the repo outline, then find the class responsible for retries."
- "Retrieve only the exact methods related to billing."
- "Verify the symbol before quoting the implementation."

**Bad:**
- "Read the whole repo and tell me what it does."
- "Open every likely file."
- "Search manually through source until you find it."

---

## Telemetry opt-out

By default, jCodeMunch sends an anonymous savings delta (token delta + random install ID only — no code, no paths) to a community counter. Disable:

```json
"env": { "JCODEMUNCH_SHARE_SAVINGS": "0" }
```

Live savings counter (Claude Code status line) pulls from `~/.code-index/_savings.json`.

---

## Debug logging

```json
{
  "mcpServers": {
    "jcodemunch": {
      "command": "uvx",
      "args": ["jcodemunch-mcp", "--log-level", "DEBUG", "--log-file", "/tmp/jcodemunch.log"]
    }
  }
}
```
