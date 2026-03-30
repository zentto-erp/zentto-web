/**
 * Layout JSON para el reporte "Plan de Cuentas".
 *
 * Diseñado para A4 portrait — columnas: Cuenta, Descripcion, Tipo, Nivel.
 * Compatible con @zentto/report-core ReportLayout.
 *
 * DataSources esperados:
 *  - header (object): empresa, totalCuentas
 *  - cuentas (array): codCuenta, descripcion, tipo, nivel
 */
export const PLAN_CUENTAS_LAYOUT = {
  version: "1.0",
  name: "Plan de Cuentas",
  description: "Catalogo de cuentas contables con tipo y nivel jerarquico",
  pageSize: { width: 210, height: 297, unit: "mm" },
  margins: { top: 12, right: 15, bottom: 12, left: 15 },
  orientation: "portrait" as const,
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object" as const,
      endpoint: "/v1/contabilidad/cuentas",
      fields: [
        { name: "empresa", label: "Empresa", type: "string" },
        { name: "totalCuentas", label: "Total Cuentas", type: "number" },
      ],
    },
    {
      id: "cuentas",
      name: "Cuentas",
      type: "array" as const,
      endpoint: "/v1/contabilidad/cuentas",
      fields: [
        { name: "codCuenta", label: "Cuenta", type: "string" },
        { name: "descripcion", label: "Descripcion", type: "string" },
        { name: "tipo", label: "Tipo", type: "string" },
        { name: "nivel", label: "Nivel", type: "number" },
      ],
    },
  ],
  bands: [
    /* ── Report Header ───────────────────────────────────────── */
    {
      id: "rh",
      type: "reportHeader",
      height: 22,
      elements: [
        {
          id: "rh-title",
          type: "text",
          content: "PLAN DE CUENTAS",
          x: 0, y: 0, width: 180, height: 9,
          style: { fontSize: 14, fontWeight: "bold", textAlign: "center", color: "#1a1a1a" },
        },
        {
          id: "rh-empresa",
          type: "field",
          dataSource: "header",
          field: "empresa",
          x: 0, y: 10, width: 130, height: 5,
          style: { fontSize: 9, fontWeight: "bold", color: "#555" },
        },
        {
          id: "rh-total-label",
          type: "text",
          content: "Total cuentas:",
          x: 120, y: 10, width: 30, height: 5,
          style: { fontSize: 8, fontWeight: "bold", color: "#555", textAlign: "right" },
        },
        {
          id: "rh-total",
          type: "field",
          dataSource: "header",
          field: "totalCuentas",
          x: 152, y: 10, width: 28, height: 5,
          format: "#,##0",
          style: { fontSize: 8, color: "#555" },
        },
        {
          id: "rh-line",
          type: "line",
          x: 0, y: 18, width: 180, height: 0,
          x2: 180, y2: 18,
          lineStyle: { color: "#e67e22", width: 1.5, style: "solid" },
        },
      ],
    },

    /* ── Column Header ───────────────────────────────────────── */
    {
      id: "ch",
      type: "columnHeader",
      height: 8,
      repeatOnEveryPage: true,
      backgroundColor: "#e67e22",
      elements: [
        { id: "ch-cuenta", type: "text", content: "Cuenta", x: 0, y: 1, width: 35, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-desc", type: "text", content: "Descripcion", x: 36, y: 1, width: 90, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-tipo", type: "text", content: "Tipo", x: 127, y: 1, width: 33, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-nivel", type: "text", content: "Nivel", x: 161, y: 1, width: 19, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
      ],
    },

    /* ── Detail (one row per cuenta) ─────────────────────────── */
    {
      id: "det",
      type: "detail",
      height: 6,
      dataSource: "cuentas",
      elements: [
        { id: "d-cuenta", type: "field", dataSource: "cuentas", field: "codCuenta", x: 0, y: 0.5, width: 35, height: 5, style: { fontSize: 7 } },
        { id: "d-desc", type: "field", dataSource: "cuentas", field: "descripcion", x: 36, y: 0.5, width: 90, height: 5, style: { fontSize: 7 } },
        { id: "d-tipo", type: "field", dataSource: "cuentas", field: "tipo", x: 127, y: 0.5, width: 33, height: 5, style: { fontSize: 7 } },
        { id: "d-nivel", type: "field", dataSource: "cuentas", field: "nivel", x: 161, y: 0.5, width: 19, height: 5, style: { fontSize: 7, textAlign: "center" } },
      ],
    },

    /* ── Report Footer ───────────────────────────────────────── */
    {
      id: "rf",
      type: "reportFooter",
      height: 12,
      elements: [
        {
          id: "rf-line",
          type: "line",
          x: 0, y: 1, width: 180, height: 0,
          x2: 180, y2: 1,
          lineStyle: { color: "#e67e22", width: 1.5, style: "solid" },
        },
        {
          id: "rf-count-label",
          type: "text",
          content: "Total cuentas:",
          x: 0, y: 4, width: 30, height: 5,
          style: { fontSize: 8, fontWeight: "bold" },
        },
        {
          id: "rf-count",
          type: "field",
          dataSource: "header",
          field: "totalCuentas",
          x: 31, y: 4, width: 20, height: 5,
          format: "#,##0",
          style: { fontSize: 8, fontWeight: "bold" },
        },
      ],
    },

    /* ── Page Footer ─────────────────────────────────────────── */
    {
      id: "pf",
      type: "pageFooter",
      height: 8,
      elements: [
        {
          id: "pf-line",
          type: "line",
          x: 0, y: 0, width: 180, height: 0,
          x2: 180, y2: 0,
          lineStyle: { color: "#ccc", width: 0.5, style: "solid" },
        },
        {
          id: "pf-page",
          type: "pageNumber",
          format: "Pagina {page} de {pages}",
          x: 55, y: 2, width: 70, height: 5,
          style: { fontSize: 7, textAlign: "center", color: "#999" },
        },
        {
          id: "pf-date",
          type: "currentDate",
          format: "dd/MM/yyyy HH:mm",
          x: 117, y: 2, width: 63, height: 5,
          style: { fontSize: 7, textAlign: "right", color: "#999" },
        },
      ],
    },
  ],
};

export const PLAN_CUENTAS_LAYOUT_SAMPLE = {
  header: {
    empresa: "Zentto Soluciones Tecnologicas S.L.",
    totalCuentas: 7,
  },
  cuentas: [
    { codCuenta: "1", descripcion: "Activo", tipo: "TITULO", nivel: 1 },
    { codCuenta: "1.1", descripcion: "Activo Circulante", tipo: "TITULO", nivel: 2 },
    { codCuenta: "1.1.01", descripcion: "Caja General", tipo: "DETALLE", nivel: 3 },
    { codCuenta: "1.1.02", descripcion: "Banesco Cta. Corriente", tipo: "DETALLE", nivel: 3 },
    { codCuenta: "2", descripcion: "Pasivo", tipo: "TITULO", nivel: 1 },
    { codCuenta: "2.1", descripcion: "Pasivo Circulante", tipo: "TITULO", nivel: 2 },
    { codCuenta: "2.1.01", descripcion: "Cuentas por pagar proveedores", tipo: "DETALLE", nivel: 3 },
  ],
};
