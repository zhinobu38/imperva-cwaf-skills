# Imperva Cloud WAF Rule Filter Parameters - Summary

This document provides a concise summary of the rule filter parameters available in Imperva Cloud WAF. For the complete list, refer to the full JSON file or the detailed markdown in the `imperva-cwaf-api-manual` skill.

## Parameter Categories

### Client Parameters
- **ASN**: Autonomous System Number (e.g., `ASN == 71`)
- **Client IP**: Source IP, supports CIDR (e.g., `ClientIP == 120.0.0.1/24`)
- **Country Code**: Two-letter ISO code (e.g., `CountryCode == TH`)
- **City**: City name (e.g., `City == "Bangkok"`)
- **Continent Code**: e.g., `ContinentCode == "AS"`
- **Client Type**: e.g., `ClientType == Browser`
- **Is Mobile**: `isMobile == Yes`
- **IP Reputation Risk Level**: e.g., `IPReputationRiskLevel >= Medium`
- **Malicious IP List**: e.g., `MaliciousIPList == TorIPs`
- **Epoch**: Unix timestamp in microseconds (e.g., `Epoch == 1502617252`)

### Request Parameters
- **HTTP Method**: `Method == POST`
- **URL**: Path without query string (e.g., `URL contains "/login"`)
- **Full-URL**: Includes query string (e.g., `Full-URL contains "id=17"`)
- **Header Exists/Value**: e.g., `HeaderExists == "Content-Length"` or `HeaderValue == {"User-Agent";"curl"}`
- **Cookie Exists/Value**: e.g., `CookieExists == "SESSIONID"` or `CookieValue == {"SESSIONID";"abc123"}`
- **Param Exists/Value**: Query string or POST data (e.g., `ParamExists == "token"` or `ParamValue == {"username";"admin"}`)
- **Query String Param Exists/Value**: Specific to query string (e.g., `QueryStringParamValue == {"type";"gif"}`)
- **Post Data/Size**: e.g., `PostData contains "username=admin"` or `PostSize >= 500`
- **User Agent**: e.g., `User-Agent contains "googlebot"`
- **Referer**: e.g., `Referer contains "google.com"`
- **Accept/Charset/Encoding/Language**: Check respective headers
- **Connection**: e.g., `Connection == "keep-alive"`
- **Content Type**: e.g., `Content-Type contains "json"`
- **HTTP Version/IP Version**: e.g., `Ver == "1.1"` or `IpVersion == 4`
- **is-HTTPS**: `is-HTTPS == No`
- **Is Naked Domain**: `IsNakedDomain == Yes`
- **Max Header Size**: e.g., `MaxHeaderSize >= 50`
- **Num On Session**: e.g., `NumOnSession > 7`
- **Scheduler**: Time-based activation (e.g., `Scheduler == {30-59;12;*;*;1,4}` for 12:30-12:59 on Mon and Thu)
- **SSL Cipher/Version**: e.g., `SslCipher == "ECDHE-RSA-AES128-GCM-SHA256"` or `SslVersion == tls1_2`
- **ABP Action**: e.g., `abp-action == "captcha_cleared"`
- **API Rate**: Rate of API calls (e.g., `Rate >= {api-rate;4}`)
- **Content Datacenter ID**: `ContentDcId == 43`
- **Request Size**: e.g., `RequestSize >= 3000`
- **Resource Type**: e.g., `ResourceType == non-html`

### Response Parameters
- **Response Code**: e.g., `ResponseCode == 201`
- **Response Content-Type**: e.g., `ResponseContentType == javascript`

## Operators
- **Equality**: `==`, `!=`
- **Comparison**: `>`, `<`, `>=`, `<=`
- **String**: `contains`, `not-contains`
- **Logical**: `is-in`, `is-not-in`, `exists`, `does-not-exist`
- **Special**: `&` (AND), `|` (OR)

## Multi-Value Matching (Semicolon Syntax)

When a filter condition needs to match multiple values, use **semicolon-separated** values instead of multiple `|` OR conditions:

```
# Good - single condition with semicolon-separated values:
ClientType != Browser;SearchBot;SiteHelper;FeedFetcher
URL contains ".jpg;.jpeg;.png;.gif;.webp"
CountryCode != CN;RU;KP

# Also valid but verbose - multiple OR conditions:
ClientType != Browser | ClientType != SearchBot | ClientType != SiteHelper
```

This applies to all filter parameters: `URL`, `Full-URL`, `CountryCode`, `ClientType`, `ParamName`, `HeaderValue`, `CookieValue`, `ParamValue`, `QueryStringParamValue`, `User-Agent`, `Referer`, `City`, `ContinentCode`, `MaliciousIPList`, `Content-Type`, `ResponseContentType`, `Resource Type`, `SSL Cipher`, `SSL Version`, etc.

**Note**: The semicolon syntax works with `==`, `!=`, `contains`, and `not-contains` operators.

## Notes
- String matching is case-insensitive unless otherwise specified.
- For string matching, `^` (start) and `$` (end) can be used within `contains`/`not-contains` for prefix/suffix matching.
- When combining conditions, use `&` for AND and `|` for OR.
- Examples of common filters:
  - Block non-Thailand: `CountryCode != TH`
  - Block specific IP: `ClientIP == 203.0.113.5`
  - Block SQLi in parameter: `ParamValue == {"id";"1 OR 1=1"}`
  - Block known bad bots: `User-Agent contains "sqlmap" | User-Agent contains "nikto"`
  - Time-based rule: `Scheduler == {0-59;22;*;*;1-5}` (every minute at 10 PM on weekdays)

## References
- Full JSON: `imperva_rule_filters.json` in the `imperva-cwaf-api-manual` skill's `api-spec` directory.
- Detailed markdown: `rule-filter-parameters.md` in the `imperva-cwaf-api-manual` skill's `references` directory.