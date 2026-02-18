#!/usr/bin/env node
// Script de Pruebas Rápidas - DatQBox API

const BASE_URL = process.env.BASE_URL || "http://localhost:3001";
const USUARIO = process.env.USUARIO || "SUP";
const CLAVE = process.env.CLAVE || "SUP";

const COLORS = {
  cyan: "\x1b[36m",
  yellow: "\x1b[33m",
  green: "\x1b[32m",
  red: "\x1b[31m",
  gray: "\x1b[90m",
  reset: "\x1b[0m"
};

function log(color, msg) {
  console.log(`${COLORS[color]}${msg}${COLORS.reset}`);
}

async function request(method, path, options = {}) {
  const url = new URL(path, BASE_URL);
  const res = await fetch(url, {
    method,
    headers: {
      "Content-Type": "application/json",
      ...options.headers
    },
    body: options.body ? JSON.stringify(options.body) : undefined
  });
  
  if (!res.ok) {
    const err = new Error(`HTTP ${res.status}`);
    err.status = res.status;
    throw err;
  }
  
  return res.json();
}

async function main() {
  log("cyan", "\n═══════════════════════════════════════════════════");
  log("cyan", "🧪 PRUEBAS RÁPIDAS - DATQBOX API");
  log("cyan", "═══════════════════════════════════════════════════\n");

  let token;
  
  // 1. Login
  log("yellow", "1️⃣  AUTENTICACIÓN");
  try {
    const auth = await request("POST", "/v1/auth/login", {
      body: { usuario: USUARIO, clave: CLAVE }
    });
    token = auth.token;
    log("green", `   ✅ POST /v1/auth/login - OK (Token: ${token.substring(0, 20)}...)`);
    log("gray", `   User: ${auth.usuario.nombre} (${auth.usuario.codUsuario})`);
  } catch (err) {
    log("red", `   ❌ Error de autenticación: ${err.message}`);
    process.exit(1);
  }

  const headers = { Authorization: `Bearer ${token}` };

  // 2. Health Check
  log("yellow", "\n2️⃣  HEALTH CHECK");
  try {
    const resp = await request("GET", "/health");
    log("green", "   ✅ GET /health - OK");
  } catch (err) {
    log("red", `   ❌ Error: ${err.message}`);
  }

  try {
    const resp = await request("GET", "/health/db");
    log("green", `   ✅ GET /health/db - ${resp.database}`);
  } catch (err) {
    log("red", `   ❌ Error: ${err.message}`);
  }

  // 3. Documentos
  log("yellow", "\n3️⃣  DOCUMENTOS");
  const docTests = [
    { name: "documentos-venta (FACT)", path: "/v1/documentos-venta?tipoOperacion=FACT&limit=1" },
    { name: "documentos-compra (ORDC)", path: "/v1/documentos-compra?tipoOperacion=ORDC&limit=1" }
  ];
  for (const t of docTests) {
    try {
      const resp = await request("GET", t.path, { headers });
      const count = resp.data?.length ?? 0;
      log("green", `   ✅ GET ${t.name} - ${count} registros`);
    } catch (err) {
      log("red", `   ❌ GET ${t.name} - HTTP ${err.status}`);
    }
  }

  // 4. Terceros
  log("yellow", "\n4️⃣  TERCEROS");
  const tercerosTests = [
    { name: "clientes", path: "/v1/clientes?limit=1" },
    { name: "proveedores", path: "/v1/proveedores?limit=1" },
    { name: "vendedores", path: "/v1/vendedores?limit=1" },
    { name: "empleados", path: "/v1/empleados?limit=1" }
  ];
  for (const t of tercerosTests) {
    try {
      const resp = await request("GET", t.path, { headers });
      const count = resp.data?.length ?? 0;
      log("green", `   ✅ GET ${t.name} - ${count} registros`);
    } catch (err) {
      log("red", `   ❌ GET ${t.name} - HTTP ${err.status}`);
    }
  }

  // 5. Inventario
  log("yellow", "\n5️⃣  INVENTARIO");
  const invTests = [
    { name: "inventario/articulos", path: "/v1/inventario/articulos?limit=1" },
    { name: "categorias", path: "/v1/categorias?limit=1" },
    { name: "marcas", path: "/v1/marcas?limit=1" },
    { name: "lineas", path: "/v1/lineas?limit=1" }
  ];
  for (const t of invTests) {
    try {
      const resp = await request("GET", t.path, { headers });
      const count = resp.data?.length ?? 0;
      log("green", `   ✅ GET ${t.name} - ${count} registros`);
    } catch (err) {
      log("red", `   ❌ GET ${t.name} - HTTP ${err.status}`);
    }
  }

  // 6. Bancos
  log("yellow", "\n6️⃣  BANCOS");
  const bancoTests = [
    { name: "bancos", path: "/v1/bancos?limit=1" },
    { name: "bancos/cuentas", path: "/v1/bancos/cuentas/list" },
    { name: "bancos/conciliaciones", path: "/v1/bancos/conciliaciones?limit=1" }
  ];
  for (const t of bancoTests) {
    try {
      const resp = await request("GET", t.path, { headers });
      let count = 0;
      if (resp.data) count = resp.data.length;
      else if (resp.rows) count = resp.rows.length;
      else if (Array.isArray(resp)) count = resp.length;
      log("green", `   ✅ GET ${t.name} - ${count} registros`);
    } catch (err) {
      log("red", `   ❌ GET ${t.name} - HTTP ${err.status}`);
    }
  }

  // 7. CxC / CxP
  log("yellow", "\n7️⃣  CUENTAS POR COBRAR/PAGAR");
  const cxTests = [
    { name: "cxc/documentos", path: "/v1/cxc/documentos?limit=1" },
    { name: "cxp/documentos", path: "/v1/cxp/documentos?limit=1" },
    { name: "cuentas-por-pagar", path: "/v1/cuentas-por-pagar?limit=1" }
  ];
  for (const t of cxTests) {
    try {
      const resp = await request("GET", t.path, { headers });
      const count = resp.data?.length ?? 0;
      log("green", `   ✅ GET ${t.name} - ${count} registros`);
    } catch (err) {
      log("red", `   ❌ GET ${t.name} - HTTP ${err.status}`);
    }
  }

  // 8. Nómina
  log("yellow", "\n8️⃣  NÓMINA");
  try {
    const resp = await request("GET", "/v1/nomina/conceptos-legales?limit=1", { headers });
    const count = Array.isArray(resp) ? resp.length : 0;
    log("green", `   ✅ GET nomina/conceptos-legales - ${count} registros`);
  } catch (err) {
    log("red", `   ❌ GET nomina/conceptos-legales - HTTP ${err.status}`);
  }

  // 9. Contabilidad
  log("yellow", "\n9️⃣  CONTABILIDAD");
  const contaTests = [
    { name: "contabilidad/cuentas", path: "/v1/contabilidad/cuentas?limit=1" },
    { name: "centro-costo", path: "/v1/centro-costo?limit=1" }
  ];
  for (const t of contaTests) {
    try {
      const resp = await request("GET", t.path, { headers });
      const count = resp.data?.length ?? 0;
      log("green", `   ✅ GET ${t.name} - ${count} registros`);
    } catch (err) {
      log("red", `   ❌ GET ${t.name} - HTTP ${err.status}`);
    }
  }

  // 10. Configuración
  log("yellow", "\n🔟  CONFIGURACIÓN");
  const configTests = [
    { name: "empresa", path: "/v1/empresa" },
    { name: "usuarios", path: "/v1/usuarios?limit=1" },
    { name: "unidades", path: "/v1/unidades?limit=1" }
  ];
  for (const t of configTests) {
    try {
      const resp = await request("GET", t.path, { headers });
      log("green", `   ✅ GET ${t.name} - OK`);
    } catch (err) {
      log("red", `   ❌ GET ${t.name} - HTTP ${err.status}`);
    }
  }

  log("cyan", "\n═══════════════════════════════════════════════════");
  log("cyan", "✅ PRUEBAS COMPLETADAS");
  log("cyan", "═══════════════════════════════════════════════════\n");
}

main().catch(console.error);
