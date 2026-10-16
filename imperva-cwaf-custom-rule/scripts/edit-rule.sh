#!/bin/bash
# Imperva CWAF — Edit (update) a custom rule
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   SITE_ID, RULE_ID must be set by user before calling
#
# Parameters (pass as env vars):
#   RULE_NAME   — rule name (optional)
#   RULE_ACTION — RULE_ACTION_BLOCK | RULE_ACTION_CAPTCHA | RULE_ACTION_INTRUSIVE_HTML | etc. (optional)
#   RULE_FILTER — filter expression (optional)
#   RULE_ENABLED — true | false (optional)
#
# Usage:
#   SITE_ID=<id> RULE_ID=<id> RULE_FILTER='CountryCode != CN;RU' bws run -- bash edit-rule.sh

SITE_ID="${SITE_ID:?Set SITE_ID}"
RULE_ID="${RULE_ID:?Set RULE_ID}"

# Fetch current rule state first
CURRENT=$(curl -s -G "https://my.imperva.com/api/prov/v3/rules?caid=${CAID}&siteIds=${SITE_ID}" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" | jq -r ".data[] | select(.rule.rule_id == ${RULE_ID}) | .rule")

if [ -z "$CURRENT" ]; then
  echo '{"error": "Rule not found"}' | jq .
  exit 1
fi

# Use current values as defaults if not overridden
CURRENT_NAME=$(echo "$CURRENT" | jq -r '.name')
CURRENT_ACTION=$(echo "$CURRENT" | jq -r '.action')
CURRENT_FILTER=$(echo "$CURRENT" | jq -r '.filter')
CURRENT_ENABLED=$(echo "$CURRENT" | jq -r '.enabled')

RULE_NAME="${RULE_NAME:-$CURRENT_NAME}"
RULE_ACTION="${RULE_ACTION:-$CURRENT_ACTION}"
RULE_FILTER="${RULE_FILTER:-$CURRENT_FILTER}"
RULE_ENABLED="${RULE_ENABLED:-$CURRENT_ENABLED}"

# Build JSON body using jq to properly escape values
JSON_BODY=$(jq -n \
  --arg name "$RULE_NAME" \
  --arg action "$RULE_ACTION" \
  --arg filter "$RULE_FILTER" \
  --argjson enabled "$RULE_ENABLED" \
  '{name: $name, action: $action, enabled: $enabled, filter: $filter}')

curl -s -X PUT \
  "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/rules/${RULE_ID}?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "x-API-Id: $IMPERVA_API_ID" \
  -H "x-API-Key: $IMPERVA_API_KEY" \
  -d "$JSON_BODY" | jq .
