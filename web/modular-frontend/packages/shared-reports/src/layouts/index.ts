/**
 * Layouts de reportes por módulo.
 *
 * Convención:
 *   layouts/{modulo}/{nombre-reporte}.ts
 *
 * Cada layout exporta una constante UPPERCASE compatible con ReportLayout
 * de @zentto/report-core.
 */

// ── Contabilidad ────────────────────────────────────────────────
export { ASIENTOS_LIST_LAYOUT } from './contabilidad/asientos-list';
export { LIBRO_MAYOR_LAYOUT } from './contabilidad/libro-mayor';
export { BALANCE_COMPROBACION_LAYOUT } from './contabilidad/balance-comprobacion';
export { LIBRO_DIARIO_LAYOUT } from './contabilidad/libro-diario';
export { PLAN_CUENTAS_LAYOUT } from './contabilidad/plan-cuentas';

// ── Inventario ──────────────────────────────────────────────────
export { ARTICULOS_LAYOUT } from './inventario/articulos';
export { MOVIMIENTOS_INVENTARIO_LAYOUT } from './inventario/movimientos';

// ── Bancos ──────────────────────────────────────────────────────
export { BANCOS_LIST_LAYOUT } from './bancos/bancos-list';
export { CUENTAS_BANCARIAS_LAYOUT } from './bancos/cuentas-bancarias';
export { MOVIMIENTOS_BANCARIOS_LAYOUT } from './bancos/movimientos-bancarios';
export { CAJA_CHICA_LAYOUT } from './bancos/caja-chica';

// ── Ventas ──────────────────────────────────────────────────────
export { DOCUMENTOS_VENTA_LAYOUT } from './ventas/documentos-venta';
export { CLIENTES_LAYOUT } from './ventas/clientes';
export { CXC_DOCUMENTOS_LAYOUT } from './ventas/cxc';

// ── Compras ─────────────────────────────────────────────────────
export { DOCUMENTOS_COMPRA_LAYOUT } from './compras/documentos-compra';
export { PROVEEDORES_LAYOUT } from './compras/proveedores';
export { CXP_DOCUMENTOS_LAYOUT } from './compras/cxp';

// ── Nomina ──────────────────────────────────────────────────────
export { EMPLEADOS_LAYOUT } from './nomina/empleados';
export { NOMINAS_LAYOUT } from './nomina/nominas';
export { CONCEPTOS_NOMINA_LAYOUT } from './nomina/conceptos';
export { VACACIONES_LAYOUT } from './nomina/vacaciones';

// ── CRM ─────────────────────────────────────────────────────────
export { LEADS_LAYOUT } from './crm/leads';
export { ACTIVIDADES_CRM_LAYOUT } from './crm/actividades';

// ── Maestros ────────────────────────────────────────────────────
export { CATEGORIAS_LAYOUT } from './maestros/categorias';
export { VENDEDORES_LAYOUT } from './maestros/vendedores';
export { ALMACENES_LAYOUT } from './maestros/almacenes';
export { CENTRO_COSTO_LAYOUT } from './maestros/centro-costo';
