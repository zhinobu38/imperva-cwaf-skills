#!/bin/bash
# Update Bot Configuration (v3 - managed bot lists)
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   SITE_ID must be set by user before calling
#
# Parameters (pass as env vars):
#   MODE — blockbadbots | cancelgoodbots
#   BOT_IDS — comma-separated bot IDs (e.g. "6,12,45")
#
# Bot IDs reference: https://docs.imperva.com/bundle/cloud-application-security/page/settings/client-classification.htm
#
# Usage:
#   SITE_ID=<id> MODE=blockbadbots BOT_IDS=6,12 bws run --project-id <bw_id> -- bash update-bot-config.sh
#   SITE_ID=<id> MODE=cancelgoodbots BOT_IDS=3 bws run ... -- bash update-bot-config.sh

SITE_ID="${SITE_ID:?Set SITE_ID (from user input or imperva-cwaf-get-site-detail)}"
MODE="${MODE:?Set MODE (blockbadbots | cancelgoodbots)}"
BOT_IDS="${BOT_IDS:-}"

# 1. GET current bot configuration
CURRENT=$(curl -s -X GET "https://my.imperva.com/api/prov/v3/sites/${SITE_ID}/settings/botConfiguration" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}")

# 2. Build bot entries from comma-separated IDs (empty string = empty array)
if [ -n "${BOT_IDS}" ]; then
  BOT_ENTRIES=$(echo "${BOT_IDS}" | tr ',' '\n' | jq -R '{id: tonumber}' | jq -s '.')
else
  BOT_ENTRIES='[]'
fi

# 3. Merge based on mode
if [ "${MODE}" = "blockbadbots" ]; then
  PAYLOAD=$(echo "${CURRENT}" | jq --argjson bots "${BOT_ENTRIES}" '.data[0].badBots = $bots')
elif [ "${MODE}" = "cancelgoodbots" ]; then
  PAYLOAD=$(echo "${CURRENT}" | jq --argjson bots "${BOT_ENTRIES}" '.data[0].canceledGoodBots = $bots')
else
  echo "ERROR: MODE must be 'blockbadbots' or 'cancelgoodbots'" >&2
  exit 1
fi

# 4. PUT updated configuration
curl -s -X POST "https://my.imperva.com/api/prov/v3/sites/${SITE_ID}/settings/botConfiguration" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  -d "${PAYLOAD}" | jq .
