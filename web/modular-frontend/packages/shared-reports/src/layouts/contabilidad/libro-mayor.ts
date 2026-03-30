/**
 * Layout JSON para el reporte "Libro Mayor".
 *
 * Diseñado para A4 landscape — columnas: Cuenta, Descripcion, Fecha, Concepto, Debe, Haber, Saldo.
 * Compatible con @zentto/report-core ReportLayout.
 *
 * DataSources esperados:
 *  - header (object): empresa, fechaDesde, fechaHasta
 *  - movimientos (array): codCuenta, descripcion, fecha, concepto, debe, haber, saldo
 */
export const LIBRO_MAYOR_LAYOUT = {
  version: "1.0",
  name: "Libro Mayor",
  description: "Reporte de movimientos del libro mayor por cuenta contable",
  pageSize: { width: 297, height: 210, unit: "mm" },
  margins: { top: 12, right: 12, bottom: 12, left: 12 },
  orientation: "landscape" as const,
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object" as const,
      endpoint: "/v1/contabilidad/reportes/libro-mayor",
      fields: [
        { name: "empresa", label: "Empresa", type: "string" },
        { name: "fechaDesde", label: "Fecha desde", type: "string" },
        { name: "fechaHasta", label: "Fecha hasta", type: "string" },
      ],
    },
    {
      id: "movimientos",
      name: "Movimientos",
      type: "array" as const,
      endpoint: "/v1/contabilidad/reportes/libro-mayor",
      fields: [
        { name: "codCuenta", label: "Cuenta", type: "string" },
        { name: "descripcion", label: "Descripcion", type: "string" },
        { name: "fecha", label: "Fecha", type: "string" },
        { name: "concepto", label: "Concepto", type: "string" },
        { name: "debe", label: "Debe", type: "currency" },
        { name: "haber", label: "Haber", type: "currency" },
        { name: "saldo", label: "Saldo", type: "currency" },
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
          content: "LIBRO MAYOR",
          x: 0, y: 0, width: 273, height: 9,
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
          id: "rh-rango-label",
          type: "text",
          content: "Periodo:",
          x: 180, y: 10, width: 16, height: 5,
          style: { fontSize: 8, fontWeight: "bold", color: "#555" },
        },
        {
          id: "rh-desde",
          type: "field",
          dataSource: "header",
          field: "fechaDesde",
          x: 197, y: 10, width: 30, height: 5,
          style: { fontSize: 8, color: "#555" },
        },
        {
          id: "rh-sep",
          type: "text",
          content: "—",
          x: 228, y: 10, width: 6, height: 5,
          style: { fontSize: 8, textAlign: "center", color: "#555" },
        },
        {
          id: "rh-hasta",
          type: "field",
          dataSource: "header",
          field: "fechaHasta",
          x: 235, y: 10, width: 38, height: 5,
          style: { fontSize: 8, color: "#555" },
        },
        {
          id: "rh-line",
          type: "line",
          x: 0, y: 18, width: 273, height: 0,
          x2: 273, y2: 18,
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
        { id: "ch-cuenta", type: "text", content: "Cuenta", x: 0, y: 1, width: 30, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-desc", type: "text", content: "Descripcion", x: 31, y: 1, width: 60, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-fecha", type: "text", content: "Fecha", x: 92, y: 1, width: 28, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-concepto", type: "text", content: "Concepto", x: 121, y: 1, width: 72, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-debe", type: "text", content: "Debe", x: 194, y: 1, width: 26, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-haber", type: "text", content: "Haber", x: 221, y: 1, width: 26, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-saldo", type: "text", content: "Saldo", x: 248, y: 1, width: 25, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
      ],
    },

    /* ── Detail (one row per movimiento) ─────────────────────── */
    {
      id: "det",
      type: "detail",
      height: 6,
      dataSource: "movimientos",
      elements: [
        { id: "d-cuenta", type: "field", dataSource: "movimientos", field: "codCuenta", x: 0, y: 0.5, width: 30, height: 5, style: { fontSize: 7 } },
        { id: "d-desc", type: "field", dataSource: "movimientos", field: "descripcion", x: 31, y: 0.5, width: 60, height: 5, style: { fontSize: 7 } },
        { id: "d-fecha", type: "field", dataSource: "movimientos", field: "fecha", x: 92, y: 0.5, width: 28, height: 5, style: { fontSize: 7 } },
        { id: "d-concepto", type: "field", dataSource: "movimientos", field: "concepto", x: 121, y: 0.5, width: 72, height: 5, style: { fontSize: 7 } },
        { id: "d-debe", type: "field", dataSource: "movimientos", field: "debe", x: 194, y: 0.5, width: 26, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-haber", type: "field", dataSource: "movimientos", field: "haber", x: 221, y: 0.5, width: 26, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-saldo", type: "field", dataSource: "movimientos", field: "saldo", x: 248, y: 0.5, width: 25, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
      ],
    },

    /* ── Report Footer (totals) ──────────────────────────────── */
    {
      id: "rf",
      type: "reportFooter",
      height: 12,
      elements: [
        {
          id: "rf-line",
          type: "line",
          x: 0, y: 1, width: 273, height: 0,
          x2: 273, y2: 1,
          lineStyle: { color: "#e67e22", width: 1.5, style: "solid" },
        },
        {
          id: "rf-totals-label",
          type: "text",
          content: "Totales:",
          x: 155, y: 4, width: 38, height: 5,
          style: { fontSize: 9, fontWeight: "bold", textAlign: "right" },
        },
        {
          id: "rf-debe",
          type: "aggregation",
          aggregation: "sum",
          dataSource: "movimientos",
          field: "debe",
          x: 194, y: 4, width: 26, height: 5,
          format: "#,##0.00",
          style: { fontSize: 9, fontWeight: "bold", textAlign: "right", color: "#e67e22" },
        },
        {
          id: "rf-haber",
          type: "aggregation",
          aggregation: "sum",
          dataSource: "movimientos",
          field: "haber",
          x: 221, y: 4, width: 26, height: 5,
          format: "#,##0.00",
          style: { fontSize: 9, fontWeight: "bold", textAlign: "right", color: "#e67e22" },
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
          x: 0, y: 0, width: 273, height: 0,
          x2: 273, y2: 0,
          lineStyle: { color: "#ccc", width: 0.5, style: "solid" },
        },
        {
          id: "pf-page",
          type: "pageNumber",
          format: "Pagina {page} de {pages}",
          x: 100, y: 2, width: 73, height: 5,
          style: { fontSize: 7, textAlign: "center", color: "#999" },
        },
        {
          id: "pf-date",
          type: "currentDate",
          format: "dd/MM/yyyy HH:mm",
          x: 210, y: 2, width: 63, height: 5,
          style: { fontSize: 7, textAlign: "right", color: "#999" },
        },
      ],
    },
  ],
};
