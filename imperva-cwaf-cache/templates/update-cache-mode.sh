#!/bin/bash
# Update Cache Mode Settings
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   SITE_ID, CAID must be set by user before calling
#
# Parameters (pass as env vars):
#   MODE_LEVEL — disabled | custom_cache_rules_only | standard | smart | all_resources (default: smart)
#
# Usage:
#   SITE_ID=<id> CAID=<caid> MODE_LEVEL=smart bws run --project-id <bw_id> -- bash update-cache-mode.sh

SITE_ID="${SITE_ID:?Set SITE_ID}"
CAID="${CAID:?Set CAID}"
MODE_LEVEL="${MODE_LEVEL:-smart}"

curl -s -X PUT "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/settings/cache" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"mode\":{\"level\":\"${MODE_LEVEL}\"}}" | jq .

