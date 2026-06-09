# Imperva CWAF Shell Template Pattern

Standard pattern for all Imperva CWAF API operations (GET→modify→PUT).

## Template Structure

Every template MUST have this header:

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
#   SITE_ID=<id> CAID=<caid> bws run --project-id <id> -- bash template.sh
```

## GET-Only Template

```bash
#!/bin/bash
SITE_ID="${SITE_ID:?Set SITE_ID}"
CAID="${CAID:?Set CAID}"

curl -s -X GET "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/settings/xxx?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" | jq .
```

## GET→Modify→PUT Template

```bash
#!/bin/bash
SITE_ID="${SITE_ID:?Set SITE_ID}"
CAID="${CAID:?Set CAID}"
PARAM="${PARAM:-default}"

# 1. GET current settings
CURRENT=$(curl -s -X GET "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/settings/xxx?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}")

# 2. Modify with jq
PAYLOAD=$(echo "${CURRENT}" | jq --arg p "${PARAM}" '
  .field = $p
')

# 3. PUT updated settings
curl -s -X PUT "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/settings/xxx?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  -d "${PAYLOAD}" | jq .
```

## Multi-Step Template (GET section → modify → GET full → merge → PUT)

Use when you need to modify one section but PUT requires the full object:

```bash
#!/bin/bash
SITE_ID="${SITE_ID:?Set SITE_ID}"
CAID="${CAID:?Set CAID}"

# 1. GET target section
SECTION=$(curl -s -X GET "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/settings/xxx?caid=${CAID}&sections=target_section" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}")

# 2. Build modified section with jq
MODIFIED=$(echo "${SECTION}" | jq '...')

# 3. GET full object
FULL=$(curl -s -X GET "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/settings/xxx?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}")

# 4. Merge modified section into full object, remove read-only fields
PAYLOAD=$(echo "${FULL}" | jq --argjson mod "${MODIFIED}" '
  .target_section = $mod
  | del(.network.port)        # if applicable — read-only
  | del(.network.ssl_port)    # if applicable — read-only
')

# 5. PUT full object
curl -s -X PUT "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/settings/xxx?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  -d "${PAYLOAD}" | jq .
```

## POST with Form-Encoded Params Template

Used by v1 security endpoints (`/sites/configure/security`):

```bash
#!/bin/bash
SITE_ID="${SITE_ID:?Set SITE_ID}"
CAID="${CAID:?Set CAID}"

curl -s -X POST "https://my.imperva.com/api/prov/v1/sites/configure/security" \
  -H "Accept: application/json" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  --data-urlencode "site_id=${SITE_ID}" \
  --data-urlencode "rule_id=api.threats.xxx" \
  --data-urlencode "param=value" | jq .
```

## Key Rules

1. **Always validate SITE_ID and CAID** with `${VAR:?error message}` — fail fast if not set
2. **Never hardcode credentials** — always use `${IMPERVA_API_ID}` / `${IMPERVA_API_KEY}` from bws run
3. **Never hardcode identifiers** — SITE_ID and CAID come from user env
4. **Always GET before PUT** — Imperva APIs generally require full object in PUT body
5. **Remove read-only fields** before PUT — e.g., `port`, `ssl_port` in delivery network section
6. **Use `jq .`** at the end for readable output
7. **Comment each step** — GET, modify, merge, PUT
