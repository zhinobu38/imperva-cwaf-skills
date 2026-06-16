# Imperva CWAF SSL/TLS API Endpoint Reference

## Base URL Mapping

| Service | Base URL | Used By |
|---------|----------|---------|
| Certificate Management | `https://api.imperva.com/certificates-ui/v3/` | get-ssl-status, enable-ssl, get-certificate-details |
| Site Settings (TLS/HSTS) | `https://api.imperva.com/sites-mgmt/v3/` | get-tls-config, update-tls-config |
| Security (v1) | `https://my.imperva.com/api/prov/v1/` | basic-security skill |

**CRITICAL**: Do NOT mix base URLs. `/certificates/managed` endpoints only work under `certificates-ui`. Using `sites-mgmt` causes persistent WAF blocks (errorCode 15).

## Endpoint Details

### GET /sites/{siteId}/certificates/managed
- **Full URL**: `https://api.imperva.com/certificates-ui/v3/sites/{siteId}/certificates/managed?caid={caid}`
- **Purpose**: Get SSL certificate status for a site
- **Response**: SiteSSLCertificatesSettings wrapped in data[]

### POST /sites/{siteId}/certificates/managed
- **Full URL**: `https://api.imperva.com/certificates-ui/v3/sites/{siteId}/certificates/managed?caid={caid}`
- **Purpose**: Enable/disable SSL certificate (full update/overwrite)
- **Body**: SiteSSLCertificatesSettings object (NOT wrapped in data[])
- **Response**: SiteSSLCertificatesSettings wrapped in data[]
- **Note**: PUT returns 405. DELETE is deprecated.

### GET /certificates
- **Full URL**: `https://api.imperva.com/certificates-ui/v3/certificates?extSiteId={siteId}&caid={caid}`
- **Purpose**: Get detailed certificate info (SANs, validation status, etc.)
- **Method**: GET with query params (use --data-urlencode for params)
- **Response**: Certificate object wrapped in data[]

### GET /sites/{siteId}/settings/TLSConfiguration
- **Full URL**: `https://api.imperva.com/sites-mgmt/v3/sites/{siteId}/settings/TLSConfiguration?caid={caid}`
- **Purpose**: Get current TLS/HSTS configuration
- **Response**: SiteTLSConfiguration wrapped in data[]

### PATCH /sites/{siteId}/settings/TLSConfiguration
- **Full URL**: `https://api.imperva.com/sites-mgmt/v3/sites/{siteId}/settings/TLSConfiguration?caid={caid}`
- **Purpose**: Update TLS/HSTS settings (partial update)
- **Body**: SiteTLSConfigurationRequest (wrapped in data[])
- **Response**: CollectionSiteTLSConfiguration (data[] wrapper)
