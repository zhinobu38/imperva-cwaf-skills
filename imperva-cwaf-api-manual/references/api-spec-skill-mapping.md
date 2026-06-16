# api-spec → Skill Mapping

This file maps API specification files to the skills that use them.
Used by the watcher's API Update Monitor workflow to identify affected skills
when release notes indicate API changes.

## Mapping Table

| api-spec file | Affected Skill(s) | API Base Path |
|---|---|---|
| site_management.yaml | imperva-cwaf-get-site-detail, imperva-cwaf-site-onboard | /api/prov/v1 |
| policies-api.yaml | imperva-cwaf-policy-management | /api/prov/v1 |
| rules.yaml | imperva-cwaf-custom-rule | /api/prov/v1 |
| cache-api.yaml | imperva-cwaf-cache | /api/prov/v1 |
| certificatesUI-api.yaml | imperva-cwaf-ssl-management | /certificates-ui/v3 |
| custom_certificate.yaml | imperva-cwaf-ssl-management | /api/prov/v1 |
| website-management-api.yaml | imperva-cwaf-ssl-management, imperva-cwaf-basic-security | /sites-mgmt/v3 |
| load-balancing-api.yaml | imperva-cwaf-lb-delivery | /api/prov/v1 |
| performance-statistics-api.json | imperva-cwaf-troubleshoot | /appdlv-dashboards-ui |
| delivery-api.yaml | imperva-cwaf-basic-security | /api/prov/v1 |
| attack-analytics-api.yaml | imperva-cwaf-troubleshoot | /api/prov/v1 |
| reputation-intelligence-api.yaml | imperva-cwaf-stats-and-visits | /ip-reputation |
| integrations.yaml | imperva-cwaf-api-manual | /api/prov/v1 |
| troubleshooting-api.yaml | imperva-cwaf-troubleshoot | /api/prov/v1 |
| traffic_statistics_and_logs.yaml | imperva-cwaf-stats-and-visits | /api/prov/v1 |
| session-release-api.yaml | imperva-cwaf-policy-management | /api/prov/v1 |
| imperva_rule_filters.json | imperva-cwaf-policy-management, imperva-cwaf-custom-rule | N/A (reference data) |
| website-monitoring-api.yaml | imperva-cwaf-status-check, imperva-cwaf-troubleshoot | /api/prov/v1 |
| basic-api-security-swagger.yaml | imperva-cwaf-basic-security | /api-security/v1 |

## How to Update

When a new API spec is added or an existing one changes:
1. Add/update the row above
2. Update the affected skill's SKILL.md with new endpoints/params
3. Bump the skill's version
4. Git commit + push

## See Also

- imperva-cwaf-api-manual/SKILL.md — How to browse and search api-spec files
- devops/watcher/references/imperva-cwaf-api-monitor-workflow.md — Full monitoring workflow
