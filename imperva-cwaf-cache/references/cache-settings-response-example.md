# Cache Settings Response Example

Full example response from `GET /sites/{siteId}/settings/cache`:

```json
{
  "mode": {
    "level": "smart",
    "time": 300,
    "https": "dont_include_html"
  },
  "key": {
    "unite_naked_full_cache": false,
    "comply_vary": false
  },
  "response": {
    "stale_content": {
      "mode": "adaptive"
    },
    "cache_shield": false,
    "cache_response_header": {
      "mode": "custom",
      "headers": []
    },
    "cache_empty_responses": false,
    "cache_300x": false,
    "cache_http_10_responses": false,
    "cache_404": {
      "enabled": false
    }
  },
  "ttl": {
    "use_shortest_caching": false,
    "prefer_last_modified": false
  },
  "client_side": {
    "enable_client_side_caching": true,
    "comply_no_cache": false,
    "send_age_header": false
  }
}
```

## Cache Rule Response Example

Example response from `GET /sites/{siteId}/settings/cache/rules/{ruleId}`:

```json
{
  "rule_id": 143907,
  "action": "HTTP_CACHE_MAKE_STATIC",
  "enabled": true,
  "filter": "URL contains \".css\"",
  "name": "Test Cache CSS Files",
  "ttl": 3600,
  "disabledByCacheMode": false
}
```

Note: Response uses `rule_id` (not `id`) and `disabledByCacheMode` (camelCase, not snake_case).

## Create Rule Response

```json
{
  "rule_id": 143907,
  "res": 0,
  "res_message": "OK",
  "debug_info": {
    "id-info": "999999"
  }
}
```

## Empty Rule List Response

```json
{
  "res": 0,
  "res_message": "OK",
  "debug_info": {
    "id-info": "999999",
    "Site has no Cache rules": "GET - /api/prov/v2/sites/852056322/settings/cache/rules/"
  }
}
```

## Update Request Examples

### Change cache mode to smart
```json
{
  "mode": {
    "level": "smart"
  }
}
```

### Enable client-side caching only
```json
{
  "client_side": {
    "enable_client_side_caching": true,
    "comply_no_cache": false,
    "send_age_header": true
  }
}
```

### Set custom response headers to cache
```json
{
  "response": {
    "cache_response_header": {
      "mode": "custom",
      "headers": ["Access-Control-Allow-Origin", "Access-Control-Allow-Methods"]
    }
  }
}
```

### Enable stale content with custom TTL
```json
{
  "response": {
    "stale_content": {
      "mode": "custom",
      "time": 7200
    }
  }
}
```

### Disable caching entirely
```json
{
  "mode": {
    "level": "disabled"
  }
}
```

## Update Cache Rule (Full Object Required)

When updating a cache rule via PUT, you MUST send the complete rule object:

```python
import json, urllib.request, ssl

url = f"https://my.imperva.com/api/prov/v2/sites/{site_id}/settings/cache/rules/{rule_id}"

# GET first to get current state
req = urllib.request.Request(url, method="GET")
# ... add auth headers ...
current = json.loads(urllib.request.urlopen(req).read())

# Modify
current["enabled"] = False

# PUT full object + Force-Risky-Operation header
data = json.dumps(current).encode()
req2 = urllib.request.Request(url, data=data, method="PUT")
req2.add_header("Content-Type", "application/json")
req2.add_header("Force-Risky-Operation", "true")
# ... add auth headers ...
resp = urllib.request.urlopen(req2)
```

## Cache Purge Response

```json
{
  "res": 0,
  "res_message": "OK",
  "debug_info": {
    "id-info": "999999"
  }
}
```
