# Imperva CWAF Credential & Identifier Policy

## Golden Rules

1. **NEVER hardcode credentials** (API ID, API Key) in any file — scripts, templates, SKILL.md, or log output
2. **NEVER print credentials** in log output, debug messages, or raw HTTP request bodies
3. **NEVER hardcode identifiers** (SITE_ID, CAID) inside templates — they must come from user input/env vars
4. **ALWAYS use `bws run`** to inject credentials via Bitwarden

## Credential Source

| Value | Source | Method |
|-------|--------|--------|
| `IMPERVA_API_ID` | Only via `bws run ` |
| `IMPERVA_API_KEY` | Only via `bws run ` |

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
SITE_ID=xxxxxx CAID=xxxxxxx \
  bws run  \
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
curl -H "x-API-Id: xxxxx" -H "x-API-key: yyyyyy ..." ...

# ❌ Hardcoded identifiers in template
SITE_ID="xxxxxxxxx"  # inside a shared template file

# ❌ Printing credentials
echo "Using key: $IMPERVA_API_KEY"
```
