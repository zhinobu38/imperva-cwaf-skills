#!/bin/bash
# Update Image Compression Settings
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   SITE_ID, CAID must be set by user before calling
#
# Usage:
#   SITE_ID=<id> CAID=<caid> COMPRESS_JPEG=true bws run --project-id <id> -- bash update-image-compression.sh
#   SITE_ID=<id> CAID=<caid> COMPRESS_PNG=false AGGRESSIVE_COMPRESSION=true bws run ... -- bash update-image-compression.sh
#   SITE_ID=<id> CAID=<caid> PROGRESSIVE_IMAGE_RENDERING=true bws run ... -- bash update-image-compression.sh

SITE_ID="${SITE_ID:?Set SITE_ID (from user input or imperva-cwaf-get-site-detail)}"
CAID="${CAID:?Set CAID (from user input or imperva-cwaf-get-site-detail)}"

# Defaults (only include in payload if env vars are set)
COMPRESS_JPEG="${COMPRESS_JPEG:-}"
COMPRESS_PNG="${COMPRESS_PNG:-}"
AGGRESSIVE_COMPRESSION="${AGGRESSIVE_COMPRESSION:-}"
PROGRESSIVE_IMAGE_RENDERING="${PROGRESSIVE_IMAGE_RENDERING:-}"

# Build image_compression JSON using jq — only include set fields
IMAGE_COMPRESSION=$(jq -n \
  --arg cj "${COMPRESS_JPEG}" \
  --arg cp "${COMPRESS_PNG}" \
  --arg ac "${AGGRESSIVE_COMPRESSION}" \
  --arg pir "${PROGRESSIVE_IMAGE_RENDERING}" \
  '{
    image_compression: (
      {}
      | if ($cj != "") then .compress_jpeg = ($cj == "true") else . end
      | if ($cp != "") then .compress_png = ($cp == "true") else . end
      | if ($ac != "") then .aggressive_compression = ($ac == "true") else . end
      | if ($pir != "") then .progressive_image_rendering = ($pir == "true") else . end
    )
  }')

echo "Image compression update: ${IMAGE_COMPRESSION}"

# PUT partial update
curl -s -X PUT "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/settings/delivery?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  -d "${IMAGE_COMPRESSION}" | jq .
