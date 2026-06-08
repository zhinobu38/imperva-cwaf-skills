# Imperva Cloud WAF API Specification Overview

This document provides a brief overview of the various API specification files available in the reference directory.

## API Specification Files

### Site Management
- `site_management.yaml` - Site management API (list sites, get site details, update sites, delete sites)

### Security Policies
- `policies-api.yaml` - Security policies management (create, update, delete, list policies)
- `rules.yaml` - Security rules management within policies

### Certificates & SSL
- `certificatesUI-api.yaml` - Certificate management UI API
- `custom_certificate.yaml` - Custom certificate operations

### Traffic & Performance
- `traffic_statistics_and_logs.yaml` - Traffic statistics and logs API
- `performance-statistics-api.json` - Performance statistics API
- `load-balancing-api.yaml` - Load balancing configuration

### Security Intelligence
- `reputation-intelligence-api.yaml` - IP reputation and threat intelligence
- `attack-analytics-api.yaml` - Attack analytics and reporting
- `cache-api.yaml` - Caching configuration and statistics

### Website Management
- `website-management-api.yaml` - Website configuration and management
- `website-monitoring-api.yaml` - Website monitoring and health checks

### Delivery & Integration
- `delivery-api.yaml` - Content delivery network settings
- `integrations.yaml` - Third-party integrations and webhooks

### Session Management
- `session-release-api.yaml` - Session management and release controls

### Troubleshooting
- `troubleshooting-api.yaml` - Diagnostic and troubleshooting endpoints

## Common Patterns

Most APIs follow these patterns:
- Base URL: `https://api.imperva.com` or `https://my.imperva.com`
- Authentication: `x-API-Id` and `x-API-Key` headers
- Common parameters: `caid` (account ID) is frequently required
- Response formats: JSON with standard HTTP status codes
- Pagination: Many list endpoints use `size` and `page` parameters

## Using the Specs

Each file is in OpenAPI 3.0 (YAML or JSON) format and contains:
- Endpoints (paths) with HTTP methods
- Request parameters (path, query, header, body)
- Response schemas and examples
- Error responses
- Security requirements

To understand a specific endpoint:
1. Find the relevant spec file (see list above)
2. Locate the path and method for the operation
3. Review required parameters and request body schema
4. Check response codes and schemas
5. Note any authentication requirements

## Related Skills

For making actual API calls, see:
- `imperva-cwaf-get-site-detail` - For site management operations
- `imperva-cwaf-site-onboard` - For onboarding new websites
- `imperva-cwaf-status-check` - For checking service status