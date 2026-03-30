/**
 * sp-integration.test.ts
 *
 * Test de integración contra la API real (dev).
 * - Login → obtiene JWT token
 * - Llama a TODOS los endpoints GET del contrato OpenAPI
 * - Verifica que ninguno devuelva 500/502/503/504 (error de servidor)
 * - 200, 400, 404 son aceptables (el endpoint funciona, solo faltan datos)
 * - 500 significa que el SP o la ruta está rota
 *
 * Variables de entorno:
 *   API_BASE_URL  (default: https://apidev.zentto.net)
 *   API_USER      (default: ADMIN)
 *   API_PASSWORD   (default: Admin123!)
 */

import { describe, it, expect, beforeAll } from "vitest";
import "dotenv/config";

// En CI no hay API Express corriendo — solo BD local. Skip si no hay URL.
const BASE = process.env.API_BASE_URL || "";
const USER = process.env.API_USER || "ADMIN";
const PASS = process.env.API_PASSWORD || "Admin123!";
const RUN = Boolean(BASE);
const describeApi = RUN ? describe : describe.skip;

let token = "";

// ── Endpoints GET del contrato OpenAPI ──────────────────────────────────
// Extraídos de web/contracts/openapi.yaml — solo GET
// Los {param} se reemplazan con valores dummy seguros
const GET_ENDPOINTS: string[] = [
  // Auth
  "/v1/auth/me",
  // Artículos
  "/v1/articulos",
  "/v1/articulos/TEST",
  // Clientes
  "/v1/clientes",
  "/v1/clientes/TEST",
  // Proveedores
  "/v1/proveedores",
  "/v1/proveedores/TEST",
  // Empleados
  "/v1/empleados",
  "/v1/empleados/TEST",
  // Facturas
  "/v1/facturas",
  "/v1/facturas/1",
  // Abonos / CxC
  "/v1/abonos",
  "/v1/abonos/1",
  "/v1/abonospagos",
  // CxP
  "/v1/cuentas-por-pagar",
  "/v1/cuentas-por-pagar/1",
  "/v1/p-cobrar",
  // Inventario
  "/v1/inventario",
  "/v1/movinvent",
  // Catálogos
  "/v1/categorias",
  "/v1/categorias/TEST",
  "/v1/marcas",
  "/v1/marcas/TEST",
  "/v1/clases",
  "/v1/clases/TEST",
  "/v1/grupos",
  "/v1/grupos/TEST",
  "/v1/tipos",
  "/v1/tipos/TEST",
  "/v1/lineas",
  "/v1/lineas/TEST",
  "/v1/unidades",
  "/v1/unidades/1",
  "/v1/almacen",
  "/v1/almacen/TEST",
  "/v1/vendedores",
  "/v1/vendedores/TEST",
  "/v1/cuentas",
  "/v1/cuentas/TEST",
  "/v1/centro-costo",
  "/v1/centro-costo/TEST",
  "/v1/empresa",
  // Bancos
  "/v1/bancos",
  "/v1/bancos/cuentas/list",
  "/v1/bancos/conciliaciones",
  "/v1/bancos/caja-chica",
  // Contabilidad
  "/v1/contabilidad/asientos",
  "/v1/contabilidad/cuentas",
  "/v1/contabilidad/centros-costo",
  "/v1/contabilidad/presupuestos",
  "/v1/contabilidad/recurrentes",
  "/v1/contabilidad/activos-fijos",
  "/v1/contabilidad/activos-fijos/categorias",
  "/v1/contabilidad/inflacion/indices",
  // Fiscal
  "/v1/contabilidad/fiscal/declaraciones",
  "/v1/contabilidad/fiscal/retenciones",
  "/v1/contabilidad/fiscal/retenciones/conceptos",
  "/v1/contabilidad/fiscal/unidad-tributaria",
  // Nómina
  "/v1/nomina/empleados",
  "/v1/nomina/conceptos",
  "/v1/nomina/constantes",
  "/v1/nomina/vacaciones",
  "/v1/nomina/liquidaciones",
  "/v1/nomina/feriados",
  "/v1/nomina/documentos/templates",
  // CRM
  "/v1/crm/leads",
  "/v1/crm/actividades",
  "/v1/crm/pipeline/stages",
  "/v1/crm/automatizaciones",
  // Manufactura
  "/v1/manufactura/bom",
  "/v1/manufactura/centros-trabajo",
  "/v1/manufactura/ordenes",
  "/v1/manufactura/rutas",
  // Flota
  "/v1/flota/vehiculos",
  "/v1/flota/combustible",
  "/v1/flota/mantenimiento",
  "/v1/flota/viajes",
  // Logística
  "/v1/logistica/recepciones",
  "/v1/logistica/devoluciones",
  "/v1/logistica/transportistas",
  // Inventario avanzado
  "/v1/inventario-avanzado/seriales",
  "/v1/inventario-avanzado/lotes",
  "/v1/inventario-avanzado/warehouses",
  // POS
  "/v1/pos/espera",
  // Restaurante
  "/v1/restaurante/admin/ambientes",
  "/v1/restaurante/admin/categorias",
  "/v1/restaurante/admin/productos",
  // E-Commerce
  "/v1/ecommerce/products",
  "/v1/ecommerce/categories",
  // Auditoría
  "/v1/auditoria/dashboard",
  "/v1/auditoria/logs",
  // Config
  "/v1/config/countries",
  "/v1/config/states/VE",
  "/v1/config/lookups/TIPO_DOC",
  "/v1/settings",
  "/v1/settings/modules",
  "/v1/usuarios",
  // Meta
  "/v1/meta/schema",
  "/v1/meta/relations",
  // Payments
  "/v1/payments/methods",
  "/v1/payments/providers",
  "/v1/payments/config",
  "/v1/payments/accepted",
  // Studio
  "/v1/studio/addons",
  // Reportes (depende de zentto-cache — skip si cache no está up)
  // "/v1/reportes/saved",
  // Shipping
  "/v1/shipping/carriers",
];

// ── Helpers ─────────────────────────────────────────────────────────────

async function apiGet(path: string): Promise<{ status: number; body: unknown }> {
  const res = await fetch(`${BASE}${path}`, {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: "application/json",
    },
  });
  let body: unknown;
  try { body = await res.json(); } catch { body = await res.text().catch(() => ""); }
  return { status: res.status, body };
}

// ── Tests ───────────────────────────────────────────────────────────────

describeApi("API Integration — login", () => {
  it("debe autenticar y obtener JWT token", async () => {
    const res = await fetch(`${BASE}/v1/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ usuario: USER, clave: PASS }),
    });
    expect(res.status, "Login falló").toBe(200);
    const data = await res.json();
    token = data.token ?? "";
    expect(token.length, "Token vacío").toBeGreaterThan(10);
    console.log(`  Token obtenido (${token.length} chars)`);
  });
});

describeApi("API Integration — TODOS los endpoints GET del contrato", () => {
  // Códigos aceptables: 2xx (OK), 400 (params faltantes), 404 (dato no existe)
  // Códigos de fallo: 500, 502, 503, 504 (error del servidor / SP roto)
  const SERVER_ERROR_CODES = [500, 502, 503, 504];

  for (const endpoint of GET_ENDPOINTS) {
    it(`GET ${endpoint} no debe dar 5xx`, async () => {
      expect(token, "No hay token — login falló").toBeTruthy();
      const { status, body } = await apiGet(endpoint);

      if (SERVER_ERROR_CODES.includes(status)) {
        const errorMsg = typeof body === "object" && body !== null
          ? JSON.stringify(body).slice(0, 300)
          : String(body).slice(0, 300);
        expect.fail(
          `GET ${endpoint} → ${status}\n  Response: ${errorMsg}`,
        );
      }

      // Log para visibilidad
      if (status >= 400 && status < 500) {
        // 4xx es aceptable (falta dato, param inválido)
      }
    });
  }
});

describeApi("API Integration — resumen", () => {
  it("imprime resumen de resultados", async () => {
    // Este test solo existe para el reporte final
    console.log(`\n  Total endpoints testeados: ${GET_ENDPOINTS.length}`);
    console.log(`  Base URL: ${BASE}`);
    expect(true).toBe(true);
  });
});
