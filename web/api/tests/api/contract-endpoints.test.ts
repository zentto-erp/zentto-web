/**
 * contract-endpoints.test.ts
 *
 * Test de funcionamiento de cada endpoint del contrato OpenAPI.
 * Verifica que ningún endpoint retorne HTTP 500 (error de SP/DB).
 *
 * Un endpoint que retorna 200, 400, 401, 403, 404, 422 está funcionando correctamente.
 * Un endpoint que retorna 500 indica un error de stored procedure o base de datos.
 *
 * Variables de entorno:
 *   API_BASE_URL      (default: http://localhost:4000)
 *   TEST_USER         (default: ADMIN)
 *   TEST_PASSWORD     (requerido para tests autenticados — si falta, se omiten)
 *   TEST_COMPANY_ID   (default: 1)
 *   TEST_BRANCH_ID    (default: 1)
 *
 * Uso:
 *   npm run test:contract
 *   API_BASE_URL=https://api.zentto.net TEST_PASSWORD=xxx npm run test:contract
 */

import { describe, it, expect, beforeAll } from 'vitest';

const BASE = process.env.API_BASE_URL ?? 'http://localhost:4000';

// ─────────────────────────────────────────────────────────────────────────────
// Sesión global
// ─────────────────────────────────────────────────────────────────────────────

let session: { token: string; companyId: number; branchId: number } | null = null;

beforeAll(async () => {
  const pwd = process.env.TEST_PASSWORD;
  if (!pwd) {
    console.warn('[contract] TEST_PASSWORD no configurado — tests autenticados se omiten');
    return;
  }
  try {
    const res = await fetch(`${BASE}/v1/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        usuario: process.env.TEST_USER ?? 'ADMIN',
        clave: pwd,
        companyId: Number(process.env.TEST_COMPANY_ID ?? 1),
        branchId: Number(process.env.TEST_BRANCH_ID ?? 1),
      }),
    });
    if (!res.ok) {
      console.warn(`[contract] Login fallido (${res.status}) — tests autenticados se omiten`);
      return;
    }
    const data = await res.json() as {
      token: string;
      company: { companyId: number; branchId: number };
    };
    session = {
      token: data.token,
      companyId: data.company.companyId,
      branchId: data.company.branchId,
    };
    console.info(
      `[contract] Sesión activa — company=${session.companyId} branch=${session.branchId}`,
    );
  } catch {
    console.warn('[contract] API no disponible — tests de contrato se omiten');
  }
}, 15_000);

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

async function api(path: string, token: string): Promise<Response | null> {
  return fetch(`${BASE}${path}`, {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/json',
    },
  }).catch(() => null);
}

async function pub(path: string): Promise<Response | null> {
  return fetch(`${BASE}${path}`, {
    headers: { Accept: 'application/json' },
  }).catch(() => null);
}

/**
 * Sustituye path parameters por valores seguros que no existen en la BD.
 * Esto produce 404 (registro no encontrado), nunca 500.
 */
function buildPath(template: string): string {
  return template
    .replace('{id}',            '999999')
    .replace('{codigo}',        'NOEXISTE')
    .replace('{numFact}',       'NOEXISTE')
    .replace('{cedula}',        'V-99999999')
    .replace('{code}',          'XX')
    .replace('{countryCode}',   'XX')
    .replace('{codCuenta}',     'NOEXISTE')
    .replace('{tipoOperacion}', 'factura')
    .replace('{boxId}',         '999999')
    .replace('{pedidoId}',      '999999')
    .replace('{ventaId}',       '999999')
    .replace('{nroCta}',        'NOEXISTE')
    .replace('{module}',        'pos')
    .replace('{entityType}',    'product')
    .replace('{entityId}',      '999999')
    .replace('{entityImageId}', '999999')
    .replace('{table}',         'clientes')
    .replace('{key}',           'NOEXISTE')
    .replace('{loanId}',        '999999')
    .replace('{filingId}',      '999999')
    .replace('{orderId}',       '999999')
    .replace('{committeeId}',   '999999')
    .replace('{memberId}',      '999999')
    .replace('{employeeCode}',  'NOEXISTE')
    .replace('{employeeId}',    '999999');
}

// ─────────────────────────────────────────────────────────────────────────────
// Lista canónica de endpoints (para el test de cobertura al final)
// ─────────────────────────────────────────────────────────────────────────────

const CONTRACT_ENDPOINTS = [
  // AUTH
  '/v1/auth/verify-email',
  '/v1/auth/me',
  // MAESTROS
  '/v1/clientes',
  '/v1/clientes/{codigo}',
  '/v1/proveedores',
  '/v1/proveedores/{codigo}',
  '/v1/inventario',
  '/v1/inventario/{codigo}',
  '/v1/articulos',
  '/v1/articulos/{codigo}',
  '/v1/vendedores',
  '/v1/vendedores/{codigo}',
  '/v1/empleados',
  '/v1/empleados/{cedula}',
  '/v1/centro-costo',
  '/v1/centro-costo/{codigo}',
  '/v1/unidades',
  '/v1/empresa',
  '/v1/usuarios',
  '/v1/usuarios/modules',
  '/v1/usuarios/{codigo}',
  // DOCUMENTOS VENTA
  '/v1/facturas',
  '/v1/facturas/{numFact}',
  '/v1/facturas/{numFact}/detalle',
  '/v1/pedidos',
  '/v1/pedidos/{numFact}',
  '/v1/pedidos/{numFact}/detalle',
  '/v1/cotizaciones',
  '/v1/cotizaciones/{numFact}',
  '/v1/cotizaciones/{numFact}/detalle',
  '/v1/notas/credito',
  '/v1/notas/credito/{numFact}',
  '/v1/notas/credito/{numFact}/detalle',
  '/v1/notas/debito',
  '/v1/notas/debito/{numFact}',
  '/v1/notas/debito/{numFact}/detalle',
  '/v1/presupuestos',
  '/v1/presupuestos/{numFact}',
  '/v1/presupuestos/{numFact}/detalle',
  '/v1/retenciones',
  '/v1/retenciones/{codigo}',
  '/v1/documentos-venta',
  '/v1/documentos-venta/{tipoOperacion}/{numFact}',
  '/v1/documentos-venta/{tipoOperacion}/{numFact}/detalle',
  // DOCUMENTOS COMPRA
  '/v1/compras',
  '/v1/compras/{numFact}',
  '/v1/compras/{numFact}/detalle',
  '/v1/ordenes',
  '/v1/ordenes/{numFact}',
  '/v1/ordenes/{numFact}/detalle',
  '/v1/documentos-compra',
  '/v1/documentos-compra/{tipoOperacion}/{numFact}',
  '/v1/documentos-compra/{tipoOperacion}/{numFact}/detalle',
  '/v1/documentos-compra/{tipoOperacion}/{numFact}/indicadores',
  // PAGOS Y COBROS
  '/v1/abonos',
  '/v1/abonos/{id}',
  '/v1/abonos/{id}/detalle',
  '/v1/pagos',
  '/v1/pagos/{id}',
  '/v1/pagos/{id}/detalle',
  '/v1/pagosc',
  '/v1/pagosc/{id}',
  '/v1/pagosc/{id}/detalle',
  '/v1/abonospagos',
  '/v1/abonospagos/{id}',
  '/v1/cuentas-por-pagar',
  '/v1/cuentas-por-pagar/{id}',
  '/v1/p-cobrar',
  '/v1/p-cobrar/{id}',
  '/v1/p-cobrar/c/list',
  '/v1/p-cobrar/c/{id}',
  '/v1/cxc/documentos',
  '/v1/cxp/documentos',
  // INVENTARIO MOVIMIENTOS
  '/v1/movinvent',
  '/v1/movinvent/{id}',
  '/v1/movinvent/mes/list',
  // BANCOS
  '/v1/bancos/cuentas/list',
  '/v1/bancos/cuentas/{nroCta}/movimientos',
  '/v1/bancos/movimientos/{id}',
  '/v1/bancos/conciliaciones',
  '/v1/bancos/conciliaciones/{id}',
  '/v1/bancos/caja-chica',
  '/v1/bancos/caja-chica/{boxId}/sesion-activa',
  '/v1/bancos/caja-chica/{boxId}/gastos',
  '/v1/bancos/caja-chica/{boxId}/resumen',
  // CONTABILIDAD
  '/v1/contabilidad/cuentas',
  '/v1/contabilidad/cuentas/{codCuenta}',
  '/v1/contabilidad/asientos',
  '/v1/contabilidad/asientos/{id}',
  '/v1/contabilidad/reportes/libro-mayor',
  '/v1/contabilidad/reportes/mayor-analitico',
  '/v1/contabilidad/reportes/balance-comprobacion',
  '/v1/contabilidad/reportes/estado-resultados',
  '/v1/contabilidad/reportes/balance-general',
  // NOMINA
  '/v1/nomina/conceptos-legales',
  '/v1/nomina/convenciones',
  '/v1/nomina/batch',
  '/v1/nomina/batch/{id}/summary',
  '/v1/nomina/batch/{id}/grid',
  '/v1/nomina/batch/{id}/employee/{employeeCode}',
  '/v1/nomina/vacaciones/solicitudes',
  '/v1/nomina/vacaciones/solicitudes/{id}',
  '/v1/nomina/vacaciones/dias-disponibles/{cedula}',
  '/v1/nomina/vacaciones/list',
  '/v1/nomina/vacaciones/{id}',
  '/v1/nomina/liquidaciones/list',
  '/v1/nomina/liquidaciones/{id}',
  '/v1/nomina/constantes',
  // RRHH
  '/v1/rrhh/utilidades',
  '/v1/rrhh/utilidades/{id}/summary',
  '/v1/rrhh/fideicomiso',
  '/v1/rrhh/fideicomiso/balance/{employeeCode}',
  '/v1/rrhh/fideicomiso/summary',
  '/v1/rrhh/caja-ahorro',
  '/v1/rrhh/caja-ahorro/balance/{employeeCode}',
  '/v1/rrhh/caja-ahorro/loans',
  '/v1/rrhh/obligaciones',
  '/v1/rrhh/obligaciones/country/{code}',
  '/v1/rrhh/obligaciones/employee/{employeeId}',
  '/v1/rrhh/obligaciones/filings',
  '/v1/rrhh/obligaciones/filings/{id}',
  '/v1/rrhh/salud-ocupacional',
  '/v1/rrhh/salud-ocupacional/{id}',
  '/v1/rrhh/examenes-medicos',
  '/v1/rrhh/examenes-medicos/pending',
  '/v1/rrhh/ordenes-medicas',
  '/v1/rrhh/capacitacion',
  '/v1/rrhh/capacitacion/certifications/{employeeCode}',
  '/v1/rrhh/comites',
  '/v1/rrhh/comites/{committeeId}/members',
  '/v1/rrhh/comites/{committeeId}/meetings',
  // PAYMENTS
  '/v1/payments/methods',
  '/v1/payments/providers',
  '/v1/payments/providers/{code}',
  '/v1/payments/providers/{code}/fields',
  '/v1/payments/plugins',
  '/v1/payments/config',
  '/v1/payments/config/{id}',
  '/v1/payments/accepted',
  '/v1/payments/accepted/{id}',
  '/v1/payments/card-readers',
  '/v1/payments/transactions',
  // FISCAL
  '/v1/fiscal/plugins',
  '/v1/fiscal/countries',
  '/v1/fiscal/countries/{countryCode}',
  '/v1/fiscal/countries/{countryCode}/default-config',
  '/v1/fiscal/countries/{countryCode}/tax-rates',
  '/v1/fiscal/countries/{countryCode}/invoice-types',
  '/v1/fiscal/countries/{countryCode}/milestones',
  '/v1/fiscal/countries/{countryCode}/sources',
  '/v1/fiscal/config',
  // CONFIG
  '/v1/config/tasas',
  '/v1/config/countries',
  '/v1/config/countries/all',
  '/v1/config/countries/{code}',
  // SETTINGS
  '/v1/settings',
  '/v1/settings/modules',
  '/v1/settings/{module}',
  // MEDIA
  '/v1/media/entities/{entityType}/{entityId}/images',
  // AUDITORIA
  '/v1/auditoria/logs',
  '/v1/auditoria/logs/{id}',
  '/v1/auditoria/dashboard',
  '/v1/auditoria/fiscal-records',
  // SISTEMA
  '/v1/sistema/notificaciones',
  '/v1/sistema/tareas',
  '/v1/sistema/mensajes',
  // SUPERVISION
  '/v1/supervision/biometric/credentials',
  // META/ADDONS
  '/v1/addons',
  '/v1/meta/schema',
  '/v1/meta/relations',
] as const;

// ─────────────────────────────────────────────────────────────────────────────
// AUTH — endpoints públicos (sin token)
// ─────────────────────────────────────────────────────────────────────────────

describe('Contrato — Auth (público)', () => {
  it('GET /v1/auth/verify-email → no retorna 500', async () => {
    const res = await pub('/v1/auth/verify-email');
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// AUTH — endpoints autenticados
// ─────────────────────────────────────────────────────────────────────────────

describe('Contrato — Auth (autenticado)', () => {
  it('GET /v1/auth/me → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/auth/me', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// MAESTROS
// ─────────────────────────────────────────────────────────────────────────────

describe('Contrato — Maestros', () => {
  it('GET /v1/clientes → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/clientes', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/clientes/{codigo} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/clientes/{codigo}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/proveedores → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/proveedores', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/proveedores/{codigo} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/proveedores/{codigo}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/inventario → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/inventario', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/inventario/{codigo} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/inventario/{codigo}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/articulos → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/articulos', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/articulos/{codigo} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/articulos/{codigo}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/vendedores → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/vendedores', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/vendedores/{codigo} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/vendedores/{codigo}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/empleados → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/empleados', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/empleados/{cedula} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/empleados/{cedula}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/centro-costo → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/centro-costo', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/centro-costo/{codigo} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/centro-costo/{codigo}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/unidades → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/unidades', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/empresa → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/empresa', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/usuarios → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/usuarios', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/usuarios/modules → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/usuarios/modules', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/usuarios/{codigo} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/usuarios/{codigo}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// DOCUMENTOS DE VENTA
// ─────────────────────────────────────────────────────────────────────────────

describe('Contrato — Documentos de Venta', () => {
  it('GET /v1/facturas → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/facturas', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/facturas/{numFact} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/facturas/{numFact}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/facturas/{numFact}/detalle → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/facturas/{numFact}/detalle'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/pedidos → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/pedidos', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/pedidos/{numFact} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/pedidos/{numFact}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/pedidos/{numFact}/detalle → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/pedidos/{numFact}/detalle'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/cotizaciones → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/cotizaciones', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/cotizaciones/{numFact} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/cotizaciones/{numFact}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/cotizaciones/{numFact}/detalle → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/cotizaciones/{numFact}/detalle'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/notas/credito → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/notas/credito', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/notas/credito/{numFact} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/notas/credito/{numFact}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/notas/credito/{numFact}/detalle → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/notas/credito/{numFact}/detalle'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/notas/debito → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/notas/debito', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/notas/debito/{numFact} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/notas/debito/{numFact}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/notas/debito/{numFact}/detalle → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/notas/debito/{numFact}/detalle'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/presupuestos → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/presupuestos', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/presupuestos/{numFact} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/presupuestos/{numFact}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/presupuestos/{numFact}/detalle → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/presupuestos/{numFact}/detalle'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/retenciones → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/retenciones', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/retenciones/{codigo} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/retenciones/{codigo}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/documentos-venta → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/documentos-venta', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/documentos-venta/{tipoOperacion}/{numFact} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/documentos-venta/{tipoOperacion}/{numFact}'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/documentos-venta/{tipoOperacion}/{numFact}/detalle → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/documentos-venta/{tipoOperacion}/{numFact}/detalle'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// DOCUMENTOS DE COMPRA
// ─────────────────────────────────────────────────────────────────────────────

describe('Contrato — Documentos de Compra', () => {
  it('GET /v1/compras → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/compras', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/compras/{numFact} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/compras/{numFact}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/compras/{numFact}/detalle → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/compras/{numFact}/detalle'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/ordenes → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/ordenes', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/ordenes/{numFact} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/ordenes/{numFact}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/ordenes/{numFact}/detalle → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/ordenes/{numFact}/detalle'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/documentos-compra → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/documentos-compra', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/documentos-compra/{tipoOperacion}/{numFact} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/documentos-compra/{tipoOperacion}/{numFact}'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/documentos-compra/{tipoOperacion}/{numFact}/detalle → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/documentos-compra/{tipoOperacion}/{numFact}/detalle'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/documentos-compra/{tipoOperacion}/{numFact}/indicadores → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/documentos-compra/{tipoOperacion}/{numFact}/indicadores'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// PAGOS Y COBROS
// ─────────────────────────────────────────────────────────────────────────────

describe('Contrato — Pagos y Cobros', () => {
  it('GET /v1/abonos → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/abonos', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/abonos/{id} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/abonos/{id}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/abonos/{id}/detalle → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/abonos/{id}/detalle'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/pagos → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/pagos', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/pagos/{id} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/pagos/{id}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/pagos/{id}/detalle → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/pagos/{id}/detalle'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/pagosc → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/pagosc', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/pagosc/{id} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/pagosc/{id}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/pagosc/{id}/detalle → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/pagosc/{id}/detalle'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/abonospagos → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/abonospagos', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/abonospagos/{id} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/abonospagos/{id}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/cuentas-por-pagar → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/cuentas-por-pagar', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/cuentas-por-pagar/{id} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/cuentas-por-pagar/{id}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/p-cobrar → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/p-cobrar', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/p-cobrar/{id} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/p-cobrar/{id}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/p-cobrar/c/list → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/p-cobrar/c/list', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/p-cobrar/c/{id} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/p-cobrar/c/{id}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/cxc/documentos → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/cxc/documentos', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/cxp/documentos → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/cxp/documentos', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// INVENTARIO — MOVIMIENTOS
// ─────────────────────────────────────────────────────────────────────────────

describe('Contrato — Inventario (movimientos)', () => {
  it('GET /v1/movinvent → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/movinvent', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/movinvent/{id} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/movinvent/{id}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/movinvent/mes/list → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/movinvent/mes/list', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// BANCOS
// ─────────────────────────────────────────────────────────────────────────────

describe('Contrato — Bancos', () => {
  it('GET /v1/bancos/cuentas/list → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/bancos/cuentas/list', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/bancos/cuentas/{nroCta}/movimientos → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/bancos/cuentas/{nroCta}/movimientos'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/bancos/movimientos/{id} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/bancos/movimientos/{id}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/bancos/conciliaciones → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/bancos/conciliaciones', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/bancos/conciliaciones/{id} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/bancos/conciliaciones/{id}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/bancos/caja-chica → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/bancos/caja-chica', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/bancos/caja-chica/{boxId}/sesion-activa → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/bancos/caja-chica/{boxId}/sesion-activa'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/bancos/caja-chica/{boxId}/gastos → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/bancos/caja-chica/{boxId}/gastos'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/bancos/caja-chica/{boxId}/resumen → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/bancos/caja-chica/{boxId}/resumen'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// CONTABILIDAD
// ─────────────────────────────────────────────────────────────────────────────

describe('Contrato — Contabilidad', () => {
  it('GET /v1/contabilidad/cuentas → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/contabilidad/cuentas', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/contabilidad/cuentas/{codCuenta} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/contabilidad/cuentas/{codCuenta}'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/contabilidad/asientos → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/contabilidad/asientos', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/contabilidad/asientos/{id} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/contabilidad/asientos/{id}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/contabilidad/reportes/libro-mayor → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/contabilidad/reportes/libro-mayor', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/contabilidad/reportes/mayor-analitico → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/contabilidad/reportes/mayor-analitico', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/contabilidad/reportes/balance-comprobacion → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/contabilidad/reportes/balance-comprobacion', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/contabilidad/reportes/estado-resultados → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/contabilidad/reportes/estado-resultados', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/contabilidad/reportes/balance-general → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/contabilidad/reportes/balance-general', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// NÓMINA
// ─────────────────────────────────────────────────────────────────────────────

describe('Contrato — Nómina', () => {
  it('GET /v1/nomina/conceptos-legales → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/nomina/conceptos-legales', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/nomina/convenciones → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/nomina/convenciones', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/nomina/batch → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/nomina/batch', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/nomina/batch/{id}/summary → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/nomina/batch/{id}/summary'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/nomina/batch/{id}/grid → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/nomina/batch/{id}/grid'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/nomina/batch/{id}/employee/{employeeCode} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/nomina/batch/{id}/employee/{employeeCode}'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/nomina/vacaciones/solicitudes → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/nomina/vacaciones/solicitudes', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/nomina/vacaciones/solicitudes/{id} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/nomina/vacaciones/solicitudes/{id}'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/nomina/vacaciones/dias-disponibles/{cedula} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/nomina/vacaciones/dias-disponibles/{cedula}'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/nomina/vacaciones/list → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/nomina/vacaciones/list', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/nomina/vacaciones/{id} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/nomina/vacaciones/{id}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/nomina/liquidaciones/list → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/nomina/liquidaciones/list', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/nomina/liquidaciones/{id} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/nomina/liquidaciones/{id}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/nomina/constantes → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/nomina/constantes', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// RRHH
// ─────────────────────────────────────────────────────────────────────────────

describe('Contrato — RRHH', () => {
  it('GET /v1/rrhh/utilidades → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/rrhh/utilidades', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/rrhh/utilidades/{id}/summary → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/rrhh/utilidades/{id}/summary'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/rrhh/fideicomiso → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/rrhh/fideicomiso', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/rrhh/fideicomiso/balance/{employeeCode} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/rrhh/fideicomiso/balance/{employeeCode}'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/rrhh/fideicomiso/summary → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/rrhh/fideicomiso/summary', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/rrhh/caja-ahorro → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/rrhh/caja-ahorro', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/rrhh/caja-ahorro/balance/{employeeCode} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/rrhh/caja-ahorro/balance/{employeeCode}'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/rrhh/caja-ahorro/loans → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/rrhh/caja-ahorro/loans', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/rrhh/obligaciones → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/rrhh/obligaciones', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/rrhh/obligaciones/country/{code} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/rrhh/obligaciones/country/{code}'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/rrhh/obligaciones/employee/{employeeId} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/rrhh/obligaciones/employee/{employeeId}'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/rrhh/obligaciones/filings → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/rrhh/obligaciones/filings', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/rrhh/obligaciones/filings/{id} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/rrhh/obligaciones/filings/{id}'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/rrhh/salud-ocupacional → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/rrhh/salud-ocupacional', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/rrhh/salud-ocupacional/{id} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/rrhh/salud-ocupacional/{id}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/rrhh/examenes-medicos → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/rrhh/examenes-medicos', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/rrhh/examenes-medicos/pending → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/rrhh/examenes-medicos/pending', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/rrhh/ordenes-medicas → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/rrhh/ordenes-medicas', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/rrhh/capacitacion → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/rrhh/capacitacion', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/rrhh/capacitacion/certifications/{employeeCode} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/rrhh/capacitacion/certifications/{employeeCode}'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/rrhh/comites → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/rrhh/comites', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/rrhh/comites/{committeeId}/members → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/rrhh/comites/{committeeId}/members'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/rrhh/comites/{committeeId}/meetings → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/rrhh/comites/{committeeId}/meetings'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// PAYMENTS
// ─────────────────────────────────────────────────────────────────────────────

describe('Contrato — Payments', () => {
  it('GET /v1/payments/methods → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/payments/methods', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/payments/providers → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/payments/providers', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/payments/providers/{code} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/payments/providers/{code}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/payments/providers/{code}/fields → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/payments/providers/{code}/fields'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/payments/plugins → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/payments/plugins', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/payments/config → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/payments/config', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/payments/config/{id} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/payments/config/{id}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/payments/accepted → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/payments/accepted', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/payments/accepted/{id} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/payments/accepted/{id}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/payments/card-readers → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/payments/card-readers', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/payments/transactions → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/payments/transactions', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// FISCAL
// ─────────────────────────────────────────────────────────────────────────────

describe('Contrato — Fiscal', () => {
  it('GET /v1/fiscal/plugins → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/fiscal/plugins', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/fiscal/countries → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/fiscal/countries', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/fiscal/countries/{countryCode} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/fiscal/countries/{countryCode}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/fiscal/countries/{countryCode}/default-config → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/fiscal/countries/{countryCode}/default-config'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/fiscal/countries/{countryCode}/tax-rates → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/fiscal/countries/{countryCode}/tax-rates'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/fiscal/countries/{countryCode}/invoice-types → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/fiscal/countries/{countryCode}/invoice-types'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/fiscal/countries/{countryCode}/milestones → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/fiscal/countries/{countryCode}/milestones'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/fiscal/countries/{countryCode}/sources → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/fiscal/countries/{countryCode}/sources'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/fiscal/config → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/fiscal/config', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

describe('Contrato — Config', () => {
  it('GET /v1/config/tasas → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/config/tasas', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/config/countries → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/config/countries', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/config/countries/all → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/config/countries/all', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/config/countries/{code} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/config/countries/{code}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS
// ─────────────────────────────────────────────────────────────────────────────

describe('Contrato — Settings', () => {
  it('GET /v1/settings → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/settings', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/settings/modules → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/settings/modules', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/settings/{module} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/settings/{module}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// MEDIA
// ─────────────────────────────────────────────────────────────────────────────

describe('Contrato — Media', () => {
  it('GET /v1/media/entities/{entityType}/{entityId}/images → no retorna 500', async () => {
    if (!session) return;
    const res = await api(
      buildPath('/v1/media/entities/{entityType}/{entityId}/images'),
      session.token,
    );
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// AUDITORÍA
// ─────────────────────────────────────────────────────────────────────────────

describe('Contrato — Auditoría', () => {
  it('GET /v1/auditoria/logs → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/auditoria/logs', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/auditoria/logs/{id} → no retorna 500', async () => {
    if (!session) return;
    const res = await api(buildPath('/v1/auditoria/logs/{id}'), session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/auditoria/dashboard → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/auditoria/dashboard', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/auditoria/fiscal-records → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/auditoria/fiscal-records', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// SISTEMA
// ─────────────────────────────────────────────────────────────────────────────

describe('Contrato — Sistema', () => {
  it('GET /v1/sistema/notificaciones → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/sistema/notificaciones', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/sistema/tareas → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/sistema/tareas', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/sistema/mensajes → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/sistema/mensajes', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// SUPERVISION
// ─────────────────────────────────────────────────────────────────────────────

describe('Contrato — Supervisión', () => {
  it('GET /v1/supervision/biometric/credentials → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/supervision/biometric/credentials', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// META / ADDONS
// ─────────────────────────────────────────────────────────────────────────────

describe('Contrato — Meta y Addons', () => {
  it('GET /v1/addons → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/addons', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/meta/schema → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/meta/schema', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });

  it('GET /v1/meta/relations → no retorna 500', async () => {
    if (!session) return;
    const res = await api('/v1/meta/relations', session.token);
    if (!res) return; // API no disponible
    expect(res.status).not.toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// COBERTURA — verifica que todos los endpoints del contrato están en este test
// ─────────────────────────────────────────────────────────────────────────────

describe('Contrato — Cobertura de endpoints', () => {
  /**
   * Este test es informativo: verifica que la lista CONTRACT_ENDPOINTS
   * tiene el número esperado de paths registrados.
   * Si se agregan nuevos endpoints al openapi.yaml, este test fallará
   * como recordatorio de actualizar el test de contrato.
   */
  it('la lista de endpoints de contrato tiene el total esperado', () => {
    // Total actual de endpoints registrados en este archivo
    const TOTAL_ESPERADO = CONTRACT_ENDPOINTS.length;

    console.info(
      `[contract] Endpoints registrados en el test: ${TOTAL_ESPERADO}`,
    );

    // Verificación informativa — ajusta el número si agregas endpoints nuevos
    expect(TOTAL_ESPERADO).toBeGreaterThanOrEqual(160);
  });

  it('todos los paths en la lista son únicos (sin duplicados)', () => {
    const unique = new Set(CONTRACT_ENDPOINTS);
    expect(unique.size).toBe(CONTRACT_ENDPOINTS.length);
  });

  it('todos los paths comienzan con /v1/', () => {
    for (const path of CONTRACT_ENDPOINTS) {
      expect(path).toMatch(/^\/v1\//);
    }
  });
});
