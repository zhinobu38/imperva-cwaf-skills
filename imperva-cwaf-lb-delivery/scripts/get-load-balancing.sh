#!/bin/bash
# Imperva CWAF Load Balancing — Get Configuration
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   SITE_ID, CAID must be set by user before calling
#
# Usage:
#   SITE_ID=<id> CAID=<caid> bws run -- bash templates/get-load-balancing.sh

set -euo pipefail

if [ -z "${SITE_ID:-}" ]; then
  echo "ERROR: SITE_ID env var is required" >&2
  exit 1
fi

URL="https://my.imperva.com/api/prov/v3/sites/${SITE_ID}/data-centers-configuration"

python3 -c "
import json, urllib.request, os, sys

site_id = os.environ.get('SITE_ID', '')
api_id = os.environ.get('IMPERVA_API_ID', '')
api_key = os.environ.get('IMPERVA_API_KEY', '')

if not api_id or not api_key:
    print('ERROR: IMPERVA_API_ID and IMPERVA_API_KEY must be set via bws run', file=sys.stderr)
    sys.exit(1)

url = 'https://my.imperva.com/api/prov/v3/sites/{}/data-centers-configuration'.format(site_id)

req = urllib.request.Request(url)
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
"
