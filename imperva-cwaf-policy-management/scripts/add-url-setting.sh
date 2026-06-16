#!/bin/bash
# Imperva CWAF Policy Management — Add URL setting to a policy
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   CAID, POLICY_ID must be set by user before calling
#
# Parameters (pass as env vars):
#   URLS     — JSON array of URL objects (e.g. '[{"pattern":"PREFIX","url":"/api/"}]')
#   ACTION   — BLOCK | ALLOW | ALERT (default: BLOCK)
#
# URL pattern types: EQUALS, NOT_EQUALS, CONTAINS, NOT_CONTAINS, PREFIX, NOT_PREFIX, SUFFIX, NOT_SUFFIX
#
# Usage:
#   CAID=<caid> POLICY_ID='<id> URLS='[{"pattern":"PREFIX","url":"/admin/"}]' ACTION=BLOCK \
#     bws run --project-id <bw_id> -- bash add-url-setting.sh

CAID="${CAID:?Set CAID}"
POLICY_ID="${POLICY_ID:?Set POLICY_ID}"
URLS="${URLS:-[]}"
ACTION="${ACTION:-BLOCK}"

curl -s -X POST "https://api.imperva.com/policies/v2/policies/${POLICY_ID}?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  -d "{
    \"policySettings\": [{
      \"policySettingType\": \"URL\",
      \"settingsAction\": \"${ACTION}\",
      \"data\": {
        \"urls\": ${URLS}
      }
    }]
  }" | jq .
