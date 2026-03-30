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
