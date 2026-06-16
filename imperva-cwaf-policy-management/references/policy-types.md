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

## Settings Actions

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

---

## Exception Types

Exceptions provide granular control to override policy settings for specific conditions. Exceptions are attached to policy settings. When a policy setting matches a request, exceptions are evaluated first. If an exception matches, the action for that setting is overridden.

### How Exceptions Work

Example: A GEO policy blocks all traffic from Russia (RU), but an exception allows a specific IP range from Russia (penetration testing).

### Exception Data Structure

```json
{
  "comment": "Description of why this exception exists",
  "data": [
    {
      "exceptionType": "<TYPE>",
      "values": ["<value1>", "<value2>"]
    }
  ]
}
```

Note: For GEO exceptions, the structure uses `countries` and `continents` instead of `values`.

### Exception Types

**IP** — IP addresses or CIDR ranges.
```json
{"exceptionType": "IP", "values": ["203.0.113.0/24", "198.51.100.5"]}
```

**GEO** — Countries and continents.
```json
{"exceptionType": "GEO", "countries": ["TH", "US"], "continents": ["AS"]}
```

**URL** — Exact URL match.
```json
{"exceptionType": "URL", "values": ["/api/healthcheck", "/status"]}
```

**URL_CONTAINS** — URL contains a substring.
```json
{"exceptionType": "URL_CONTAINS", "values": ["healthcheck", "monitoring"]}
```

**URL_NOT_EQUALS** — URL is not the specified value.
```json
{"exceptionType": "URL_NOT_EQUALS", "values": ["/admin/emergency"]}
```

**URL_NOT_CONTAINS** — URL does not contain the substring.
```json
{"exceptionType": "URL_NOT_CONTAINS", "values": ["debug", "test"]}
```

**URL_PREFIX** — URL starts with the prefix.
```json
{"exceptionType": "URL_PREFIX", "values": ["/api/public/", "/health/"]}
```

**URL_NOT_PREFIX** — URL does not start with the prefix.
```json
{"exceptionType": "URL_NOT_PREFIX", "values": ["/internal/"]}
```

**URL_SUFFIX** — URL ends with the suffix.
```json
{"exceptionType": "URL_SUFFIX", "values": [".css", ".js", ".png"]}
```

**URL_NOT_SUFFIX** — URL does not end with the suffix.
```json
{"exceptionType": "URL_NOT_SUFFIX", "values": [".exe", ".sh"]}
```

**CLIENT_ID** — Client application ID.
```json
{"exceptionType": "CLIENT_ID", "values": ["app-12345"]}
```

**SITE_ID** — Site ID for multi-site exception scoping.
```json
{"exceptionType": "SITE_ID", "values": ["<EXAMPLE_SITE_ID>"]}
```

**HTTP_PARAM** — HTTP parameter matching.
```json
{"exceptionType": "HTTP_PARAM", "values": ["bypass_token=secret123"]}
```

**USER_AGENT** — User-Agent string matching.
```json
{"exceptionType": "USER_AGENT", "values": ["GoogleBot/2.1", "MonitoringService/1.0"]}
```

**FILE_HASH** — File hash for known-safe file exceptions.
```json
{"exceptionType": "FILE_HASH", "values": ["sha256:abc123..."]}
```

### Multi-Condition Exceptions

Multiple exception conditions can be combined in a single exception object using AND logic:

```json
{
  "data": [
    {"exceptionType": "IP", "values": ["203.0.113.0/24"]},
    {"exceptionType": "URL_PREFIX", "values": ["/api/"]}
  ]
}
```

This means: exception applies when BOTH the IP is in range AND the URL starts with /api/.

### Common Exception Patterns

**Allow monitoring endpoints globally:**
```json
{"comment": "Allow monitoring services to access health endpoints",
 "data": [{"exceptionType": "URL_CONTAINS", "values": ["/health", "/ping", "/status"]}]}
```

**Allow pen test IPs through block rules:**
```json
{"comment": "Penetration testing company IP range - allows through 2026-06-30",
 "data": [{"exceptionType": "IP", "values": ["203.0.113.0/24"]}]}
```

**Whitelist search engine bots:**
```json
{"comment": "Allow search engine crawlers",
 "data": [{"exceptionType": "USER_AGENT", "values": ["GoogleBot", "BingBot", "DuckDuckBot"]}]}
```

**Exclude static files from inspection:**
```json
{"comment": "Skip inspection for static assets",
 "data": [{"exceptionType": "URL_SUFFIX", "values": [".css", ".js", ".png", ".jpg", ".gif", ".svg", ".woff2"]}]}
```
