# Imperva CWAF Credential Retrieval

## Rule: NEVER hardcode credentials

API credentials (ID and Key) MUST ALWAYS be retrieved from Bitwarden at runtime.
NEVER store credentials in:
- Scripts or code files
- Memory entries
- SKILL.md or any .md files
- Environment variable references in scripts
- Any plaintext file

## Retrieval method

Use `bws run` (Bitwarden Secrets Manager CLI) to inject credentials as environment variables at runtime:

```bash
bws run --project-id <BW_PROJECT_ID_WRITE> -- <command>
```

Secrets are injected as env vars: `IMPERVA_API_ID` and `IMPERVA_API_KEY`.

**CRITICAL**: The correct Bitwarden project is `hermes-aws` (ID: `<BW_PROJECT_ID_WRITE>`), NOT the `hermes` project (ID: `<BW_PROJECT_ID_READ>`). The `hermes` project has different credentials that may authenticate but lack write permissions, causing 9415 "Operation not allowed" errors.

## Script patterns (confirmed working)

### Option A: Python script file (recommended for complex logic)

Write a Python script with NO credentials in it, then execute via `bws run`:

```python
# /tmp/my_script.py — no credentials hardcoded
import os, json, urllib.request

api_id = os.environ["IMPERVA_API_ID"]
api_key = os.environ["IMPERVA_API_KEY"]
# ... use credentials ...
```

```bash
bws run --project-id <BW_PROJECT_ID_WRITE> -- python3 /tmp/my_script.py
```

**DO NOT** use inline `python3 -c "..."` with `bws run` — shell escaping causes failures with complex Python.

### Option B: Shell script with curl (recommended for simple API calls)

Write a shell script that references env vars naturally:

```bash
#!/bin/bash
curl -s -X POST \
  "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/rules?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "x-API-Id: $IMPERVA_API_ID" \
  -H "x-API-Key: $IMPERVA_API_KEY" \
  -d '{"name":"MyRule","action":"RULE_ACTION_BLOCK","enabled":true,"filter":"CountryCode != TH"}'
```

```bash
chmod +x /tmp/script.sh
bws run --project-id <BW_PROJECT_ID_WRITE> -- bash /tmp/script.sh
```

## Debugging credential issues

If you get `9415 Operation not allowed`:
1. **First check**: Are you using the correct Bitwarden project? (`hermes-aws`, not `hermes`)
2. **Second check**: Does the API key have write permissions in Imperva portal?
3. Note: 9415 is NOT caused by site NOT_CONFIGURED status — correct credentials work even on NOT_CONFIGURED sites

If you get `401 Authentication missing or invalid`:
- The API key itself is wrong or expired
- Verify the key in Bitwarden portal

## Cleanup

Delete temporary scripts from `/tmp/` after use. Never leave scripts with API logic on disk longer than needed.
