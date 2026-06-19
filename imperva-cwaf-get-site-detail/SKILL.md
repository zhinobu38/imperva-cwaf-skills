---
name: imperva-cwaf-get-site-detail
description: List, search, and delete Imperva Cloud WAF sites using the Sites Management API
category: imperva-cwaf
version: 3.3.0
---

# Imperva CWAF Get Site Detail

List all sites or search by keyword from Imperva Cloud WAF.

## Shared References

| Reference | Description |
|-----------|-------------|
| `../references/skill-dev-standard.md` | Dev standard |
| `../references/credential-and-identifier-policy.md` | Credential rules |
| `../references/shell-template-pattern.md` | Shell template patterns |

## Credential & Identifier Policy (MANDATORY)

| Value | Source | Method |
|-------|--------|--------|
| `IMPERVA_API_ID` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `IMPERVA_API_KEY` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `CAID` | User / memory | Pass as env var |

**NEVER hardcode credentials or identifiers.**

## ⚡ MANDATORY: Use the Script

**ALWAYS use the provided script. Do NOT write inline curl.**

### List All Sites

```bash
# Table output (default — human readable)
CAID=<caid> bws run --uuids-as-keynames --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-get-site-detail/scripts/list-sites.sh

# JSON output (for scripting / jq / grep)
OUTPUT_FORMAT=json CAID=<caid> bws run --uuids-as-keynames --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-get-site-detail/scripts/list-sites.sh
```

Optional env vars: `CAID`, `SIZE=100`, `PAGE=0` (SIZE must be one of: 10, 25, 50, 100), `OUTPUT_FORMAT=json|table` (default: table), `SEARCH=<keyword>` (case-insensitive filter on site name/domain).
Positional args also accepted as fallback: `bws run ... -- bash script.sh <caid> <size> <page>`.

### Delete Sites (Single or Batch)

**🔴 2-Step Confirmation is MANDATORY before deleting any site. Never skip this.**

**Step 1 — Show & Confirm the target sites:**
List the sites that match the deletion criteria. Display them in a table.
Ask the user to confirm: "Do you want to delete all these sites? (yes/no)"

**Step 2 — Final confirmation:**
If Step 1 is confirmed, ask again: "Are you sure? This action cannot be undone. (yes/no)"
Only proceed to delete if the user confirms **both** steps.

If the user says no at any step, abort immediately.

```bash
# Delete a site by ID (after 2-step confirmation)
CAID=<caid> bws run --uuids-as-keynames --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-get-site-detail/scripts/delete-site.sh <site_id>

# Delete multiple sites (loop, after 2-step confirmation)
for id in <id1> <id2> <id3>; do
  CAID=<caid> bws run --uuids-as-keynames --project-id <bw_id> -- bash \
    ~/.hermes/skills/imperva-cwaf/imperva-cwaf-get-site-detail/scripts/delete-site.sh $id
done
```

**Guidelines:**
- Always list the sites first and show them to the user
- MUST complete both confirmation steps before running any delete command
- NEVER delete based on keyword/search alone without explicit per-site confirmation
- When deleting by keyword (e.g. "train*"), list ALL matching sites and confirm the full list first
- Single site deletion also requires 2-step confirmation

### Search Sites by Keyword

```bash
# Find sites matching "train" (case-insensitive)
SEARCH=train CAID=<caid> bws run --uuids-as-keynames --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-get-site-detail/scripts/list-sites.sh

# Combine with JSON output for scripting
SEARCH=train OUTPUT_FORMAT=json CAID=<caid> bws run --uuids-as-keynames --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-get-site-detail/scripts/list-sites.sh
```

### Get Single Site Detail (by Site ID)

```bash
# Get site detail — returns siteId, name, domain, cname, siteStatus, active
CAID=<caid> SITE_ID=<site_id> bws run --uuids-as-keynames --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-get-site-detail/scripts/get-site-detail.sh
```

Use this to check if a site already exists (before onboarding) or to get the CNAME after onboarding.

---

## Response Format

List response includes `data` array with site objects:
- `id`, `name`, `type`, `active`, `siteStatus`, `cname`, `creationTime`

Each site object contains:
- `id`: Site ID (immutable)
- `name`: Domain/FQDN
- `type`: Service type (e.g., `CLOUD_WAF`)
- `active`: Boolean
- `siteStatus`: `NOT_CONFIGURED`, `ACTIVE`, etc.
- `cname`: CNAME record for Imperva

## Error Handling

| Code | Meaning |
|------|---------|
| 400 | Bad request (invalid parameters) |
| 401 | Unauthorized |
| 404 | Site not found |
| 429 | Rate limited |
| 15 (HTTP 403) | WAF intermittent block — IP-based, NOT auth failure. Retry with exponential backoff. |

## Pitfalls
- **Dev Standard — No raw credentials anywhere**: NEVER write inline curl with hardcoded API IDs/keys. NEVER put credentials in script files, terminal commands, or environment variable exports typed directly into the chat. ALWAYS use `bws run --uuids-as-keynames --project-id <id> -- bash script.sh` so credentials are injected at runtime from Bitwarden. Scripts MUST read `IMPERVA_API_ID` and `IMPERVA_API_KEY` from environment variables only.
- **WAF intermittent block (errorCode 15, HTTP 403)**: Imperva's WAF may intermittently block API requests from certain IPs (especially cloud/AWS IPs). Response: `{"errorCode":"15","description":"This request was blocked by our security service"}`. This is NOT a rate limit (rate limit returns HTTP 429) and NOT an auth failure (auth failure returns HTTP 401). It is an IP-based WAF block that typically resolves within seconds to minutes. **Retry with exponential backoff** (5s, 15s, 30s, 60s) until the request succeeds. Do NOT assume credentials are wrong when seeing errorCode 15.
- **Delete is irreversible**: `DELETE /sites-mgmt/v3/sites/{id}` permanently removes the site. Always run `DRY_RUN=true` first, show the user what will be deleted, and get explicit confirmation before executing the real delete. The delete API returns HTTP 200 on success (not 204).
- **Duplicate secret names in Bitwarden**: If `bws run` fails with "Multiple secrets with name: 'IMPERVA_API_ID'", use `--uuids-as-keynames` flag to disambiguate.
- **SEARCH filter is client-side**: The `SEARCH` env var filters results after the API returns them. For accounts with many sites, this may miss matches on unlisted pages. Use `SIZE=100` and paginate if needed.
- **`bws run` quoting and jq @tsv**: When `bws run -- bash script.sh` is used, the command string is passed through an extra shell layer. This can break:
  - `$'\t'` ANSI-C quoting in `column -t -s $'\t'` — use `column -t -s "\t"` instead
  - Complex jq expressions with nested quotes — keep jq filter in single quotes, pipe to `column` outside
  - Test both table and JSON output formats after any script change.
- **Dual API endpoints**: Imperva provides two working API paths for listing sites:
  - **v3 (preferred)**: `GET https://api.imperva.com/sites-mgmt/v3/sites?caid=<id>&size=100&page=0` — returns `{data:[...], meta:{totalPages, totalElements}}`
  - **v1 (legacy)**: `POST https://my.imperva.com/api/prov/v1/sites/list?page_size=100&page_num=0` — returns `{sites:[...], res:0}`
  - Both require `x-API-Id` and `x-API-Key` headers. The v3 endpoint is preferred for new work.
- When `siteStatus` is `NOT_CONFIGURED`, SSL fields may not be present
- Max `size` is 100 per page
- Site ID is immutable — use it for all subsequent operations

## Style Note
- Be concise and direct. Don't over-explain or narrate tool calls. Get to the result.
- Only act on explicit user requests. Don't make changes or notify about changes the user didn't ask for.

## Related Skills
- `imperva-cwaf-site-onboard`: Onboard a new site
- `imperva-cwaf-ssl-management`: Configure SSL/TLS
- `imperva-cwaf-policy-management`: Apply policies
- `imperva-cwaf-troubleshoot`: Diagnose performance and availability issues (latency, errors, origin response time)
