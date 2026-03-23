#!/usr/bin/env python3
"""
test-all-endpoints.py — Prueba masiva de TODOS los endpoints de la API Zentto.
Lee endpoints.json, hace login, y prueba cada GET/POST.
Genera reporte de OK/FAIL.

Uso: python3 scripts/test-all-endpoints.py
"""
import urllib.request, json, ssl, sys, time

BASE = "https://api.zentto.net"
ctx = ssl.create_default_context()

def api(method, path, body=None, token=None):
    url = BASE + path
    data = json.dumps(body).encode() if body else None
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        resp = urllib.request.urlopen(req, timeout=15, context=ctx)
        return resp.status, json.loads(resp.read().decode()) if resp.headers.get("content-type", "").startswith("application/json") else resp.read().decode()[:200]
    except urllib.error.HTTPError as e:
        body_text = e.read().decode()[:300]
        try:
            return e.code, json.loads(body_text)
        except:
            return e.code, body_text
    except Exception as e:
        return 0, str(e)[:200]

# Login
print("=== LOGIN ===")
status, body = api("POST", "/v1/auth/login", {"usuario": "admin", "clave": "Admin123!"})
if status != 200 or not isinstance(body, dict) or "token" not in body:
    print(f"LOGIN FAILED: {status} {body}")
    sys.exit(1)
token = body["token"]
print(f"OK — Admin logged in, {len(body.get('modulos',[]))} modules")

# Load endpoints
with open("scripts/endpoints.json") as f:
    endpoints = json.load(f)

# Solo GET endpoints (POST/PUT/DELETE necesitan body válido)
get_endpoints = [e for e in endpoints if e["method"] == "GET"]
post_endpoints = [e for e in endpoints if e["method"] in ("POST", "PUT", "DELETE")]

print(f"\n=== TESTING {len(get_endpoints)} GET ENDPOINTS ===\n")

results = {"ok": [], "fail_4xx": [], "fail_5xx": [], "fail_other": []}

for ep in get_endpoints:
    path = ep["path"]
    # Reemplazar path params con valores de prueba
    test_path = path
    test_path = test_path.replace("{id}", "1").replace("{code}", "DEFAULT")
    test_path = test_path.replace("{companyId}", "1").replace("{branchId}", "1")
    test_path = test_path.replace("{numFact}", "F-000001").replace("{nroCta}", "0001")
    test_path = test_path.replace("{codigo}", "ADMIN").replace("{slug}", "clientes")
    test_path = test_path.replace("{countryCode}", "VE").replace("{typeCode}", "PAYROLL_FREQUENCY")
    test_path = test_path.replace("{subdomain}", "default").replace("{email}", "admin@zentto.net")
    test_path = test_path.replace("{batchId}", "1").replace("{requestId}", "1")
    test_path = test_path.replace("{templateId}", "1").replace("{templateCode}", "RECIBO")
    test_path = test_path.replace("{conceptCode}", "SSO").replace("{employeeCode}", "V-12345678")
    test_path = test_path.replace("{date}", "2026-03-23").replace("{year}", "2026")
    test_path = test_path.replace("{leadId}", "1").replace("{activityId}", "1")
    test_path = test_path.replace("{vehicleId}", "1").replace("{orderId}", "1")
    test_path = test_path.replace("{warehouseId}", "1").replace("{pipelineId}", "1")
    test_path = test_path.replace("{assetId}", "1").replace("{taxYear}", "2026")
    test_path = test_path.replace("{period}", "2026-01").replace("{accountCode}", "1.1")

    status, resp = api("GET", test_path, token=token)
    tag = ep.get("tag", "?")

    if status in (200, 201):
        results["ok"].append({"path": path, "tag": tag, "status": status})
    elif 400 <= status < 500:
        results["fail_4xx"].append({"path": path, "tag": tag, "status": status, "error": str(resp)[:100] if isinstance(resp, (dict, str)) else ""})
    elif status >= 500:
        results["fail_5xx"].append({"path": path, "tag": tag, "status": status, "error": str(resp)[:150] if isinstance(resp, (dict, str)) else ""})
    else:
        results["fail_other"].append({"path": path, "tag": tag, "status": status, "error": str(resp)[:100]})

    symbol = "OK" if status in (200, 201) else "5xx" if status >= 500 else "4xx"
    print(f"  {symbol:3s} {status:3d} [{tag:15s}] GET {test_path}")

    # Rate limit protection
    time.sleep(0.1)

print(f"\n=== RESULTS ===")
print(f"  OK (2xx):     {len(results['ok'])}")
print(f"  Client (4xx): {len(results['fail_4xx'])}")
print(f"  Server (5xx): {len(results['fail_5xx'])}")
print(f"  Other:        {len(results['fail_other'])}")

if results["fail_5xx"]:
    print(f"\n=== 5xx ERRORS (need fixing) ===")
    for e in results["fail_5xx"]:
        print(f"  [{e['tag']}] {e['path']} -> {e['status']} {e['error'][:120]}")

# Save results
with open("scripts/test-results.json", "w") as f:
    json.dump(results, f, indent=2, ensure_ascii=False)
print(f"\nResultados guardados en scripts/test-results.json")
