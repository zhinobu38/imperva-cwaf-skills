# Imperva CWAF Sites Management API Response Structure

Based on actual API testing during session on 2026-05-30.

## List Sites Endpoint
`GET https://api.imperva.com/sites-mgmt/v3/sites`

### Response Format
```json
{
  "data": [
    {
      "id": 539880281,
      "name": "thegreat.impervamtth.com",
      "type": "CLOUD_WAF",
      "active": true,
      "accountId": <YOUR_CAID>,
      "creationTime": 1780120010463,
      "cname": "7maby9o.ng.impervadns.net",
      "siteStatus": "NOT_CONFIGURED"
    }
  ],
  "meta": {
    "totalElements": 3,
    "totalPages": 1,
    "size": 100,
    "page": 0
  },
  "links": {
    "self": "https://api.imperva.com/sites-mgmt/v3/sites?caid=<YOUR_CAID>&page=0&size=100"
  }
}
```

### Field Descriptions (Site Object in `data` array)
- `id`: Integer - Site ID
- `name`: String - Domain/FQDN (e.g., "example.com")
- `type`: String - Service type (e.g., "CLOUD_WAF")
- `active`: Boolean - Whether site is active (processing traffic)
- `accountId`: Integer - Account ID that owns the site
- `creationTime`: Integer - Timestamp in milliseconds since epoch
- `cname`: String - The CNAME record provided by Imperva for DNS configuration
- `siteStatus`: String (optional) - Detailed status (e.g., "NOT_CONFIGURED", "ACTIVE")

### Pagination Objects
- `meta`: Contains pagination information
  - `totalElements`: Total number of sites matching filters
  - `totalPages`: Total number of pages
  - `size`: Number of sites per page (max 100)
  - `page`: Current page number (0-based)
- `links`: Contains URL for current page
  - `self`: Link to current page

## Get Specific Site Endpoint
`GET https://api.imperva.com/sites-mgmt/v3/sites/{siteId}`

### Response Format (based on skill documentation)
```json
{
  "id": 12345678,
  "name": "example.com",
  "domain": "example.com",
  "status": "ACTIVE",
  "type": "CLOUD_WAF",
  "servers": ["1.2.3.4", "5.6.7.8"],
  "ssl": {
    "enabled": true,
    "certificate": "...",
    "expires": 1234567890000
  },
  "dnsValidation": {
    "recordType": "CNAME",
    "recordName": "verify.example.com",
    "recordValue": "abc123.verification.dns.imperva.com"
  },
  "createdAt": 1234567890000,
  "updatedAt": 1234567890001
}
```