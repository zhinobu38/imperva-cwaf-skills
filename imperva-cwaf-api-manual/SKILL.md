---
name: imperva-cwaf-api-manual
description: A skill to browse and search the Imperva Cloud WAF API specification documents for reference and understanding of endpoints, parameters, and responses.
category: imperva-cwaf
version: 1.0.0
---

# Imperva CWAF API Manual

This skill provides functionality to browse, search, and view the Imperva Cloud WAF API specification documents stored in the `api-spec` directory. These specifications are in OpenAPI (YAML/JSON) format and detail the endpoints, parameters, responses, and schemas for various Imperva Cloud WAF services.

## Directory Structure

The API specifications are located in:
```
~/.hermes/skills/imperva-cwaf/imperva-cwaf-api-manual/api-spec/
```

Each file represents a specific API service or functional area. For example:
- `site_management.yaml` - Site management API (list sites, get site details, etc.)
- `policies-api.yaml` - Policies API
- `rules.yaml` - Rules API
- `cache-api.yaml` - Cache settings and cache rules API
- `certificatesUI-api.yaml` - Certificate management API
- `website-management-api.yaml` - Website settings (TLS/HSTS, etc.)
- `load-balancing-api.yaml` - Load balancing and failover settings (data centers, servers, LB algorithms)
- `performance-statistics-api.json` - Application Performance Statistics API v3 (popLatency, originResponseTime, errorResponseTypes per site/account)
- ... and others.

## How to List API Specs

To see a list of all available API specification files:

```bash
ls ~/.hermes/skills/imperva-cwaf/imperva-cwaf-api-manual/api-spec/
```

Or using the Hermes Agent `terminal` tool:

```bash
terminal --command "ls ~/.hermes/skills/imperva-cwaf/imperva-cwaf-api-manual/api-spec/"
```

## How to Search within API Specs

To search for a specific term (e.g., an endpoint, parameter, or schema) across all API spec files:

```bash
grep -r "your_search_term" ~/.hermes/skills/imperva-cwaf/imperva-cwaf-api-manual/api-spec/
```

Using the Hermes Agent `search_files` tool (for content search):

```bash
# Search for content matching a regex pattern
search_files --pattern="your_search_term" --path=~/.hermes/skills/imperva-cwaf/imperva-cwaf-api-manual/api-spec/ --target=content
```

To search for a specific file by name:

```bash
search_files --pattern="*site*" --path=~/.hermes/skills/imperva-cwaf/imperva-cwaf-api-manual/api-spec/ --target=files
```

## How to View a Specific API Spec

To view the content of a specific API specification file (e.g., `site_management.yaml`):

```bash
cat ~/.hermes/skills/imperva-cwaf/imperva-cwaf-api-manual/api-spec/site_management.yaml
```

Using the Hermes Agent `read_file` tool (with pagination if needed):

```bash
read_file --path=~/.hermes/skills/imperva-cwaf/imperva-cwaf-api-manual/api-spec/site_management.yaml --limit=100
```

## Example Usage

### Listing all available API specs
```bash
ls ~/.hermes/skills/imperva-cwaf/imperva-cwaf-api-manual/api-spec/
```

### Searching for the "sites" endpoint in all specs
```bash
grep -r "sites" ~/.hermes/skills/imperva-cwaf/imperva-cwaf-api-manual/api-spec/ | head -20
```

### Viewing the site management API spec (first 50 lines)
```bash
read_file --path=~/.hermes/skills/imperva-cwaf/imperva-cwaf-api-manual/api-spec/site_management.yaml --limit=50
```

### Finding all files related to "certificate"
```bash
search_files --pattern="*certificate*" --path=~/.hermes/skills/imperva-cwaf/imperva-cwaf-api-manual/api-spec/ --target=files
```

### Practical Example: Using API Specs to Configure TLS/HSTS
Based on real usage in this session, here's how to use the API specs to make actual configuration changes:

1. **Find the TLS configuration endpoint** in website-management-api.yaml:
   - Look for `/v3/sites/{siteId}/settings/TLSConfiguration`
   - See that it supports PATCH method for partial updates
   - Check the request body format in the examples section

2. **Construct the API call** using the information from the spec:
   ```bash
   # Get current TLS/HSTS settings first (GET)
   curl -s -G "https://api.imperva.com/sites-mgmt/v3/sites/<EXAMPLE_SITE_ID>/settings/TLSConfiguration?caid=<YOUR_CAID>" \
     -H "Accept: application/json" \
     -H "x-API-Id: $IMPERVA_API_ID" \
     -H "x-API-Key: $IMPERVA_API_KEY"

   # Update to enable HSTS and set Enhanced Security profile (PATCH)
   curl -X PATCH "https://api.imperva.com/sites-mgmt/v3/sites/<EXAMPLE_SITE_ID>/settings/TLSConfiguration?caid=<YOUR_CAID>" \
     -H "Accept: application/json" \
     -H "x-API-Id: $IMPERVA_API_ID" \
     -H "x-API-Key: $IMPERVA_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "data": [
         {
           "hstsConfiguration": {
             "isEnabled": true,
             "maxAge": 31536000,
             "subDomainsIncluded": false,
             "preLoaded": false
           },
           "inboundTlsSettings": {
             "configurationProfile": "ENHANCED_SECURITY"
           },
           "disablePQCSupport": false
         }
       ]
     }'
   ```

3. **Verify the changes** (GET again):
   ```bash
   curl -s -G "https://api.imperva.com/sites-mgmt/v3/sites/<EXAMPLE_SITE_ID>/settings/TLSConfiguration?caid=<YOUR_CAID>" \
     -H "Accept: application/json" \
     -H "x-API-Id: $IMPERVA_API_ID" \
     -H "x-API-Key: $IMPERVA_API_KEY" | jq .
   ```

## api-spec → Skill Mapping

See `references/api-spec-skill-mapping.md` for a complete table mapping each api-spec file to the skill(s) that use it, including API base paths. This is used by the release notes monitor to identify affected skills when API changes are detected.

## How to Download Updated API Specs from Thales Docs

The Thales documentation portal (`docs-cybersec.thalesgroup.com`) is a JS SPA. Browser snapshots return empty content. Use the backend API directly:

### Step 1: Find API Reference Links in Release Notes

```bash
# Fetch release notes content via backend API
curl -s "https://docs-cybersec-be.thalesgroup.com/api/bundle/cloud-application-security/page/release-notes/YYYY-MM-DD.htm" | python3 -c "
import json, re, sys
data = json.load(sys.stdin)
html = data.get('topic_html', '')
links = re.findall(r'href=\"([^\"]+)\"', html)
for l in links:
    if 'api-docs' in l.lower() or 'api' in l.lower():
        print(l)
"
```

### Step 2: Download API Spec from API Reference Page

Navigate to the API reference page and find the download button:

```bash
# Fetch the API reference page
curl -s "https://docs-cybersec-be.thalesgroup.com/api/bundle/api-docs/page/{api-page}.htm" | python3 -c "
import json, re, sys
data = json.load(sys.stdin)
html = data.get('topic_html', '')
# Find download links for spec files
links = re.findall(r'href=\"([^\"]+)\"', html)
for l in links:
    if l.endswith('.yaml') or l.endswith('.json') or 'download' in l.lower():
        print(l)
"
```

Then download the spec file directly:
```bash
curl -s "https://docs-cybersec.thalesgroup.com/path/to/spec.yaml" -o ~/.hermes/skills/imperva-cwaf/imperva-cwaf-api-manual/api-spec/{filename}.yaml
```

### Step 3: Archive Old Spec and Update

```bash
# Create archive directory
mkdir -p ~/.hermes/skills/imperva-cwaf/imperva-cwaf-api-manual/api-spec/archive

# Archive old spec with timestamp
mv ~/.hermes/skills/imperva-cwaf/imperva-cwaf-api-manual/api-spec/{filename}.yaml \
   ~/.hermes/skills/imperva-cwaf/imperva-cwaf-api-manual/api-spec/archive/{filename}-$(date +%Y%m%d).yaml

# New spec is already in place from Step 2
```

### RSS Feed for Release Notes

```bash
# Get latest release notes list
curl -s -L "https://docs-cybersec.thalesgroup.com/bundle/cloud-application-security/page/release-notes.rss"
```

The RSS feed contains `<item>` elements with `<link>` pointing to individual release note pages. Compare the latest `<link>` against your last-known release URL to detect new releases.

### Key URLs

| Purpose | URL |
|---------|-----|
| Release notes index | `https://docs-cybersec.thalesgroup.com/bundle/cloud-application-security/page/release-notes/release-notes.htm` |
| Individual release | `https://docs-cybersec-be.thalesgroup.com/api/bundle/cloud-application-security/page/release-notes/YYYY-MM-DD.htm` |
| RSS feed | `https://docs-cybersec.thalesgroup.com/bundle/cloud-application-security/page/release-notes.rss` |
| API reference pages | `https://docs-cybersec-be.thalesgroup.com/api/bundle/api-docs/page/{api-name}.htm` |

## Shared References

These files are maintained at the `imperva-cwaf/` skill group level and are the
single source of truth for all sub-skills. Do NOT duplicate their content.

| Reference | Description |
|-----------|-------------|
| `../references/skill-dev-standard.md` | Dev standard: template structure, credential rules, known API behaviors, pitfalls |
| `../references/credential-and-identifier-policy.md` | Credential/identifier sourcing rules (Bitwarden bws run) |
| `../references/shell-template-pattern.md` | Shell template patterns (GET→modify→PUT, form-encoded POST, header format) |

## Credential Policy

**NEVER hardcode Imperva API credentials in any file.** Always retrieve from Bitwarden:
```bash
bws run --project-id <BW_PROJECT_ID_READ> -- <command>
```

All examples in this skill reference `$IMPERVA_API_ID` and `$IMPERVA_API_KEY` — these are injected by `bws run`, NOT local env vars.
- The specs may be updated periodically. Ensure you are referencing the latest version by checking the file modification times or checking for updates in the skill directory.
- This skill does not make any external network requests; it only reads local files.

## API Update Monitoring

Automated API change detection is handled by `imperva_api_update_monitor.sh` in `../imperva-cwaf-api-manual/scripts/`.
See `references/api-spec-to-skill-mapping.md` for the complete spec-to-skill mapping.

When a release note indicates an API change:
1. Run the monitor script: `bash scripts/imperva_api_update_monitor.sh`
2. Review the HIGH/MEDIUM/LOW impact report
3. If API reference links are found, follow the download/update workflow in watcher skill's "Imperva CWAF API Update Monitor" section

## Support Files

- `references/api-spec-to-skill-mapping.md` — complete mapping of spec files → skills & scripts (many-to-many)

- `imperva-cwaf-policy-management`: For managing WAF rules, ACL, Whitelist policies and exceptions (create, modify, apply, remove).
- `imperva-cwaf-custom-rule`: For managing site-level custom rules (redirect, block, rewrite, etc.) via the Rules API.
- `imperva-cwaf-get-site-detail`: For retrieving site details or listing sites.
- `imperva-cwaf-site-onboard`: For onboarding a new site.
- `imperva-cwaf-status-check`: For checking Imperva service status.
- `imperva-cwaf-ssl-management`: For managing SSL certificates and TLS/HSTS settings.
- `imperva-cwaf-cache`: For managing cache settings, cache rules, client-side caching, response header caching, and cache purging.
- `imperva-cwaf-load-balancing`: For managing load balancing, data centers, origin servers, LB algorithms, geo routing, failover, and traffic resume.
- `imperva-cwaf-troubleshoot`: For troubleshooting website performance and availability — performance statistics (latency, origin response time, errors) with PoP filtering.
- `imperva-cwaf-troubleshoot`: For diagnosing website performance and availability issues (popLatency, originResponseTime, errorResponseTypes).

## Support Files

- `references/rule-filter-parameters.md`: Comprehensive list of rule filter parameters with examples and usage guidelines.
- `references/integrations-api-guide.md`: Practical reference for `api-spec/integrations.yaml` — client apps, geo codes, Imperva IP ranges, and API text inventory endpoints with use cases.
- `references/jq-tempfile-technique.md`: How to write jq filters to temp files to avoid double-shell quoting issues through `bws run`.

---