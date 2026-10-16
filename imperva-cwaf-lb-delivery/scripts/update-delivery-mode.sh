#!/bin/bash
# Update Delivery Mode — Compression Settings
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   SITE_ID, CAID must be set by user before calling
#
# Usage:
#   SITE_ID=<id> CAID=<caid> COMPRESSION_TYPE=BROTLI bws run -- bash update-delivery-mode.sh
#   SITE_ID=<id> CAID=<caid> MINIFY_JS=false bws run -- bash update-delivery-mode.sh

SITE_ID="${SITE_ID:?Set SITE_ID (from user input or imperva-cwaf-get-site-detail)}"
CAID="${CAID:?Set CAID (from user input or imperva-cwaf-get-site-detail)}"

# Defaults (only override if env vars are set)
COMPRESSION_TYPE="${COMPRESSION_TYPE:-}"
FILE_COMPRESSION="${FILE_COMPRESSION:-}"
MINIFY_JS="${MINIFY_JS:-}"
MINIFY_CSS="${MINIFY_CSS:-}"
MINIFY_STATIC_HTML="${MINIFY_STATIC_HTML:-}"

# 1. GET current settings
CURRENT=$(curl -s -X GET "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/settings/delivery?caid=${CAID}&sections=compression" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}")

# 2. Build compression JSON using jq
COMPRESSION=$(echo "${CURRENT}" | jq --arg ct "${COMPRESSION_TYPE}" \
  --arg fc "${FILE_COMPRESSION}" \
  --arg mj "${MINIFY_JS}" \
  --arg mc "${MINIFY_CSS}" \
  --arg mh "${MINIFY_STATIC_HTML}" '
  .compression
  | if ($ct != "") then .compression_type = $ct else . end
  | if ($fc != "") then .file_compression = ($fc == "true") else . end
  | if ($mj != "") then .minify_js = ($mj == "true") else . end
  | if ($mc != "") then .minify_css = ($mc == "true") else . end
  | if ($mh != "") then .minify_static_html = ($mh == "true") else . end
')

echo "Compression update: ${COMPRESSION}"

# 3. Get full current settings and merge compression update
FULL=$(curl -s -X GET "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/settings/delivery?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}")

# Remove read-only port fields before PUT
PAYLOAD=$(echo "${FULL}" | jq --argjson comp "${COMPRESSION}" '
  .compression = $comp
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
