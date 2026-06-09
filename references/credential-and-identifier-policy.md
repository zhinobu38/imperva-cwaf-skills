# Imperva CWAF Credential & Identifier Policy

## Golden Rules

1. **NEVER hardcode credentials** (API ID, API Key) in any file — scripts, templates, SKILL.md, or log output
2. **NEVER print credentials** in log output, debug messages, or raw HTTP request bodies
3. **NEVER hardcode identifiers** (SITE_ID, CAID) inside templates — they must come from user input/env vars
4. **ALWAYS use `bws run`** to inject credentials via Bitwarden

## Credential Source

| Value | Source | Method |
|-------|--------|--------|
| `IMPERVA_API_ID` | Bitwarden project `hermes-aws` (ID: `61c6c700-2d78-4860-b79e-b46200e193e9`) | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `IMPERVA_API_KEY` | Bitwarden project `hermes-aws` (ID: `61c6c700-2d78-4860-b79e-b46200e193e9`) | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |

- **Wrong project**: Using `hermes` project credentials authenticate (no 401) but cause 9415 "Operation not allowed" on write operations
- **Scope**: bws run injects ONLY `IMPERVA_API_ID` and `IMPERVA_API_KEY`. It does NOT inject SITE_ID or CAID.

## Identifier Source

| Value | Source | Method |
|-------|--------|--------|
| `SITE_ID` | User input / memory / `imperva-cwaf-get-site-detail` skill | Pass as env var before calling script |
| `CAID` | User input / memory / `imperva-cwaf-get-site-detail` skill | Pass as env var before calling script |

- SITE_ID and CAID are **public identifiers, not secrets** — OK in scripts, but must come from user/config, never hardcoded in shared templates

## Correct Patterns

```bash
# ✅ Shell script with curl — credentials from bws run, identifiers from env
SITE_ID=852056322 CAID=2429928 \
  bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9 \
  -- bash /tmp/script.sh

# ✅ Shell script template with jq — GET→modify→PUT pattern
```

```python
# ✅ Python script — credentials from os.environ, identifiers as parameters
import os
api_id = os.environ["IMPERVA_API_ID"]
api_key = os.environ["IMPERVA_API_KEY"]
```

## Wrong Patterns

```bash
# ❌ Hardcoded credentials
curl -H "x-API-Id: 214929" -H "x-API-key: da98b3 ..." ...

# ❌ Hardcoded identifiers in template
SITE_ID="852056322"  # inside a shared template file

# ❌ Printing credentials
echo "Using key: $IMPERVA_API_KEY"

# ❌ Using wrong Bitwarden project
bws run --project-id <hermes_project_id> -- ...
```
