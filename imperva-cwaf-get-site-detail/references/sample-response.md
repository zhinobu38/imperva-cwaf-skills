# Sample API Response from Imperva CWAF Sites Management API

Actual response captured during testing on 2026-05-30 for account ID <YOUR_CAID>.

```json
{
  "data": [
    {
      "id": xxxxxxx,
      "name": "thegreat.impervamtth.com",
      "type": "CLOUD_WAF",
      "active": true,
      "accountId": <YOUR_CAID>,
      "creationTime": 1780120010463,
      "cname": "xxx.ng.impervadns.net",
      "siteStatus": "NOT_CONFIGURED"
    },
    {
      "id": xxxxxxx,
      "name": "agent2.impervamtth.com",
      "type": "CLOUD_WAF",
      "active": true,
      "accountId": <YOUR_CAID>,
      "creationTime": 1780120640956,
      "cname": "xxx.ng.impervadns.net",
      "siteStatus": "ACTIVE"
    },
    {
      "id": <EXAMPLE_SITE_ID>,
      "name": "testagent.xxx.com",
      "type": "CLOUD_WAF",
      "active": true,
      "accountId": <YOUR_CAID>,
      "creationTime": 1780117269272,
      "cname": "xxx.ng.impervadns.net",
      "siteStatus": "NOT_CONFIGURED"
    }
  ],
  "meta": {
    "totalElements": 3,
    "totalPages": 1,
    "size": 100,
    "page": 0
  },
  "links": {
    "self": "https://api.imperva.com/sites-mgmt/v3/sites?caid=<YOUR_CAID>&page=0&size=100"
  }
}
```