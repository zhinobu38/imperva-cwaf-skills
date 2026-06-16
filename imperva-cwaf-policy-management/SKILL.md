---
name: imperva-cwaf-policy-management
description: Manage Imperva Cloud WAF policies — WAF rules, ACL, Whitelist, and exceptions. Create, modify, apply, and remove policies across sites.
category: imperva-cwaf
version: 2.0.0
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

## Credential & Identifier Policy (MANDATORY)

| Value | Source | Method |
|-------|--------|--------|
| `IMPERVA_API_ID` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `IMPERVA_API_KEY` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `CAID` | User / memory | Pass as env var |
| `SITE_ID` | User / memory / get-site-detail | Pass as env var |
| `POLICY_ID` | From list/get/create response | Pass as env var |

**NEVER hardcode credentials or identifiers.**

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

### Settings Actions

| Action | Description |
|--------|-------------|
| BLOCK | Block the request |
| ALLOW | Allow the request (skip checks) |
| ALERT | Log but don't block |
| BLOCK_USER | Block the user session |
| BLOCK_IP | Block the IP address |
| IGNORE | Skip this policy rule entirely |
| HIDDEN_ALERT | Log internally without alerting |
| MASK | Mask sensitive data |

### Exception Types

| Type | Values Format | Example |
|------|---------------|---------|
| GEO | Country/continent codes | TH, US, APAC |
| IP | IP addresses/CIDRs | 192.168.1.0/24 |
| URL | URL strings | /admin/login |
| URL_PREFIX | URL prefix string | /api/ |
| URL_SUFFIX | URL suffix string | .php |
| URL_CONTAINS | URL substring | login |
| USER_AGENT | User agent strings | GoogleBot |

---

## Pitfalls

- **No `data` wrapper in ANY Imperva API request body.** All Imperva Cloud WAF APIs use flat JSON — do NOT wrap in `{"data": {...}}` anywhere.
- **Always remove policy from site before deleting.** Unassign first, then delete.
- **Exception settings must reference the parent setting `id`.** GET the policy first to find the setting ID before adding exceptions.
- **Response `isError` is a boolean field**, not an HTTP status code. Check `isError` in the JSON body.
- **POST appends, PUT replaces.** Use POST to add settings, PUT to fully reconstruct.
- **WAF_RULES policies cannot be disabled once created.**

## Related Skills

- `imperva-cwaf-api-manual`: Full API specification reference in `api-spec/policies-api.yaml`
- `imperva-cwaf-custom-rule`: Manage custom rules (separate from policies)
- `imperva-cwaf-get-site-detail`: Get site IDs and current configuration
