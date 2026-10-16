---
name: imperva-cwaf-basic-security
description: Manage Imperva Cloud WAF basic security settings — backdoor protection, DDoS protection, and bot access control.
category: imperva-cwaf
version: 2.1.0
---

# Imperva CWAF Basic Security

Manage basic security settings (backdoor, DDoS, bot control) for a site via the Imperva Cloud WAF API.

## Shared References

| Reference | Description |
|-----------|-------------|
| `../../references/skill-dev-standard.md` | Dev standard: template structure, credential rules, known API behaviors, pitfalls |
| `../../references/credential-and-identifier-policy.md` | Credential/identifier sourcing rules (Bitwarden bws run) |
| `../../references/shell-template-pattern.md` | Shell template patterns (GET→modify→PUT, form-encoded POST, header format) |

## Credential & Identifier Policy (MANDATORY)

| Value | Source | Method |
|-------|--------|--------|
| `IMPERVA_API_ID` | Bitwarden | Only via `bws run` |
| `IMPERVA_API_KEY` | Bitwarden | Only via `bws run` |
| `SITE_ID` | User / memory / get-site-detail | Pass as env var |
| `CAID` | User / memory / get-site-detail | Pass as env var |

**NEVER hardcode credentials or identifiers.**

## Best Practice

> Before configuring any security settings, review the best practice:
> `~/myai/second-brain/20-Cybersecurity/Imperva-CWAF/Best-Practice-Configuration.md`
> Key points: DDoS Auto mode + threshold, security log if SIEM is available

## API Endpoints

| Operation | Method | Endpoint | Version |
|-----------|--------|----------|---------|
| Get security config | POST | `https://my.imperva.com/api/prov/v1/sites/status` | v1 |
| Set backdoor / DDoS / bot | POST | `https://my.imperva.com/api/prov/v1/sites/configure/security` | v1 |
| Get bot configuration | GET | `https://my.imperva.com/api/prov/v3/sites/{SITE_ID}/settings/botConfiguration` | v3 |
| Update bot configuration | POST | `https://my.imperva.com/api/prov/v3/sites/{SITE_ID}/settings/botConfiguration` | v3 |

**Notes:**
- v1 endpoints use form-encoded POST (`Content-Type: application/x-www-form-urlencoded`)
- v3 endpoints use JSON (`Content-Type: application/json`)
- v1 requires `site_id` and `caid` as form params
- v3 requires only `SITE_ID` in path; CAID not needed

## Operations

### Get Current Security Status

```bash
SITE_ID=<id> CAID=<caid> bws run -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-basic-security/scripts/get-security.sh
```

### Backdoor Protection

```bash
# Enable quarantine
SITE_ID=<id> CAID=<caid> ACTION=api.threats.action.quarantine_url \
  bws run -- bash scripts/set-backdoor.sh

# Alert only
SITE_ID=<id> CAID=<caid> ACTION=api.threats.action.alert \
  bws run -- bash scripts/set-backdoor.sh

# Disable
SITE_ID=<id> CAID=<caid> ACTION=api.threats.action.disabled \
  bws run -- bash scripts/set-backdoor.sh

# Remove URL from quarantine
SITE_ID=<id> CAID=<caid> ACTION=api.threats.action.quarantine_url QUARANTINE_URL=/bad.php \
  bws run -- bash scripts/set-backdoor.sh
```

### DDoS Protection

```bash
# Auto mode (default)
SITE_ID=<id> CAID=<caid> ACTIVATION_MODE=auto \
  bws run -- bash scripts/set-ddos.sh

# Auto with custom threshold and challenge action
SITE_ID=<id> CAID=<caid> ACTIVATION_MODE=auto TRAFFIC_THRESHOLD=100 UNKNOWN_CLIENTS_CHALLENGE=javascript \
  bws run -- bash scripts/set-ddos.sh

# Adaptive with custom threshold
SITE_ID=<id> CAID=<caid> ACTIVATION_MODE=adaptive TRAFFIC_THRESHOLD=1500 \
  bws run -- bash scripts/set-ddos.sh

# Disable
SITE_ID=<id> CAID=<caid> ACTIVATION_MODE=off \
  bws run -- bash scripts/set-ddos.sh
```

### Bot Access Control (v1 — simple toggle)

```bash
SITE_ID=<id> CAID=<caid> BLOCK_BAD_BOTS=true CHALLENGE_SUSPECTED_BOTS=true \
  bws run -- bash scripts/set-bot-control.sh
```

### Bot Configuration (v3 — managed lists)

```bash
# Get current bot config
SITE_ID=<id> bws run -- bash scripts/get-bot-config.sh

# Update bot lists
SITE_ID=<id> MODE=blockbadbots BOT_IDS=6,12,45 \
  bws run -- bash scripts/update-bot-config.sh
```

## Response Structure

### v1 POST (set-backdoor, set-ddos, set-bot-control)

```json
{
  "site_id": xxxxxx,
  "domain": "testagent.xxx.com",
  "account_id": xxxxxx,
  "security": {
    "waf": {
      "rules": [
        {
          "id": "api.threats.backdoor",
          "name": "Backdoor Protect",
          "action": "api.threats.action.quarantine_url",
          "action_text": "Auto-Quarantine"
        },
        {
          "id": "api.threats.ddos",
          "name": "DDoS",
          "activation_mode": "api.threats.ddos.activation_mode.auto",
          "activation_mode_text": "Auto",
          "ddos_traffic_threshold": 1000,
          "unknown_clients_challenge": "cookies",
          "block_non_essential_bots": true
        },
        {
          "id": "api.threats.bot_access_control",
          "name": "Bot Access Control",
          "block_bad_bots": true,
          "challenge_suspected_bots": false
        }
      ]
    }
  },
  "res": 0,
  "res_message": "OK"
}
```

### v1 POST get-security (sites/status)

```json
{
  "security": {
    "waf": {
      "rules": [...]
    }
  }
}
```

### v3 GET bot config

```json
{
  "data": [
    {
      "badBots": [],
      "canceledGoodBots": []
    }
  ]
}
```

## Settings Reference

### Backdoor Actions

| Action | Description |
|--------|-------------|
| `api.threats.action.quarantine_url` | Auto-quarantine detected backdoor URLs |
| `api.threats.action.alert` | Alert only |
| `api.threats.action.disabled` | Disable backdoor protection |

### DDoS Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `ACTIVATION_MODE` | `auto` | off / auto / on / adaptive |
| `TRAFFIC_THRESHOLD` | `750` | 10–10000 requests/sec |
| `UNKNOWN_CLIENTS_CHALLENGE` | `none` | none / cookies / javascript / captcha |
| `BLOCK_NON_ESSENTIAL_BOTS` | `false` | true / false — do NOT change unless user explicitly asks |

### DDoS Activation Modes

| Mode | Description |
|------|-------------|
| `off` | Disabled |
| `auto` | Auto-activate on attack |
| `on` | Always enabled |
| `adaptive` | Adaptive threshold (requires specific license) |

### DDoS Challenge Actions (UNKNOWN_CLIENTS_CHALLENGE)

| Action | Description |
|--------|-------------|
| `none` | No challenge (default) |
| `cookies` | Cookie challenge |
| `javascript` | JavaScript challenge |
| `captcha` | CAPTCHA challenge |

## Error Handling

| Code | HTTP | Meaning | Resolution |
|------|------|---------|------------|
| 200 | 200 | Success | — |
| 400 | 400 | Bad request (invalid params, missing fields) | Check required env vars |
| 401 | 401 | Unauthorized | Check Bitwarden credentials |
| 403 | 403 | WAF intermittent block (errorCode 15) | Retry with exponential backoff (5s, 15s, 30s, 60s) |
| 429 | 429 | Rate limited | Wait and retry |
| 13003 | 200 | Adaptive DDoS not supported by plan | Use `ACTIVATION_MODE=auto` with explicit `TRAFFIC_THRESHOLD` instead |
| 9415 | 200 | Operation not allowed | Check Bitwarden project (must be `hermes-aws`, not `hermes`) and API key write permissions |

## Pitfalls

- **v1 uses form-encoded POST** — not JSON body. Use `--data-urlencode` for params.
- **Bot v3 requires full replacement** — GET first, modify, POST whole object.
- **Bot v3 uses POST for update** — not PUT.
- **Bot v3 does NOT need CAID** — only SITE_ID in path.
- **DDoS threshold range**: 10–10000 only.
- **DDoS adaptive mode** requires specific license — returns `res: 13003` with message "Unable to change DDoS activation mode to adaptive. Your plan does not support this operation." Fallback: use `ACTIVATION_MODE=auto` with explicit `TRAFFIC_THRESHOLD` and `UNKNOWN_CLIENTS_CHALLENGE` instead.
- **WAF intermittent blocks on v3 API**: The `api.imperva.com` endpoints (v3) are more frequently blocked by Imperva's own WAF than `my.imperva.com` (v1). errorCode 15 may persist across multiple retries for certain endpoints (e.g., `/certificates/managed`). Consider the endpoint potentially blocked by WAF rules rather than a script error if retries don't resolve.
- **Base URL matters**: Certificate management endpoints use `https://api.imperva.com/certificates-ui/v3/` while site settings use `https://api.imperva.com/sites-mgmt/v3/`. Mixing them causes WAF blocks.

## Related Skills

- `imperva-cwaf-get-site-detail`: Get site IDs
- `imperva-cwaf-policy-management`: WAF policies (ACL, whitelist)
- `imperva-cwaf-custom-rule`: Custom rules

## Support Files

- `references/api-response-samples.md`: Real API response samples from testing (v1/v3 endpoints, error codes)
