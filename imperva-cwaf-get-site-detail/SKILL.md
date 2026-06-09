---
name: imperva-cwaf-get-site-detail
description: Retrieve details of a specific site or list sites from Imperva Cloud WAF using the Sites Management API
category: imperva-cwaf
version: 2.2.0
---

# Imperva CWAF Get Site Detail

This skill provides functionality to retrieve the details of an existing site (configuration, status, etc.) or list sites from Imperva Cloud WAF using the Sites Management API.

## API Endpoint

### Get a specific site
```
GET https://api.imperva.com/sites-mgmt/v3/sites/{siteId}
```

### List sites (with filters and pagination)
```
GET https://api.imperva.com/sites-mgmt/v3/sites
```

## Shared References

These files are maintained at the `imperva-cwaf/` skill group level and are the
single source of truth for all sub-skills. Do NOT duplicate their content.

| Reference | Description |
|-----------|-------------|
| `../references/skill-dev-standard.md` | Dev standard: template structure, credential rules, known API behaviors, pitfalls |
| `../references/credential-and-identifier-policy.md` | Credential/identifier sourcing rules (Bitwarden bws run) |
| `../references/shell-template-pattern.md` | Shell template patterns (GET→modify→PUT, form-encoded POST, header format) |

## Parameters

### Path Parameters
- `siteId` (optional): The unique identifier of the site to retrieve. If provided, returns details for that specific site. If omitted, returns a list of sites based on query parameters.

### Query Parameters
- `caid` (required): The Imperva ID of the account or subaccount that owns the site(s).
- `siteIds` (optional): [integer array] Filter by specific site IDs.
- `names` (optional): [string array] Filter by site names (FQDN) - exact match.
- `size` (optional): Number of sites per page (default: 100, maximum: 100).
- `page` (optional): Page number for pagination (default: 0).

### Headers
- `Accept: application/json`
- `x-API-Id`: Your Imperva API ID (from Bitwarden — see below)
- `x-API-Key`: Your Imperva API key (from Bitwarden — see below)

## Credential Retrieval (MANDATORY)

**ALWAYS retrieve API credentials from Bitwarden (bws).** Never use local env vars or hardcoded values.

See `../references/credential-and-identifier-policy.md` for full details.

Quick pattern:
```bash
bws run --project-id <BW_PROJECT_ID_READ> -- python3 /tmp/script.py
```

## Pre-run Checklist
Before executing the request, please verify the following parameters:
- **CAID**: Ensure you are targeting the correct Imperva account/subaccount.
- **Site ID** (if getting specific site): Obtain the correct site ID from your inventory or via the site list API.
- **Credentials**: Will be injected by `bws run` — do NOT set local env vars.

## Example Usage

All examples below use the `bws run` pattern. Write the script to a file first, then execute:

```bash
bws run --project-id <BW_PROJECT_ID_READ> -- python3 /tmp/list_sites.py
```

## Response

### Get a specific site (HTTP 200)
On success, the response includes a JSON object with:
- `data`: Array containing the site object (see site object structure below)

### List sites (HTTP 200)
On success, based on actual API testing, the response includes a JSON object with:
- `data`: Array of site objects (each with the fields below)
- `meta`: Object containing pagination info:
  - `totalElements`: Total number of sites matching the filters
  - `totalPages`: Total number of pages
  - `size`: Number of sites per page
  - `page`: Current page number (0-based)
- `links`: Object containing pagination links (e.g., `self`)

Each site object in `data` contains:
- `id`: Site ID
- `name`: The domain/FQDN (e.g., "example.com")
- `type`: Service type (e.g., `CLOUD_WAF`)
- `active`: Boolean indicating if site is active
- `accountId`: The account ID
- `creationTime`: Timestamp in milliseconds since epoch
- `cname`: The CNAME record for Imperva
- `siteStatus`: Optional status (e.g., `NOT_CONFIGURED`, `ACTIVE`)
- `ssl`: SSL configuration details (when site is configured and active)
- `dnsValidation`: DNS validation records (if applicable)
- `updatedAt`: Timestamps

### SSL Configuration Note
When a site's `siteStatus` is `NOT_CONFIGURED`, the SSL configuration details may not be present in the response. Ensure the site is fully configured and active before expecting SSL fields such as certificate details, TLS version, or HTTPS enforcement settings.

### List sites (HTTP 200)
On success, based on actual API testing, the response includes a JSON object with:
- `data`: Array of site objects (each with the fields below)
- `meta`: Object containing pagination info:
  - `totalElements`: Total number of sites matching the filters
  - `totalPages`: Total number of pages
  - `size`: Number of sites per page
  - `page`: Current page number (0-based)
- `links`: Object containing pagination links (e.g., `self`)

Each site object in `data` contains:
- `id`: Site ID
- `name`: The domain/FQDN (e.g., "example.com")
- `type`: Service type (e.g., `CLOUD_WAF`)
- `active`: Boolean indicating if site is active
- `accountId`: The account ID
- `creationTime`: Timestamp in milliseconds since epoch
- `cname`: The CNAME record for Imperva
- `siteStatus`: Optional status (e.g., `NOT_CONFIGURED`, `ACTIVE`)

## Error Handling
- HTTP 403: Request blocked by Imperva security service (check status.imperva.com)
- HTTP 400: Bad request (invalid parameters, missing or incorrect siteId/caid)
- HTTP 401: Unauthorized (invalid or missing credentials)
- HTTP 404: Not found (siteId does not exist in the given account - only when getting specific site)
- HTTP 500: Internal server error

## Troubleshooting
- **Site not found (404)**: Double-check the `siteId` and `caid`. Ensure the site exists in the specified account (only when getting specific site).
- **Unauthorized (401)**: Verify that `IMPERVA_API_ID` and `IMPERVA_API_KEY` are correctly set and have permission to read site details.
- **Rate limiting**: If you receive HTTP 429, implement exponential backoff and retry.
- **Empty list**: If listing sites returns empty array, verify filters and CAID.

## Notes
- **Credentials**: ALWAYS retrieve from Bitwarden via `bws run --project-id <BW_PROJECT_ID_READ>`. Never hardcode or reference local env vars.
- The site ID is immutable and can be obtained from the site onboarding response or via the site list endpoint.
- When listing sites, the maximum `size` is 100 as per API limitation.
- Always verify the CAID (account ID) you are targeting; providing an incorrect CAID may result in accessing the wrong account's data.
- Based on actual API response, the list endpoint uses `data` array (not `content`) and `meta` object for pagination.
- For the actual JSON structure returned by the API, see `references/sample-response.md`.
- For guidance on checking SSL configuration, see `references/ssl-configuration-check.md`.
- This skill is part of the imperva-cwaf skill set for Imperva Cloud WAF API interactions.

## Output Template\nFor listing sites, you can use the following format to display results in a readable table:\n\n```\nID          Domain/FQDN               Type       Status          Active  Created           CNAME\n539880281   thegreat.impervamtth.com  CLOUD_WAF  NOT_CONFIGURED  Yes     2026-05-30 05:46  7maby9o.ng.impervadns.net\n847611422   agent2.impervamtth.com    CLOUD_WAF  ACTIVE          Yes     2026-05-30 05:57  mkgctpk.ng.impervadns.net\n<EXAMPLE_SITE_ID>   testagent.thtechs.com     CLOUD_WAF  NOT_CONFIGURED  Yes     2026-05-30 05:01  gm4fq8z.ng.impervadns.net\n```\n\nYou can generate this output using tools like `jq` and `column` as shown in the examples, or by implementing similar formatting in your automation scripts.