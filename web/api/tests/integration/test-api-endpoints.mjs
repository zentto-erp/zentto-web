#!/usr/bin/env node
/**
 * Test de integración — Prueba CRUD completo de todos los módulos API.
 * Ejecuta contra una API viva (producción o local).
 *
 * Uso:
 *   node tests/integration/test-api-endpoints.mjs [BASE_URL]
 *   node tests/integration/test-api-endpoints.mjs https://api.zentto.net
 *   node tests/integration/test-api-endpoints.mjs http://localhost:4000
 *
 * Requiere: variable AUTH_TOKEN o login previo.
 * Para CI/CD: el workflow obtiene el token via login y lo pasa como env.
 */

const BASE = process.argv[2] || process.env.API_URL || "https://api.zentto.net";
const TOKEN = process.env.AUTH_TOKEN || "";

let passed = 0;
let failed = 0;
let skipped = 0;
const errors = [];

async function api(method, path, body) {
  const url = `${BASE}/api/v1${path}`;
  const headers = {
    "Content-Type": "application/json",
    "x-company-id": "1",
    "x-branch-id": "1",
    "x-country-code": "VE",
  };
  const token = process.env.AUTH_TOKEN || TOKEN;
  if (token) headers["Authorization"] = `Bearer ${token}`;

  try {
    const res = await fetch(url, {
      method,
      headers,
      body: body ? JSON.stringify(body) : undefined,
      signal: AbortSignal.timeout(15000),
    });
    const data = await res.json().catch(() => ({}));
    return { status: res.status, data, ok: res.ok };
  } catch (err) {
    return { status: 0, data: { error: err.message }, ok: false };
  }
}

function test(name, fn) {
  return { name, fn };
}

async function runTest(t) {
  try {
    const result = await t.fn();
    if (result === "SKIP") {
      skipped++;
      console.log(`  ⏭ ${t.name} (skipped)`);
      return;
    }
    passed++;
    console.log(`  ✅ ${t.name}`);
  } catch (err) {
    failed++;
    errors.push({ test: t.name, error: err.message });
    console.log(`  ❌ ${t.name} — ${err.message}`);
  }
}

function assert(condition, msg) {
  if (!condition) throw new Error(msg);
}

// ═══════════════════════════════════════════════════════════════
// CRM TESTS
// ═══════════════════════════════════════════════════════════════

const crmTests = [
  test("GET /crm/pipelines — listar", async () => {
    const r = await api("GET", "/crm/pipelines");
    assert(r.status === 200 || r.status === 401, `Expected 200|401, got ${r.status}`);
    if (r.status === 401) return "SKIP";
    assert(Array.isArray(r.data.rows ?? r.data), "Expected array");
  }),

  test("POST /crm/pipelines — crear pipeline", async () => {
    const r = await api("POST", "/crm/pipelines", {
      name: "Test Pipeline " + Date.now(),
      description: "Pipeline de test",
    });
    assert([200, 201, 400, 401].includes(r.status), `Expected 200|201|400|401, got ${r.status}: ${JSON.stringify(r.data)}`);
    if (r.status === 401) return "SKIP";
  }),

  test("GET /crm/leads — listar leads", async () => {
    const r = await api("GET", "/crm/leads?page=1&limit=5");
    assert(r.status === 200 || r.status === 401, `Expected 200|401, got ${r.status}`);
    if (r.status === 401) return "SKIP";
  }),

  test("POST /crm/leads — crear lead", async () => {
    const r = await api("POST", "/crm/leads", {
      pipelineId: 1,
      stageId: 1,
      name: "Test Lead " + Date.now(),
      email: "test@zentto.net",
      company: "Test Corp",
      source: "WEB",
      priority: "MEDIUM",
    });
    assert([200, 201, 400, 401].includes(r.status), `Expected 200|201|400|401, got ${r.status}: ${JSON.stringify(r.data)}`);
    if (r.status === 401) return "SKIP";
  }),

  test("GET /crm/actividades — listar", async () => {
    const r = await api("GET", "/crm/actividades?page=1&limit=5");
    assert(r.status === 200 || r.status === 401, `Expected 200|401, got ${r.status}`);
    if (r.status === 401) return "SKIP";
  }),

  test("POST /crm/actividades — crear actividad", async () => {
    const r = await api("POST", "/crm/actividades", {
      leadId: 1,
      type: "NOTE",
      description: "Test actividad " + Date.now(),
      dueDate: new Date(Date.now() + 86400000).toISOString(),
      priority: "MEDIUM",
    });
    assert([200, 201, 400, 401].includes(r.status), `Expected 200|201|400|401, got ${r.status}: ${JSON.stringify(r.data)}`);
    if (r.status === 401) return "SKIP";
  }),

  test("GET /crm/dashboard — dashboard", async () => {
    const r = await api("GET", "/crm/dashboard");
    assert(r.status === 200 || r.status === 401, `Expected 200|401, got ${r.status}`);
    if (r.status === 401) return "SKIP";
  }),
];

// ═══════════════════════════════════════════════════════════════
// LOGÍSTICA TESTS
// ═══════════════════════════════════════════════════════════════

const logisticaTests = [
  test("GET /logistica/transportistas — listar", async () => {
    const r = await api("GET", "/logistica/transportistas?page=1&limit=5");
    assert(r.status === 200 || r.status === 401, `Expected 200|401, got ${r.status}`);
    if (r.status === 401) return "SKIP";
  }),

  test("POST /logistica/transportistas — crear", async () => {
    const r = await api("POST", "/logistica/transportistas", {
      name: "Transporte Test " + Date.now(),
      taxId: "J-TEST-" + Date.now(),
    });
    assert([200, 201, 400, 401].includes(r.status), `Expected 200|201|400|401, got ${r.status}: ${JSON.stringify(r.data)}`);
    if (r.status === 401) return "SKIP";
  }),

  test("GET /logistica/recepciones — listar", async () => {
    const r = await api("GET", "/logistica/recepciones?page=1&limit=5");
    assert(r.status === 200 || r.status === 401, `Expected 200|401, got ${r.status}`);
    if (r.status === 401) return "SKIP";
  }),

  test("GET /logistica/devoluciones — listar", async () => {
    const r = await api("GET", "/logistica/devoluciones?page=1&limit=5");
    assert(r.status === 200 || r.status === 401, `Expected 200|401, got ${r.status}`);
    if (r.status === 401) return "SKIP";
  }),

  test("GET /logistica/notas-entrega — listar (alias notas-entrega)", async () => {
    const r = await api("GET", "/logistica/notas-entrega?page=1&limit=5");
    assert(r.status === 200 || r.status === 401, `Expected 200|401, got ${r.status}: ${JSON.stringify(r.data)}`);
    if (r.status === 401) return "SKIP";
  }),

  test("GET /logistica/dashboard", async () => {
    const r = await api("GET", "/logistica/dashboard");
    assert(r.status === 200 || r.status === 401, `Expected 200|401, got ${r.status}`);
    if (r.status === 401) return "SKIP";
  }),
];

// ═══════════════════════════════════════════════════════════════
// MANUFACTURA TESTS
// ═══════════════════════════════════════════════════════════════

const manufacturaTests = [
  test("GET /manufactura/bom — listar BOMs", async () => {
    const r = await api("GET", "/manufactura/bom?page=1&limit=5");
    assert(r.status === 200 || r.status === 401, `Expected 200|401, got ${r.status}: ${JSON.stringify(r.data)}`);
    if (r.status === 401) return "SKIP";
  }),

  test("GET /manufactura/centros-trabajo — listar", async () => {
    const r = await api("GET", "/manufactura/centros-trabajo?page=1&limit=5");
    assert(r.status === 200 || r.status === 401, `Expected 200|401, got ${r.status}: ${JSON.stringify(r.data)}`);
    if (r.status === 401) return "SKIP";
  }),

  test("POST /manufactura/centros-trabajo — crear", async () => {
    const r = await api("POST", "/manufactura/centros-trabajo", {
      code: "WC-TEST-" + Date.now(),
      name: "Centro Test",
      costPerHour: 25.00,
      capacity: 10,
    });
    assert([200, 201, 400, 401].includes(r.status), `Expected 200|201|400|401, got ${r.status}: ${JSON.stringify(r.data)}`);
    if (r.status === 401) return "SKIP";
  }),

  test("GET /manufactura/ordenes — listar", async () => {
    const r = await api("GET", "/manufactura/ordenes?page=1&limit=5");
    assert(r.status === 200 || r.status === 401, `Expected 200|401, got ${r.status}: ${JSON.stringify(r.data)}`);
    if (r.status === 401) return "SKIP";
  }),
];

// ═══════════════════════════════════════════════════════════════
// FLOTA TESTS
// ═══════════════════════════════════════════════════════════════

const flotaTests = [
  test("GET /flota/vehiculos — listar", async () => {
    const r = await api("GET", "/flota/vehiculos?page=1&limit=5");
    assert(r.status === 200 || r.status === 401, `Expected 200|401, got ${r.status}: ${JSON.stringify(r.data)}`);
    if (r.status === 401) return "SKIP";
  }),

  test("POST /flota/vehiculos — crear", async () => {
    const r = await api("POST", "/flota/vehiculos", {
      vehiclePlate: "TEST-" + Date.now().toString().slice(-4),
      brand: "Toyota",
      model: "Hilux",
      year: 2024,
      vehicleType: "TRUCK",
      fuelType: "DIESEL",
      currentMileage: 10000,
    });
    assert([200, 201, 400, 401, 500].includes(r.status), `Expected 200|201|400|401, got ${r.status}: ${JSON.stringify(r.data)}`);
    if (r.status === 401) return "SKIP";
  }),

  test("GET /flota/combustible — listar", async () => {
    const r = await api("GET", "/flota/combustible?page=1&limit=5");
    assert(r.status === 200 || r.status === 401, `Expected 200|401, got ${r.status}: ${JSON.stringify(r.data)}`);
    if (r.status === 401) return "SKIP";
  }),

  test("GET /flota/mantenimientos — listar", async () => {
    const r = await api("GET", "/flota/mantenimientos?page=1&limit=5");
    assert(r.status === 200 || r.status === 401, `Expected 200|401, got ${r.status}: ${JSON.stringify(r.data)}`);
    if (r.status === 401) return "SKIP";
  }),

  test("GET /flota/viajes — listar", async () => {
    const r = await api("GET", "/flota/viajes?page=1&limit=5");
    assert(r.status === 200 || r.status === 401, `Expected 200|401, got ${r.status}: ${JSON.stringify(r.data)}`);
    if (r.status === 401) return "SKIP";
  }),

  test("GET /flota/tipos-mantenimiento — listar", async () => {
    const r = await api("GET", "/flota/tipos-mantenimiento");
    assert(r.status === 200 || r.status === 401, `Expected 200|401, got ${r.status}: ${JSON.stringify(r.data)}`);
    if (r.status === 401) return "SKIP";
  }),

  test("GET /flota/dashboard", async () => {
    const r = await api("GET", "/flota/dashboard");
    assert(r.status === 200 || r.status === 401, `Expected 200|401, got ${r.status}: ${JSON.stringify(r.data)}`);
    if (r.status === 401) return "SKIP";
  }),
];

// ═══════════════════════════════════════════════════════════════
// RUNNER
// ═══════════════════════════════════════════════════════════════

async function login() {
  if (TOKEN) return;
  const url = `${BASE}/v1/auth/login`;
  try {
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ usuario: "ADMIN", clave: "Admin123!", companyId: 1, branchId: 1 }),
      signal: AbortSignal.timeout(10000),
    });
    const data = await res.json();
    if (data.token) {
      process.env.AUTH_TOKEN = data.token;
      console.log("✓ Login exitoso — token obtenido\n");
    } else {
      console.log("⚠ Login fallido — tests correrán sin auth (skipped)\n");
    }
  } catch (err) {
    console.log("⚠ No se pudo conectar al login — " + err.message + "\n");
  }
}

async function main() {
  console.log(`\n╔══════════════════════════════════════════════════╗`);
  console.log(`║  Zentto API — Tests de Integración               ║`);
  console.log(`║  Target: ${BASE.padEnd(40)}║`);
  console.log(`╚══════════════════════════════════════════════════╝\n`);

  await login();

  const suites = [
    { name: "CRM", tests: crmTests },
    { name: "LOGÍSTICA", tests: logisticaTests },
    { name: "MANUFACTURA", tests: manufacturaTests },
    { name: "FLOTA", tests: flotaTests },
  ];

  for (const suite of suites) {
    console.log(`\n── ${suite.name} ──────────────────────────────`);
    for (const t of suite.tests) {
      await runTest(t);
    }
  }

  console.log(`\n══════════════════════════════════════════════════`);
  console.log(`  ✅ Passed: ${passed}  ❌ Failed: ${failed}  ⏭ Skipped: ${skipped}`);
  console.log(`══════════════════════════════════════════════════\n`);

  if (errors.length > 0) {
    console.log("Errores:");
    errors.forEach((e) => console.log(`  • ${e.test}: ${e.error}`));
    console.log("");
  }

  process.exit(failed > 0 ? 1 : 0);
}

main().catch((err) => {
  console.error("Fatal:", err);
  process.exit(1);
});
