---
name: imperva-cwaf-custom-rule
description: Create, manage, and test Imperva Cloud WAF custom rules using the API.
category: imperva-cwaf
version: 1.2.0
---

# Imperva CWAF Custom Rule Skill

This skill provides functionality to create, update, delete, and test custom rules in Imperva Cloud WAF via the API. It leverages the rule filter parameters documented in the `imperva-cwaf-api-manual` skill.

## Prerequisites

- You must have API credentials (ID and Key) for Imperva Cloud WAF.
- You must know the Site ID (or Account ID) for the site you want to manage.
- The `imperva-cwaf-api-manual` skill should be available for reference on rule filter parameters.

## Credential Retrieval (MANDATORY)

**ALWAYS retrieve API credentials from Bitwarden (bws).** Never use local env vars or hardcoded values.

**CRITICAL**: Use project `hermes-aws` (ID: `<BW_PROJECT_ID_WRITE>`), NOT the `hermes` project. The `hermes` project has different credentials that may authenticate but lack write permissions, causing 9415 errors.

See `references/credential-retrieval.md` for full details.

Quick pattern:
```bash
# Write script without credentials, then run via bws run
bws run --project-id <BW_PROJECT_ID_WRITE> -- python3 /tmp/script.py
```

For simple curl calls, use a shell script (env vars expand naturally):
```bash
bws run --project-id <BW_PROJECT_ID_WRITE> -- bash /tmp/script.sh
```

## Rule Filter Parameters Reference

The rule filter parameters are documented in the `imperva-cwaf-api-manual` skill. For a quick reference, see the rule filter summary:

```bash
skill_view imperva-cwaf-custom-rule file_path=references/rule-filter-summary.md
```

For the complete list, you can view:

```bash
skill_view imperva-cwaf-api-manual file_path=references/rule-filter-parameters.md
```

Or directly read the file:

```bash
read_file ~/.hermes/skills/imperva-cwaf/imperva-cwaf-api-manual/references/rule-filter-parameters.md
```

Additionally, the complete rule filter parameters are available as a JSON file in the api-spec directory of the imperva-cwaf-api-manual skill:

```bash
read_file ~/.hermes/skills/imperva-cwaf/imperva-cwaf-api-manual/api-spec/imperva_rule_filters.json
```

## API Endpoints for Custom Rules

The custom rules are managed via the Rules API. For listing rules, use the Rules API (v3) endpoint:

```
https://my.imperva.com/api/prov/v3/rules?caid={caid}&siteIds={siteIds}
```

Where `{caid}` is the Account ID and `{siteIds}` is the Site ID (or comma-separated list of Site IDs).

For other operations (getting, creating, updating, deleting specific rules), use the Rules API (v2) endpoint:

```
https://my.imperva.com/api/prov/v2/sites/{siteId}/rules
```

Where `{siteId}` is the numeric ID of the site.

### Common Operations

1. **List all custom rules** (GET)
2. **Get a specific custom rule** (GET by ruleId)
3. **Create a new custom rule** (POST)
4. **Update an existing custom rule** (PUT)
5. **Delete a custom rule** (DELETE)

### Request Headers

- `Accept: application/json`
- `x-API-Id: <your-api-id>`
- `x-API-Key: <your-api-key>`
- `Content-Type: application/json` (for POST/PUT)

### Example: Get Current Rules

```bash
bws run --project-id <BW_PROJECT_ID_WRITE> -- python3 /tmp/list_rules.py
```

### Example: Create a Custom Rule

**Important:** The POST body uses a flat object (no `data` wrapper), and ClientType filter values must use PascalCase.

```bash
# Write rule JSON to a file
cat > /tmp/rule.json << 'EOF'
{
  "name": "Block SQL Injection Attempts",
  "action": "RULE_ACTION_BLOCK",
  "enabled": true,
  "filter": "URL contains \"/login\" & ParamValue == {\"username\";\"' OR '1'='1\"}
}
EOF

# Execute via bws run (credentials injected automatically)
bws run --project-id <BW_PROJECT_ID_READ> -- python3 /tmp/create_rule.py
```

### JavaScript Challenge Action

Use `RULE_ACTION_INTRUSIVE_HTML` for JavaScript-based challenges (not `RULE_ACTION_CHALLENGE_JS` which does not exist in the API). This action requires clients to support JavaScript to complete the request.

```bash
cat > /tmp/rule.json << 'EOF'
{
  "name": "ChallengeNonBrowserBots",
  "action": "RULE_ACTION_INTRUSIVE_HTML",
  "enabled": true,
  "filter": "ClientType != Browser;SearchBot;SiteHelper"
}
EOF
bws run --project-id <BW_PROJECT_ID_READ> -- python3 /tmp/create_rule.py
```

### Example: Update a Custom Rule

**Important:** The PUT body uses a flat JSON object (no `data` wrapper).

```bash
bws run --project-id <BW_PROJECT_ID_READ> -- python3 /tmp/update_rule.py
```

### Example: Delete a Custom Rule

```bash
bws run --project-id <BW_PROJECT_ID_READ> -- python3 /tmp/delete_rule.py
```

## Testing Rule Filters

Before deploying a rule, you can test the filter against sample requests. While there isn't a direct API for testing, you can:

1. Use the Imperva WAF portal's "Test Rule" feature.
2. Or, if you have access to the logs, verify that the rule matches the intended traffic.

## Error Handling

Common HTTP status codes:
- 200: Success
- 201: Created (for POST)
- 400: Bad Request (invalid filter syntax, missing fields)
- 401: Unauthorized (invalid API credentials — check Bitwarden service account)
- 403: Forbidden (insufficient permissions)
- 404: Not Found (site or rule not found)
- 429: Too Many Requests (rate limited)
- 500: Internal Server Error

### Error 9415 "Operation not allowed"

This error means the API key **authenticated but the operation was rejected**. Common causes (check in order):
1. **Wrong Bitwarden project**: Using `hermes` project credentials instead of `hermes-aws`. The hermes project creds authenticate but lack write permissions.
2. **API key lacks write permission**: The service account needs "Rules: Write" in Imperva portal.
3. This is NOT caused by site NOT_CONFIGURED status — confirmed: correct credentials work on NOT_CONFIGURED sites.
4. This is NOT an API format error — the request structure was validated correct.

## Pitfalls

- **Body structure for POST/PUT**: All Imperva APIs use flat JSON (no `data` wrapper) — Policies, Custom Rules, Cache, everything. Never wrap request bodies in `{"data": {...}}`.
- **ClientType enum values**: Must use exact PascalCase: Browser, SearchBot, SiteHelper, Unknown, AIBot, ClickBot, SpamBot, Crawler, etc. Lowercase values will return "Invalid value" error.
- **JavaScript challenge action**: Use `RULE_ACTION_INTRUSIVE_HTML` (not `RULE_ACTION_CHALLENGE_JS` which does not exist in the API enum).
- **Multi-value matching with semicolon**: Use semicolon-separated values instead of multiple `|` OR conditions:
  - Instead of: `ClientType != Browser & ClientType != SearchBot & ClientType != SiteHelper`
  - Use: `ClientType != Browser;SearchBot;SiteHelper;FeedFetcher`
  - This applies to all filter parameters that support multi-value: `URL`, `CountryCode`, `ClientType`, `ParamName`, `HeaderValue`, `CookieValue`, etc.
- **Wrong Bitwarden project**: Using project `hermes` instead of `hermes-aws` gives credentials that authenticate (no 401) but cause 9415 "Operation not allowed" on write operations. Always verify you're using `hermes-aws`.
- **Inline Python fails**: `bws run -- python3 -c "..."` fails for complex Python due to shell escaping. Always write a script file first.

## Automation Tips

- **Credentials**: Always use `bws run --project-id <BW_PROJECT_ID_WRITE>` to inject credentials. Never reference `$IMPERVA_API_ID` or `$IMPERVA_API_KEY` directly in scripts.
- **Project name**: `hermes-aws` (NOT `hermes`). Using the wrong project gives creds that authenticate but cause 9415 on write operations.
- **Script pattern**: Write Python scripts to `/tmp/` with no credentials in the file, then execute via `bws run`.
- **Curl pattern**: For simple API calls, write a shell script with curl referencing `$IMPERVA_API_ID`/`$IMPERVA_API_KEY` env vars naturally — they expand from bws run context.
- **DO NOT** use `bws run -- python3 -c "..."` with inline Python — shell escaping fails. Write a file instead.
- Always test rule filters in a staging environment before applying to production.

## Related Skills

- `imperva-cwaf-api-manual`: For browsing API specifications and rule filter parameters.
- `imperva-cwaf-policy-management`: For managing account-level policies (ACL, WHITELIST, WAF_RULES) and their exceptions. Use this for policy-based management; use this skill (`imperva-cwaf-custom-rule`) for site-specific custom rules.
- `imperva-cwaf-get-site-detail`: To retrieve site information (including siteId).
- `imperva-cwaf-status-check`: To check the operational status of Imperva services.

## Notes

- The rule filter syntax is shared between WAF custom rules (`imperva-cwaf-custom-rule`) and cache rules (`imperva-cwaf-cache`). The same semicolon multi-value syntax, operators, and parameter names apply to both.
- **Action enum values**: `RULE_ACTION_INTRUSIVE_HTML` is the JavaScript challenge action (not `RULE_ACTION_CHALLENGE_JS`). Valid actions: `RULE_ACTION_BLOCK`, `RULE_ACTION_CAPTCHA`, `RULE_ACTION_INTRUSIVE_HTML`, etc.
- **JSON body structure**: API v2 `/sites/{siteId}/rules` expects the rule object directly in the body (no `data` wrapper).
- **Case sensitivity**: Filter values are case-sensitive. ClientType values: `Browser`, `SearchBot`, `SiteHelper`, `AIBot`, `ClickBot`, `Crawler`, `SpamBot`, etc. (PascalCase, not lowercase).
- **ClientType filter values are Case-Sensitive: use PascalCase** (Browser, SearchBot, SiteHelper, Unknown, AIBot, ClickBot, SpamBot, etc.). Lowercase will fail with "Invalid value" error.
- String values in filters are case-insensitive unless otherwise noted.
- The v2 rules endpoint accepts `caid` as a query parameter. Include it for consistency with other Imperva API calls.
- For complex filters, consider using a heredoc or a JSON file to avoid escaping issues in the command line.
- **Cleanup**: Delete temporary script files from `/tmp/` after use.
- See `templates/create-rule.sh` for a reusable curl-based rule creation script.
- See `references/credential-retrieval.md` for full credential retrieval details and debugging.

## Example: Creating a Rule via Shell Script

```bash
export SITE_ID=<EXAMPLE_SITE_ID>
export CAID=<YOUR_CAID>
export RULE_NAME="CaptchaNonThailandLogin"
export RULE_ACTION="RULE_ACTION_CAPTCHA"
export RULE_FILTER='URL contains "/login" & CountryCode != TH'

bws run --project-id <BW_PROJECT_ID_WRITE> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-custom-rule/templates/create-rule.sh
```

---