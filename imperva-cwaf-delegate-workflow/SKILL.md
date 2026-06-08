---
name: imperva-cwaf-delegate-workflow
description: Orchestrate full Imperva CWAF site configuration using delegate_task for parallel execution — onboard, SSL/TLS, policies, custom rules, and verification.
category: imperva-cwaf
version: 1.0.0
---

# Imperva CWAF Delegate Task Workflow

Orchestrate a complete Imperva Cloud WAF site configuration using `delegate_task` for parallel execution. This workflow breaks the configuration into phases where independent tasks run concurrently.

## Architecture

```
Phase 1 (Sequential — prerequisites)
  ├── Task 1a: Check Imperva service status
  └── Task 1b: Onboard site + get site ID (depends on 1a OK)

Phase 2 (Parallel — independent configuration tasks)
  ├── Task 2a: Configure SSL certificate + TLS/HSTS
  ├── Task 2b: Create & apply policies (ACL, Whitelist, WAF Rules)
  └── Task 2c: Create custom rules

Phase 3 (Sequential — verification)
  └── Task 3: Verify all configurations are in place
```

## Required Parameters

Before running the workflow, collect these from the user:

| Parameter | Description | Example |
|-----------|-------------|---------|
| `domain` | FQDN to onboard | `myapp.example.com` |
| `origin_ip` | Origin server IP | `203.0.113.50` |
| `caid` | Imperva account ID | `<YOUR_CAID>` |
| `api_id` | Imperva API ID | `214929` |
| `api_key` | Imperva API Key | `22dc432c-...` |

## Optional Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `site_name` | Same as `domain` | Friendly name for the site |
| `tls_profile` | `ENHANCED_SECURITY` | TLS configuration profile |
| `hsts_max_age` | `31536000` | HSTS max-age in seconds |
| `hsts_subdomains` | `false` | Include subdomains in HSTS |
| `blocked_countries` | `[]` | Countries to block in ACL (e.g., `["RU","CN"]`) |
| `whitelist_urls` | `[]` | URLs to whitelist (e.g., `["/api/health","/status"]`) |
| `custom_rules` | `[]` | Custom rule definitions (see format below) |

---

## Phase 1: Prerequisites (Sequential)

### Task 1a — Status Check

Check that Imperva services are operational before making any API calls.

```python
# delegate_task goal for status check
goal = """Check Imperva service status by running:
curl -s https://status.imperva.com/api/v2/summary.json

If status.indicator is NOT "none", report the current incidents and recommend waiting.
If status.indicator is "none", confirm all systems operational and proceed."""
```

If status check fails or shows incidents, **STOP** and report to the user. Do not proceed to Phase 1b.

### Task 1b — Site Onboarding + Get Site ID

Onboard the site if it doesn't already exist, then obtain the site ID.

```python
# delegate_task goal for onboarding
goal = f"""Onboard a new site to Imperva CWAF and get its site ID.

CAID: {caid}
API ID: {api_id}
API Key: {api_key}
Domain: {domain}
Origin IP: {origin_ip}
Site Name: {site_name}

Step 1: Check if site already exists by listing sites:
curl -s -G "https://api.imperva.com/sites-mgmt/v3/sites?caid={caid}&names={domain}" \\
  -H "Accept: application/json" \\
  -H "x-API-Id: {api_id}" \\
  -H "x-API-Key: {api_key}"

Step 2: If site exists, extract the site ID from the response and return it.
If site does NOT exist, onboard it:
curl -X POST "https://api.imperva.com/sites-mgmt/v3/sites/onboard?caid={caid}" \\
  -H "Accept: application/json" \\
  -H "Content-Type: application/json" \\
  -H "x-API-Id: {api_id}" \\
  -H "x-API-Key: {api_key}" \\
  -d '{{"domain": "{domain}", "name": "{site_name}", "servers": ["{origin_ip}"], "generateCertificate": true, "type": "CLOUD_WAF"}}'

Step 3: Return the SITE_ID from the response.

IMPORTANT: Return the site ID as a clear verifiable value like: SITE_ID=<EXAMPLE_SITE_ID>"""
```

**Output needed from Phase 1**: `site_id` — this is required by all Phase 2 tasks.

---

## Phase 2: Configuration (Parallel)

Run all three tasks in parallel using `delegate_task(tasks=[...])`. Each task receives the `site_id` from Phase 1.

### Task 2a — SSL Certificate + TLS/HSTS

```python
{
    "goal": f"""Configure SSL certificate and TLS/HSTS for Imperva CWAF site.

CAID: {caid}
API ID: {api_id}
API Key: {api_key}
Site ID: {site_id}
TLS Profile: {tls_profile}
HSTS Max-Age: {hsts_max_age}
HSTS Subdomains: {hsts_subdomains}

Step 1: Enable SSL certificate (managed):
curl -X PUT "https://api.imperva.com/sites-mgmt/v3/sites/{site_id}/certificates/managed?caid={caid}" \\
  -H "Accept: application/json" \\
  -H "Content-Type: application/json" \\
  -H "x-API-Id: {api_id}" \\
  -H "x-API-Key: {api_key}" \\
  -d '{{"siteCertificateEnabled": true, "defaultValidationMethod": "CNAME"}}'

Step 2: Configure TLS/HSTS:
curl -X PATCH "https://api.imperva.com/sites-mgmt/v3/sites/{site_id}/settings/TLSConfiguration?caid={caid}" \\
  -H "Accept: application/json" \\
  -H "Content-Type: application/json" \\
  -H "x-API-Id: {api_id}" \\
  -H "x-API-Key: {api_key}" \\
  -d '{{"data": [{{"hstsConfiguration": {{"isEnabled": true, "maxAge": {hsts_max_age}, "subDomainsIncluded": {hsts_subdomains}, "preLoaded": false}}, "inboundTlsSettings": {{"configurationProfile": "{tls_profile}"}}, "disablePQCSupport": false}}]}}'

Step 3: Verify SSL is active by checking certificate details:
curl -s -G "https://api.imperva.com/certificates-ui/v3/certificates" \\
  --data-urlencode "extSiteId={site_id}" \\
  --data-urlencode "caid={caid}" \\
  -H "Accept: application/json" \\
  -H "x-API-Id: {api_id}" \\
  -H "x-API-Key: {api_key}"

Report: certificate status, TLS profile, HSTS enabled status.""",
    "toolsets": ["terminal"]
}
```

### Task 2b — Policy Creation & Assignment

```python
{
    "goal": f"""Create and apply security policies for Imperva CWAF site.

CAID: {caid}
API ID: {api_id}
API Key: {api_key}
Site ID: {site_id}
Blocked Countries: {blocked_countries}
Whitelist URLs: {whitelist_urls}

Step 1: Check existing policies applied to the site:
curl -s -G "https://api.imperva.com/policies/v2/assets/WEBSITE/{site_id}/policies?caid={caid}&extended=true" \\
  -H "Accept: application/json" \\
  -H "x-API-Id: {api_id}" \\
  -H "x-API-Key: {api_key}"

Step 2 (if blocked_countries provided): Create ACL policy and add GEO block setting.
- POST to create: "https://api.imperva.com/policies/v2/policies?caid={caid}"
  Body: {{"name": "ACL-{domain}", "policyType": "ACL", "enabled": true}}
- POST to add GEO setting: "https://api.imperva.com/policies/v2/policies/<policyId>?caid={caid}"
  Body: {{"policySettings": [{{"policySettingType": "GEO", "settingsAction": "BLOCK", "data": {{"geo": {{"countries": {blocked_countries}, "continents": []}}}}}]}}
- POST to apply: "https://api.imperva.com/policies/v2/assets/WEBSITE/{site_id}/policies/<policyId>?caid={caid}"

Step 3 (if whitelist_urls provided): Create or update Whitelist policy.
- Same pattern as ACL but policyType: "WHITELIST" and settings with URL exceptions.

Step 4: List final policies applied to site to confirm.

Report: all policy IDs created and applied, with their types and settings.""",
    "toolsets": ["terminal"]
}
```

### Task 2c — Custom Rules

```python
{
    "goal": f"""Create custom security rules for Imperva CWAF site.

CAID: {caid}
API ID: {api_id}
API Key: {api_key}
Site ID: {site_id}
Custom Rules: {custom_rules_json}

Step 1: List existing custom rules:
curl -s -G "https://my.imperva.com/api/prov/v3/rules?caid={caid}&siteIds={site_id}" \\
  -H "Accept: application/json" \\
  -H "x-API-Id: {api_id}" \\
  -H "x-API-Key: {api_key}"

Step 2: For each custom rule definition, create it:
curl -X POST "https://my.imperva.com/api/prov/v2/sites/{site_id}/rules?caid={caid}" \\
  -H "Accept: application/json" \\
  -H "Content-Type: application/json" \\
  -H "x-API-Id: {api_id}" \\
  -H "x-API-Key: {api_key}" \\
  -d @rule.json

Custom rule JSON format:
{{
  "data": [{{
    "ruleName": "<alphanumeric name>",
    "ruleAction": "RULE_ACTION_BLOCK",
    "ruleEnabled": true,
    "ruleFilter": "<filter expression>",
    "ruleDescription": "<description>",
    "severity": "High"
  }}]
}}

IMPORTANT: Rule names must be alphanumeric only (no spaces or special chars). Rule actions must be enum values: RULE_ACTION_BLOCK, RULE_ACTION_ALERT, etc.

Report: all rule IDs created and their filter expressions.""",
    "toolsets": ["terminal"]
}
```

**Running Phase 2** with `delegate_task`:

```python
delegate_task(tasks=[
    task_2a,  # SSL/TLS/HSTS
    task_2b,  # Policies
    task_2c,  # Custom Rules
])
```

All three run in parallel. Each returns a summary with verifiable IDs.

---

## Phase 3: Verification (Sequential)

After Phase 2 completes, verify the full configuration.

```python
# delegate_task goal for verification
goal = f"""Verify the complete Imperva CWAF configuration for site {site_id}.

CAID: {caid}
API ID: {api_id}
API Key: {api_key}
Site ID: {site_id}

Step 1: Get site details:
curl -s -G "https://api.imperva.com/sites-mgmt/v3/sites/{site_id}?caid={caid}" \\
  -H "Accept: application/json" \\
  -H "x-API-Id: {api_id}" \\
  -H "x-API-Key: {api_key}"

Step 2: Check SSL certificate status:
curl -s -G "https://api.imperva.com/certificates-ui/v3/certificates" \\
  --data-urlencode "extSiteId={site_id}" --data-urlencode "caid={caid}" \\
  -H "Accept: application/json" \\
  -H "x-API-Id: {api_id}" \\
  -H "x-API-Key: {api_key}"

Step 3: Check TLS/HSTS settings:
curl -s -G "https://api.imperva.com/sites-mgmt/v3/sites/{site_id}/settings/TLSConfiguration?caid={caid}" \\
  -H "Accept: application/json" \\
  -H "x-API-Id: {api_id}" \\
  -H "x-API-Key: {api_key}"

Step 4: Check applied policies:
curl -s -G "https://api.imperva.com/policies/v2/assets/WEBSITE/{site_id}/policies?caid={caid}&extended=true" \\
  -H "Accept: application/json" \\
  -H "x-API-Id: {api_id}" \\
  -H "x-API-Key: {api_key}"

Step 5: Check custom rules:
curl -s -G "https://my.imperva.com/api/prov/v3/rules?caid={caid}&siteIds={site_id}" \\
  -H "Accept: application/json" \\
  -H "x-API-Id: {api_id}" \\
  -H "x-API-Key: {api_key}"

Report a summary table:
| Component | Status | Details |
|-----------|--------|---------|
| Site      | ...    | domain, active, siteStatus |
| SSL       | ...    | certificate status, type, expiry |
| TLS/HSTS  | ...    | profile, HSTS enabled, max-age |
| Policies  | ...    | count, types, IDs |
| Custom Rules | ... | count, names, actions |"""
```

---

## Complete Workflow Implementation

Here is the full `delegate_task` call pattern:

```python
# PHASE 1 — Prerequisites (sequential)
phase1_result = delegate_task(
    goal="Check Imperva service status and onboard site...",
    # Single task: status → onboard → return site_id
)

# Extract site_id from phase1_result
site_id = extract_site_id(phase1_result)

# PHASE 2 — Configuration (parallel)
phase2_results = delegate_task(
    tasks=[
        {"goal": ssl_tls_goal, "toolsets": ["terminal"]},
        {"goal": policy_goal,   "toolsets": ["terminal"]},
        {"goal": custom_rule_goal, "toolsets": ["terminal"]},
    ]
)

# PHASE 3 — Verification (sequential)
phase3_result = delegate_task(
    goal="Verify all configurations...",
)

# Report final summary to user
```

---

## Partial Workflow Options

Not every site needs the full workflow. Choose the appropriate subset:

| Scenario | Phases | Tasks |
|----------|--------|-------|
| New site — full setup | 1→2→3 | All tasks |
| Existing site — add SSL only | 1a → 2a only | Status check + SSL |
| Existing site — add policies only | 1a → 2b only | Status check + Policies |
| Existing site — add custom rules only | 1a → 2c only | Status check + Rules |
| Verify existing config | 3 only | Verification |
| Reconfigure TLS/HSTS | 1a → 2a | Status check + SSL/TLS patch |

---

## Pitfalls

- **Phase 2 tasks need the `site_id`** from Phase 1. Never run Phase 2 before Phase 1 completes.
- **SSL must be enabled before TLS/HSTS** — Task 2a handles this internally (enable cert first, then configure TLS).
- **Policy API uses flat JSON (no `data` wrapper)** — but Custom Rules API uses `{"data": [...]}` wrapper. Don't mix them up.
- **Always remove policy from site before deleting it** — the API errors if you delete an applied policy.
- **Custom rule names must be alphanumeric** — no spaces, hyphens, or special characters.
- **Custom rule actions are enums** — use `RULE_ACTION_BLOCK`, `RULE_ACTION_ALERT`, etc.
- **Exception settings need parent setting `id`** — GET the policy first to find the setting ID before adding exceptions.
- **Parallel tasks are isolated** — each subagent has its own session. Pass all needed credentials explicitly in the `context`.

---

## Dedicated Imperva Agent Profile

For repeated or complex Imperva operations, consider using the dedicated `imperva-agent` profile instead of `delegate_task`:

```
hermes --profile imperva-agent chat -q "List all sites"
imperva-agent chat -q "Configure SSL for site <EXAMPLE_SITE_ID>"
```

The imperva-agent profile has all 8 imperva-cwaf skills pre-loaded, Imperva-specific memory (CAID, known sites, API quirks), and Bitwarden secrets configured. It uses `openai/gpt-oss-120b:free` which is fast and cost-effective for API automation tasks.

Use `delegate_task` when you need parallel execution of independent subtasks. Use `imperva-agent` profile for interactive or sequential Imperva work.

---

## Related Skills

- `imperva-cwaf-site-onboard`: Site onboarding API details
- `imperva-cwaf-ssl-management`: SSL/TLS/HSTS API details
- `imperva-cwaf-policy-management`: Policy CRUD and asset assignment
- `imperva-cwaf-custom-rule`: Custom rule creation and management
- `imperva-cwaf-get-site-detail`: Site listing and detail retrieval
- `imperva-cwaf-status-check`: Service status verification
- `imperva-cwaf-api-manual`: Full API specification reference
