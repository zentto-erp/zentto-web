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
export { ASIENTOS_LIST_LAYOUT, ASIENTOS_LIST_LAYOUT_SAMPLE } from './contabilidad/asientos-list';
export { LIBRO_MAYOR_LAYOUT, LIBRO_MAYOR_LAYOUT_SAMPLE } from './contabilidad/libro-mayor';
export { BALANCE_COMPROBACION_LAYOUT, BALANCE_COMPROBACION_LAYOUT_SAMPLE } from './contabilidad/balance-comprobacion';
export { LIBRO_DIARIO_LAYOUT, LIBRO_DIARIO_LAYOUT_SAMPLE } from './contabilidad/libro-diario';
export { PLAN_CUENTAS_LAYOUT, PLAN_CUENTAS_LAYOUT_SAMPLE } from './contabilidad/plan-cuentas';

// ── Inventario ──────────────────────────────────────────────────
export { ARTICULOS_LAYOUT, ARTICULOS_LAYOUT_SAMPLE } from './inventario/articulos';
export { MOVIMIENTOS_INVENTARIO_LAYOUT, MOVIMIENTOS_INVENTARIO_LAYOUT_SAMPLE } from './inventario/movimientos';

// ── Bancos ──────────────────────────────────────────────────────
export { BANCOS_LIST_LAYOUT, BANCOS_LIST_LAYOUT_SAMPLE } from './bancos/bancos-list';
export { CUENTAS_BANCARIAS_LAYOUT, CUENTAS_BANCARIAS_LAYOUT_SAMPLE } from './bancos/cuentas-bancarias';
export { MOVIMIENTOS_BANCARIOS_LAYOUT, MOVIMIENTOS_BANCARIOS_LAYOUT_SAMPLE } from './bancos/movimientos-bancarios';
export { CAJA_CHICA_LAYOUT, CAJA_CHICA_LAYOUT_SAMPLE } from './bancos/caja-chica';

// ── Ventas ──────────────────────────────────────────────────────
export { DOCUMENTOS_VENTA_LAYOUT, DOCUMENTOS_VENTA_LAYOUT_SAMPLE } from './ventas/documentos-venta';
export { CLIENTES_LAYOUT, CLIENTES_LAYOUT_SAMPLE } from './ventas/clientes';
export { CXC_DOCUMENTOS_LAYOUT, CXC_DOCUMENTOS_LAYOUT_SAMPLE } from './ventas/cxc';

// ── Compras ─────────────────────────────────────────────────────
export { DOCUMENTOS_COMPRA_LAYOUT, DOCUMENTOS_COMPRA_LAYOUT_SAMPLE } from './compras/documentos-compra';
export { PROVEEDORES_LAYOUT, PROVEEDORES_LAYOUT_SAMPLE } from './compras/proveedores';
export { CXP_DOCUMENTOS_LAYOUT, CXP_DOCUMENTOS_LAYOUT_SAMPLE } from './compras/cxp';

// ── Nomina ──────────────────────────────────────────────────────
export { EMPLEADOS_LAYOUT, EMPLEADOS_LAYOUT_SAMPLE } from './nomina/empleados';
export { NOMINAS_LAYOUT, NOMINAS_LAYOUT_SAMPLE } from './nomina/nominas';
export { CONCEPTOS_NOMINA_LAYOUT, CONCEPTOS_NOMINA_LAYOUT_SAMPLE } from './nomina/conceptos';
export { VACACIONES_LAYOUT, VACACIONES_LAYOUT_SAMPLE } from './nomina/vacaciones';

// ── CRM ─────────────────────────────────────────────────────────
export { LEADS_LAYOUT, LEADS_LAYOUT_SAMPLE } from './crm/leads';
export { ACTIVIDADES_CRM_LAYOUT, ACTIVIDADES_CRM_LAYOUT_SAMPLE } from './crm/actividades';

// ── Maestros ────────────────────────────────────────────────────
export { CATEGORIAS_LAYOUT, CATEGORIAS_LAYOUT_SAMPLE } from './maestros/categorias';
export { VENDEDORES_LAYOUT, VENDEDORES_LAYOUT_SAMPLE } from './maestros/vendedores';
export { ALMACENES_LAYOUT, ALMACENES_LAYOUT_SAMPLE } from './maestros/almacenes';
export { CENTRO_COSTO_LAYOUT, CENTRO_COSTO_LAYOUT_SAMPLE } from './maestros/centro-costo';
