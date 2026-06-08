# Policy Types Reference

Detailed information about each Imperva CWAF policy type.

## ACL (Access Control List)

Controls access based on IP addresses, geographic locations, or URLs.

**Use cases:**
- Block traffic from specific countries or continents
- Block known malicious IP addresses/ranges
- Allow only specific IP addresses (whitelist approach)
- Control access to specific URL paths

**Settings types:**
- IP: Block/allow specific IP addresses or CIDR ranges
- GEO: Block/allow by country or continent code
- URL: Block/allow by URL pattern

**Actions:** BLOCK, ALLOW, ALERT

**Important:** An ACL policy is applied alongside other ACL policies. Multiple ACL policies can be active on a single site.

---

## WHITELIST

Creates exceptions to skip security checks for specific sources.

**Use cases:**
- Allow penetration testing IPs without disabling WAF
- Whitelist monitoring/health check endpoints
- Exclude trusted API consumers from rate limiting

**Settings types:** Same as ACL (IP, GEO, URL)

**Actions:** ALLOW, IGNORE

**Important:** Whitelist policies are additive. Multiple whitelist policies can be applied to a single site.

---

## WAF_RULES

Defines web application firewall rule behavior including attack detection and response overrides.

**Use cases:**
- Override default WAF behavior for specific attack types
- Set SQL Injection to "Alert Only" instead of "Block"
- Configure Cross-Site Scripting detection sensitivity
- Override response codes for blocked requests

**Settings types (WAF attack classifications):**
- SQL_INJECTION
- CROSS_SITE_SCRIPTING (XSS)
- ILLEGAL_RESOURCE_ACCESS
- REMOTE_FILE_INCLUSION (RFI)
- RESP_DATA_LEAK (Response Data Leak)
- MALICIOUS_FILE_UPLOAD

**Actions:** BLOCK, ALERT, BLOCK_USER, BLOCK_IP, IGNORE, MASK

**Important:**
- Only ONE WAF Rules policy can be applied to a site at a time.
- Each account has a default WAF Rules policy.
- WAF Rules policies cannot be disabled.
- To change WAF rules on a site, apply a different WAF Rules policy.

---

## FILE_UPLOAD

Controls file upload behavior and scanning.

**Use cases:**
- Restrict file types that can be uploaded
- Configure malware scanning for uploads
- Set file size limits

**Settings types:**
- MALICIOUS_FILE_UPLOAD: Action to take on malicious files

**Actions:** BLOCK, ALERT, ALLOW

---

## Policy Type Comparison

| Feature | ACL | WHITELIST | WAF_RULES | FILE_UPLOAD |
|---------|-----|-----------|-----------|-------------|
| Multiple per site | Yes | Yes | No (one only) | Yes |
| Can disable | Yes | Yes | No | Yes |
| IP-based rules | Yes | Yes | No | No |
| Geo-based rules | Yes | Yes | No | No |
| URL-based rules | Yes | Yes | No | No |
| Attack type rules | No | No | Yes | Yes |
| File type rules | No | No | No | Yes |

---

## URL Pattern Types

When creating URL-based settings or exceptions, the pattern field supports:

| Pattern | Description | Example |
|---------|-------------|---------|
| EQUALS | Exact URL match | `/login` |
| NOT_EQUALS | URL is not this value | `/admin` |
| CONTAINS | URL contains substring | `api` |
| NOT_CONTAINS | URL does not contain substring | `debug` |
| PREFIX | URL starts with | `/api/v1/` |
| NOT_PREFIX | URL does not start with | `/admin` |
| SUFFIX | URL ends with | `.php` |
| NOT_SUFFIX | URL does not end with | `.html` |

---

## Country and Continent Codes

Common GEO policy values:

**Country codes (ISO 3166-1 alpha-2):**
TH (Thailand), US (United States), CN (China), RU (Russia), GB (United Kingdom), JP (Japan), KR (South Korea), etc.

**Continent codes:**
AF (Africa), AN (Antarctica), AS (Asia), EU (Europe), NA (North America), OC (Oceania), SA (South America)
