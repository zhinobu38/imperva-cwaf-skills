# Imperva Cloud WAF Rule Filter Parameters

This document contains the extracted rule filter parameters from the Imperva Cloud WAF API specification document "rule-filter-parameters.pdf".

## Parameter Categories

### Client Parameters
Provide information about the connecting client.

- **ASN**: The client IP Autonomous System Number (ASN).
  - Example: `ASN == 71`

- **City**: The name of the city where the client sending the request is located.
  - Example: `City == "Amsterdam"`

- **Client Certificate CN**: The common name of the client certificate, if one exists. This parameter value is case sensitive.
  - Example: `ClientCrtCN == "yoursite.com"`

- **ClientCertExist**: Checks whether the request includes an SSL client certificate.
  - Example: `ClientCertExist == Yes & URL not-contains "^/app"`

- **Client ID**: The Imperva ID for the client application.
  - Example: `ClientId == 15`

- **Client IP**: The client (source) IP of the current request. You can also enter an IP using CIDR notation.
  - Example: `ClientIP == 120.0.0.1`

- **Client Type**: The client application type, such as Browser or SpamBot.
  - Example: `ClientType == Browser`
  - Valid values (case-sensitive): `AIBot`, `Browser`, `ClickBot`, `CommentSpamBot`, `Crawler`, `DDoSBot`, `FeedFetcher`, `HackingTool`, `MaskingProxy`, `SearchBot`, `SiteHelper`, `SpamBot`, `Unknown`, `VulnerabilityScanner`, `Worm`

- **Continent Code**: The client (source) IP origin continent.
  - Example: `ContinentCode == "EU"`

- **Country Code**: The client (source) IP origin country.
  - Example: `CountryCode == GB`

- **Declared Client Id**: The ID of the client application, according to the declaration in the UserAgent HTTP header.
  - Example: `DecClientId == 77 (Java Developer Tool)`

- **Declared Client Type**: Client type based on the client declaration in the UserAgent HTTP header.
  - Example: `DecClientType == "Browser"`

- **Epoch**: The UNIX timestamp of the request - the number of microseconds since midnight January 1, 1970.
  - Example: `Epoch == 1502617252`

- **IP Reputation Risk Level**: The risk level posed by this IP, based on the assessment of the Imperva Reputation Intelligence service.
  - Example: `IPReputationRiskLevel >= Medium`

- **Is Mobile**: Distinguishes between requests coming from mobile devices and requests coming from desktop clients based on the user-agent used in the request.
  - Example: `URL == "/welcome.html" & isMobile == Yes`

- **Latitude**: The approximate latitude coordinates of the client sending the request.
  - Example: `Latitude == 4.863890`

- **Longitude**: The approximate longitude coordinates of the client sending the request.
  - Example: `Longitude == 4.863890`

- **Malicious IP List**: The client (source) IP address of the request is identified as an anonymous proxy IP or a Tor exit node.
  - Example: `MaliciousIPList == TorIPs | MaliciousIPList == AnonymousProxyIPs`

- **Postal Code**: The postal/zip code of the client sending the request. May be available for requests from specific countries.
  - Example: `PostalCode == 123456`

- **Source Port**: The client's outgoing port number. It can be used, for example, to distinguish users behind NAT.
  - Example: `SrcPort == 6000`

- **State**: The state, province, or region where the client sending the request is located. The State parameter must be used together with the CountryCode parameter.
  - Example: `CountryCode == US & State == NY for New York in the United States`

### Request Parameters
Provide information about the current HTTP request.

- **User Agent**: Checks for the specified string pattern in the User-Agent header in the client request.
  - Example: `User-Agent contains "googlebot"`

- **API Rate**: Measures the rate of API requests in a client session during a one minute period.
  - Example: `Rate >= {api-rate;4}`

- **Accept**: Checks for the specified string pattern in the Accept HTTP header value.
  - Example: `Accept == "text/html"`

- **Accept Charset**: Checks for the specified string pattern in the Accept-Charset HTTP header value.
  - Example: `Accept-Charset == "utf-8"`

- **Accept Encoding**: Checks for the specified string pattern in the Accept-Encoding HTTP header value.
  - Example: `Accept-Encoding == "gzip"`

- **Accept Language**: Checks for the specified string pattern in the Accept-Language HTTP header value.
  - Example: `Accept-Language == "en-us"`

- **Connection**: Checks for the specified string pattern in the Connection HTTP header value.
  - Example: `Connection == "keep-alive"`

- **Content Datacenter ID**: Checks for the Imperva ID of the destination origin data center for the request.
  - Example: `ContentDcId == 43`

- **Content Type**: The value of the Content-Type HTTP header in the request.
  - Example: `Content-Type contains "json"`

- **Cookie Exists**: Checks for the specified string pattern in the cookie names in the client request.
  - Example: `CookieExists == "SessionID"`

- **Cookie Value**: Checks for the specified string pattern in the cookie values in the client request.
  - Example: `CookieValue == {"cookie_name";"cookie_value"}`

- **Full-URL**: Checks for the specified string pattern in the full path in the client request, including the query string. The protocol (http:// or https://) is not included in the matching.
  - Example: `Full-URL contains "/uploads/upload.php?id=17"`

- **Header Exists**: Checks whether a certain HTTP header exists.
  - Example: `HeaderExists == "Content-Length"`

- **Header Value**: Checks for the specified string pattern in the HTTP header value.
  - Example: `HeaderValue == {"HeaderName";"HeaderValue"}`

- **Header Value Length**: Checks the length of the specified HTTP header.
  - Example: `HeaderValueLength > {"Cookie";1024}`

- **HTTP Version**: The HTTP version of the request.
  - Example: `Ver == "1.1"`

- **IP Version**: The IP version of the request.
  - Example: `IpVersion == 4`

- **is-HTTPS**: Checks whether or not the request is HTTPS.
  - Example: `is-HTTPS == No`

- **Is Naked Domain**: Checks if the domain name is a naked domain.
  - Example: `IsNakedDomain == Yes`

- **Max Header Size**: The size of the largest HTTP header value.
  - Example: `MaxHeaderSize >= 50`

- **HTTP Method**: Checks for the specified string pattern in the HTTP method.
  - Example: `Method == POST`

- **Num On Session**: The index of the current request in the current session.
  - Example: `NumOnSession > 7`

- **Param Exists**: Checks for the specified string pattern in the parameter names in the query string and post data in the client request.
  - Example: `ParamExists != "test"`

- **Param Value**: Checks for the specified string pattern in the parameter values in the query string and post data in the client request.
  - Example: `ParamValue == {"PNAME";"PVAL"}`

- **Post Data**: Checks for the specified string pattern in the raw post data in the client request.
  - Example: `PostData contains "username=bob&password=alice"`

- **Post Data Exists**: Checks for post data existence in the request.
  - Example: `PostDataExists == Yes`

- **Post Size**: The length of POST body in bytes. If the Content-Length header is present, its value is used.
  - Example: `PostSize >= 500`

- **Query String**: Checks for the specified string pattern in the query string.
  - Example: `QueryString == "type=gif"`

- **Query String Param Exists**: Checks for the specified string pattern in the parameter names in the query string.
  - Example: `QueryStringParamExists != "test"`

- **Query String Param Value**: Checks for the specified string pattern in the parameter values in the query string.
  - Example: `QueryStringParamValue == {"PNAME";"PVAL"}`

- **Referer**: Checks for the specified string pattern in the Referer header in the client request.
  - Example: `Referer contains "google.com"`

- **Request Size**: The size of request in bytes, including the URL, query string, and headers.
  - Example: `RequestSize >= 3000`

- **Resource Type**: Checks for the resource type of the request.
  - Example: `ResourceType == non-html`

- **Scheduler**: The times and days for a custom rule to be active. The rule is triggered when requests arrive during the specified times.
  - Example: `Scheduler == {30-59;12;*;*;1,4}`

- **SSL Cipher**: The cipher suite in the request.
  - Example: `SslCipher == "ECDHE-RSA-AES128-GCM-SHA256";"can-add-another-type-here"`

- **SSL Version**: The SSL(TLS) Version.
  - Example: `SslVersion == tls1_2`

- **URL**: Checks for the specified string pattern in the path in the client request (without the query string).
  - Example: `URL contains "/uploads/upload.php"`

- **ABP Action**: Checks for the action taken by Advanced Bot Protection (ABP).
  - Example: `abp-action == "captcha_cleared"`

### Response Parameters
Provide information about the response coming from the origin.

- **Response Code**: Checks for the response code sent by the origin server.
  - Example: `ResponseCode == 201`

- **Response Content-Type**: Checks for the response Content-Type sent by the origin server.
  - Example: `ResponseContentType == javascript`

## Supported Operators

### Equality
- `==`: Is equal to
- `!=`: Is not

### Comparison
- `>`: Value is larger than
- `<`: Value is smaller than
- `>=`: Value is greater than or equal to
- `<=`: Value is equal to or smaller than

### String
- `contains`: Value contains
- `not-contains`: Does not contain
- `begins-with`: Begins with
- `ends-with`: Ends with
- `matches-regex`: Matches regex
- `not-matches-regex`: Does not match regex

### Logical
- `is-in`: Is in - matches if the parameter value is in the provided list (comma-separated)
- `is-not-in`: Is not in - matches if the parameter value is NOT in the provided list
- `exists`: Exists
- `does-not-exist`: Does not exist

### Multiple Value Matching
Instead of multiple conditions with `&`, use semicolon to list multiple values:
```
ClientType != Browser;SearchBot;SiteHelper;FeedFetcher
URL == "/abc";"/efg"
```

### Special
- `&`: AND operator
- `|`: OR operator

## Usage Examples

### Basic Filter
```
ClientIP == 120.0.0.1
```

### Complex Filter with Multiple Conditions
```
ClientIP == 120.0.0.1 & URL contains "/login" & User-Agent contains "Mozilla"
```

### Using CIDR Notation
```
ClientIP == 120.0.0.0/24
```

### Using Logical Operators
```
CountryCode == US & State == NY
```

### Using String Matching
```
URL contains "/admin" & User-Agent not-contains "bot"
```

### Using Numeric Comparisons
```
RequestSize > 10000 & ResponseCode >= 400
```

## Notes

- Parameter values are not case sensitive unless stated otherwise.
- When manually configuring a rule filter via the API, make sure that operators are specified in lower case.
- For examples of rules you can use to address common use cases, see Security Rule Use Case Examples and Delivery Rule Use Case Examples in the Imperva documentation.