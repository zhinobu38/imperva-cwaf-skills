---
name: imperva-cwaf-load-balancing
description: Manage Imperva Cloud WAF load balancing and failover settings — data centers, servers, LB algorithms, geo routing, failover, and traffic resume.
category: imperva-cwaf
version: 1.0.0
---

# Imperva CWAF Load Balancing Skill

Manage load balancing, data center, and origin server settings for a site via the Imperva Cloud WAF API.

## Credential & Identifier Policy (MANDATORY)

### Credentials — ห้าม hardcode เด็ดขาด

| Value | Source | Method |
|-------|--------|--------|
| `IMPERVA_API_ID` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `IMPERVA_API_KEY` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |

- **ห้าม** hardcode credential ใน script, template, หรือ SKILL.md
- **ห้าม** print credential ใน log หรือ raw request output
- **ห้าม** ใช้ credential จาก project `hermes` (auth ได้แต่ไม่มี write permission → 9415 error)
- bws inject เฉพาะ `IMPERVA_API_ID` + `IMPERVA_API_KEY` — ไม่มี SITE_ID/CAID

### Identifiers — ระบุแหล่งที่มาชัดเจน

| Value | Source | Method |
|-------|--------|--------|
| `SITE_ID` | User / memory / `imperva-cwaf-get-site-detail` skill | Pass เป็น env var ก่อนเรียก script |
| `CAID` | User / memory / `imperva-cwaf-get-site-detail` skill | Pass เป็น env var ก่อนเรียก script |

### Correct Usage Pattern

```bash
# GET current config
SITE_ID=852056322 CAID=2429928 \
  bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9 \
  -- bash templates/get-load-balancing.sh

# UPDATE config (after modifying JSON)
SITE_ID=852056322 CAID=2429928 \
  bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9 \
  -- bash templates/update-load-balancing.sh

# RESUME traffic to active DCs
SITE_ID=852056322 CAID=2429928 \
  bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9 \
  -- bash templates/resume-dc.sh
```

## Shared References

These files are maintained at the `imperva-cwaf/` skill group level and are the
single source of truth for all sub-skills. Do NOT duplicate their content.

| Reference | Description |
|-----------|-------------|
| `../imperva-cwaf-api-manual/references/skill-dev-standard.md` | Dev standard: template structure, credential rules, known API behaviors, pitfalls |
| `../imperva-cwaf-api-manual/references/credential-and-identifier-policy.md` | Credential/identifier sourcing rules (Bitwarden bws run) |
| `../imperva-cwaf-api-manual/references/shell-template-pattern.md` | Shell template patterns (GET→modify→PUT, form-encoded POST, header format) |

## API Endpoints

### v3 — Primary (full configuration)

```
GET  /api/prov/v3/sites/{siteId}/data-centers-configuration
PUT  /api/prov/v3/sites/{siteId}/data-centers-configuration
```

Base URL: `https://my.imperva.com`

### v2 — Resume Traffic

```
POST /api/prov/v2/sites/{siteId}/dataCenters/resume
```

Base URL: `https://my.imperva.com`

## Operations

### Get Load Balancing Configuration

```
GET /api/prov/v3/sites/{siteId}/data-centers-configuration
```

Returns the full data center and server configuration for the site.

**Python pattern:**
```python
import json, urllib.request, os

site_id = os.environ["SITE_ID"]
api_id = os.environ["IMPERVA_API_ID"]
api_key = os.environ["IMPERVA_API_KEY"]

url = "https://my.imperva.com/api/prov/v3/sites/{}/data-centers-configuration".format(site_id)

req = urllib.request.Request(url)
req.add_header("Accept", "application/json")
req.add_header("x-API-Id", api_id)
req.add_header("x-API-Key", api_key)

resp = urllib.request.urlopen(req, timeout=30)
data = json.loads(resp.read().decode())
print(json.dumps(data, indent=2))
```

### Update Load Balancing Configuration

```
PUT /api/prov/v3/sites/{siteId}/data-centers-configuration
```

**Body:** Full `DataCentersConfigurationDTO` — all sections must be included. This is a full replacement (not partial update).

**CRITICAL:** Always GET first, then modify, then PUT. Never construct the body from scratch — you will lose existing DC/server configs.

**Python pattern:**
```python
import json, urllib.request, os

site_id = os.environ["SITE_ID"]
api_id = os.environ["IMPERVA_API_ID"]
api_key = os.environ["IMPERVA_API_KEY"]

url = "https://my.imperva.com/api/prov/v3/sites/{}/data-centers-configuration".format(site_id)

# 1. GET current
req = urllib.request.Request(url)
req.add_header("Accept", "application/json")
req.add_header("x-API-Id", api_id)
req.add_header("x-API-Key", api_key)
resp = urllib.request.urlopen(req, timeout=30)
current = json.loads(resp.read().decode())

# 2. Modify (example: change global LB algorithm)
current["data"][0]["lbAlgorithm"] = "WEIGHTED_LB"

# 3. PUT full object
body = json.dumps(current).encode()
req2 = urllib.request.Request(url, data=body, method="PUT")
req2.add_header("Content-Type", "application/json")
req2.add_header("Accept", "application/json")
req2.add_header("x-API-Id", api_id)
req2.add_header("x-API-Key", api_key)
resp2 = urllib.request.urlopen(req2, timeout=30)
print(json.dumps(json.loads(resp2.read().decode()), indent=2))
```

### Resume Traffic to Active DCs

```
POST /api/prov/v2/sites/{siteId}/dataCenters/resume
```

Use this after failover when active DCs are back online. Traffic does NOT revert automatically.

**Python pattern:**
```python
import urllib.request, os

site_id = os.environ["SITE_ID"]
api_id = os.environ["IMPERVA_API_ID"]
api_key = os.environ["IMPERVA_API_KEY"]

url = "https://my.imperva.com/api/prov/v2/sites/{}/dataCenters/resume".format(site_id)

req = urllib.request.Request(url, method="POST")
req.add_header("Accept", "application/json")
req.add_header("x-API-Id", api_id)
req.add_header("x-API-Key", api_key)

resp = urllib.request.urlopen(req, timeout=30)
print(resp.read().decode())
```

## Response Structure

```json
{
  "data": [
    {
      "lbAlgorithm": "BEST_CONNECTION_TIME",
      "failOverRequiredMonitors": "MOST",
      "dataCenterMode": "SINGLE_DC",
      "minAvailableServersForDataCenterUp": 1,
      "kickStartURL": "https://www.example.com:443/kickStart",
      "kickStartUser": "kickstart-user",
      "kickStartPass": "kickstart-pass",
      "isPersistent": true,
      "dataCenters": [
        {
          "name": "London DC",
          "id": 7543,
          "ipMode": "MULTIPLE_IP",
          "webServersPerServer": 1,
          "lbAlgorithm": "WEIGHTED",
          "weight": 40,
          "isEnabled": true,
          "isActive": true,
          "isContent": false,
          "isRestOfTheWorld": false,
          "geoLocations": ["EUROPE", "US_EAST"],
          "originPop": "lax",
          "servers": [
            {
              "address": "1.2.3.4",
              "id": 7543,
              "isEnabled": true,
              "serverMode": "ACTIVE",
              "weight": 70
            }
          ]
        }
      ]
    }
  ]
}
```

## Configuration Reference

### Global-Level Settings (per site)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `lbAlgorithm` | string | `BEST_CONNECTION_TIME` | Global LB algorithm: `BEST_CONNECTION_TIME`, `GEO_PREFERRED`, `GEO_REQUIRED`, `WEIGHTED_LB` |
| `failOverRequiredMonitors` | string | `MOST` | How many PoPs must report DC down before failover: `ONE`, `MANY`, `MOST`, `ALL` |
| `dataCenterMode` | string | `SINGLE_DC` | `SINGLE_SERVER` (no LB), `SINGLE_DC` (LB within DC), `MULTIPLE_DC` (LB across DCs + geo routing) |
| `minAvailableServersForDataCenterUp` | int | 1 | Minimum servers that must be up for DC to be considered UP |
| `kickStartURL` | string | | URL sent to standby server during failover. Port required for HTTPS. |
| `kickStartUser` | string | | Username for kickstart URL auth |
| `kickStartPass` | string | | Password for kickstart URL auth |
| `isPersistent` | boolean | true | Session stickiness to origin servers via cookie |

### Data Center-Level Settings

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | string | (required) | Data center name |
| `id` | integer | | Data center ID (auto-assigned on creation) |
| `ipMode` | string | `MULTIPLE_IP` | `SINGLE_IP` (single server, multi-port) or `MULTIPLE_IP` (multiple servers) |
| `webServersPerServer` | int | 1 | When `ipMode=SINGLE_IP`: number of webserver ports per server (1-100) |
| `lbAlgorithm` | string | `LB_LEAST_PENDING_REQUESTS` | Per-DC LB: `LB_LEAST_PENDING_REQUESTS`, `LB_LEAST_OPEN_CONNECTIONS`, `LB_SOURCE_IP_HASH`, `RANDOM`, `WEIGHTED` |
| `weight` | int | | Traffic weight %. Required if global `lbAlgorithm=WEIGHTED_LB`. Total across all DCs must = 100 |
| `isEnabled` | boolean | true | Enable/disable this DC. At least one DC must be enabled. |
| `isActive` | boolean | true | false = standby DC. Max 1 standby per site. Failover only when no active DC available. |
| `isContent` | boolean | false | true = only handles requests from forward delivery rules. Must be active. |
| `isRestOfTheWorld` | boolean | false | true = handles traffic from unassigned regions (for GEO modes). Exactly 1 DC must have this. |
| `geoLocations` | array | | Regions this DC serves. Required if global `lbAlgorithm=GEO_PREFERRED` or `GEO_REQUIRED`. Values: `EUROPE`, `AUSTRALIA`, `US_EAST`, `US_WEST`, `AFRICA`, `ASIA`, `SOUTH_AMERICA`, `NORTH_AMERICA` |
| `originPop` | string | | PoP code (3 chars, e.g. `lax`). If unset, all PoPs can send traffic to this DC. |

### Server-Level Settings

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `address` | string | (required) | Server address: hostname, IPv4, or IPv6 |
| `id` | integer | | Server ID (auto-assigned on creation) |
| `isEnabled` | boolean | true | Enable/disable this server. At least one server per DC must be enabled. |
| `serverMode` | string | `ACTIVE` | `ACTIVE` or `STANDBY` |
| `weight` | int | | Traffic weight %. Required if DC `lbAlgorithm=WEIGHTED`. Total across all servers in DC must = 100. |

## Interactive Configuration Wizard

When the user wants to **update** load balancing settings, use this step-by-step wizard to collect configuration details. Do NOT ask for everything at once — guide through each level.

### Step 1: Show Current Config

Always start by showing the current configuration so the user can see what exists.

```
[GET current config and display in readable format]
```

### Step 2: Ask What to Change

Present a menu of options:

```
What would you like to change?

  1. Global settings (LB algorithm, failover, data center mode, kickstart, session stickiness)
  2. Data center settings (add/edit/remove DC, change DC properties)
  3. Server settings (add/edit/remove server within a DC)
  4. Resume traffic to active DCs (after failover)
  5. Show current config only (no changes)

Enter choice [1-5]:
```

### Step 3: Collect Details Based on Choice

#### Option 1: Global Settings

Ask one field at a time, showing current value and valid options:

```
Current LB algorithm: BEST_CONNECTION_TIME
New LB algorithm? (BEST_CONNECTION_TIME / GEO_PREFERRED / GEO_REQUIRED / WEIGHTED_LB) [Enter to keep current]:

Current failover monitors: MOST
New failover monitors? (ONE / MANY / MOST / ALL) [Enter to keep current]:

Current data center mode: SINGLE_DC
New data center mode? (SINGLE_SERVER / SINGLE_DC / MULTIPLE_DC) [Enter to keep current]:

Current min available servers for DC up: 1
New value? (integer, min=1) [Enter to keep current]:

Current kickStart URL: (none)
New kickStart URL? [Enter to keep current / Enter empty to clear]:

Current session stickiness: true
New session stickiness? (true / false) [Enter to keep current]:
```

#### Option 2: Data Center Settings

First list existing DCs with their IDs and properties, then:

```
Existing data centers:
  [1] London DC (id=7543, enabled=true, active=true, weight=40)
  [2] Tokyo DC (id=7544, enabled=true, active=false, weight=60)

What would you like to do?
  a. Edit existing DC
  b. Add new DC
  c. Remove DC
  d. Cancel

Enter choice [a-d]:
```

If **Edit existing DC**:
```
Select DC to edit [1-2]:

Selected: London DC (id=7543)

Fields you can edit:
  1. name (current: "London DC")
  2. ipMode (current: MULTIPLE_IP)
  3. lbAlgorithm (current: WEIGHTED)
  4. weight (current: 40)
  5. isEnabled (current: true)
  6. isActive (current: true)
  7. isContent (current: false)
  8. isRestOfTheWorld (current: false)
  9. geoLocations (current: [EUROPE, US_EAST])
  10. originPop (current: lax)
  11. webServersPerServer (current: 1)

Select field to edit [1-11] or 'd' when done:
```

If **Add new DC**:
```
New data center configuration:

Name (required): 
ipMode? (SINGLE_IP / MULTIPLE_IP) [MULTIPLE_IP]:
webServersPerServer? (1-100, only for SINGLE_IP) [1]:
lbAlgorithm? (LB_LEAST_PENDING_REQUESTS / LB_LEAST_OPEN_CONNECTIONS / LB_SOURCE_IP_HASH / RANDOM / WEIGHTED) [LB_LEAST_PENDING_REQUESTS]:
weight? (0-100):
isEnabled? (true/false) [true]:
isActive? (true/false) [true]:
isContent? (true/false) [false]:
isRestOfTheWorld? (true/false) [false]:
geoLocations? (comma-separated: EUROPE, AUSTRALIA, US_EAST, US_WEST, AFRICA, ASIA, SOUTH_AMERICA, NORTH_AMERICA) [none]:
originPop? (3-char code e.g. lax) [none]:

Now add servers for this DC (at least 1 required):
  Server 1 address (required):
  Server 1 isEnabled? (true/false) [true]:
  Server 1 serverMode? (ACTIVE / STANDBY) [ACTIVE]:
  Server 1 weight? (0-100):

Add another server? (y/n):
```

If **Remove DC**:
```
Select DC to remove [1-2]:
WARNING: This will remove the DC and all its servers. Continue? (y/n):
```

#### Option 3: Server Settings

First list DCs, then servers within selected DC:

```
Select DC:
  [1] London DC (id=7543) — 2 servers
  [2] Tokyo DC (id=7544) — 1 server

Enter choice [1-2]:

Servers in London DC:
  [1] 1.2.3.4 (id=7543, enabled=true, active, weight=70)
  [2] 1.2.3.5 (id=7544, enabled=true, active, weight=30)

What would you like to do?
  a. Edit existing server
  b. Add new server
  c. Remove server
  d. Cancel

Enter choice [a-d]:
```

If **Edit existing server**:
```
Select server [1-2]:

Selected: 1.2.3.4 (id=7543)

Fields you can edit:
  1. address (current: "1.2.3.4")
  2. isEnabled (current: true)
  3. serverMode (current: ACTIVE)
  4. weight (current: 70)

Select field to edit [1-4] or 'd' when done:
```

If **Add new server**:
```
New server configuration:

Address (required): 
isEnabled? (true/false) [true]:
serverMode? (ACTIVE / STANDBY) [ACTIVE]:
weight? (0-100):
```

If **Remove server**:
```
Select server to remove [1-2]:
WARNING: At least 1 enabled server must remain per DC. Continue? (y/n):
```

#### Option 4: Resume Traffic

```
This will resume traffic to active data centers.
Use this after failover when active DCs are back online.

Continue? (y/n):
```

### Step 4: Confirm Before Applying

Always show a summary before applying changes:

```
=== Summary of Changes ===

Global:
  lbAlgorithm: BEST_CONNECTION_TIME → WEIGHTED_LB

Data Centers:
  [London DC] weight: 40 → 60
  [Tokyo DC] weight: 60 → 40

Servers:
  (no changes)

Apply these changes? (y/n):
```

### Step 5: Apply and Verify

```
[Apply changes via PUT]
[GET again to verify]
[Show diff of changes]
```

## Error Handling

| HTTP Code | Meaning | Action |
|-----------|---------|--------|
| 200 | OK | Success |
| 401 | Unauthorized | Check API credentials |
| 403 | Forbidden | Check user permissions |
| 404 | Site not found | Verify SITE_ID |
| 406 | Invalid input | Check request body format and field values |
| 500 | Server error | Retry or contact Imperva support |

**Common error codes in response body (`res` field):**
| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Invalid data center |
| 5 | Cannot set Origin PoP for DC |
| 9413 | Invalid/unknown site |
| 9415 | Invalid server/DC state |

## Pitfalls

- **ห้าม hardcode credential**: ห้ามใส่ API ID / API Key ใน script, template, หรือ log output เด็ดขาด
- **ห้าม hardcode identifier ใน template**: SITE_ID / CAID ต้องมาจาก user env var
- **PUT is full replacement**: Always GET first, modify, then PUT. Never construct body from scratch.
- **At least 1 DC must be enabled**: Cannot disable all DCs
- **At least 1 server per DC must be enabled**: Cannot disable all servers in a DC
- **Max 1 standby DC**: Only one DC can have `isActive=false`
- **GEO mode requires isRestOfTheWorld**: Exactly 1 DC must have `isRestOfTheWorld=true` when using GEO_PREFERRED/GEO_REQUIRED
- **WEIGHTED_LB requires weights sum to 100**: Both at DC level and server level
- **SINGLE_IP requires IP address**: Cannot use hostname/CNAME with SINGLE_IP mode
- **port/ssl_port are read-only**: Never include in PUT body (same as delivery settings)
- **Inline Python fails in bws run**: Write script file first, then execute via `bws run`
- **Resume is manual**: Traffic does not auto-revert to active DCs after failover

## Related Skills

- `imperva-cwaf-api-manual`: For browsing API specifications. Load balancing spec at `api-spec/load-balancing-api.yaml`
- `imperva-cwaf-get-site-detail`: Get site IDs and current configuration
- `imperva-cwaf-delivery`: For managing delivery settings (compression, network, redirection)
- `imperva-cwaf-cache`: For managing cache settings and cache rules
- `imperva-cwaf-ssl-management`: For managing SSL certificates and TLS/HSTS settings
- `imperva-cwaf-site-onboard`: For onboarding a new site
