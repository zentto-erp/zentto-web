/**
 * Layout JSON para el reporte "Libro Diario".
 *
 * Diseñado para A4 landscape — columnas: Fecha, N. Asiento, Cuenta, Descripcion, Concepto, Debe, Haber.
 * Compatible con @zentto/report-core ReportLayout.
 *
 * DataSources esperados:
 *  - header (object): empresa, fechaDesde, fechaHasta
 *  - asientos (array): fecha, numeroAsiento, codCuenta, descripcion, concepto, debe, haber
 */
export const LIBRO_DIARIO_LAYOUT = {
  version: "1.0",
  name: "Libro Diario",
  description: "Reporte del libro diario con detalle de asientos contables",
  pageSize: { width: 297, height: 210, unit: "mm" },
  margins: { top: 12, right: 12, bottom: 12, left: 12 },
  orientation: "landscape" as const,
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object" as const,
      endpoint: "/v1/contabilidad/reportes/libro-diario",
      fields: [
        { name: "empresa", label: "Empresa", type: "string" },
        { name: "fechaDesde", label: "Fecha desde", type: "string" },
        { name: "fechaHasta", label: "Fecha hasta", type: "string" },
      ],
    },
    {
      id: "asientos",
      name: "Asientos",
      type: "array" as const,
      endpoint: "/v1/contabilidad/reportes/libro-diario",
      fields: [
        { name: "fecha", label: "Fecha", type: "string" },
        { name: "numeroAsiento", label: "N. Asiento", type: "number" },
        { name: "codCuenta", label: "Cuenta", type: "string" },
        { name: "descripcion", label: "Descripcion", type: "string" },
        { name: "concepto", label: "Concepto", type: "string" },
        { name: "debe", label: "Debe", type: "currency" },
        { name: "haber", label: "Haber", type: "currency" },
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
          content: "LIBRO DIARIO",
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
        { id: "ch-fecha", type: "text", content: "Fecha", x: 0, y: 1, width: 28, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-num", type: "text", content: "N. Asiento", x: 29, y: 1, width: 25, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
        { id: "ch-cuenta", type: "text", content: "Cuenta", x: 55, y: 1, width: 30, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-desc", type: "text", content: "Descripcion", x: 86, y: 1, width: 55, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-concepto", type: "text", content: "Concepto", x: 142, y: 1, width: 63, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-debe", type: "text", content: "Debe", x: 206, y: 1, width: 33, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-haber", type: "text", content: "Haber", x: 240, y: 1, width: 33, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
      ],
    },

    /* ── Detail (one row per asiento) ────────────────────────── */
    {
      id: "det",
      type: "detail",
      height: 6,
      dataSource: "asientos",
      elements: [
        { id: "d-fecha", type: "field", dataSource: "asientos", field: "fecha", x: 0, y: 0.5, width: 28, height: 5, style: { fontSize: 7 } },
        { id: "d-num", type: "field", dataSource: "asientos", field: "numeroAsiento", x: 29, y: 0.5, width: 25, height: 5, style: { fontSize: 7, textAlign: "center" } },
        { id: "d-cuenta", type: "field", dataSource: "asientos", field: "codCuenta", x: 55, y: 0.5, width: 30, height: 5, style: { fontSize: 7 } },
        { id: "d-desc", type: "field", dataSource: "asientos", field: "descripcion", x: 86, y: 0.5, width: 55, height: 5, style: { fontSize: 7 } },
        { id: "d-concepto", type: "field", dataSource: "asientos", field: "concepto", x: 142, y: 0.5, width: 63, height: 5, style: { fontSize: 7 } },
        { id: "d-debe", type: "field", dataSource: "asientos", field: "debe", x: 206, y: 0.5, width: 33, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-haber", type: "field", dataSource: "asientos", field: "haber", x: 240, y: 0.5, width: 33, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
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
          x: 155, y: 4, width: 50, height: 5,
          style: { fontSize: 9, fontWeight: "bold", textAlign: "right" },
        },
        {
          id: "rf-debe",
          type: "aggregation",
          aggregation: "sum",
          dataSource: "asientos",
          field: "debe",
          x: 206, y: 4, width: 33, height: 5,
          format: "#,##0.00",
          style: { fontSize: 9, fontWeight: "bold", textAlign: "right", color: "#e67e22" },
        },
        {
          id: "rf-haber",
          type: "aggregation",
          aggregation: "sum",
          dataSource: "asientos",
          field: "haber",
          x: 240, y: 4, width: 33, height: 5,
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

export const LIBRO_DIARIO_LAYOUT_SAMPLE = {
  header: {
    empresa: "Zentto Soluciones Tecnologicas S.L.",
    fechaDesde: "01/01/2026",
    fechaHasta: "31/03/2026",
  },
  asientos: [
    { fecha: "05/01/2026", numeroAsiento: 1, codCuenta: "1.1.01", descripcion: "Caja General", concepto: "Cobro factura FV-001", debe: 12500.00, haber: 0.00 },
    { fecha: "05/01/2026", numeroAsiento: 1, codCuenta: "4.1.01", descripcion: "Ventas nacionales", concepto: "Cobro factura FV-001", debe: 0.00, haber: 12500.00 },
    { fecha: "15/01/2026", numeroAsiento: 2, codCuenta: "1.1.02", descripcion: "Banesco Cta. Corriente", concepto: "Deposito cliente Martinez", debe: 28750.00, haber: 0.00 },
    { fecha: "15/01/2026", numeroAsiento: 2, codCuenta: "1.1.01", descripcion: "Caja General", concepto: "Deposito cliente Martinez", debe: 0.00, haber: 28750.00 },
    { fecha: "28/02/2026", numeroAsiento: 5, codCuenta: "6.1.03", descripcion: "Gastos de personal", concepto: "Nomina febrero 2026", debe: 18200.00, haber: 0.00 },
    { fecha: "28/02/2026", numeroAsiento: 5, codCuenta: "1.1.02", descripcion: "Banesco Cta. Corriente", concepto: "Nomina febrero 2026", debe: 0.00, haber: 18200.00 },
    { fecha: "15/03/2026", numeroAsiento: 8, codCuenta: "1.2.01", descripcion: "Inventario de mercancia", concepto: "Compra inventario a credito", debe: 22000.00, haber: 0.00 },
    { fecha: "15/03/2026", numeroAsiento: 8, codCuenta: "2.1.01", descripcion: "Cuentas por pagar", concepto: "Compra inventario a credito", debe: 0.00, haber: 22000.00 },
  ],
};
