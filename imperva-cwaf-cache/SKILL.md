---
name: imperva-cwaf-cache
description: Manage Imperva Cloud WAF cache settings, custom cache rules, client-side caching, response header caching, and cache purging via the API.
category: imperva-cwaf
version: 2.0.0
---

# Imperva CWAF Cache Management

Manage all cache-related settings for Imperva Cloud WAF sites via the Cache API v2.

## Shared References

| Reference | Description |
|-----------|-------------|
| `../references/skill-dev-standard.md` | Dev standard |
| `../references/credential-and-identifier-policy.md` | Credential rules |
| `../references/shell-template-pattern.md` | Shell template patterns |

## Credential & Identifier Policy (MANDATORY)

| Value | Source | Method |
|-------|--------|--------|
| `IMPERVA_API_ID` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `IMPERVA_API_KEY` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `SITE_ID` | User / memory / get-site-detail | Pass as env var |

**NEVER hardcode credentials or identifiers.**

## ⚡ MANDATORY: Use the Scripts

**ALWAYS use the provided scripts. Do NOT write inline curl or Python.**

All scripts at: `~/.hermes/skills/imperva-cwaf/imperva-cwaf-cache/templates/`

### Get Cache Settings

```bash
SITE_ID=<id> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-cache/templates/get-cache-mode.sh
```

Optional: `SECTIONS=mode,client_side` to filter sections.

### Update Cache Mode

```bash
SITE_ID=<id> MODE_LEVEL=smart bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-cache/templates/update-cache-mode.sh
```

### Create Cache Rule

```bash
SITE_ID=<id> RULE_NAME=CacheStatic RULE_ACTION=HTTP_CACHE_MAKE_STATIC \
  RULE_FILTER='URL contains ".css"' RULE_TTL=86400 \
  bws run --project-id <bw_id> -- bash templates/create-cache-rule.sh
```

### Update Cache Rule

```bash
# Write full rule JSON to file, then:
SITE_ID=<id> RULE_ID=<id> \
  bws run --project-id <bw_id> -- python3 \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-cache/templates/update-cache-rule.py < rule.json
```

### Purge Cache

```bash
# Purge specific URL pattern
SITE_ID=<id> URL_PATTERN=style.css bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-cache/templates/purge-cache.sh

# Purge all
SITE_ID=<id> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-cache/templates/purge-cache.sh
```

---

## Cache Mode Levels

| Level | Description |
|-------|-------------|
| `disabled` | Turn off all caching |
| `custom_cache_rules_only` | Only cache via custom rules |
| `standard` | Cache per HTTP headers |
| `smart` | Standard + dynamic page profiling |
| `all_resources` | Cache everything |

## Cache Rule Actions

| Action | Description |
|--------|-------------|
| `HTTP_CACHE_MAKE_STATIC` | Always cache |
| `HTTP_CACHE_CLIENT_CACHE_CTL` | Cache on client |
| `HTTP_CACHE_FORCE_UNCACHEABLE` | Never cache |
| `HTTP_CACHE_ADD_TAG` | Tag for purging |
| `HTTP_CACHE_IGNORE_PARAMS` | Ignore query params in cache key |

See `references/cache-rule-actions.md` for full list.

## Response Format

Legacy envelope: `{"res": 0, "res_message": "OK"}`

## Pitfalls
- **Flat JSON only** — no `{"data": {...}}` wrapper anywhere
- **PUT cache settings is partial** — only changed fields needed
- **PUT cache rules needs FULL object** — GET first, modify, PUT complete
- **Force-Risky-Operation header** required for rule PUT
- **Cache rule ID field is `rule_id`** not `id`
- **Empty rule list** returns `{"res": 0, "debug_info": {"Site has no Cache rules": "..."}}`

## Related Skills
- `imperva-cwaf-get-site-detail`: Get site IDs
- `imperva-cwaf-custom-rule`: WAF custom rules (separate from cache rules)
- `imperva-cwaf-policy-management`: WAF policies
