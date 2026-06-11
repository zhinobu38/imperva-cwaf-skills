#!/bin/bash
# Update Network Settings
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   SITE_ID, CAID must be set by user before calling
#
# Usage:
#   SITE_ID=<id> CAID=<caid> TCP_PRE_POOLING=true bws run --project-id <id> -- bash update-network.sh
#   SITE_ID=<id> CAID=<caid> ENABLE_HTTP2=true HTTP2_TO_ORIGIN=false bws run ... -- bash update-network.sh
#   SITE_ID=<id> CAID=<caid> SUPPORT_NON_SNI_CLIENTS=false bws run ... -- bash update-network.sh
#   SITE_ID=<id> CAID=<caid> ORIGIN_CONNECTION_REUSE=true bws run ... -- bash update-network.sh

SITE_ID="${SITE_ID:?Set SITE_ID (from user input or imperva-cwaf-get-site-detail)}"
CAID="${CAID:?Set CAID (from user input or imperva-cwaf-get-site-detail)}"

# Defaults (only override if env vars are set)
TCP_PRE_POOLING="${TCP_PRE_POOLING:-}"
ORIGIN_CONNECTION_REUSE="${ORIGIN_CONNECTION_REUSE:-}"
SUPPORT_NON_SNI_CLIENTS="${SUPPORT_NON_SNI_CLIENTS:-}"
ENABLE_HTTP2="${ENABLE_HTTP2:-}"
HTTP2_TO_ORIGIN="${HTTP2_TO_ORIGIN:-}"

# 1. GET current full delivery settings
FULL=$(curl -s -X GET "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/settings/delivery?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}")

# 2. Build network JSON using jq — only modify set fields
NETWORK=$(echo "${FULL}" | jq --arg tpp "${TCP_PRE_POOLING}" \
  --arg ocr "${ORIGIN_CONNECTION_REUSE}" \
  --arg sni "${SUPPORT_NON_SNI_CLIENTS}" \
  --arg eh2 "${ENABLE_HTTP2}" \
  --arg h2o "${HTTP2_TO_ORIGIN}" '
  .network
  | if ($tpp != "") then .tcp_pre_pooling = ($tpp == "true") else . end
  | if ($ocr != "") then .origin_connection_reuse = ($ocr == "true") else . end
  | if ($sni != "") then .support_non_sni_clients = ($sni == "true") else . end
  | if ($eh2 != "") then .enable_http2 = ($eh2 == "true") else . end
  | if ($h2o != "") then .http2_to_origin = ($h2o == "true") else . end
')

echo "Network update: ${NETWORK}"

# 3. Merge network update into full settings, remove read-only port fields
PAYLOAD=$(echo "${FULL}" | jq --argjson net "${NETWORK}" '
  .network = $net
  | del(.network.port)
  | del(.network.ssl_port)
')

# 4. PUT full delivery settings
curl -s -X PUT "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/settings/delivery?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  -d "${PAYLOAD}" | jq .
