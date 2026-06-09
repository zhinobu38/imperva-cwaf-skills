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
| Integrations `/api/integration/v1/*` | POST (or GET for /ips); read-only lookup, no site ID or CAID needed | — |

## Common Pitfalls

- **Delivery port/ssl_port**: Read-only. Including in PUT body -> 406 "Invalid Port". Always `del()` before PUT.
- **Inline Python fails**: `bws run -- python3 -c "..."` fails for complex Python. Always write a script file first.
- **write_file proxy**: Avoid `$` patterns in Python f-strings/DictFormat. Use `.format(s=..., c=...)` with named params.
- **Compression type**: Only `GZIP` and `BROTLI` (case-sensitive).
- **Cache rule response**: Uses legacy envelope `{"res": 0, "res_message": "OK"}`.
- **Cache rule ID field**: `rule_id` not `id` in POST response.
- **Security v1 uses form-encoded POST**: Not JSON body; use `--data-urlencode` for params.
- **Bot v3 uses POST for update**: Not PUT. GET first, modify, then POST the full object.

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

## Shared References Architecture

All imperva-cwaf sub-skills use a **shared references** pattern to avoid duplication:

```
imperva-cwaf/
├── references/                          ← SHARED (single source of truth)
│   ├── skill-dev-standard.md            ← This file
│   ├── credential-and-identifier-policy.md
│   └── shell-template-pattern.md
├── imperva-cwaf-<feature>/
│   ├── SKILL.md                         ← Contains "## Shared References" section
│   ├── references/                      ← Skill-specific only (optional)
│   └── templates/                       ← Standard header required
```

### Rules for Shared References

1. **Every SKILL.md must have a `## Shared References` section** that links to the 3 shared files using `../references/` path
2. **Never duplicate shared content** in per-skill references — link to shared instead
3. **Per-skill references/** should only contain skill-specific content (e.g., API response examples, domain-specific guides)
4. **If a per-skill reference duplicates shared content**, delete the per-skill file and update SKILL.md to reference the shared file
5. **Empty references/ directories should be removed** — don't leave dangling empty dirs

### Verification Checklist (run after any skill modification)

When adding, removing, or restructuring reference files, verify:

1. All SKILL.md files have `## Shared References` section with `../references/` paths
2. No SKILL.md references deleted/moved files (check text mentions, not just file existence)
3. All `references/` links in SKILL.md resolve to actual files
4. All templates have the standard header (Credential source + Identifier source)
5. No duplicate reference files exist across skills
6. Empty `references/` directories are removed

### Template Header Verification

Every `.sh` template must start with the standard header containing:
- `# <Skill Name> — <Operation>`
- `# Credential source: Bitwarden (bws run) — DO NOT hardcode`
- `# Identifier source: User env vars — DO NOT hardcode in template`
- `# Usage:` example with `bws run` pattern
