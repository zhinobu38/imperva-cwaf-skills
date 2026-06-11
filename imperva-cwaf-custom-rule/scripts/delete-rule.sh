#!/bin/bash
# Imperva CWAF — Delete a custom rule
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   SITE_ID, RULE_ID must be set by user before calling
#
# Usage:
#   SITE_ID=<id> RULE_ID=<id> bws run --project-id <bw_id> -- bash delete-rule.sh

SITE_ID="${SITE_ID:?Set SITE_ID}"
RULE_ID="${RULE_ID:?Set RULE_ID}"

curl -s -X DELETE "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/rules/${RULE_ID}" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" | jq .
