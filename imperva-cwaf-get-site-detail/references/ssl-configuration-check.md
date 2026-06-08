# SSL Configuration Checking for Imperva CWAF Sites

When checking SSL configuration for a site in Imperva Cloud WAF, note the following:

1. **Site Status Matters**: Sites with `siteStatus: "NOT_CONFIGURED"` may not have SSL configuration details available in the site details response.

2. **SSL Information Location**: When available, SSL details are typically found in an `ssl` field within the site object, containing information such as:
   - Certificate details (if uploaded)
   - TLS version settings
   - HTTPS enforcement configuration
   - Certificate expiration dates

3. **Checking SSL Status**:
   - First, retrieve site details using the get site endpoint
   - Check if `siteStatus` is `ACTIVE` or similar configured state
   - Look for the `ssl` field in the response
   - If `ssl` field is absent or empty, SSL may not be configured

4. **Common SSL Configuration States**:
   - Not configured: No SSL field or empty SSL object
   - Configured: SSL field contains certificate and settings information
   - Expired: Certificate present but past expiration date
   - Pending: Certificate uploaded but not yet activated

5. **API Limitations**: The Sites Management API may not return detailed SSL information in the basic site details endpoint. For comprehensive SSL management, you may need to use dedicated SSL/certificate management endpoints if available in your Imperva API version.

6. **Troubleshooting Empty SSL Response**:
   - Verify the site is in an active configured state
   - Check if SSL certificates have been uploaded via the Imperva dashboard or API
   - Ensure your API credentials have permissions to read SSL configuration
   - Consider that some SSL information may only be available through specific SSL management endpoints

This guidance is based on actual API responses where sites in `NOT_CONFIGURED` state did not return SSL configuration details in the site objects.