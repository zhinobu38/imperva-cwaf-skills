#!/bin/bash
# Imperva CWAF Load Balancing — Update Monitoring Settings (GET → modify → PUT)
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   SITE_ID, CAID must be set by user before calling
#
# Usage:
#   SITE_ID=<id> CAID=<caid> bws run -- bash scripts/update-monitoring.sh < modified.json
#
# Workflow:
#   1. GET current settings via get-monitoring.sh
#   2. User modifies the JSON
#   3. Pipe modified JSON into this script
#
# API supports both PUT (full update) and POST (partial update).
# This script uses PUT for full replacement.

set -euo pipefail

if [ -z "${SITE_ID:-}" ]; then
  echo "ERROR: SITE_ID env var is required" >&2
  exit 1
fi

URL="https://api.imperva.com/appdlv-site-settings/v2/site/${SITE_ID}/monitoring"

# Write Python script to temp file to avoid shell escaping issues
PY_SCRIPT=$(mktemp /tmp/imperva-monitoring-update-XXXXXX.py)
trap "rm -f ${PY_SCRIPT}" EXIT

cat > "${PY_SCRIPT}" << 'PYEOF'
import json, urllib.request, os, sys

site_id = os.environ.get('SITE_ID', '')
api_id = os.environ.get('IMPERVA_API_ID', '')
api_key = os.environ.get('IMPERVA_API_KEY', '')
caid = os.environ.get('CAID', '')

if not api_id or not api_key:
    print('ERROR: IMPERVA_API_ID and IMPERVA_API_KEY must be set via bws run', file=sys.stderr)
    sys.exit(1)

# Read modified JSON from stdin
modified_json = sys.stdin.read()
if not modified_json.strip():
    print('ERROR: No JSON input on stdin. Pipe modified JSON into this script.', file=sys.stderr)
    sys.exit(1)

try:
    modified = json.loads(modified_json)
except json.JSONDecodeError as e:
    print('ERROR: Invalid JSON input: {}'.format(e), file=sys.stderr)
    sys.exit(1)

url = 'https://api.imperva.com/appdlv-site-settings/v2/site/{}/monitoring'.format(site_id)
if caid:
    url += '?caid={}'.format(caid)

body = json.dumps(modified).encode()

req = urllib.request.Request(url, data=body, method='PUT')
req.add_header('Content-Type', 'application/json')
req.add_header('Accept', 'application/json')
req.add_header('x-API-Id', api_id)
req.add_header('x-API-Key', api_key)

try:
    resp = urllib.request.urlopen(req, timeout=30)
    data = json.loads(resp.read().decode())
    print(json.dumps(data, indent=2))
except urllib.error.HTTPError as e:
    body = e.read().decode() if e.fp else ''
    print('HTTP Error {}: {}'.format(e.code, e.reason), file=sys.stderr)
    if body:
        print(body, file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print('Error: {}'.format(e), file=sys.stderr)
    sys.exit(1)
PYEOF

python3 "${PY_SCRIPT}"
