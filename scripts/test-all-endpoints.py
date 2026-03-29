#!/usr/bin/env python3
"""
test-all-endpoints.py — Prueba masiva de TODOS los endpoints de la API Zentto.
Fase 1: Login + discovery (obtener IDs reales de la BD).
Fase 2: Test de todos los GET endpoints con datos reales + query params.
Genera reporte de OK/FAIL.

Uso: python3 scripts/test-all-endpoints.py
"""
import urllib.request, json, ssl, sys, time

BASE = "https://api.zentto.net"
ctx = ssl.create_default_context()
TIMEOUT = 30  # segundos

def api(method, path, body=None, token=None):
    url = BASE + path
    data = json.dumps(body).encode() if body else None
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        resp = urllib.request.urlopen(req, timeout=TIMEOUT, context=ctx)
        ct = resp.headers.get("content-type", "")
        raw = resp.read().decode()
        if ct.startswith("application/json"):
            return resp.status, json.loads(raw)
        return resp.status, raw[:300]
    except urllib.error.HTTPError as e:
        body_text = e.read().decode()[:500]
        try:
            return e.code, json.loads(body_text)
        except:
            return e.code, body_text
    except Exception as e:
        return 0, str(e)[:300]

# =============================================
# FASE 0: LOGIN
# =============================================
print("=== FASE 0: LOGIN ===")
status, body = api("POST", "/v1/auth/login", {"usuario": "admin", "clave": "Admin123!"})
if status != 200 or not isinstance(body, dict) or "token" not in body:
    print(f"LOGIN FAILED: {status} {body}")
    sys.exit(1)
token = body["token"]
user_id = body.get("userId", body.get("id", None))
print(f"OK — Admin logged in, userId={user_id}, {len(body.get('modulos',[]))} modules")

# =============================================
# FASE 1: DISCOVERY — obtener IDs reales
# =============================================
print("\n=== FASE 1: DISCOVERY ===")

def discover(path, id_field, label=""):
    """Fetch list endpoint and extract first ID."""
    s, b = api("GET", path, token=token)
    if s == 200 and isinstance(b, (list, dict)):
        rows = b if isinstance(b, list) else b.get("rows", b.get("data", b.get("items", [])))
        if isinstance(rows, list) and len(rows) > 0:
            val = rows[0].get(id_field) or rows[0].get(id_field.lower()) or rows[0].get(id_field[0].upper() + id_field[1:])
            if val is not None:
                print(f"  OK {label or path}: {id_field}={val}")
                return val
    print(f"  -- {label or path}: no data")
    return None

# Discover real IDs from list endpoints
ids = {}
ids["proveedor"] = discover("/v1/proveedores", "codProveedor", "proveedores")
ids["articulo"] = discover("/v1/articulos", "codArticulo", "articulos")
ids["inventario"] = discover("/v1/inventario", "codArticulo", "inventario")
ids["abono_id"] = discover("/v1/abonos", "id", "abonos")
ids["pago_id"] = discover("/v1/pagos", "id", "pagos")
ids["pagoc_id"] = discover("/v1/pagosc", "id", "pagosc")
ids["abonopago_id"] = discover("/v1/abonospagos", "id", "abonospagos")
ids["cxp_id"] = discover("/v1/cuentas-por-pagar", "id", "cuentas-por-pagar")
ids["retencion"] = discover("/v1/retenciones", "codRetencion", "retenciones")
ids["movinvent_id"] = discover("/v1/movinvent", "id", "movinvent")
ids["vendedor"] = discover("/v1/vendedores", "codVendedor", "vendedores")
ids["centro_costo"] = discover("/v1/centro-costo", "codCentro", "centro-costo")
ids["empleado_cedula"] = discover("/v1/empleados", "cedula", "empleados")
ids["cuenta_contable"] = discover("/v1/contabilidad/cuentas", "codCuenta", "contabilidad/cuentas")
ids["asiento_id"] = discover("/v1/contabilidad/asientos", "id", "contabilidad/asientos")
ids["batch_id"] = discover("/v1/nomina/batch", "id", "nomina/batch")
ids["usuario_code"] = discover("/v1/usuarios", "codUsuario", "usuarios")
ids["banco_nro_cta"] = discover("/v1/bancos/cuentas/list", "nroCta", "bancos/cuentas")
ids["conciliacion_id"] = discover("/v1/bancos/conciliaciones", "id", "conciliaciones")
ids["caja_chica_id"] = discover("/v1/bancos/caja-chica", "Id", "caja-chica")
ids["auditoria_id"] = discover("/v1/auditoria/logs", "id", "auditoria")
ids["vacacion_sol_id"] = discover("/v1/nomina/vacaciones/solicitudes", "id", "vacaciones/solicitudes")
ids["vacacion_id"] = discover("/v1/nomina/vacaciones/list", "id", "vacaciones/list")
ids["liquidacion_id"] = discover("/v1/nomina/liquidaciones/list", "id", "liquidaciones")
ids["utilidades_id"] = discover("/v1/rrhh/utilidades", "id", "utilidades")
ids["filing_id"] = discover("/v1/rrhh/obligaciones/filings", "id", "obligaciones/filings")
ids["salud_id"] = discover("/v1/rrhh/salud-ocupacional", "id", "salud-ocupacional")
ids["comite_id"] = discover("/v1/rrhh/comites", "id", "comites")
ids["ticket_number"] = discover("/v1/support/tickets", "number", "tickets")
ids["cxc_cliente"] = discover("/v1/cxc/documentos", "codCliente", "cxc/documentos")
ids["cxp_proveedor"] = discover("/v1/cxp/documentos", "codProveedor", "cxp/documentos")

# Try empresa
s, b = api("GET", "/v1/empresa", token=token)
if s == 200:
    ids["empresa_id"] = b.get("id") or b.get("CompanyId") or 1
    print(f"  OK empresa: id={ids['empresa_id']}")
else:
    ids["empresa_id"] = 1

# Try clientes
s, b = api("GET", "/v1/clientes?page=1&limit=1", token=token)
if s == 200:
    rows = b if isinstance(b, list) else b.get("rows", [])
    if rows:
        ids["cliente"] = rows[0].get("codCliente", rows[0].get("codigo"))
        print(f"  OK clientes: codCliente={ids.get('cliente')}")

# Build employee code from empleados
if ids.get("empleado_cedula"):
    ids["employee_code"] = ids["empleado_cedula"]

print(f"\n  Discovery complete: {sum(1 for v in ids.values() if v is not None)}/{len(ids)} IDs found")

# =============================================
# FASE 2: TEST ALL ENDPOINTS
# =============================================
# Load endpoints
with open("scripts/endpoints.json") as f:
    endpoints = json.load(f)

get_endpoints = [e for e in endpoints if e["method"] == "GET"]

# Rutas legacy eliminadas de endpoints.json — ya no se prueban
LEGACY_ROUTES = set()

# Endpoints que necesitan query params específicos
QUERY_PARAMS = {
    "/v1/contabilidad/reportes/libro-mayor": "?fechaDesde=2026-01-01&fechaHasta=2026-03-23&codCuenta=1.1",
    "/v1/contabilidad/reportes/mayor-analitico": "?fechaDesde=2026-01-01&fechaHasta=2026-03-23&codCuenta=1.1",
    "/v1/contabilidad/reportes/balance-comprobacion": "?fechaDesde=2026-01-01&fechaHasta=2026-03-23",
    "/v1/contabilidad/reportes/estado-resultados": "?fechaDesde=2026-01-01&fechaHasta=2026-03-23",
    "/v1/contabilidad/reportes/balance-general": "?fechaCorte=2026-03-23",
    "/v1/payments/config": "?empresaId=1",
    "/v1/payments/accepted": "?empresaId=1",
    "/v1/payments/card-readers": "?empresaId=1",
    "/v1/payments/transactions": "?empresaId=1",
    "/v1/auditoria/dashboard": "?fechaDesde=2026-01-01&fechaHasta=2026-03-23",
    "/v1/documentos-venta": "?tipoOperacion=FACTURA",
    "/v1/rrhh/fideicomiso/summary": "?year=2026&quarter=1",
    "/v1/clientes": "?page=1&limit=5",
    "/v1/movinvent/mes/list": "?periodo=2026-03&page=1&limit=5",
}

# Endpoints que no se pueden probar (necesitan token especial, datos POST, etc.)
SKIP_ENDPOINTS = {
    "/v1/auth/verify-email",       # necesita token de email real
    "/v1/integrations/zoho/callback",  # necesita auth code de Zoho
    "/v1/devices/my",              # necesita userId válido del JWT (admin test no tiene sub numérico)
}

print(f"\n=== FASE 2: TESTING {len(get_endpoints)} GET ENDPOINTS ===\n")

results = {"ok": [], "fail_4xx": [], "fail_5xx": [], "fail_other": [], "skipped": [], "legacy": []}

for ep in get_endpoints:
    path = ep["path"]
    tag = ep.get("tag", "?")

    # Skip endpoints que no se pueden probar
    if path in SKIP_ENDPOINTS:
        results["skipped"].append({"path": path, "tag": tag, "reason": "needs special auth/data"})
        print(f"  SKP     [{tag:15s}] GET {path}")
        continue

    # Legacy routes
    if path in LEGACY_ROUTES:
        results["legacy"].append({"path": path, "tag": tag})
        print(f"  OLD     [{tag:15s}] GET {path} (legacy)")
        continue

    # Build test path with real IDs
    test_path = path

    # Path param replacements using discovered IDs
    if ids.get("proveedor"):
        test_path = test_path.replace("{codigo}", str(ids["proveedor"]))
    else:
        test_path = test_path.replace("{codigo}", "ADMIN")

    if ids.get("abono_id"):
        # Only replace {id} if this is the abonos path
        pass  # handled below per-route

    # Smart {id} replacement based on route context
    if "{id}" in test_path:
        if "/abonos/" in path:
            test_path = test_path.replace("{id}", str(ids.get("abono_id") or 1))
        elif "/pagos/" in path and "pagosc" not in path:
            test_path = test_path.replace("{id}", str(ids.get("pago_id") or 1))
        elif "/pagosc/" in path:
            test_path = test_path.replace("{id}", str(ids.get("pagoc_id") or 1))
        elif "/abonospagos/" in path:
            test_path = test_path.replace("{id}", str(ids.get("abonopago_id") or 1))
        elif "/cuentas-por-pagar/" in path:
            test_path = test_path.replace("{id}", str(ids.get("cxp_id") or 1))
        elif "/contabilidad/asientos/" in path:
            test_path = test_path.replace("{id}", str(ids.get("asiento_id") or 1))
        elif "/nomina/batch/" in path:
            test_path = test_path.replace("{id}", str(ids.get("batch_id") or 1))
        elif "/nomina/vacaciones/solicitudes/" in path:
            test_path = test_path.replace("{id}", str(ids.get("vacacion_sol_id") or 1))
        elif "/nomina/vacaciones/" in path:
            test_path = test_path.replace("{id}", str(ids.get("vacacion_id") or 1))
        elif "/nomina/liquidaciones/" in path:
            test_path = test_path.replace("{id}", str(ids.get("liquidacion_id") or 1))
        elif "/rrhh/utilidades/" in path:
            test_path = test_path.replace("{id}", str(ids.get("utilidades_id") or 1))
        elif "/rrhh/obligaciones/filings/" in path:
            test_path = test_path.replace("{id}", str(ids.get("filing_id") or 1))
        elif "/rrhh/salud-ocupacional/" in path:
            test_path = test_path.replace("{id}", str(ids.get("salud_id") or 1))
        elif "/auditoria/logs/" in path:
            test_path = test_path.replace("{id}", str(ids.get("auditoria_id") or 1))
        elif "/bancos/conciliaciones/" in path:
            test_path = test_path.replace("{id}", str(ids.get("conciliacion_id") or 1))
        elif "/bancos/movimientos/" in path:
            test_path = test_path.replace("{id}", "1")
        else:
            test_path = test_path.replace("{id}", "1")

    # Other path params
    test_path = test_path.replace("{code}", str(ids.get("usuario_code") or "DEFAULT"))
    test_path = test_path.replace("{companyId}", "1").replace("{branchId}", "1")
    test_path = test_path.replace("{numFact}", "F-000001")
    test_path = test_path.replace("{nroCta}", str(ids.get("banco_nro_cta") or "0001"))
    test_path = test_path.replace("{countryCode}", "VE").replace("{typeCode}", "PAYROLL_FREQUENCY")
    test_path = test_path.replace("{subdomain}", "default").replace("{email}", "admin@zentto.net")
    test_path = test_path.replace("{batchId}", str(ids.get("batch_id") or 1))
    test_path = test_path.replace("{requestId}", "1")
    test_path = test_path.replace("{templateId}", "1").replace("{templateCode}", "RECIBO")
    test_path = test_path.replace("{conceptCode}", "SSO")
    test_path = test_path.replace("{employeeCode}", str(ids.get("employee_code") or "V-12345678"))
    test_path = test_path.replace("{cedula}", str(ids.get("empleado_cedula") or "V-12345678"))
    test_path = test_path.replace("{date}", "2026-03-23").replace("{year}", "2026")
    test_path = test_path.replace("{leadId}", "1").replace("{activityId}", "1")
    test_path = test_path.replace("{vehicleId}", "1").replace("{orderId}", "1")
    test_path = test_path.replace("{warehouseId}", "1").replace("{pipelineId}", "1")
    test_path = test_path.replace("{assetId}", "1").replace("{taxYear}", "2026")
    test_path = test_path.replace("{employeeId}", "1")
    test_path = test_path.replace("{committeeId}", str(ids.get("comite_id") or 1))
    test_path = test_path.replace("{boxId}", str(ids.get("caja_chica_id") or 1))
    test_path = test_path.replace("{entityType}", "product").replace("{entityId}", "1")
    test_path = test_path.replace("{tipoOperacion}", "FACTURA").replace("{module}", "general")
    test_path = test_path.replace("{period}", "2026-01").replace("{accountCode}", str(ids.get("cuenta_contable") or "1.1"))
    test_path = test_path.replace("{number}", str(ids.get("ticket_number") or "1"))
    test_path = test_path.replace("{codCliente}", str(ids.get("cxc_cliente") or "CLI001"))
    test_path = test_path.replace("{codProveedor}", str(ids.get("cxp_proveedor") or "PROV001"))
    test_path = test_path.replace("{codCuenta}", str(ids.get("cuenta_contable") or "1.1"))
    test_path = test_path.replace("{table}", "cfg.Country").replace("{key}", "VE")

    # Add query params if needed
    if path in QUERY_PARAMS:
        test_path += QUERY_PARAMS[path]

    # Execute
    status, resp = api("GET", test_path, token=token)

    if status in (200, 201):
        results["ok"].append({"path": path, "tag": tag, "status": status})
    elif 400 <= status < 500:
        results["fail_4xx"].append({"path": path, "tag": tag, "status": status,
            "testPath": test_path,
            "error": str(resp)[:150] if isinstance(resp, (dict, str)) else ""})
    elif status >= 500:
        results["fail_5xx"].append({"path": path, "tag": tag, "status": status,
            "testPath": test_path,
            "error": str(resp)[:200] if isinstance(resp, (dict, str)) else ""})
    else:
        results["fail_other"].append({"path": path, "tag": tag, "status": status,
            "testPath": test_path,
            "error": str(resp)[:150]})

    symbol = "OK" if status in (200, 201) else "5xx" if status >= 500 else "4xx" if 400 <= status < 500 else "TMO"
    print(f"  {symbol:3s} {status:3d} [{tag:15s}] GET {test_path}")

    time.sleep(0.1)

# =============================================
# REPORT
# =============================================
print(f"\n{'='*60}")
print(f"=== RESULTS ===")
print(f"  OK (2xx):     {len(results['ok'])}")
print(f"  Client (4xx): {len(results['fail_4xx'])}")
print(f"  Server (5xx): {len(results['fail_5xx'])}")
print(f"  Timeout/Err:  {len(results['fail_other'])}")
print(f"  Skipped:      {len(results['skipped'])}")
print(f"  Legacy:       {len(results['legacy'])}")
total_testable = len(get_endpoints) - len(results["skipped"]) - len(results["legacy"])
pct = len(results["ok"]) / total_testable * 100 if total_testable > 0 else 0
print(f"  Coverage:     {len(results['ok'])}/{total_testable} ({pct:.1f}%)")

if results["fail_5xx"]:
    print(f"\n=== 5xx ERRORS (need fixing) ===")
    for e in results["fail_5xx"]:
        print(f"  [{e['tag']}] {e['path']}")
        print(f"    tested: {e.get('testPath','')}")
        print(f"    error:  {e['error'][:120]}")

if results["fail_4xx"]:
    print(f"\n=== 4xx ERRORS (need data/params) ===")
    for e in results["fail_4xx"]:
        print(f"  {e['status']} [{e['tag']}] {e.get('testPath', e['path'])[:70]}  {e['error'][:80]}")

if results["fail_other"]:
    print(f"\n=== TIMEOUTS / CONNECTION ERRORS ===")
    for e in results["fail_other"]:
        print(f"  [{e['tag']}] {e.get('testPath', e['path'])[:70]}  {e['error'][:80]}")

# Save results
with open("scripts/test-results.json", "w") as f:
    json.dump(results, f, indent=2, ensure_ascii=False)
print(f"\nResultados guardados en scripts/test-results.json")
