#!/bin/bash
# Imperva CWAF Policy Management — Add GEO setting to a policy
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   CAID, POLICY_ID must be set by user before calling
#
# Parameters (pass as env vars):
#   COUNTRIES — JSON array of country codes (e.g. '["RU","CN"]')
#   CONTINENTS — JSON array of continent codes (e.g. '["AS"]')
#   ACTION     — BLOCK | ALLOW | ALERT (default: BLOCK)
#
# Usage:
#   CAID=<caid> POLICY_ID=<id> COUNTRIES='["RU","CN"]' ACTION=BLOCK \
#     bws run -- bash add-geo-setting.sh

CAID="${CAID:?Set CAID}"
POLICY_ID="${POLICY_ID:?Set POLICY_ID}"
COUNTRIES="${COUNTRIES:-[]}"
CONTINENTS="${CONTINENTS:-[]}"
ACTION="${ACTION:-BLOCK}"

curl -s -X POST "https://api.imperva.com/policies/v2/policies/${POLICY_ID}?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  -d "{
    \"policySettings\": [{
      \"policySettingType\": \"GEO\",
      \"settingsAction\": \"${ACTION}\",
      \"data\": {
        \"geo\": {
          \"countries\": ${COUNTRIES},
          \"continents\": ${CONTINENTS}
        }
      }
    }]
  }" | jq .
