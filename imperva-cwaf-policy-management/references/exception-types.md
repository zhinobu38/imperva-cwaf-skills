# Exception Types Reference

Exceptions provide granular control to override policy settings for specific conditions.

## How Exceptions Work

Exceptions are attached to policy settings. When a policy setting matches a request, exceptions are evaluated first. If an exception matches, the action for that setting is overridden.

Example: A GEO policy blocks all traffic from Russia (RU), but an exception allows a specific IP range from Russia (penetration testing).

## Exception Data Structure

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

## Exception Types

### IP
IP addresses or CIDR ranges.

```json
{
  "exceptionType": "IP",
  "values": ["203.0.113.0/24", "198.51.100.5"]
}
```

### GEO
Countries and continents.

```json
{
  "exceptionType": "GEO",
  "countries": ["TH", "US"],
  "continents": ["AS"]
}
```

### URL
Exact URL match.

```json
{
  "exceptionType": "URL",
  "values": ["/api/healthcheck", "/status"]
}
```

### URL_CONTAINS
URL contains a substring.

```json
{
  "exceptionType": "URL_CONTAINS",
  "values": ["healthcheck", "monitoring"]
}
```

### URL_NOT_EQUALS
URL is not the specified value.

```json
{
  "exceptionType": "URL_NOT_EQUALS",
  "values": ["/admin/emergency"]
}
```

### URL_NOT_CONTAINS
URL does not contain the substring.

```json
{
  "exceptionType": "URL_NOT_CONTAINS",
  "values": ["debug", "test"]
}
```

### URL_PREFIX
URL starts with the prefix.

```json
{
  "exceptionType": "URL_PREFIX",
  "values": ["/api/public/", "/health/"]
}
```

### URL_NOT_PREFIX
URL does not start with the prefix.

```json
{
  "exceptionType": "URL_NOT_PREFIX",
  "values": ["/internal/"]
}
```

### URL_SUFFIX
URL ends with the suffix.

```json
{
  "exceptionType": "URL_SUFFIX",
  "values": [".css", ".js", ".png"]
}
```

### URL_NOT_SUFFIX
URL does not end with the suffix.

```json
{
  "exceptionType": "URL_NOT_SUFFIX",
  "values": [".exe", ".sh"]
}
```

### CLIENT_ID
Client application ID.

```json
{
  "exceptionType": "CLIENT_ID",
  "values": ["app-12345"]
}
```

### SITE_ID
Site ID for multi-site exception scoping.

```json
{
  "exceptionType": "SITE_ID",
  "values": ["<EXAMPLE_SITE_ID>"]
}
```

### HTTP_PARAM
HTTP parameter matching.

```json
{
  "exceptionType": "HTTP_PARAM",
  "values": ["bypass_token=secret123"]
}
```

### USER_AGENT
User-Agent string matching.

```json
{
  "exceptionType": "USER_AGENT",
  "values": ["GoogleBot/2.1", "MonitoringService/1.0"]
}
```

### FILE_HASH
File hash for known-safe file exceptions.

```json
{
  "exceptionType": "FILE_HASH",
  "values": ["sha256:abc123..."]
}
```

## Multi-Condition Exceptions

Multiple exception conditions can be combined in a single exception object using AND logic:

```json
{
  "data": [
    {
      "exceptionType": "IP",
      "values": ["203.0.113.0/24"]
    },
    {
      "exceptionType": "URL_PREFIX",
      "values": ["/api/"]
    }
  ]
}
```

This means: exception applies when BOTH the IP is in range AND the URL starts with /api/.

## Common Exception Patterns

### Allow monitoring endpoints globally
```json
{
  "comment": "Allow monitoring services to access health endpoints",
  "data": [{
    "exceptionType": "URL_CONTAINS",
    "values": ["/health", "/ping", "/status"]
  }]
}
```

### Allow pen test IPs through block rules
```json
{
  "comment": "Penetration testing company IP range - allows through 2026-06-30",
  "data": [{
    "exceptionType": "IP",
    "values": ["203.0.113.0/24"]
  }]
}
```

### Whitelist search engine bots
```json
{
  "comment": "Allow search engine crawlers",
  "data": [{
    "exceptionType": "USER_AGENT",
    "values": ["GoogleBot", "BingBot", "DuckDuckBot"]
  }]
}
```

### Exclude static files from inspection
```json
{
  "comment": "Skip inspection for static assets",
  "data": [{
    "exceptionType": "URL_SUFFIX",
    "values": [".css", ".js", ".png", ".jpg", ".gif", ".svg", ".woff2"]
  }]
}
```
