# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`lean-lsp-mcp` is a Python MCP (Model Context Protocol) server that enables LLM agents to interact with the Lean theorem prover via the Language Server Protocol (LSP). It exposes 21 MCP tools covering diagnostics, proof goals, type info, theorem search, REPL interaction, and proof profiling.

## Commands

All commands use `uv` as the package manager.

**Lint:**
```bash
uv sync --extra lint
uv run ruff check src/ tests/
uv run ruff format --check src/ tests/
```

**Test (unit tests only — no Lean required):**
```bash
uv sync --extra dev
uv run pytest tests/unit/ -v
```

**Single test:**
```bash
uv run pytest tests/unit/test_server.py::test_name -v
```

**All tests (requires a built Lean project in `tests/test_project/`):**
```bash
uv run pytest tests/ -v --timeout=300 -m "not slow"
```

**Run the server:**
```bash
uvx lean-lsp-mcp                              # stdio transport
uvx lean-lsp-mcp --transport streamable-http  # HTTP streaming
uvx lean-lsp-mcp --transport sse              # Server-sent events
```

**Release:**
```bash
./release.sh <version>
```

## Architecture

### Entry Points
- `src/lean_lsp_mcp/__init__.py` — `main()`, CLI argument parsing, transport selection, stdout suppression setup
- `src/lean_lsp_mcp/__main__.py` — delegates to `main()`

### Core Files
- **`server.py`** (1,742 lines) — All 21 MCP tool definitions, request handlers, lifecycle management, rate limiting. The central file for all tool logic.
- **`client_utils.py`** — LSP client lifecycle: project path inference (walks up for `lean-toolchain`), client initialization and caching, file path resolution.
- **`utils.py`** — LSP response validation, output capture at file-descriptor level (prevents stdio noise), token verification, goal/diagnostic extraction.
- **`models.py`** — 40+ Pydantic models for all structured tool outputs.

### Feature Modules
- **`loogle.py`** — Manages a local Loogle subprocess (cache downloads, subprocess lifecycle).
- **`repl.py`** — Lean REPL subprocess management with timeout and memory limits.
- **`outline_utils.py`** — Parses `#info_trees` to build file outlines (declarations, imports, type signatures).
- **`profile_utils.py`** — Runs `lean --profile`, parses timing output to identify slow tactics.
- **`search_utils.py`** — ripgrep integration for `lean_local_search`.
- **`verify.py`** — Axiom extraction via `#print axioms` and source pattern scanning.
- **`instructions.py`** — The MCP `instructions` field shown to LLMs about tool usage.

### Key Design Patterns

**Rate limiting:** `@rate_limited(category, max_requests, per_seconds)` decorator on external search tools (3–10 requests per 30s window).

**LSP client pooling:** One `leanclient` instance per project path, reused across tool calls, replaced on project path change. Initialized lazily via `client_utils.py`.

**Project path inference:** Walks directory tree upward to find `lean-toolchain`; result is cached. Can also be set via `LEAN_PROJECT_PATH` env var.

**Output suppression:** File-descriptor-level stdout/stderr capture prevents subprocess noise from leaking into stdio MCP transport.

**Graceful degradation:** Local Loogle → remote API; REPL unavailable → LSP multi-attempt; ripgrep missing → `lean_local_search` disabled.

### Tool Categories
1. **LSP-based file tools:** `lean_file_outline`, `lean_diagnostic_messages`, `lean_goal`, `lean_term_goal`, `lean_hover_info`, `lean_declaration_file`, `lean_completions`, `lean_code_actions`, `lean_get_widgets`, `lean_get_widget_source`
2. **Proof development:** `lean_multi_attempt`, `lean_run_code`, `lean_profile_proof`, `lean_verify`
3. **External search (rate-limited):** `lean_local_search`, `lean_leansearch`, `lean_loogle`, `lean_leanfinder`, `lean_state_search`, `lean_hammer_premise`
4. **Project management:** `lean_build`

## Environment Variables

| Variable | Purpose |
|---|---|
| `LEAN_PROJECT_PATH` | Path to Lean project (auto-detected if unset) |
| `LEAN_LOG_LEVEL` | `INFO`/`WARNING`/`ERROR`/`NONE` |
| `LEAN_REPL` | Enable REPL mode (`true`/`1`/`yes`) |
| `LEAN_REPL_PATH` | REPL binary path (auto-detected) |
| `LEAN_LSP_MCP_TOKEN` | Bearer token for HTTP/SSE transport auth |
| `LEAN_LOOGLE_LOCAL` | Enable local Loogle (`true`/`1`/`yes`) |
| `LEAN_LSP_TEST_MODE` | Test mode — prevents cache downloads |

## Testing Structure

- `tests/unit/` — Fast unit tests, no Lean installation required. Run in CI on Python 3.10–3.13.
- `tests/test_editor_tools.py`, `tests/test_verify.py`, `tests/test_logging.py` — Integration tests requiring a built Lean project at `tests/test_project/`.
- `tests/helpers/` — `mcp_client.py` (MCP test client) and `test_project.py` (project setup).
- Integration tests run weekly via GitHub Actions cron or manual dispatch.

## Dependencies

Core: `leanclient==0.9.2`, `mcp[cli]==1.26.0`, `orjson`, `certifi`
External tools (optional): `ripgrep` (for local search), `lake`/`elan`/Lean (for integration tests)
Python: ≥ 3.10
