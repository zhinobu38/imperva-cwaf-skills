---
name: imperva-cwaf-ssl-management
description: Manage SSL certificates and TLS/HSTS settings for Imperva Cloud WAF sites
category: imperva-cwaf
version: 1.0.0
---

# Imperva CWAF SSL Management

This skill provides functionality to manage SSL certificates and TLS/HSTS settings for websites in Imperva Cloud WAF using the appropriate APIs.

## API Endpoints

### SSL Certificate Management
#### Enable/Disable Site Certificate (Imperva-Managed)
```http
PUT https://api.imperva.com/sites-mgmt/v3/sites/{siteId}/certificates/managed?caid={caid}
```

#### Get Site Certificate Settings
```http
GET https://api.imperva.com/sites-mgmt/v3/sites/{siteId}/certificates/managed?caid={caid}
```

#### Upload Custom Certificate
```http
POST https://api.imperva.com/api/prov/v1/sites/customCertificate/upload
```

### TLS/HSTS Configuration
#### Get TLS/HSTS Settings
```http
GET https://api.imperva.com/sites-mgmt/v3/sites/{siteId}/settings/TLSConfiguration?caid={caid}
```

#### Update TLS/HSTS Settings (Partial)
```http
PATCH https://api.imperva.com/sites-mgmt/v3/sites/{siteId}/settings/TLSConfiguration?caid={caid}
```

#### Update TLS/HSTS Settings (Full)
```http
PUT https://api.imperva.com/sites-mgmt/v3/sites/{siteId}/settings/TLSConfiguration?caid={caid}
```

### Parameters

#### For SSL Certificate Management Endpoints (sites-mgmt)
- `siteId` (required): The Imperva ID of the site
- `caid` (required): The Imperva ID of the account or subaccount

#### For Custom Certificate Upload Endpoint (api/prov/v1)
- `site_id` (required): Numeric identifier of the site to operate on
- `certificate` (required): The certificate file in base64 format
- `private_key` (optional): The private key of the certificate in base64 format (required for PEM/CER, optional for PFX)
- `passphrase` (optional): The passphrase used to protect your SSL certificate/private key

### Request Body for SSL Certificate Management (PUT/PATCH)
```json
{
  "siteCertificateEnabled": true,
  "defaultValidationMethod": "CNAME"
}
```

### Request Body for Custom Certificate Upload (POST)
The custom certificate upload uses query parameters rather than a JSON request body:
- `site_id`: [site ID] (query parameter)
- `certificate`: [base64 encoded certificate] (query parameter)
- `private_key`: [base64 encoded private key] (query parameter, optional for PFX)
- `passphrase`: [passphrase] (query parameter, optional)

### Request Body for TLS/HSTS Configuration
```json
{
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
}
```

### Configuration Profile Options
- `DEFAULT`: Imperva's default TLS configuration
- `CUSTOM`: Custom TLS configuration (requires specifying TLS versions and ciphers)
- `ENHANCED_SECURITY`: Predefined enhanced security profile

### HSTS Configuration
- `isEnabled`: Boolean to enable/disable HSTS
- `maxAge`: Time in seconds browsers should remember HTTPS-only setting (default: 31536000 for 1 year)
- `subDomainsIncluded`: Boolean to apply HSTS to subdomains
- `preLoaded`: Boolean for preload list inclusion (requires domain submission to hstspreload.org)

## Workflow Steps

### 1. Enable SSL Certificate for a Site
1. Ensure you have the site ID (can be obtained from site listing or onboarding)
2. Verify your CAID and API credentials are set
3. Execute the SSL certificate enablement API call:
   ```bash
   curl -X PUT "https://api.imperva.com/sites-mgmt/v3/sites/{siteId}/certificates/managed?caid={caid}" \
     -H "Accept: application/json" \
     -H "x-API-Id: {API_ID}" \
     -H "x-API-Key: {API_KEY}" \
     -H "Content-Type: application/json" \
     -d '{"siteCertificateEnabled": true, "defaultValidationMethod": "CNAME"}'
   ```
4. Verify the certificate was provisioned by checking certificate details:
   ```bash
   curl -s -G "https://api.imperva.com/certificates-ui/v3/certificates" \
     --data-urlencode "extSiteId={siteId}" \
     --data-urlencode "caid={caid}" \
     -H "Accept: application/json" \
     -H "x-API-Id: {API_ID}" \
     -H "x-API-Key: {API_KEY}" | jq .
   ```

### 2. Configure HSTS and TLS Settings
1. First, check if SSL certificate is enabled for the site:
   ```bash
   curl -s -G "https://api.imperva.com/sites-mgmt/v3/sites/{siteId}/certificates/managed?caid={caid}"
     -H "Accept: application/json"
     -H "x-API-Id: {API_ID}"
     -H "x-API-Key: {API_KEY}"
   ```
   If the response indicates SSL is not enabled (siteCertificateEnabled: false or error), you need to enable SSL first before configuring HSTS/TLS.

2. Retrieve current TLS/HSTS settings to understand existing configuration (only if SSL is enabled):
   ```bash
   curl -s -G "https://api.imperva.com/sites-mgmt/v3/sites/{siteId}/settings/TLSConfiguration?caid={caid}"
     -H "Accept: application/json"
     -H "x-API-Id: {API_ID}"
     -H "x-API-Key: {API_KEY}" | jq .
   ```
3. Apply desired HSTS and TLS configuration using PATCH (partial update):
   ```bash
   curl -X PATCH "https://api.imperva.com/sites-mgmt/v3/sites/{siteId}/settings/TLSConfiguration?caid={caid}"
     -H "Accept: application/json"
     -H "x-API-Id: {API_ID}"
     -H "x-API-Key: {API_KEY}"
     -H "Content-Type: application/json"
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
     }' | jq .
   ```
4. Verify the changes were applied by retrieving the settings again.

### 3. Check Certificate Details
To view details of the SSL certificate issued for a site:
```bash
curl -s -G "https://api.imperva.com/certificates-ui/v3/certificates" \
  --data-urlencode "extSiteId={siteId}" \
  --data-urlencode "caid={caid}" \
  -H "Accept: application/json" \
  -H "x-API-Id: {API_ID}" \
  -H "x-API-Key: {API_KEY}" | jq .
```

## Response Formats

### SSL Certificate Enable Response
```json
{
  "data": [
    {
      "siteId": <EXAMPLE_SITE_ID>,
      "defaultValidationMethod": "CNAME",
      "siteCertificateEnabled": true,
      "certificateDetails": [
        {
          "id": 226642,
          "name": "ATLAS_114-1780117274422",
          "status": "ACTIVE",
          "type": "MANAGED",
          "expirationDate": 1787893284000,
          "inRenewal": false,
          "sans": [
            {
              "sanId": 2637328,
              "sanValue": "testagent.thtechs.com",
              "validationMethod": "CNAME",
              "expirationDate": 1793874150000,
              "status": "VALIDATED",
              "statusDate": 1780117349000,
              "numSitesCovered": 1,
              "verificationCode": "globalsign-domain-verification=B6F62F285CFC5FFEAB0F31DFAFE8A8ED",
              "cnameValidationValue": "_72a2bdf765ca58119968b12af58f14bbb162e4de.d2e54e385767ceecb47942897668bf0d.stcsgntmmnxcumzjskuiatzgmszweyrq.validation.imperva.com",
              "autoValidation": true,
              "approverFqdn": "thtechs.com",
              "validationEmail": null,
              "domainIds": [342193269],
              "sitesIds": [3337418]
            }
          ],
          "extSiteId": <EXAMPLE_SITE_ID>,
          "authType": "RSA",
          "level": "SITE",
          "siteId": 3337418
        }
      ]
    }
  ]
}
```

### TLS/HSTS Configuration Response
```json
{
  "data": [
    {
      "hstsConfiguration": {
        "preLoaded": false,
        "maxAge": 31536000,
        "subDomainsIncluded": false,
        "isEnabled": true
      },
      "inboundTlsSettings": {
        "configurationProfile": "ENHANCED_SECURITY"
      },
      "disablePQCSupport": false
    }
  ]
}
```

## Error Handling

- HTTP 400: Bad request (invalid parameters, missing or incorrect siteId/caid)
- HTTP 401: Unauthorized (invalid or missing credentials)
- HTTP 403: Forbidden (insufficient permissions or request blocked by security service)
- HTTP 404: Not found (siteId does not exist in the given account)
- HTTP 409: Conflict (certificate already exists or conflicting configuration)
- HTTP 500: Internal server error
- HTTP 504: Gateway timeout

## Shared References

These files are maintained at the `imperva-cwaf/` skill group level and are the
single source of truth for all sub-skills. Do NOT duplicate their content.

| Reference | Description |
|-----------|-------------|
| `../references/skill-dev-standard.md` | Dev standard: template structure, credential rules, known API behaviors, pitfalls |
| `../references/credential-and-identifier-policy.md` | Credential/identifier sourcing rules (Bitwarden bws run) |
| `../references/shell-template-pattern.md` | Shell template patterns (GET→modify→PUT, form-encoded POST, header format) |

## Required Environment Variables
- `IMPERVA_API_ID`: Your Imperva API ID
- `IMPERVA_API_KEY`: Your Imperva API key
- `IMPERVA_CAID`: Your Imperva account ID (can be passed as caid parameter)
## Notes

1. SSL certificate provisioning may take a few minutes to become active
2. When using CNAME validation, you must create the specified CNAME record in your DNS
3. The Enhanced Security profile provides a balanced set of secure cipher suites
4. HSTS should be tested with a short max-age initially before increasing to longer periods
5. Subdomain inclusion in HSTS requires all subdomains to support HTTPS
6. Certificate renewal is automatic for Imperva-managed certificates
7. The site may still show `siteStatus: NOT_CONFIGURED` in Sites Management API even after SSL is configured - this is normal as SSL management is handled separately
8. **Important**: Before configuring TLS/HSTS settings, always verify that SSL certificate is enabled for the site. If SSL is not enabled, the TLS/HSTS configuration will fail. In such cases, stop and ask the user whether to enable SSL certificate first or skip HSTS configuration for this site to avoid unnecessary errors.
