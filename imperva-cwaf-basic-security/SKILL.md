---
name: imperva-cwaf-basic-security
description: Manage Imperva Cloud WAF basic security settings — backdoor protection, DDoS protection, and bot access control.
category: imperva-cwaf
version: 2.0.0
---

# Imperva CWAF Basic Security

Manage basic security settings (backdoor, DDoS, bot control) for a site via the Imperva Cloud WAF API.

## Credential & Identifier Policy (MANDATORY)

| Value | Source | Method |
|-------|--------|--------|
| `IMPERVA_API_ID` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `IMPERVA_API_KEY` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `SITE_ID` | User / memory / get-site-detail | Pass as env var |
| `CAID` | User / memory / get-site-detail | Pass as env var |

**NEVER hardcode credentials or identifiers.**

## ⚡ MANDATORY: Use the Scripts

**ALWAYS use the provided scripts. Do NOT write inline curl.**

All scripts at: `~/.hermes/skills/imperva-cwaf/imperva-cwaf-basic-security/templates/`

### Get Current Security Status

```bash
SITE_ID=<id> CAID=<caid> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-basic-security/templates/get-security.sh
```

### Backdoor Protection

```bash
# Enable quarantine
SITE_ID=<id> CAID=<caid> ACTION=api.threats.action.quarantine_url \
  bws run --project-id <bw_id> -- bash templates/set-backdoor.sh

# Alert only
SITE_ID=<id> CAID=<caid> ACTION=api.threats.action.alert \
  bws run --project-id <bw_id> -- bash templates/set-backdoor.sh

# Disable
SITE_ID=<id> CAID=<caid> ACTION=api.threats.action.disabled \
  bws run --project-id <bw_id> -- bash templates/set-backdoor.sh

# Remove URL from quarantine
SITE_ID=<id> CAID=<caid> ACTION=api.threats.action.quarantine_url QUARANTINE_URL=/bad.php \
  bws run --project-id <bw_id> -- bash templates/set-backdoor.sh
```

### DDoS Protection

```bash
# Auto mode (default)
SITE_ID=<id> CAID=<caid> ACTIVATION_MODE=auto \
  bws run --project-id <bw_id> -- bash templates/set-ddos.sh

# Auto with custom threshold and challenge action
SITE_ID=<id> CAID=<caid> ACTIVATION_MODE=auto TRAFFIC_THRESHOLD=100 UNKNOWN_CLIENTS_CHALLENGE=javascript \
  bws run --project-id <bw_id> -- bash templates/set-ddos.sh

# Adaptive with custom threshold
SITE_ID=<id> CAID=<caid> ACTIVATION_MODE=adaptive TRAFFIC_THRESHOLD=1500 \
  bws run --project-id <bw_id> -- bash templates/set-ddos.sh

# Disable
SITE_ID=<id> CAID=<caid> ACTIVATION_MODE=off \
  bws run --project-id <bw_id> -- bash templates/set-ddos.sh
```

### Bot Access Control (v1 — simple toggle)

```bash
SITE_ID=<id> CAID=<caid> BLOCK_BAD_BOTS=true CHALLENGE_SUSPECTED_BOTS=true \
  bws run --project-id <bw_id> -- bash templates/set-bot-control.sh
```

### Bot Configuration (v3 — managed lists)

```bash
# Get current bot config
SITE_ID=<id> bws run --project-id <bw_id> -- bash templates/get-bot-config.sh

# Update bot lists
SITE_ID=<id> MODE=blockbadbots BOT_IDS=6,12,45 \
  bws run --project-id <bw_id> -- bash templates/update-bot-config.sh
```

---

## Action Reference

### Backdoor Actions
| Action | Description |
|--------|-------------|
| `api.threats.action.quarantine_url` | Auto-quarantine detected backdoor URLs |
| `api.threats.action.alert` | Alert only |
| `api.threats.action.disabled` | Disable backdoor protection |

### DDoS Activation Modes
| Mode | Description |
|------|-------------|
| `off` | Disabled |
| `auto` | Auto-activate on attack |
| `on` | Always enabled |
| `adaptive` | Adaptive threshold |

### DDoS Parameters
| Parameter | Default | Description |
|-----------|---------|-------------|
| `ACTIVATION_MODE` | `auto` | off / auto / on / adaptive |
| `TRAFFIC_THRESHOLD` | `750` | 10–10000 requests/sec |
| `UNKNOWN_CLIENTS_CHALLENGE` | `none` | none / cookies / javascript / captcha |
| `BLOCK_NON_ESSENTIAL_BOTS` | `false` | true / false — do NOT change unless user explicitly asks |

### DDoS Challenge Actions (UNKNOWN_CLIENTS_CHALLENGE)
| Action | Description |
|--------|-------------|
| `none` | No challenge (default) |
| `cookies` | Cookie challenge |
| `javascript` | JavaScript challenge |
| `captcha` | CAPTCHA challenge |

---

## Response Format

v1 POST: `{"res": 0, "res_message": "OK"}`
v3 GET bot config: `{"data": [{"badBots": [...], "canceledGoodBots": [...]}]}`

## Pitfalls
- **v1 uses form-encoded POST** — not JSON body
- **Bot v3 requires full replacement** — GET first, modify, POST whole object
- **Bot v3 uses POST for update** — not PUT
- **DDoS threshold range**: 10–10000 only
- **DDoS adaptive mode** requires specific license — returns `res: 13003` with message "Unable to change DDoS activation mode to adaptive. Your plan does not support this operation." Fallback: use `ACTIVATION_MODE=auto` with explicit `TRAFFIC_THRESHOLD` and `UNKNOWN_CLIENTS_CHALLENGE` instead.
- **WAF intermittent block (errorCode 15, HTTP 403)**: Imperva's WAF may intermittently block API requests from certain IPs (especially cloud/AWS IPs). Response: `{"errorCode":"15","description":"This request was blocked by our security service"}`. This is NOT a rate limit (rate limit returns HTTP 429) and NOT an auth failure (auth failure returns HTTP 401). It is an IP-based WAF block that typically resolves within seconds to minutes. **Retry with exponential backoff** (5s, 15s, 30s, 60s) until the request succeeds. Do NOT assume credentials are wrong when seeing errorCode 15.

## Related Skills
- `imperva-cwaf-get-site-detail`: Get site IDs
- `imperva-cwaf-policy-management`: WAF policies (ACL, whitelist)
- `imperva-cwaf-custom-rule`: Custom rules
