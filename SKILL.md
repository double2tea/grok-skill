---
name: grok-search
description: Real-time web research/search with sources (outputs JSON).
---

## When to use (aggressive)

- Default to using this skill before answering anything that might be outdated, ambiguous, or requires external confirmation (APIs, versions, errors, docs, releases).
- If you feel even slightly unsure, search first, then answer with evidence.

## Quick start

### Configure (recommended)

Run once to write config:

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\grok-search\configure.ps1"
```

Default config path (recommended): `C:\Users\<you>\.codex\skills\grok-search\config.json` (override with `--config` or `GROK_CONFIG_PATH`).

Write to user-level config instead (optional):

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\grok-search\configure.ps1" -Global
```

### Configure (env vars)

If you prefer env vars:

```powershell
$env:GROK_API_URL="http://localhost:8080/v1/chat/completions"
$env:GROK_BASE_URL="http://localhost:8080"
$env:GROK2API_API_KEY="YOUR_API_KEY"
$env:GROK_SEARCH_DEPTH="thinking"
$env:GROK_MODEL="grok-4"
```

### Run

```bash
python scripts/grok_search.py --depth thinking --query "What changed in X recently?"
```

## Output

Prints JSON to stdout:

- `content`: the synthesized answer
- `sources`: best-effort list of URLs (and optional titles/snippets)
- `raw`: raw assistant content (if parsing failed)

## Notes

- Endpoint priority:
  1. `GROK_API_URL` / `--api-url` / `config.api_url` (full API URL; supports host, `/v1`, or `/v1/chat/completions`)
  2. `GROK_BASE_URL` / `--base-url` / `config.base_url` (auto appends `/v1/chat/completions`)
- API key env fallback: `GROK_API_KEY` or `GROK2API_API_KEY` (request still works without key when server auth is disabled).
- Model/depth priority:
  1. `--model` / `GROK_MODEL` / `GROK2API_MODEL`
  2. `--depth` / `GROK_SEARCH_DEPTH` / `GROK_DEPTH` / `config.depth` -> `config.depth_models`
  3. `config.model` (fallback, default `grok-4`)
- Default depth map in config: `fast -> grok-4.1-fast`, `thinking -> grok-4.1-thinking`, `heavy -> grok-4-heavy`.
- If your 2api requires custom flags to enable web search, pass them via `--extra-body-json` / `GROK_EXTRA_BODY_JSON`.
