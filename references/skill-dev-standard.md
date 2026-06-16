# Imperva CWAF Skill Development Standard

This document is the **authoritative development standard** for ALL `imperva-cwaf` skills.
Every sub-skill references this file — do not duplicate its content.

## Template Structure

All Imperva CWAF skills use shell script templates with this standard header:

```bash
#!/bin/bash
# <Skill Name> — <Operation>
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   SITE_ID, CAID must be set by user before calling
#
# Usage:
#   SITE_ID=<id> CAID=<caid> bws run --project-id <bw_id> -- bash template.sh
```

## Credential Rules (เด็ดขาด)

| Value | Source | ห้าม |
|-------|--------|------|
| `IMPERVA_API_ID` | `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` | hardcode ใน script/template/SKILL.md |
| `IMPERVA_API_KEY` | `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` | print ใน log หรือ raw request output |
| `SITE_ID` | User env / memory / `imperva-cwaf-get-site-detail` | hardcode ใน template |
| `CAID` | User env / memory / `imperva-cwaf-get-site-detail` | hardcode ใน template |

- bws project `hermes-aws` (ID: `61c6c700-2d78-4860-b79e-b46200e193e9`) — NOT `hermes`
- bws inject เฉพาะ `IMPERVA_API_ID` + `IMPERVA_API_KEY` — ไม่มี SITE_ID/CAID
- SITE_ID/CAID เป็น public identifier (ไม่ใช่ secret) แต่ต้องมาจาก user input เท่านั้น

## Template Pattern: GET → Modify → PUT

For APIs that require full-object PUT:

```bash
# 1. GET current settings
CURRENT=$(curl -s -X GET "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/settings/..." \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}")

# 2. Modify with jq
MODIFIED=$(echo "${CURRENT}" | jq '.field = "new_value"')

# 3. PUT full object
curl -s -X PUT "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/settings/..." \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  -d "${MODIFIED}" | jq .
```

## Known API Behaviors

| API | PUT Behavior | Special Headers |
|-----|-------------|-----------------|
| Delivery `/settings/delivery` | Requires FULL object (all 5 sections). Partial -> 406. Must `del(.network.port)` and `del(.network.ssl_port)` before PUT | None |
| Cache settings `/settings/cache` | Partial update works | None |
| Cache rules `/settings/cache/rules/{id}` | Requires FULL object. Partial -> error | `Force-Risky-Operation: true` |
| Policies | POST appends, PUT replaces entirely | — |
| Custom rules | Flat JSON body (no `data` wrapper) | — |
| Security v1 `/sites/configure/security` | POST with form-encoded params per rule | — |
| Bot config v3 `/settings/botConfiguration` | POST with JSON body; full replacement | — |

## Common Pitfalls

- **Delivery port/ssl_port**: Read-only. Including in PUT body -> 406 "Invalid Port". Always `del()` before PUT.
- **Inline Python fails**: `bws run -- python3 -c "..."` fails for complex Python. Always write a script file first.
- **write_file proxy**: Avoid `$` patterns in Python f-strings/DictFormat. Use `.format(s=..., c=...)` with named params.
- **Compression type**: Only `GZIP` and `BROTLI` (case-sensitive).
- **Cache rule response**: Uses legacy envelope `{"res": 0, "res_message": "OK"}`.
- **Cache rule ID field**: `rule_id` not `id` in POST response.
- **Security v1 uses form-encoded POST**: Not JSON body; use `--data-urlencode` for params.
- **Bot v3 uses POST for update**: Not PUT. GET first, modify, then POST the full object.
- **Parameter passing**: Always support BOTH env var and positional arg: `${CAID:-${1:-default}}`. SKILL.md may document env var usage but users may pass positional args — script must handle both.
- **bws run quoting**: Special characters (tab `\t`, newline) in multiline strings get mangled through `bws run`. Always test scripts through `bws run` for real — never assume from reading code alone.
- **column -t with tab separator**: `column -s "\t"` breaks through `bws run` (expands to literal "t"). Use `awk -F'\t'` as intermediate step before `column -t`.
- **jq @tsv output**: Pipe through `awk -F'\t'` before `column -t` to avoid multi-line array issues.
- **Error 15 (WAF block) vs real API error**: Imperva WAF intermittently blocks requests from cloud/AWS IPs with errorCode 15. This is NOT a schema/auth error. Retry with exponential backoff (5s, 15s, 30s, 60s) before concluding the script is wrong.
- **Test all output formats**: When script supports multiple output formats (table, json, etc.), test EVERY format through `bws run` — testing only one format does not guarantee others work.

## Skill File Structure

```
imperva-cwaf-<feature>/
├── SKILL.md                    # Main documentation
└── templates/
    ├── get-<feature>.sh        # GET operation
    ├── update-<feature>.sh     # PUT operation (GET->modify->PUT pattern)
    └── set-<subfeature>.sh     # Specialized operations
```

## SKILL.md Standard Sections

1. Credential & Identifier Policy (MANDATORY) — table format with hardcode rules
2. API Endpoint
3. Operations (GET/PUT with param tables)
4. Response Structure (JSON example from real API)
5. Settings Reference (field tables per section)
6. Error Handling (HTTP codes + 9415)
7. Pitfalls (hardcode rules first, then API-specific)
8. Related Skills
