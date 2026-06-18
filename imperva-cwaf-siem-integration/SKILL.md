---
name: imperva-cwaf-siem-integration
description: Retrieve Imperva Cloud WAF SIEM log integration configuration — connections and log configurations (read-only)
category: imperva-cwaf
version: 1.0.0
---

# Imperva CWAF SIEM Integration

Read-only retrieval of SIEM log integration configuration — connections and log configurations.

**API:** Imperva SIEM Configurations API 3.0
**Base URL:** `https://api.imperva.com/siem-config-service`

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
| `CAID` | User / memory | Pass as env var |

**NEVER hardcode credentials or identifiers.**

## ⚡ MANDATORY: Use the Scripts

**ALWAYS use the provided scripts. Do NOT write inline curl.**

---

## 1. Connections

Manage log storage repository connections (S3, SFTP, Splunk).

### List All Connections

```bash
CAID=<caid> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-siem-integration/scripts/get-connections.sh
```

### Get Single Connection

```bash
CAID=<caid> CONNECTION_ID=<24-char-id> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-siem-integration/scripts/get-connections.sh
```

### JSON Output

```bash
OUTPUT_FORMAT=json CAID=<caid> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-siem-integration/scripts/get-connections.sh
```

### Parameters

| Env Var | Required | Description |
|---------|----------|-------------|
| `CAID` | No | Imperva Account ID. Defaults to API credential's account |
| `CONNECTION_ID` | No | 24-char connection ID. Omit to list all |
| `OUTPUT_FORMAT` | No | `table` (default) or `json` |

### Storage Types

| Type | Connection Info Fields |
|------|----------------------|
| `CUSTOMER_S3` | `accessKey`, `secretKey`, `path` |
| `CUSTOMER_S3_ARN` | `path` (ARN) |
| `CUSTOMER_SFTP` | `host`, `username`, `password`, `path` |
| `CUSTOMER_SPLUNK` | `host`, `port`, `token` |

### Response Fields

| Field | Description |
|-------|-------------|
| `id` | 24-char unique connection ID (assigned by Imperva) |
| `connectionName` | Human-readable name |
| `assetId` | Imperva account ID |
| `storageType` | One of the 4 types above |
| `connectionInfo` | Type-specific connection details |

---

## 2. Log Configurations

Configure which logs to receive and where to send them.

### List All Log Configurations

```bash
CAID=<caid> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-siem-integration/scripts/get-log-configurations.sh
```

### Get Single Log Configuration

```bash
CAID=<caid> CONFIG_ID=<24-char-id> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-siem-integration/scripts/get-log-configurations.sh
```

### JSON Output

```bash
OUTPUT_FORMAT=json CAID=<caid> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-siem-integration/scripts/get-log-configurations.sh
```

### Parameters

| Env Var | Required | Description |
|---------|----------|-------------|
| `CAID` | No | Imperva Account ID. Defaults to API credential's account |
| `CONFIG_ID` | No | 24-char configuration ID. Omit to list all |
| `OUTPUT_FORMAT` | No | `table` (default) or `json` |

### Response Fields

| Field | Description |
|-------|-------------|
| `id` | 24-char unique config ID (assigned by Imperva) |
| `configurationName` | Human-readable name |
| `provider` | Service provider (see table below) |
| `datasets` | Array of dataset names |
| `enabled` | Boolean — is config active |
| `format` | Log format: `CEF` (default), `W3C`, `LEEF` — CLOUD_WAF only |
| `compressLogs` | Boolean — CLOUD_WAF and ATTACK_ANALYTICS only |
| `defaultSiteLogsLevel` | `NONE`, `FULL`, `SECURITY` — CLOUD_WAF only |
| `publicKey` | Public key for log encryption — CLOUD_WAF and ATTACK_ANALYTICS only |
| `publicKeyFileName` | PEM file name — CLOUD_WAF and ATTACK_ANALYTICS only |

### Providers & Datasets

| Provider | Datasets |
|----------|----------|
| `CLOUD_WAF` | `WAF_RAW_LOGS`, `CLOUD_WAF_ACCESS` |
| `ATTACK_ANALYTICS` | `WAF_ANALYTICS_LOGS` |
| `ABP` | `ABP`, `ABP_ACCESS` |
| `NETSEC` | `NETFLOW`, `IP`, `ATTACK`, `CONNECTION`, `NOTIFICATIONS` |
| `AUDIT` | `AUDIT_TRAIL` |
| `ATO` | `ATO` |
| `CSP` | `SIGNIFICANT_DOMAIN_DISCOVERY`, `GOOGLE_ANALYTICS_IDS`, `SIGNIFICANT_SCRIPT_DISCOVERY`, `SIGNIFICANT_DATA_TRANSFER_DISCOVERY`, `DOMAIN_DISCOVERY_ENFORCE_MODE`, `CSP_HEADER_HEALTH`, `SIGNIFICANT_SCRIPT_NEW_HASH_DISCOVERY`, `SIGNIFICANT_SUSPICIOUS_DOMAIN_INSTANT_BLOCK` |
| `DNSMS` | `DNSMS_SECURITY_LOGS` |
| `DNS` | `DNS_Protection_Events`, `DNS_Security_Logs`, `DNS_Traffic_Logs` |
| `API_Security` | `BOLA` |

---

## Error Handling

| Code | Meaning |
|------|---------|
| 400 | Bad request (invalid parameters) |
| 401 | Unauthorized (invalid/missing API credentials) |
| 404 | Resource not found |
| 500 | Internal server error |
| 15 (HTTP 403) | WAF intermittent block — retry with exponential backoff (5s, 15s, 30s, 60s) |

## Pitfalls

- **WAF intermittent block (errorCode 15)**: Imperva's WAF may intermittently block API requests from certain IPs. This is NOT an auth failure. Retry with exponential backoff.
- **Secrets hidden in table output**: Passwords, secret keys, and tokens are masked (`****`) in table output. Use `OUTPUT_FORMAT=json` to see full values.
- **CAID optional**: When omitted, the API operates on the account associated with the API credentials. Specify `CAID` to operate on a different sub-account.
- **Response wrapper**: All responses use `{data: [...]}` array wrapper. Single-resource GET also returns `data` array (with one element).

## Related Skills

- `imperva-cwaf-api-manual`: Browse and search Imperva CWAF API specifications
- `imperva-cwaf-get-site-detail`: List and search sites
