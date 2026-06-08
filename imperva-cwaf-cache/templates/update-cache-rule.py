#!/usr/bin/env python3
"""
Update a Cache Rule via Imperva Cache API.
Usage: Set SITE_ID and RULE_ID env vars, then run via bws run.

IMPORTANT: This sends the FULL rule object. Modify the fields you want to change.
"""
import os, json, urllib.request, ssl

site_id = os.environ["SITE_ID"]
rule_id = os.environ["RULE_ID"]
api_id = os.environ["IMPERVA_API_ID"]
api_key = os.environ["IMPERVA_API_KEY"]

url = f"https://my.imperva.com/api/prov/v2/sites/{site_id}/settings/cache/rules/{rule_id}"

# IMPORTANT: Send the FULL rule object, not just changed fields
rule_data = {
    "name": "Cache Static Assets",
    "action": "HTTP_CACHE_MAKE_STATIC",
    "enabled": False,   # <-- change this
    "filter": "URL contains \".css\" | URL contains \".js\" | URL contains \".png\"",
    "ttl": 86400
}

data = json.dumps(rule_data).encode()
req = urllib.request.Request(url, data=data, method="PUT")
req.add_header("Accept", "application/json")
req.add_header("x-API-Id", api_id)
req.add_header("x-API-Key", api_key)
req.add_header("Content-Type", "application/json")
req.add_header("Force-Risky-Operation", "true")

ctx = ssl.create_default_context()
resp = urllib.request.urlopen(req, context=ctx, timeout=15)
body = json.loads(resp.read().decode())
print(json.dumps(body, indent=2))

if body.get("res") == 0:
    print("\nRule updated successfully.")
else:
    print(f"\nError: {body.get('res_message', 'Unknown error')}")
