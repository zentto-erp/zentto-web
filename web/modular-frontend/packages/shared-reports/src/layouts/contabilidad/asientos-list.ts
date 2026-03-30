/**
 * Layout JSON para el reporte "Listado de Asientos Contables".
 *
 * Diseñado para A4 landscape — columnas: #, ID, Fecha, Tipo, Concepto, Ref, Debe, Haber, Estado.
 * Compatible con @zentto/report-core ReportLayout.
 *
 * DataSources esperados:
 *  - header (object): empresa, fechaDesde, fechaHasta, totalDebe, totalHaber, totalRegistros
 *  - asientos (array): id, fecha, tipoAsiento, concepto, referencia, totalDebe, totalHaber, estado
 */
export const ASIENTOS_LIST_LAYOUT = {
  version: "1.0",
  name: "Listado de Asientos Contables",
  description: "Listado tabular de asientos contables con totales Debe/Haber",
  pageSize: { width: 297, height: 210, unit: "mm" },
  margins: { top: 12, right: 12, bottom: 12, left: 12 },
  orientation: "landscape" as const,
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object" as const,
      endpoint: "/v1/contabilidad/empresa",
      fields: [
        { name: "empresa", label: "Empresa", type: "string" },
        { name: "fechaDesde", label: "Fecha desde", type: "string" },
        { name: "fechaHasta", label: "Fecha hasta", type: "string" },
        { name: "totalDebe", label: "Total Debe", type: "currency" },
        { name: "totalHaber", label: "Total Haber", type: "currency" },
        { name: "totalRegistros", label: "Total Registros", type: "number" },
      ],
    },
    {
      id: "asientos",
      name: "Asientos",
      type: "array" as const,
      endpoint: "/v1/contabilidad/asientos",
      fields: [
        { name: "num", label: "#", type: "number" },
        { name: "id", label: "ID", type: "number" },
        { name: "fecha", label: "Fecha", type: "string" },
        { name: "tipoAsiento", label: "Tipo", type: "string" },
        { name: "concepto", label: "Concepto", type: "string" },
        { name: "referencia", label: "Ref.", type: "string" },
        { name: "totalDebe", label: "Debe", type: "currency" },
        { name: "totalHaber", label: "Haber", type: "currency" },
        { name: "estado", label: "Estado", type: "string" },
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
          content: "LISTADO DE ASIENTOS CONTABLES",
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
        { id: "ch-num", type: "text", content: "#", x: 0, y: 1, width: 10, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
        { id: "ch-id", type: "text", content: "ID", x: 11, y: 1, width: 15, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
        { id: "ch-fecha", type: "text", content: "Fecha", x: 27, y: 1, width: 25, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-tipo", type: "text", content: "Tipo", x: 53, y: 1, width: 28, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-concepto", type: "text", content: "Concepto", x: 82, y: 1, width: 82, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-ref", type: "text", content: "Ref.", x: 165, y: 1, width: 22, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-debe", type: "text", content: "Debe", x: 188, y: 1, width: 30, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-haber", type: "text", content: "Haber", x: 219, y: 1, width: 30, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-estado", type: "text", content: "Estado", x: 250, y: 1, width: 23, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
      ],
    },

    /* ── Detail (one row per asiento) ────────────────────────── */
    {
      id: "det",
      type: "detail",
      height: 6,
      dataSource: "asientos",
      elements: [
        { id: "d-num", type: "field", dataSource: "asientos", field: "num", x: 0, y: 0.5, width: 10, height: 5, style: { fontSize: 7, textAlign: "center", color: "#888" } },
        { id: "d-id", type: "field", dataSource: "asientos", field: "id", x: 11, y: 0.5, width: 15, height: 5, style: { fontSize: 7, textAlign: "center" } },
        { id: "d-fecha", type: "field", dataSource: "asientos", field: "fecha", x: 27, y: 0.5, width: 25, height: 5, style: { fontSize: 7 } },
        { id: "d-tipo", type: "field", dataSource: "asientos", field: "tipoAsiento", x: 53, y: 0.5, width: 28, height: 5, style: { fontSize: 7 } },
        { id: "d-concepto", type: "field", dataSource: "asientos", field: "concepto", x: 82, y: 0.5, width: 82, height: 5, style: { fontSize: 7 } },
        { id: "d-ref", type: "field", dataSource: "asientos", field: "referencia", x: 165, y: 0.5, width: 22, height: 5, style: { fontSize: 7 } },
        { id: "d-debe", type: "field", dataSource: "asientos", field: "totalDebe", x: 188, y: 0.5, width: 30, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-haber", type: "field", dataSource: "asientos", field: "totalHaber", x: 219, y: 0.5, width: 30, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-estado", type: "field", dataSource: "asientos", field: "estado", x: 250, y: 0.5, width: 23, height: 5, style: { fontSize: 7, textAlign: "center" } },
      ],
    },

    /* ── Report Footer (totals) ──────────────────────────────── */
    {
      id: "rf",
      type: "reportFooter",
      height: 16,
      elements: [
        {
          id: "rf-line",
          type: "line",
          x: 0, y: 1, width: 273, height: 0,
          x2: 273, y2: 1,
          lineStyle: { color: "#e67e22", width: 1.5, style: "solid" },
        },
        {
          id: "rf-count-label",
          type: "text",
          content: "Total registros:",
          x: 0, y: 4, width: 30, height: 5,
          style: { fontSize: 8, fontWeight: "bold" },
        },
        {
          id: "rf-count",
          type: "field",
          dataSource: "header",
          field: "totalRegistros",
          x: 31, y: 4, width: 20, height: 5,
          format: "#,##0",
          style: { fontSize: 8, fontWeight: "bold" },
        },
        {
          id: "rf-totals-label",
          type: "text",
          content: "Totales:",
          x: 155, y: 4, width: 32, height: 5,
          style: { fontSize: 9, fontWeight: "bold", textAlign: "right" },
        },
        {
          id: "rf-debe",
          type: "field",
          dataSource: "header",
          field: "totalDebe",
          x: 188, y: 4, width: 30, height: 5,
          format: "#,##0.00",
          style: { fontSize: 9, fontWeight: "bold", textAlign: "right", color: "#e67e22" },
        },
        {
          id: "rf-haber",
          type: "field",
          dataSource: "header",
          field: "totalHaber",
          x: 219, y: 4, width: 30, height: 5,
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
