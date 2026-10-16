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
| `IMPERVA_API_ID` | Bitwarden | Only via `bws run` |
| `IMPERVA_API_KEY` | Bitwarden | Only via `bws run` |
| `CAID` | User / memory | Pass as env var |
| `SITE_ID` | User / memory / get-site-detail | Pass as env var |
| `POLICY_ID` | From list/get/create response | Pass as env var |

**NEVER hardcode credentials or identifiers.**

## Best Practice

> Before managing any policies, review the best practice:
> `~/myai/second-brain/20-Cybersecurity/Imperva-CWAF/Best-Practice-Configuration.md`
> Key points: WAF signature categories → Block all, Alert for FP concern → monitor 1-2 weeks → Block

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
CAID=<caid> bws run -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-policy-management/scripts/list-policies.sh
```

Optional: `POLICY_TYPE=ACL` to filter by type.

### Get a Specific Policy

```bash
CAID=<caid> POLICY_ID=<id> bws run -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-policy-management/scripts/get-policy.sh
```

### Create a New Policy

```bash
CAID=<caid> POLICY_NAME="Block RU" POLICY_TYPE=ACL \
  bws run -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-policy-management/scripts/create-policy.sh
```

### Add GEO Setting to a Policy

```bash
CAID=<caid> POLICY_ID=<id> COUNTRIES='["RU","CN"]' ACTION=BLOCK \
  bws run -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-policy-management/scripts/add-geo-setting.sh
```

### Add IP Setting to a Policy

```bash
CAID=<caid> POLICY_ID=<id> IPS='["198.51.100.0/24","10.0.0.1"]' ACTION=BLOCK \
  bws run -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-policy-management/scripts/add-ip-setting.sh
```

### Add URL Setting to a Policy

```bash
CAID=<caid> POLICY_ID=<id> URLS='[{"pattern":"PREFIX","url":"/admin/"}]' ACTION=BLOCK \
  bws run -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-policy-management/scripts/add-url-setting.sh
```

### Add Exception to a Policy Setting

```bash
# First GET the policy to find the setting ID, then:
CAID=<caid> POLICY_ID=<id> SETTING_ID=<sid> \
  EXCEPTIONS='[{"exceptionType":"IP","values":["10.0.0.0/8"]}]' \
  bws run -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-policy-management/scripts/add-exception.sh
```

### Apply Policy to a Site

```bash
SITE_ID=<id> POLICY_ID=<id> bws run -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-policy-management/scripts/apply-policy.sh
```

### Remove Policy from a Site

```bash
SITE_ID=<id> POLICY_ID=<id> bws run -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-policy-management/scripts/remove-policy.sh
```

### Delete a Policy

```bash
CAID=<caid> POLICY_ID=<id> bws run -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-policy-management/scripts/delete-policy.sh
```

### List Policies Applied to a Site

```bash
SITE_ID=<id> bws run -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-policy-management/scripts/list-site-policies.sh
```

### Update a Policy

```bash
# Update name and/or description and/or enabled status
CAID=<caid> POLICY_ID=<id> POLICY_NAME="New Name" bws run -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-policy-management/scripts/update-policy.sh

CAID=<caid> POLICY_ID=<id> ENABLED=false bws run -- bash \
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
> bws run -- python3 \
>   ~/.hermes/skills/imperva-cwaf/imperva-cwaf-api-manual/scripts/integrations.py \
>   geo [--country CODE] [--continent CODE] [--limit N]
> ```

---

## Common Workflows

### Create ACL Policy with GEO Block and Apply to Site

```bash
# Step 1: Create policy
CAID=<caid> POLICY_NAME="Block RU" POLICY_TYPE=ACL \
  bws run -- bash scripts/create-policy.sh
# → Note the returned policy ID

# Step 2: Add GEO setting
CAID=<caid> POLICY_ID=<id> COUNTRIES='["RU"]' ACTION=BLOCK \
  bws run -- bash scripts/add-geo-setting.sh

# Step 3: Apply to site
SITE_ID=<id> POLICY_ID=<id> \
  bws run -- bash scripts/apply-policy.sh
```

### Copy Policy from One Site to Another

1. `list-site-policies.sh` on source site → get policy ID
2. `get-policy.sh` → get full policy JSON
3. `create-policy.sh` with new name
4. `add-geo-setting.sh` (or other settings) to replicate
5. `apply-policy.sh` on target site

### Delete Policies by Name Pattern (⚠️ DESTRUCTIVE — Always Confirm First)

**MANDATORY workflow — never skip the confirmation step.**

```bash
# Step 1: List all policies
CAID=<caid> bws run -- bash scripts/list-policies.sh
```

Step 2: **Filter by name pattern with correct position matching (case insensitive).** All matching is case insensitive — `train` matches `train`, `Train`, `TRAIN`, `Training`, etc. Use exact position logic:

| User says | Match condition | Example match | Example NOT match |
|-----------|----------------|---------------|-------------------|
| "ชื่อขึ้นต้นด้วย X" / "starts with X" | `name.toLowerCase().startsWith("x")` | `train4`, `Train3 ACL`, `Training16` | `my-train`, `retrain`, `WAF RULE Train 3` |
| "ชื่อลงท้ายด้วย X" / "ends with X" | `name.toLowerCase().endsWith("x")` | `policy-acl`, `test-ACL` | `acl-test`, `myacl2` |
| "ชื่อมี X" / "contains X" | `name.toLowerCase().contains("x")` | `my-train-policy`, `retrain`, `WAF RULE Train 3` | — |

> ⚠️ **CRITICAL**: "ขึ้นต้นด้วย train" means `name.toLowerCase().startsWith("train")` ONLY.
> `train4` ✅ `Train3` ✅ `Training16` ✅ — all match (case insensitive, position 0).
> `my-train` ❌ `retrain` ❌ `WAF RULE Train 3` ❌ — "train" is not at position 0.
> When in doubt, show the filtered list and ask the user to verify before proceeding.

Step 3: **Present the filtered list to the user for explicit approval BEFORE deleting.**

Format:
```
The following N policies match the criteria "starts with 'train'":

  ID        Name                     Type
  ────────  ───────────────────────  ──────────
  2104459   train14.xxx.com rule  WAF_RULES
  2104462   train15 WAF Policy        WAF_RULES
  ...

⚠️ This will DELETE N policies. This action cannot be undone.
Proceed? (yes/no)
```

Step 4: **Only after user confirms "yes", execute deletions one by one:**

```bash
CAID=<caid> POLICY_ID=<id> bws run -- bash scripts/delete-policy.sh
```

Step 5: **Report results** — show ✅ deleted and ❌ failed (with reason).

> **Note**: Some policies cannot be deleted (e.g., default mandatory policies). If deletion fails, report the error and continue with the remaining policies.

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
- **⚠️ ALWAYS confirm before deleting policies.** List the matched policies, show count, and get explicit user approval before executing ANY delete. Never batch-delete without confirmation.
- **⚠️ Name pattern matching — respect position, case insensitive.** "Starts with X" means the name begins with X at position 0, case insensitive. `train`, `Train`, `TRAIN`, `Training` all match "starts with train". But `my-train`, `retrain`, `WAF RULE Train 3` do NOT match — "train" is not at position 0. "Contains X" matches X anywhere in the name. When the user's intent is ambiguous, show the filtered list and ask before proceeding.

## Changelog

- **2.2.0** (2026-06-19): Added "Delete Policies by Name Pattern" workflow with mandatory confirmation step. Added pitfalls for delete confirmation and name pattern position matching (starts with vs contains).
- **2.1.0** (2026-06-16): Added add-ip-setting.sh, add-url-setting.sh, add-exception.sh, update-policy.sh. Fixed policy-examples.md (removed erroneous `data` wrapper from all curl bodies). Removed duplicated tables (policy-types.md is now the single source for settings/actions/exceptions). Added Setup section for execute permissions. Merged exception-types.md into policy-types.md. Added review-before-edit pitfall and test lifecycle pitfall.
- **2.0.0**: Initial version with scripts/ migration from templates/.

## Related Skills

- `imperva-cwaf-api-manual`: Full API specification reference in `api-spec/policies-api.yaml`
- `imperva-cwaf-custom-rule`: Manage custom rules (separate from policies)
- `imperva-cwaf-get-site-detail`: Get site IDs and current configuration
