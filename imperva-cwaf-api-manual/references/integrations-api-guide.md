# integrations.yaml — Practical Reference

**File:** `api-spec/integrations.yaml`
**Script:** `../scripts/integrations.py`
**Base URL:** `https://my.imperva.com`
**Auth:** `x-API-Id` + `x-API-Key` headers (via `bws run`)

Utility/reference API — read-only lookup calls, does not manage sites or security settings.
Provides data used alongside other skills (custom rules, policies, troubleshooting).

---

## Usage

All commands use the same pattern:
```bash
bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9 -- python3 \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-api-manual/scripts/integrations.py \
  <command> [options]
```

See `--help` for full options:
```bash
... integrations.py --help
... integrations.py clapps --help
```

---

## 1. clapps — Client Applications

`POST /api/integration/v1/clapps`

**Purpose:** Retrieve all client applications and their types.
**Response:** `clientApps` (id→name) + `clientAppTypes` (id→type) — parallel maps, matched by key.
**Verified:** res:0, 1060 entries.

```bash
# All client apps (default 20)
... integrations.py clapps

# Filter by type
... integrations.py clapps --type Browser
... integrations.py clapps --type SearchBot
... integrations.py clapps --type HackingTool

# Filter by name (substring)
... integrations.py clapps --name google

# Combined filters + show all
... integrations.py clapps --type Browser --name fox --limit 0
```

**Verified type categories (from 1060 entries):**

| Type | Count | Examples |
|------|-------|---------|
| Browser | 61 | Firefox, Chrome, Safari, Opera, Maxthon |
| SearchBot | ~100+ | Googlebot, Baidu Spider, Yahoo! Slurp |
| Crawler | many | General Crawler |
| HackingTool | many | Wget |
| VulnerabilityScanner | many | Skipfish |
| MaskingProxy | many | Google Translate, Guardster |
| SiteHelper | many | SiteUptime, Google Services |
| Unknown | many | Bot |

**Verified sample:**
```
clientApps:
  1: Firefox     2: Internet Explorer  3: Chrome    4: Safari
  5: General Crawler  6: Googlebot     7: Bot        8: Opera
  10: Wget            13: Skipfish      16: Baidu Spider  19: Yahoo! Slurp

clientAppTypes (same key):
  1: Browser    5: Crawler    6: SearchBot    7: Unknown
  10: HackingTool    13: VulnerabilityScanner    16: SearchBot
```

---

## 2. geo — Geographical Codes

`POST /api/integration/v1/geo`

**Purpose:** Retrieve all country codes and continent codes.
**Response:** `countriesCodes` (e.g. `BD: Bangladesh`), `continentsCodes` (e.g. `AF: Africa`).
**Verified:** res:0, 253 countries, 7 continents.

```bash
# All countries (default 20)
... integrations.py geo

# Filter by country code or name
... integrations.py geo --country TH
... integrations.py geo --country Thailand

# Filter by continent
... integrations.py geo --continent AS
... integrations.py geo --continent Asia

# Show all
... integrations.py geo --limit 0
```

**Verified continent codes (7):**
`EU` Europe, `AS` Asia, `NA` North America, `OC` Oceania, `AF` Africa, `AN` Antarctica, `SA` South America

**Verified country sample:**
`AD: Andorra, AE: United Arab Emirates, AF: Afghanistan, ... TH: Thailand, ... US: United States`

---

## 3. texts — API Text Messages

`POST /api/integration/v1/texts`

**Purpose:** Retrieve all text messages used in API responses (key→value mapping).
**Response:** `texts` (map of message key → English text).
**Verified:** res:0, 333 entries.

```bash
# All texts (default 20)
... integrations.py texts

# Filter by key (substring)
... integrations.py texts --key acl
... integrations.py texts --key error
... integrations.py texts --key bot

# Show all
... integrations.py texts --limit 0
```

**Verified sample (ACL-related keys):**
```
api.acl.blacklisted_countries: Visitors from denylisted Countries
api.acl.blacklisted_ips: Visitors from denylisted IPs
api.acl.blacklisted_urls: Visitors from denylisted URLs
```

---

## 4. ips — Imperva IP Ranges

`GET /api/integration/v1/ips`

**Purpose:** Retrieve Imperva's current IP ranges (IPv4 + IPv6).
**Query param:** `resp_format` — `json` (default) | `apache` | `nginx` | `iptables` | `text`.
**Verified:** 11 IPv4 ranges, 1 IPv6 range.

```bash
# JSON format (default)
... integrations.py ips

# Firewall-ready formats
... integrations.py ips --format nginx
... integrations.py ips --format iptables
... integrations.py ips --format apache
... integrations.py ips --format text
```

**Verified IPv4 ranges (11):**
```
199.83.128.0/21    198.143.32.0/19    149.126.72.0/21
103.28.248.0/22    185.11.124.0/22    192.230.64.0/18
45.64.64.0/22      107.154.0.0/16     45.60.0.0/16
45.223.0.0/16      131.125.128.0/17
```

**Verified IPv6 ranges (1):**
```
2a02:e980::/29
```

---

## Quick Reference

| Need | Command |
|------|---------|
| Country code for policy | `integrations.py geo --country Thailand` |
| Client app type for custom rule | `integrations.py clapps --type HackingTool` |
| All browser IDs | `integrations.py clapps --type Browser --limit 0` |
| Debug API error message | `integrations.py texts --key <error_key>` |
| Whitelist Imperva IPs | `integrations.py ips --format nginx` |
