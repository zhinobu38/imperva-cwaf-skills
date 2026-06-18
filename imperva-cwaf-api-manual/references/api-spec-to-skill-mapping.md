# API Spec to Skill Mapping

This file maps API spec files to the skills and scripts that use them.
Used by the API update monitor to determine which skills are affected
when an API spec is updated.

## API Base URL → Spec File

| API Base URL | Spec File |
|---|---|
| `api.imperva.com/sites-mgmt/v3` | `site_management.yaml` |
| `api.imperva.com/policies/v2` | `policies-api.yaml` |
| `my.imperva.com/api/prov/v2` (rules) | `rules.yaml` |
| `my.imperva.com/api/prov/v3` (rules) | `rules.yaml` |
| `my.imperva.com/api/prov/v2` (cache) | `cache-api.yaml` |
| `api.imperva.com/certificates-ui/v3` | `certificatesUI-api.yaml` |
| `api.imperva.com/sites-mgmt/v3` (TLS) | `website-management-api.yaml` |
| `my.imperva.com/api/prov/v1` (security) | `delivery-api.yaml` |
| `my.imperva.com/api/prov/v3` (bot config) | `delivery-api.yaml` |
| `api.imperva.com/appdlv-dashboards-ui/v3` | `performance-statistics-api.json` |
| `api.imperva.com/ip-reputation/v1` | `reputation-intelligence-api.yaml` |
| `api.imperva.com/waf-settings-v2` | `website-management-api.yaml` |
| `api.imperva.com/api/stats/v1` | `traffic_statistics_and_logs.yaml` |
| `api.imperva.com/api/visits/v1` | `traffic_statistics_and_logs.yaml` |
| `api.imperva.com/api/prov/v1` (sessions) | `session-release-api.yaml` |
| `api.imperva.com/api/prov/v1` (monitoring) | `website-monitoring-api.yaml` |
| `api.imperva.com/api/prov/v1` (attack analytics) | `attack-analytics-api.yaml` |
| `api.imperva.com/basic-api-security` | `basic-api-security-swagger.yaml` |
| `api.imperva.com/siem-config-service/v3` | `siem-log-api.yaml` |

## Spec File → Skills & Scripts

### site_management.yaml
 - **Skills:** `imperva-cwaf-get-site-detail`, `imperva-cwaf-site-onboard`, `imperva-cwaf-basic-security`
- **Scripts:**
   - `imperva-cwaf-get-site-detail/scripts/list-sites.sh`
   - `imperva-cwaf-site-onboard/scripts/get-site-cname.sh`
   - `imperva-cwaf-site-onboard/scripts/onboard.sh`

### policies-api.yaml
- **Skills:** `imperva-cwaf-policy-management`
- **Scripts:**
  - `imperva-cwaf-policy-management/scripts/add-exception.sh`
  - `imperva-cwaf-policy-management/scripts/add-geo-setting.sh`
  - `imperva-cwaf-policy-management/scripts/add-ip-setting.sh`
  - `imperva-cwaf-policy-management/scripts/add-url-setting.sh`
  - `imperva-cwaf-policy-management/scripts/apply-policy.sh`
  - `imperva-cwaf-policy-management/scripts/create-policy.sh`
  - `imperva-cwaf-policy-management/scripts/delete-policy.sh`
  - `imperva-cwaf-policy-management/scripts/get-policy.sh`
  - `imperva-cwaf-policy-management/scripts/list-policies.sh`
  - `imperva-cwaf-policy-management/scripts/list-site-policies.sh`
  - `imperva-cwaf-policy-management/scripts/remove-policy.sh`
  - `imperva-cwaf-policy-management/scripts/update-policy.sh`

### rules.yaml
- **Skills:** `imperva-cwaf-custom-rule`
- **Scripts:**
  - `imperva-cwaf-custom-rule/scripts/create-rule.sh`
  - `imperva-cwaf-custom-rule/scripts/delete-rule.sh`
  - `imperva-cwaf-custom-rule/scripts/edit-rule.sh`
  - `imperva-cwaf-custom-rule/scripts/list-rules.sh`

### cache-api.yaml
- **Skills:** `imperva-cwaf-cache`
- **Scripts:**
  - `imperva-cwaf-cache/scripts/create-cache-rule.sh`
  - `imperva-cwaf-cache/scripts/delete-cache-rule.sh`
  - `imperva-cwaf-cache/scripts/get-cache-rules.sh`
  - `imperva-cwaf-cache/scripts/get-cache-settings.sh`
  - `imperva-cwaf-cache/scripts/purge-cache.sh`
  - `imperva-cwaf-cache/scripts/update-cache-mode.sh`
  - `imperva-cwaf-cache/scripts/update-cache-rule.sh`

### certificatesUI-api.yaml
- **Skills:** `imperva-cwaf-ssl-management`
- **Scripts:**
  - `imperva-cwaf-ssl-management/scripts/enable-ssl.sh`
  - `imperva-cwaf-ssl-management/scripts/get-certificate-details.sh`
  - `imperva-cwaf-ssl-management/scripts/get-ssl-status.sh`

### website-management-api.yaml
- **Skills:** `imperva-cwaf-ssl-management`
- **Scripts:**
  - `imperva-cwaf-ssl-management/scripts/get-tls-config.sh`
  - `imperva-cwaf-ssl-management/scripts/update-tls-config.sh`

### delivery-api.yaml
- **Skills:** `imperva-cwaf-lb-delivery`
- **Scripts:**
  - `imperva-cwaf-lb-delivery/scripts/get-delivery.sh`
  - `imperva-cwaf-lb-delivery/scripts/get-load-balancing.sh`
  - `imperva-cwaf-lb-delivery/scripts/restore-defaults.sh`
  - `imperva-cwaf-lb-delivery/scripts/resume-dc.sh`
  - `imperva-cwaf-lb-delivery/scripts/set-error-page.sh`
  - `imperva-cwaf-lb-delivery/scripts/update-delivery-mode.sh`
  - `imperva-cwaf-lb-delivery/scripts/update-image-compression.sh`
  - `imperva-cwaf-lb-delivery/scripts/update-load-balancing.sh`
  - `imperva-cwaf-lb-delivery/scripts/update-network.sh`
  - `imperva-cwaf-lb-delivery/scripts/update-redirection.sh`

### load-balancing-api.yaml
- **Skills:** (none currently — lb-delivery uses delivery-api.yaml instead)
- **Scripts:** (none)

### performance-statistics-api.json
- **Skills:** `imperva-cwaf-troubleshoot`
- **Scripts:**
  - `imperva-cwaf-troubleshoot/scripts/get-performance-stats.sh`

### reputation-intelligence-api.yaml
- **Skills:** `imperva-cwaf-stats-and-visits`
- **Scripts:**
  - `imperva-cwaf-stats-and-visits/scripts/imperva_ip_reputation.sh`

### traffic_statistics_and_logs.yaml
- **Skills:** `imperva-cwaf-stats-and-visits`
- **Scripts:** (referenced for stats/visits endpoints)

### session-release-api.yaml
- **Skills:** `imperva-cwaf-stats-and-visits`
- **Scripts:**
  - `imperva-cwaf-stats-and-visits/scripts/imperva_release_session.sh`

### attack-analytics-api.yaml
- **Skills:** `imperva-cwaf-troubleshoot`, `imperva-cwaf-stats-and-visits`
- **Scripts:** (future use)

### website-monitoring-api.yaml
- **Skills:** `imperva-cwaf-status-check`, `imperva-cwaf-troubleshoot`
- **Scripts:** (future use)

### integrations.yaml
- **Skills:** `imperva-cwaf-api-manual` (reference only)
- **Scripts:**
  - `imperva-cwaf-api-manual/scripts/integrations.py`

### troubleshooting-api.yaml
- **Skills:** `imperva-cwaf-troubleshoot`
- **Scripts:** (future use)

### basic-api-security-swagger.yaml
- **Skills:** `imperva-cwaf-basic-security` (future use — new spec from June 7, 2026 release)
- **Scripts:** (none currently)

### siem-log-api.yaml
- **Skills:** `imperva-cwaf-siem-integration`
- **Scripts:**
  - `imperva-cwaf-siem-integration/scripts/get-connections.sh`
  - `imperva-cwaf-siem-integration/scripts/get-log-configurations.sh`

### custom_certificate.yaml
- **Skills:** `imperva-cwaf-ssl-management` (reference only)
- **Scripts:** (none)

### imperva_rule_filters.json
- **Skills:** `imperva-cwaf-policy-management`, `imperva-cwaf-custom-rule` (reference only)
- **Scripts:** (none)

## Update History

| Date | Spec Updated | Skills Affected | Notes |
|---|---|---|---|
| 2026-06-17 | Initial mapping created | — | Baseline mapping |
| 2026-06-18 | `siem-log-api.yaml` added | `imperva-cwaf-siem-integration` | New SIEM integration skill (read-only) |
