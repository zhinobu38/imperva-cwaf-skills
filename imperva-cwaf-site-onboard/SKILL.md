---
name: imperva-cwaf-site-onboard
description: Onboard a new website to Imperva Cloud WAF using the API
category: imperva-cwaf
version: 1.0.0
---

# Imperva CWAF Site Onboarding

This skill provides functionality to onboard a new website to Imperva Cloud WAF using the Sites Management API.

## API Endpoint
```
POST https://api.imperva.com/sites-mgmt/v3/sites/onboard
```

## Parameters

### Query Parameters
- `caid` (required): The Imperva ID of the account or subaccount

### Request Body (JSON)
- `domain` (required): The fully qualified domain name to onboard
- `servers` (required): Array of origin server IP addresses
- `name` (required): A friendly name for the site (usually same as domain)
- `generateCertificate` (optional): Whether to generate a certificate for the site (default: true)
- `type` (optional): The type of service, e.g., "CLOUD_WAF" (default: "CLOUD_WAF")

### Headers
- `Accept: application/json`
- `Content-Type: application/json`
- `x-API-Id`: Your Imperva API ID (environment variable `IMPERVA_API_ID`)
- `x-API-Key`: Your Imperva API key (environment variable `IMPERVA_API_KEY`)

## Pre-run Checklist
Before executing the onboarding, please verify the following parameters:
- **CAID**: Ensure you are targeting the correct Imperva account/subaccount.
- **Domain**: The fully qualified domain name (e.g., `testagent.thtechs.com`) must be correct and owned by you.
- **Servers**: The origin server IP address(es) must be accurate and reachable.
- **Name**: A friendly identifier for the site (typically same as domain).
- **GenerateCertificate**: Set to `true` if you want Imperva to provision a certificate; otherwise provide an existing `certificateId`.
- **Type**: Usually `CLOUD_WAF` unless you are using a different service.

Confirm all values are correct before proceeding to avoid misconfiguration.

## Example Usage

This skill provides reference information for Imperva CWAF site onboarding. To use this information:

### Via Command Line (cURL)
```bash
curl --request POST \\
  --url 'https://api.imperva.com/sites-mgmt/v3/sites/onboard?caid=<YOUR_CAID>' \\
  --header 'Accept: application/json' \\
  --header 'Content-Type: application/json' \\
  --header "x-API-Id: $IMPERVA_API_ID" \\
  --header "x-API-Key: $IMPERVA_API_KEY" \\
  --data '{
    "domain": "thegreat.impervamtth.com",
    "name": "thegreat.impervamtth.com",
    "servers": ["119.110.254.25"],
    "generateCertificate": true,
    "type": "CLOUD_WAF"
  }'
```

### Via Hermes Agent (Reference Implementation)
When building automation in Hermes Agent, reference this skill for:
1. API endpoint and parameters
2. Required headers and credentials
3. Error handling and troubleshooting
4. Pre-run checklist items

You can then implement the API call using:
- `terminal` tool with curl commands
- `execute_code` tool with Python requests
- Or other HTTP client methods available in your automation
## Response
On success (HTTP 200), the response includes:
- Site configuration details
- DNS validation instructions (SSL section)
- Network configuration instructions

## Error Handling
- HTTP 403: Request blocked by Imperva security service (check status.imperva.com)
- HTTP 400: Bad request (invalid parameters)
- HTTP 401: Unauthorized (invalid credentials)
- HTTP 404: Not found
- HTTP 500: Internal server error

## Troubleshooting
- **Name already exists for account**: If you receive error `{"status":400,"detail":"Name already exists for account","field":"name"}`, it means the site name you specified already exists in the target Imperva account (CAID). To resolve:
  1. Use a different site name (e.g., add a prefix/suffix or use a subdomain)
  2. Or check existing sites in your account to manage the existing site instead of creating a new one
  3. Verify you're targeting the correct CAID (account ID) - an incorrect CAID may cause unexpected conflicts

## Notes
- Requires IMPERVA_API_ID and IMPERVA_API_KEY environment variables
- May require IP whitelisting in your Imperva account
- The onboarding process provides SSL and network configuration instructions that must be followed to complete setup
- Part of the imperva-cwaf skill set for Imperva Cloud WAF API interactions
- Always verify the CAID (account ID) you are targeting; providing an incorrect CAID may onboard the site to the wrong account.
- See `references/credential-access.md` for techniques to securely access Imperva API credentials in Hermes environment.