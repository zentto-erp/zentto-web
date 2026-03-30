/**
 * Layout JSON para el reporte "Categorias".
 *
 * Diseñado para A4 portrait — columnas: Codigo, Descripcion, Tipo, Estado.
 * Compatible con @zentto/report-core ReportLayout.
 *
 * DataSources esperados:
 *  - header (object): empresa, totalCategorias
 *  - categorias (array): codigo, descripcion, tipo, estado
 */
export const CATEGORIAS_LAYOUT = {
  version: "1.0",
  name: "Categorias",
  description: "Listado tabular de categorias maestras con tipo y estado",
  pageSize: { width: 210, height: 297, unit: "mm" },
  margins: { top: 15, right: 15, bottom: 15, left: 15 },
  orientation: "portrait" as const,
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object" as const,
      endpoint: "/v1/categorias",
      fields: [
        { name: "empresa", label: "Empresa", type: "string" },
        { name: "totalCategorias", label: "Total Categorias", type: "number" },
      ],
    },
    {
      id: "categorias",
      name: "Categorias",
      type: "array" as const,
      endpoint: "/v1/categorias",
      fields: [
        { name: "codigo", label: "Codigo", type: "string" },
        { name: "descripcion", label: "Descripcion", type: "string" },
        { name: "tipo", label: "Tipo", type: "string" },
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
          content: "CATEGORIAS",
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
        { id: "ch-codigo", type: "text", content: "Codigo", x: 0, y: 1, width: 30, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-desc", type: "text", content: "Descripcion", x: 31, y: 1, width: 80, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-tipo", type: "text", content: "Tipo", x: 112, y: 1, width: 35, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-estado", type: "text", content: "Estado", x: 148, y: 1, width: 32, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
      ],
    },

    /* -- Detail (one row per categoria) -------------------------------- */
    {
      id: "det",
      type: "detail",
      height: 6,
      dataSource: "categorias",
      elements: [
        { id: "d-codigo", type: "field", dataSource: "categorias", field: "codigo", x: 0, y: 0.5, width: 30, height: 5, style: { fontSize: 7 } },
        { id: "d-desc", type: "field", dataSource: "categorias", field: "descripcion", x: 31, y: 0.5, width: 80, height: 5, style: { fontSize: 7 } },
        { id: "d-tipo", type: "field", dataSource: "categorias", field: "tipo", x: 112, y: 0.5, width: 35, height: 5, style: { fontSize: 7 } },
        { id: "d-estado", type: "field", dataSource: "categorias", field: "estado", x: 148, y: 0.5, width: 32, height: 5, style: { fontSize: 7, textAlign: "center" } },
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
          content: "Total categorias:",
          x: 0, y: 4, width: 35, height: 5,
          style: { fontSize: 8, fontWeight: "bold" },
        },
        {
          id: "rf-count",
          type: "field",
          dataSource: "header",
          field: "totalCategorias",
          x: 36, y: 4, width: 20, height: 5,
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
