#!/usr/bin/env bash
# imperva_ip_reputation.sh — Query Imperva Reputation Intelligence API
# Usage: imperva_ip_reputation.sh <ip> [--format table|json]
#
# Credentials: IMPERVA_API_ID, IMPERVA_API_KEY (from bws run)
# Rate limit: 10 req/min
# API: GET https://api.imperva.com/ip-reputation/v1/reputation?ip=<IP>

set -euo pipefail

# ── Args ──────────────────────────────────────────────────────────────
IP=""
FORMAT="table"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --format)
      FORMAT="$2"; shift 2
      ;;
    -h|--help)
      sed -n '2,15p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      if [[ -z "$IP" ]]; then IP="$1"; fi
      shift
      ;;
  esac
done

if [[ -z "$IP" ]]; then
  echo "❌ Usage: $0 <ip> [--format table|json]" >&2
  exit 1
fi

# Validate IPv4
if ! [[ "$IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "❌ Invalid IPv4 address: $IP" >&2
  exit 1
fi

# ── Credentials ───────────────────────────────────────────────────────
if [[ -z "${IMPERVA_API_ID:-}" ]]; then
  echo "❌ IMPERVA_API_ID not set. Use: bws run -- $0 $IP" >&2
  exit 1
fi
if [[ -z "${IMPERVA_API_KEY:-}" ]]; then
  echo "❌ IMPERVA_API_KEY not set. Use: bws run -- $0 $IP" >&2
  exit 1
fi

# ── Call API ──────────────────────────────────────────────────────────
URL="https://api.imperva.com/ip-reputation/v1/reputation?ip=${IP}"

RESP=$(curl -sS \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  -H "Accept: application/json" \
  "$URL")

# Check for curl failure
if [[ -z "$RESP" ]]; then
  echo "❌ Empty response from API" >&2
  exit 1
fi

# ── Output ────────────────────────────────────────────────────────────
if [[ "$FORMAT" == "json" ]]; then
  echo "$RESP" | python3 -m json.tool 2>/dev/null || echo "$RESP"
  exit 0
fi

# ── Table format ──────────────────────────────────────────────────────
# Write response to temp file for Python to read (avoids shell escaping issues)
TMPFILE=$(mktemp /tmp/imperva_reputation_XXXXXX.json)
trap "rm -f $TMPFILE" EXIT
echo "$RESP" > "$TMPFILE"

python3 -c "
import json, sys

with open('$TMPFILE') as f:
    data = json.load(f)

ip = data.get('ip', 'N/A')
origin = data.get('origin') or {}
asn = data.get('asn') or {}
risk = data.get('risk') or {}
known_to_use = data.get('known_to_use') or 'N/A'
known_for = data.get('known_for') or 'N/A'
requests = data.get('requests')
violations = data.get('violations') or {}
violations_over_time = data.get('violations_over_time') or {}
client_app = data.get('client_application') or {}
client_app_details = data.get('client_application_details') or {}
attacks_by_industry = data.get('attacks_by_industry') or {}

# Handle known_to_use / known_for — can be string or list
if isinstance(known_to_use, list):
    known_to_use = ', '.join(known_to_use)
if isinstance(known_for, list):
    known_for = ', '.join(known_for)

# Risk score visual bar
score_num = risk.get('risk_score_number')
try:
    score_int = int(score_num) if score_num is not None else 0
except (ValueError, TypeError):
    score_int = 0
bar_filled = min(score_int // 5, 20)
bar_empty = 20 - bar_filled
bar = '█' * bar_filled + '░' * bar_empty

risk_level = risk.get('risk_score', 'N/A')
if risk_level == 'CRITICAL':
    risk_emoji = '🔴'
elif risk_level == 'HIGH':
    risk_emoji = '🟠'
elif risk_level == 'MEDIUM':
    risk_emoji = '🟡'
elif risk_level == 'LOW':
    risk_emoji = '🟢'
else:
    risk_emoji = '⚪'

# Helper to truncate and pad
def pad(s, width):
    s = str(s)
    if len(s) > width:
        return s[:width-3] + '...'
    return s.ljust(width)

W = 48  # content width inside box

print()
print('╔══════════════════════════════════════════════════════════════╗')
print('║          🛡️  Imperva Reputation Intelligence                ║')
print('╠══════════════════════════════════════════════════════════════╣')
print(f'║  IP:        {pad(ip, W)}║')
print('╠══════════════════════════════════════════════════════════════╣')
print('║  🌍 Origin                                                    ║')
country = origin.get('country') or 'N/A'
city = origin.get('city') or 'N/A'
asn_num = asn.get('organization_number', '')
asn_name = asn.get('organization_name', 'N/A')
print(f'║    Country:  {pad(country, W)}║')
print(f'║    City:     {pad(city, W)}║')
asn_str = f'{asn_num} ({asn_name})' if asn_num else asn_name
print(f'║    ASN:      {pad(asn_str, W)}║')
print('╠══════════════════════════════════════════════════════════════╣')
print('║  ⚠️  Risk Score                                               ║')
score_display = f'{score_num}/100' if score_num is not None else 'N/A'
print(f'║    Level:    {risk_emoji} {pad(risk_level + \" (\" + score_display + \")\", W - 2)}║')
if score_int > 0:
    print(f'║    Bar:      [{bar}] {score_int}%{' ' * max(0, 16 - len(str(score_int)))}║')
risk_desc = risk.get('risk_description') or ''
if risk_desc:
    print(f'║    Detail:   {pad(risk_desc, W)}║')
print('╠══════════════════════════════════════════════════════════════╣')
print('║  🔍 Intelligence                                              ║')
print(f'║    Known to use:  {pad(known_to_use, W - 4)}║')
print(f'║    Known for:     {pad(known_for, W - 4)}║')
req_str = str(requests) if requests is not None else 'N/A'
print(f'║    Requests (2wk): {pad(req_str, W - 5)}║')
print('╠══════════════════════════════════════════════════════════════╣')

# Violations distribution
if violations:
    print('║  📊 Attack Distribution (%)                                  ║')
    for k, v in violations.items():
        line = f'{k}: {v}'
        print(f'║    {pad(line, W)}║')
    print('╠══════════════════════════════════════════════════════════════╣')

# Client applications
if client_app:
    print('║  🤖 Client Application (%)                                   ║')
    for k, v in client_app.items():
        line = f'{k}: {v}'
        print(f'║    {pad(line, W)}║')
    print('╠══════════════════════════════════════════════════════════════╣')

# Industries
if attacks_by_industry:
    print('║  🏭 Attacks by Industry (%)                                  ║')
    for k, v in attacks_by_industry.items():
        line = f'{k}: {v}'
        print(f'║    {pad(line, W)}║')
    print('╠══════════════════════════════════════════════════════════════╣')

# Violations over time (summary)
if violations_over_time:
    print('║  📈 Violations Over Time                                     ║')
    for atype, timestamps in violations_over_time.items():
        if isinstance(timestamps, dict):
            ts_count = len(timestamps)
            try:
                total_hits = sum(int(v) for v in timestamps.values())
            except (ValueError, TypeError):
                total_hits = 0
            line = f'{atype}: {ts_count} data points, {total_hits} hits'
        else:
            line = f'{atype}: {timestamps}'
        print(f'║    {pad(line, W)}║')
    print('╠══════════════════════════════════════════════════════════════╣')

print('╚══════════════════════════════════════════════════════════════╝')
print()
"
