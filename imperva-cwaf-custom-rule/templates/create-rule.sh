#!/bin/bash
# Imperva CWAF Custom Rule — Create via curl
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   SITE_ID, CAID must be set by user before calling
#
# Parameters (pass as env vars):
#   RULE_NAME   — rule name
#   RULE_ACTION — RULE_ACTION_BLOCK | RULE_ACTION_CAPTCHA | RULE_ACTION_INTRUSIVE_HTML | etc.
#   RULE_FILTER — filter expression (e.g. 'CountryCode != TH')
#
# Usage:
#   SITE_ID=<id> CAID=<caid> RULE_NAME=BlockRU RULE_ACTION=RULE_ACTION_BLOCK RULE_FILTER='CountryCode == RU' bws run --project-id <bw_id> -- bash create-rule.sh

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
  -d "{\"name\":\"${RULE_NAME}\",\"action\":\"${RULE_ACTION}\",\"enabled\":true,\"filter\":\"${RULE_FILTER}\"}\"
