#!/bin/bash
# imperva_release_session.sh — Release a blocked session in Imperva CWAF
#
# Usage:
#   SITE_ID=<id> CAID=<caid> bws run --project-id <bw_id> -- bash imperva_release_session.sh --session-id <session_id>
#
# ⚠️  NOTE: This operation is for USER-REQUESTED release of blocked sessions ONLY.
#     It is NOT related to WAF exceptions/whitelist policies.
#     For managing exceptions, use: imperva-cwaf-policy-management
#
# Examples:
#   SITE_ID=852056322 CAID=2429928 bws run --project-id <id> -- \
#     bash imperva_release_session.sh --session-id "abc123def456"

set -euo pipefail

# ── Parse args ───────────────────────────────────────────────────────────────

SITE_ID="${SITE_ID:-}"
CAID="${CAID:-}"
SESSION_ID=""
FORMAT="table"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --site-id)    SITE_ID="$2";        shift 2 ;;
    --caid)       CAID="$2";           shift 2 ;;
    --session-id) SESSION_ID="$2";     shift 2 ;;
    --format)     FORMAT="$2";         shift 2 ;;
    -h|--help)
      head -16 "$0" | sed 's/^#\? \?//'
      exit 0
      ;;
    *) echo "ERROR: Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$SITE_ID" ]]; then
  echo "ERROR: SITE_ID must be set via --site-id or SITE_ID env var" >&2
  exit 1
fi
if [[ -z "$SESSION_ID" ]]; then
  echo "ERROR: --session-id is required" >&2
  exit 1
fi

# ── Credentials (injected by bws run) ────────────────────────────────────────

API_ID="${IMPERVA_API_ID:-}"
API_KEY="${IMPERVA_API_KEY:-}"
if [[ -z "$API_ID" || -z "$API_KEY" ]]; then
  echo "ERROR: IMPERVA_API_ID and IMPERVA_API_KEY must be set (injected by bws run)" >&2
  exit 1
fi

# ── Build request ────────────────────────────────────────────────────────────

BASE_URL="https://api.imperva.com/waf-settings-v2"
URL="${BASE_URL}/v3/sites/${SITE_ID}/sessions/${SESSION_ID}/release"

# Add caid query param if set
if [[ -n "$CAID" ]]; then
  URL="${URL}?caid=${CAID}"
fi

[[ "$FORMAT" == "table" ]] && echo "  Site ID:     ${SITE_ID}"
[[ "$FORMAT" == "table" ]] && echo "  Session ID:  ${SESSION_ID}"
[[ "$FORMAT" == "table" ]] && [[ -n "$CAID" ]] && echo "  CAID:        ${CAID}"
[[ "$FORMAT" == "table" ]] && echo "  Endpoint:    POST /v3/sites/${SITE_ID}/sessions/${SESSION_ID}/release"
[[ "$FORMAT" == "table" ]] && echo ""

# ── Call API ─────────────────────────────────────────────────────────────────

RESP=$(curl -s -w "\n%{http_code}" \
  -X POST "$URL" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "x-API-Id: ${API_ID}" \
  -H "x-API-Key: ${API_KEY}")

HTTP_CODE=$(echo "$RESP" | tail -1)
BODY=$(echo "$RESP" | sed '$d')

# ── Output ───────────────────────────────────────────────────────────────────

if [[ "$FORMAT" == "json" ]]; then
  echo "{\"status_code\": ${HTTP_CODE}, \"response\": ${BODY}}"
  exit 0
fi

# Table / human-readable output
case "$HTTP_CODE" in
  200)
    # Parse response: { "data": [ { "message": "...", "successful": true } ] }
    SUCCESSFUL=$(echo "$BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',[{}])[0].get('successful','unknown'))" 2>/dev/null || echo "unknown")
    MESSAGE=$(echo "$BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',[{}])[0].get('message',''))" 2>/dev/null || echo "")
    if [[ "$SUCCESSFUL" == "True" || "$SUCCESSFUL" == "true" ]]; then
      echo "✅ Release result:"
      echo "   Successful: true"
      [[ -n "$MESSAGE" ]] && echo "   Message:    ${MESSAGE}"
      echo ""
      echo "→ The blocked session has been released"
    else
      echo "⚠️  Release completed but successful=${SUCCESSFUL}"
      [[ -n "$MESSAGE" ]] && echo "   Message: ${MESSAGE}"
    fi
    ;;
  400)
    DETAIL=$(echo "$BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('errors',[{}])[0].get('detail',''))" 2>/dev/null || echo "")
    echo "❌ Release failed (HTTP 400): ${DETAIL:-Bad Request}"
    if echo "${DETAIL}" | grep -qi "session"; then
      echo "   → Check that the session ID is correct and the session still exists"
    fi
    exit 1
    ;;
  404)
    DETAIL=$(echo "$BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('errors',[{}])[0].get('detail',''))" 2>/dev/null || echo "")
    echo "❌ Release failed (HTTP 404): ${DETAIL:-Not Found}"
    if echo "${DETAIL}" | grep -qi "site"; then
      echo "   → Check that the site ID is correct"
    fi
    exit 1
    ;;
  500)
    echo "❌ Release failed (HTTP 500): Internal Server Error"
    echo "   → Retry later or contact Imperva support"
    exit 1
    ;;
  *)
    echo "❌ Release failed (HTTP ${HTTP_CODE})"
    echo "   Response: ${BODY}"
    exit 1
    ;;
esac
