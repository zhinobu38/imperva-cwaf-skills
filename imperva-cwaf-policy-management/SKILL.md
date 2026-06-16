---
name: imperva-cwaf-policy-management
description: Manage Imperva Cloud WAF policies — WAF rules, ACL, Whitelist, and exceptions. Create, modify, apply, and remove policies across sites.
category: imperva-cwaf
version: 2.1.0
---

# Imperva CWAF Policy Management

Manage security policies (WAF Rules, ACL, Whitelist, File Upload) including policy settings, exceptions, and asset assignments via the Policies API.

## Prerequisites

- API Credentials: CAID, API ID, API Key (same as other Imperva CWAF skills)
- Site ID of the target website (use `imperva-cwaf-get-site-detail` if unknown)

## Shared References

| Reference | Description |
|-----------|-------------|
| `../references/skill-dev-standard.md` | Dev standard: template structure, credential rules, known API behaviors, pitfalls |
| `../references/credential-and-identifier-policy.md` | Credential/identifier sourcing rules (Bitwarden bws run) |
| `../references/shell-template-pattern.md` | Shell template patterns (GET→modify→PUT, form-encoded POST, header format) |
| `references/policy-types.md` | Policy types, settings actions, URL patterns, and exception types |

## Credential & Identifier Policy (MANDATORY)

| Value | Source | Method |
|-------|--------|--------|
| `IMPERVA_API_ID` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `IMPERVA_API_KEY` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `CAID` | User / memory | Pass as env var |
| `SITE_ID` | User / memory / get-site-detail | Pass as env var |
| `POLICY_ID` | From list/get/create response | Pass as env var |

**NEVER hardcode credentials or identifiers.**

## Setup

```bash
# Scripts need execute permission (one-time)
chmod +x ~/.hermes/skills/imperva-cwaf/imperva-cwaf-policy-management/scripts/*.sh
```

## ⚡ MANDATORY: Use the Scripts

**ALWAYS use the provided scripts. Do NOT write inline curl.**

All scripts are at: `~/.hermes/skills/imperva-cwaf/imperva-cwaf-policy-management/scripts/`

### List All Policies

```bash
CAID=<caid> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-policy-management/scripts/list-policies.sh
```

Optional: `POLICY_TYPE=ACL` to filter by type.

### Get a Specific Policy

```bash
CAID=<caid> POLICY_ID=<id> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-policy-management/scripts/get-policy.sh
```

### Create a New Policy

```bash
CAID=<caid> POLICY_NAME="Block RU" POLICY_TYPE=ACL \
  bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-policy-management/scripts/create-policy.sh
```

### Add GEO Setting to a Policy

```bash
CAID=<caid> POLICY_ID=<id> COUNTRIES='["RU","CN"]' ACTION=BLOCK \
  bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-policy-management/scripts/add-geo-setting.sh
```

### Add IP Setting to a Policy

```bash
CAID=<caid> POLICY_ID=<id> IPS='["198.51.100.0/24","10.0.0.1"]' ACTION=BLOCK \
  bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-policy-management/scripts/add-ip-setting.sh
```

### Add URL Setting to a Policy

```bash
CAID=<caid> POLICY_ID=<id> URLS='[{"pattern":"PREFIX","url":"/admin/"}]' ACTION=BLOCK \
  bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-policy-management/scripts/add-url-setting.sh
```

### Add Exception to a Policy Setting

```bash
# First GET the policy to find the setting ID, then:
CAID=<caid> POLICY_ID=<id> SETTING_ID=<sid> \
  EXCEPTIONS='[{"exceptionType":"IP","values":["10.0.0.0/8"]}]' \
  bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-policy-management/scripts/add-exception.sh
```

### Apply Policy to a Site

```bash
SITE_ID=<id> POLICY_ID=<id> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-policy-management/scripts/apply-policy.sh
```

### Remove Policy from a Site

```bash
SITE_ID=<id> POLICY_ID=<id> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-policy-management/scripts/remove-policy.sh
```

### Delete a Policy

```bash
CAID=<caid> POLICY_ID=<id> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-policy-management/scripts/delete-policy.sh
```

### List Policies Applied to a Site

```bash
SITE_ID=<id> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-policy-management/scripts/list-site-policies.sh
```

### Update a Policy

```bash
# Update name and/or description and/or enabled status
CAID=<caid> POLICY_ID=<id> POLICY_NAME="New Name" bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-policy-management/scripts/update-policy.sh

CAID=<caid> POLICY_ID=<id> ENABLED=false bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-policy-management/scripts/update-policy.sh
```

---

## Policy Types

| Policy Type | Description | Apply To |
|-------------|-------------|----------|
| WAF_RULES | WAF rule definitions (SQLi, XSS, etc.) | Websites |
| ACL | Access Control Lists (IP/Geo/URL allow/block) | Websites |
| WHITELIST | Whitelist to skip security checks | Websites |
| FILE_UPLOAD | File upload policies | Websites |

See `references/policy-types.md` for full details.

> **Looking up country/continent codes for GEO policies?** Use the integrations script:
> ```bash
> bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9 -- python3 \
>   ~/.hermes/skills/imperva-cwaf/imperva-cwaf-api-manual/scripts/integrations.py \
>   geo [--country CODE] [--continent CODE] [--limit N]
> ```

---

## Common Workflows

### Create ACL Policy with GEO Block and Apply to Site

```bash
# Step 1: Create policy
CAID=<caid> POLICY_NAME="Block RU" POLICY_TYPE=ACL \
  bws run --project-id <bw_id> -- bash scripts/create-policy.sh
# → Note the returned policy ID

# Step 2: Add GEO setting
CAID=<caid> POLICY_ID=<id> COUNTRIES='["RU"]' ACTION=BLOCK \
  bws run --project-id <bw_id> -- bash scripts/add-geo-setting.sh

# Step 3: Apply to site
SITE_ID=<id> POLICY_ID=<id> \
  bws run --project-id <bw_id> -- bash scripts/apply-policy.sh
```

### Copy Policy from One Site to Another

1. `list-site-policies.sh` on source site → get policy ID
2. `get-policy.sh` → get full policy JSON
3. `create-policy.sh` with new name
4. `add-geo-setting.sh` (or other settings) to replicate
5. `apply-policy.sh` on target site

---

## Response Format

All responses follow this envelope:
```json
{ "isError": false, "value": { ... } }
```

When `isError` is `true`, `value` contains an error message string.

---

## Error Handling

| HTTP Code | Meaning |
|-----------|---------|
| 200 | Success |
| 400 | Bad Request (invalid JSON, missing fields, invalid policy type) |
| 401 | Unauthorized (invalid API credentials) |
| 404 | Not Found (policy or site doesn't exist) |
| 429 | Rate Limited |
| 500 | Internal Server Error |

---

## Settings Reference

See `references/policy-types.md` for policy types, settings actions, URL pattern types, and exception types.

---

## Pitfalls

- **No `data` wrapper in ANY Imperva API request body.** All Imperva Cloud WAF APIs use flat JSON — do NOT wrap in `{"data": {...}}` anywhere.
- **Always remove policy from site before deleting.** Unassign first, then delete.
- **Exception settings must reference the parent setting `id`.** GET the policy first to find the setting ID before adding exceptions.
- **Response `isError` is a boolean field**, not an HTTP status code. Check `isError` in the JSON body.
- **POST appends, PUT replaces.** Use POST to add settings, PUT to fully reconstruct.
- **WAF_RULES policies cannot be disabled once created.**
- **Test lifecycle for new/modified scripts:** Create a test policy → verify with GET → delete. Never test write operations on production policies. Always clean up test artifacts.
- **Review-before-edit:** Before improving a skill, always read all current files first to check if changes were already applied. Another agent or session may have made the same edits — avoid redundant or conflicting work.

## Changelog

- **2.1.0** (2026-06-16): Added add-ip-setting.sh, add-url-setting.sh, add-exception.sh, update-policy.sh. Fixed policy-examples.md (removed erroneous `data` wrapper from all curl bodies). Removed duplicated tables (policy-types.md is now the single source for settings/actions/exceptions). Added Setup section for execute permissions. Merged exception-types.md into policy-types.md. Added review-before-edit pitfall and test lifecycle pitfall.
- **2.0.0**: Initial version with scripts/ migration from templates/.

## Related Skills

- `imperva-cwaf-api-manual`: Full API specification reference in `api-spec/policies-api.yaml`
- `imperva-cwaf-custom-rule`: Manage custom rules (separate from policies)
- `imperva-cwaf-get-site-detail`: Get site IDs and current configuration
