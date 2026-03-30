/**
 * Layout JSON para el reporte "Centros de Costo".
 *
 * Diseñado para A4 portrait — columnas: Codigo, Nombre, Responsable, Presupuesto, Estado.
 * Compatible con @zentto/report-core ReportLayout.
 *
 * DataSources esperados:
 *  - header (object): empresa, totalCentros
 *  - centros (array): codigo, nombre, responsable, presupuesto, estado
 */
export const CENTRO_COSTO_LAYOUT = {
  version: "1.0",
  name: "Centros de Costo",
  description: "Listado tabular de centros de costo con responsable y presupuesto",
  pageSize: { width: 210, height: 297, unit: "mm" },
  margins: { top: 15, right: 15, bottom: 15, left: 15 },
  orientation: "portrait" as const,
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object" as const,
      endpoint: "/v1/centro-costo",
      fields: [
        { name: "empresa", label: "Empresa", type: "string" },
        { name: "totalCentros", label: "Total Centros", type: "number" },
      ],
    },
    {
      id: "centros",
      name: "Centros",
      type: "array" as const,
      endpoint: "/v1/centro-costo",
      fields: [
        { name: "codigo", label: "Codigo", type: "string" },
        { name: "nombre", label: "Nombre", type: "string" },
        { name: "responsable", label: "Responsable", type: "string" },
        { name: "presupuesto", label: "Presupuesto", type: "currency" },
        { name: "estado", label: "Estado", type: "string" },
      ],
    },
  ],
  bands: [
    /* -- Report Header ------------------------------------------------- */
    {
      id: "rh",
      type: "reportHeader",
      height: 22,
      elements: [
        {
          id: "rh-title",
          type: "text",
          content: "CENTROS DE COSTO",
          x: 0, y: 0, width: 180, height: 9,
          style: { fontSize: 14, fontWeight: "bold", textAlign: "center", color: "#1a1a1a" },
        },
        {
          id: "rh-empresa",
          type: "field",
          dataSource: "header",
          field: "empresa",
          x: 0, y: 10, width: 100, height: 5,
          style: { fontSize: 9, fontWeight: "bold", color: "#555" },
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

    /* -- Column Header ------------------------------------------------- */
    {
      id: "ch",
      type: "columnHeader",
      height: 8,
      repeatOnEveryPage: true,
      backgroundColor: "#e67e22",
      elements: [
        { id: "ch-codigo", type: "text", content: "Codigo", x: 0, y: 1, width: 25, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-nombre", type: "text", content: "Nombre", x: 26, y: 1, width: 50, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-resp", type: "text", content: "Responsable", x: 77, y: 1, width: 40, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-ppto", type: "text", content: "Presupuesto", x: 118, y: 1, width: 35, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-estado", type: "text", content: "Estado", x: 154, y: 1, width: 26, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
      ],
    },

    /* -- Detail (one row per centro) ----------------------------------- */
    {
      id: "det",
      type: "detail",
      height: 6,
      dataSource: "centros",
      elements: [
        { id: "d-codigo", type: "field", dataSource: "centros", field: "codigo", x: 0, y: 0.5, width: 25, height: 5, style: { fontSize: 7 } },
        { id: "d-nombre", type: "field", dataSource: "centros", field: "nombre", x: 26, y: 0.5, width: 50, height: 5, style: { fontSize: 7 } },
        { id: "d-resp", type: "field", dataSource: "centros", field: "responsable", x: 77, y: 0.5, width: 40, height: 5, style: { fontSize: 7 } },
        { id: "d-ppto", type: "field", dataSource: "centros", field: "presupuesto", x: 118, y: 0.5, width: 35, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-estado", type: "field", dataSource: "centros", field: "estado", x: 154, y: 0.5, width: 26, height: 5, style: { fontSize: 7, textAlign: "center" } },
      ],
    },

    /* -- Report Footer (totals) ---------------------------------------- */
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
          content: "Total centros:",
          x: 0, y: 4, width: 30, height: 5,
          style: { fontSize: 8, fontWeight: "bold" },
        },
        {
          id: "rf-count",
          type: "field",
          dataSource: "header",
          field: "totalCentros",
          x: 31, y: 4, width: 20, height: 5,
          format: "#,##0",
          style: { fontSize: 8, fontWeight: "bold", color: "#e67e22" },
        },
      ],
    },

    /* -- Page Footer --------------------------------------------------- */
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
          x: 50, y: 2, width: 80, height: 5,
          style: { fontSize: 7, textAlign: "center", color: "#999" },
        },
        {
          id: "pf-date",
          type: "currentDate",
          format: "dd/MM/yyyy HH:mm",
          x: 120, y: 2, width: 60, height: 5,
          style: { fontSize: 7, textAlign: "right", color: "#999" },
        },
      ],
    },
  ],
};
