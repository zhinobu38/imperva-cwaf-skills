#!/bin/bash
# Imperva CWAF Custom Rule - Create via curl
# Usage: Set SITE_ID and CAID, then run via bws run
#   bws run --project-id <project_id> -- bash templates/create-rule.sh

SITE_ID="${SITE_ID:?Set SITE_ID}"
CAID="${CAID:?Set CAID}"
RULE_NAME="${RULE_NAME:-CustomRule}"
RULE_ACTION="${RULE_ACTION:-RULE_ACTION_CAPTCHA}"
RULE_FILTER="${RULE_FILTER:-CountryCode != TH}"

curl -s -X POST \
  "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/rules?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "x-API-Id: $IMPERVA_API_ID" \
  -H "x-API-Key: $IMPERVA_API_KEY" \
  -d "{\"name\":\"${RULE_NAME}\",\"action\":\"${RULE_ACTION}\",\"enabled\":true,\"filter\":\"${RULE_FILTER}\"}"
