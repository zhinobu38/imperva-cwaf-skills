#!/bin/bash
# imperva_api_update_monitor.sh
# Phase 1-3: Detect release notes changes, analyze API impact, report
#
# Usage: bash imperva_api_update_monitor.sh [--force]
#   --force : skip date check, analyze latest release regardless
#
# Output: Report to stdout (for cron delivery)
# Exit: 0 = success, 1 = error

set -euo pipefail

# ── Config ──────────────────────────────────────────────────────────
API_BASE="https://docs-cybersec-be.thalesgroup.com/api/bundle/cloud-application-security"
RSS_URL="https://docs-cybersec.thalesgroup.com/bundle/cloud-application-security/page/release-notes.rss"
STATE_FILE="$HOME/.hermes/watcher_state/imperva-cwaf-api-monitor.json"
SPEC_DIR="$HOME/.hermes/skills/imperva-cwaf/imperva-cwaf-api-manual/api-spec"
ARCHIVE_DIR="$SPEC_DIR/archive"
MAPPING_FILE="$HOME/.hermes/skills/imperva-cwaf/imperva-cwaf-api-manual/references/api-spec-to-skill-mapping.md"
FORCE="${1:-}"

mkdir -p "$(dirname "$STATE_FILE")" "$ARCHIVE_DIR"

# ── Helpers ─────────────────────────────────────────────────────────
log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2; }
json_get() {
  python3 -c "import json,sys; d=json.load(open('$1')); print(d.get('$2',''))" 2>/dev/null || echo ""
}

# Strip HTML tags, decode entities
strip_html() {
  python3 -c "
import re, html, sys
text = sys.stdin.read()
text = re.sub(r'<[^>]+>', ' ', text)
text = html.unescape(text)
text = re.sub(r'\s+', ' ', text).strip()
print(text)
"
}

# ── Phase 1: Detect ─────────────────────────────────────────────────
log "Phase 1: Checking for new release notes..."

# Fetch RSS to get latest release
RSS_CONTENT=$(curl -s -L --max-time 15 "$RSS_URL")
LATEST_ITEM=$(echo "$RSS_CONTENT" | python3 -c "
import sys, re
content = sys.stdin.read()
items = re.findall(r'<item>(.*?)</item>', content, re.DOTALL)
if items:
    title = re.search(r'<title>(.*?)</title>', items[0])
    link  = re.search(r'<link>(.*?)</link>', items[0])
    desc  = re.search(r'<description>(.*?)</description>', items[0])
    date  = re.search(r'<pubDate>(.*?)</pubDate>', items[0])
    print(f'TITLE={title.group(1) if title else \"\"}')
    print(f'LINK={link.group(1) if link else \"\"}')
    print(f'DATE={date.group(1) if date else \"\"}')
" 2>/dev/null)

LATEST_TITLE=$(echo "$LATEST_ITEM" | grep '^TITLE=' | cut -d= -f2-)
LATEST_LINK=$(echo "$LATEST_ITEM" | grep '^LINK=' | cut -d= -f2-)
LATEST_DATE=$(echo "$LATEST_ITEM" | grep '^DATE=' | cut -d= -f2-)

if [ -z "$LATEST_LINK" ]; then
  log "ERROR: Could not fetch RSS feed"
  exit 1
fi

# Extract date from URL (YYYY-MM-DD)
RELEASE_DATE=$(echo "$LATEST_LINK" | grep -oP '\d{4}-\d{2}-\d{2}' | head -1)
if [ -z "$RELEASE_DATE" ]; then
  log "ERROR: Could not extract date from URL: $LATEST_LINK"
  exit 1
fi

log "Latest release: $RELEASE_DATE — $LATEST_TITLE"

# Check state file
LAST_KNOWN_DATE=""
if [ -f "$STATE_FILE" ]; then
  LAST_KNOWN_DATE=$(json_get "$STATE_FILE" "last_release_date")
fi

if [ "$LAST_KNOWN_DATE" = "$RELEASE_DATE" ] && [ "$FORCE" != "--force" ]; then
  log "No new release since last check ($LAST_KNOWN_DATE). Exiting."
  echo "[SILENT]"
  exit 0
fi

log "New release detected! Last known: ${LAST_KNOWN_DATE:-none}, New: $RELEASE_DATE"

# ── Phase 2: Analyze ────────────────────────────────────────────────
log "Phase 2: Analyzing release notes for API changes..."

# Fetch release note content via backend API
RELEASE_JSON=$(curl -s --max-time 15 "${API_BASE}/page/release-notes/${RELEASE_DATE}.htm")
RELEASE_HTML=$(echo "$RELEASE_JSON" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('topic_html', ''))
except:
    print('')
" 2>/dev/null)

if [ -z "$RELEASE_HTML" ]; then
  log "WARNING: Could not fetch release content. Saving state and reporting."
  echo "{\"last_release_date\":\"$RELEASE_DATE\",\"last_checked\":\"$(date -Iseconds)\",\"status\":\"fetch_failed\"}" > "$STATE_FILE"
  echo "⚠️ Imperva CWAF Release Monitor — Fetch Failed"
  echo ""
  echo "Release: $RELEASE_DATE — $LATEST_TITLE"
  echo "URL: $LATEST_LINK"
  echo ""
  echo "Could not fetch release content for analysis."
  exit 0
fi

# Extract all external links from release notes
RELEASE_LINKS=$(echo "$RELEASE_HTML" | python3 -c "
import re, sys
html = sys.stdin.read()
links = re.findall(r'href=\"([^\"]+)\"', html)
seen = set()
for l in links:
    if l.startswith('#'):
        continue
    # Normalize relative URLs
    if l.startswith('../'):
        l = 'https://docs-cybersec.thalesgroup.com/bundle/cloud-application-security/page/' + l[3:]
    elif l.startswith('/'):
        l = 'https://docs-cybersec.thalesgroup.com' + l
    if l not in seen:
        seen.add(l)
        print(l)
" 2>/dev/null)

# Categorize links
API_DOC_LINKS=""
MANUAL_LINKS=""
KB_LINKS=""
OTHER_LINKS=""

while IFS= read -r link; do
  [ -z "$link" ] && continue
  if echo "$link" | grep -q 'api-docs.*definition'; then
    API_DOC_LINKS="${API_DOC_LINKS}${link}\n"
  elif echo "$link" | grep -q 'z-kb-articles'; then
    KB_LINKS="${KB_LINKS}${link}\n"
  elif echo "$link" | grep -qP '(page|bundle)/.*\.htm'; then
    MANUAL_LINKS="${MANUAL_LINKS}${link}\n"
  else
    OTHER_LINKS="${OTHER_LINKS}${link}\n"
  fi
done <<< "$RELEASE_LINKS"

# Extract release note text for keyword analysis
RELEASE_TEXT=$(echo "$RELEASE_HTML" | strip_html)

# Check for API-related keywords
API_CHANGE_KEYWORDS="deprecat|new endpoint|API update|API change|rate limit|breaking change|API version|endpoint.*remov|endpoint.*add|API.*modif|swagger|openapi|spec"
API_CHANGE_FOUND=$(echo "$RELEASE_TEXT" | grep -iE "$API_CHANGE_KEYWORDS" | head -5 || true)

# Check for specific API mentions
MENTIONED_APIS=""
for api_pattern in "sites-mgmt" "policies/v2" "prov/v1" "prov/v2" "prov/v3" "certificates-ui" "ip-reputation" "appdlv" "waf-settings" "basic-api-security" "api-docs"; do
  if echo "$RELEASE_TEXT" | grep -qi "$api_pattern"; then
    MENTIONED_APIS="${MENTIONED_APIS}${api_pattern}\n"
  fi
done

# ── Phase 3: Report ─────────────────────────────────────────────────
log "Phase 3: Generating report..."

# Count findings
NUM_API_DOCS=$(echo -e "$API_DOC_LINKS" | grep -c '.' 2>/dev/null || echo 0)
NUM_MANUAL=$(echo -e "$MANUAL_LINKS" | grep -c '.' 2>/dev/null || echo 0)
NUM_KB=$(echo -e "$KB_LINKS" | grep -c '.' 2>/dev/null || echo 0)

# Determine impact level
IMPACT="LOW"
if [ "$NUM_API_DOCS" -gt 0 ]; then
  IMPACT="HIGH"
elif [ -n "$API_CHANGE_FOUND" ]; then
  IMPACT="MEDIUM"
fi

# Build report
cat <<REPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Imperva CWAF API Update Monitor Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 Release Date: $RELEASE_DATE
📌 Title: $LATEST_TITLE
🔗 URL: $LATEST_LINK
📊 Impact Level: $IMPACT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

REPORT

# API Reference Links found
if [ "$NUM_API_DOCS" -gt 0 ]; then
  echo "📋 API Reference Links Found ($NUM_API_DOCS):"
  echo -e "$API_DOC_LINKS" | while IFS= read -r l; do
    [ -z "$l" ] && continue
    # Extract spec name from URL
    SPEC_NAME=$(echo "$l" | grep -oP 'page/\K[^-]+' | head -1)
    echo "  ▸ $l"
    echo "    → Spec: ${SPEC_NAME}-api-definition"
  done
  echo ""
fi

# Manual/Doc Links
if [ "$NUM_MANUAL" -gt 0 ]; then
  echo "📖 Documentation Links ($NUM_MANUAL):"
  echo -e "$MANUAL_LINKS" | head -5 | while IFS= read -r l; do
    [ -z "$l" ] && continue
    echo "  ▸ $l"
  done
  echo ""
fi

# API Changes detected in text
if [ -n "$API_CHANGE_FOUND" ]; then
  echo "⚡ API Change Keywords Detected:"
  echo "$API_CHANGE_FOUND" | while IFS= read -r line; do
    echo "  ⚠️  $line"
  done
  echo ""
fi

# Mentioned APIs
if [ -n "$MENTIONED_APIS" ]; then
  echo "🔗 API Services Mentioned:"
  echo -e "$MENTIONED_APIS" | sort -u | while IFS= read -r api; do
    [ -z "$api" ] && continue
    # Map to spec file
    SPEC_HINT=""
    case "$api" in
      "sites-mgmt")     SPEC_HINT="→ site_management.yaml" ;;
      "policies/v2")    SPEC_HINT="→ policies-api.yaml" ;;
      "prov/v1"|"prov/v2"|"prov/v3")
                        SPEC_HINT="→ rules.yaml / cache-api.yaml / delivery-api.yaml" ;;
      "certificates-ui") SPEC_HINT="→ certificatesUI-api.yaml" ;;
      "ip-reputation")  SPEC_HINT="→ reputation-intelligence-api.yaml" ;;
      "appdlv")         SPEC_HINT="→ performance-statistics-api.json" ;;
      "waf-settings")   SPEC_HINT="→ website-management-api.yaml" ;;
      "basic-api-security") SPEC_HINT="→ basic-api-security-swagger.yaml" ;;
    esac
    echo "  • $api  $SPEC_HINT"
  done
  echo ""
fi

# Release summary (first 500 chars of text)
echo "📝 Release Summary:"
echo "$RELEASE_TEXT" | head -c 500
echo ""
echo ""

# Action items
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📌 Next Steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$IMPACT" = "HIGH" ]; then
  echo "  1. Review API reference links above"
  echo "  2. Download updated spec files from API reference pages"
  echo "  3. Archive old specs to api-spec/archive/"
  echo "  4. Update affected skills & scripts"
  echo "  5. Run tests against real API"
  echo "  6. Update mapping file & git commit"
  echo ""
  echo "  👤 Boss approval required before proceeding."
elif [ "$IMPACT" = "MEDIUM" ]; then
  echo "  1. Review API change keywords above"
  echo "  2. Check if any spec files need updating"
  echo "  3. If yes → follow HIGH impact steps"
  echo ""
  echo "  👤 Review recommended."
else
  echo "  No significant API changes detected."
  echo "  State file updated. Will check again next run."
fi

# Save state
echo "{\"last_release_date\":\"$RELEASE_DATE\",\"last_checked\":\"$(date -Iseconds)\",\"last_title\":\"$LATEST_TITLE\",\"last_link\":\"$LATEST_LINK\",\"impact\":\"$IMPACT\",\"api_docs_found\":$NUM_API_DOCS}" > "$STATE_FILE"
log "State saved to $STATE_FILE"
