/**
 * Layout JSON para el reporte "Listado de Articulos / Productos".
 *
 * Diseñado para A4 landscape — columnas: Codigo, Nombre, Categoria, Marca, Unidad, Stock, Precio Unit., Estado.
 * Compatible con @zentto/report-core ReportLayout.
 *
 * DataSources esperados:
 *  - header (object): empresa, totalArticulos
 *  - articulos (array): codigo, nombre, categoria, marca, unidad, stock, precioUnitario, estado
 */
export const ARTICULOS_LAYOUT = {
  version: "1.0",
  name: "Listado de Articulos",
  description: "Listado tabular de articulos/productos del inventario",
  pageSize: { width: 297, height: 210, unit: "mm" },
  margins: { top: 12, right: 12, bottom: 12, left: 12 },
  orientation: "landscape" as const,
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object" as const,
      endpoint: "/v1/inventario",
      fields: [
        { name: "empresa", label: "Empresa", type: "string" },
        { name: "totalArticulos", label: "Total Articulos", type: "number" },
      ],
    },
    {
      id: "articulos",
      name: "Articulos",
      type: "array" as const,
      endpoint: "/v1/inventario",
      fields: [
        { name: "codigo", label: "Codigo", type: "string" },
        { name: "nombre", label: "Nombre", type: "string" },
        { name: "categoria", label: "Categoria", type: "string" },
        { name: "marca", label: "Marca", type: "string" },
        { name: "unidad", label: "Unidad", type: "string" },
        { name: "stock", label: "Stock", type: "number" },
        { name: "precioUnitario", label: "Precio Unit.", type: "currency" },
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
          content: "LISTADO DE ARTICULOS",
          x: 0, y: 0, width: 273, height: 9,
          style: { fontSize: 14, fontWeight: "bold", textAlign: "center", color: "#1a1a1a" },
        },
        {
          id: "rh-empresa",
          type: "field",
          dataSource: "header",
          field: "empresa",
          x: 0, y: 10, width: 200, height: 5,
          style: { fontSize: 9, fontWeight: "bold", color: "#555" },
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

    /* -- Column Header ------------------------------------------------- */
    {
      id: "ch",
      type: "columnHeader",
      height: 8,
      repeatOnEveryPage: true,
      backgroundColor: "#e67e22",
      elements: [
        { id: "ch-codigo", type: "text", content: "Codigo", x: 0, y: 1, width: 28, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-nombre", type: "text", content: "Nombre", x: 28, y: 1, width: 70, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-categoria", type: "text", content: "Categoria", x: 98, y: 1, width: 38, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-marca", type: "text", content: "Marca", x: 136, y: 1, width: 35, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-unidad", type: "text", content: "Unidad", x: 171, y: 1, width: 22, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
        { id: "ch-stock", type: "text", content: "Stock", x: 193, y: 1, width: 25, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-precio", type: "text", content: "Precio Unit.", x: 218, y: 1, width: 30, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-estado", type: "text", content: "Estado", x: 248, y: 1, width: 25, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
      ],
    },

    /* -- Detail (one row per articulo) --------------------------------- */
    {
      id: "det",
      type: "detail",
      height: 6,
      dataSource: "articulos",
      elements: [
        { id: "d-codigo", type: "field", dataSource: "articulos", field: "codigo", x: 0, y: 0.5, width: 28, height: 5, style: { fontSize: 7 } },
        { id: "d-nombre", type: "field", dataSource: "articulos", field: "nombre", x: 28, y: 0.5, width: 70, height: 5, style: { fontSize: 7 } },
        { id: "d-categoria", type: "field", dataSource: "articulos", field: "categoria", x: 98, y: 0.5, width: 38, height: 5, style: { fontSize: 7 } },
        { id: "d-marca", type: "field", dataSource: "articulos", field: "marca", x: 136, y: 0.5, width: 35, height: 5, style: { fontSize: 7 } },
        { id: "d-unidad", type: "field", dataSource: "articulos", field: "unidad", x: 171, y: 0.5, width: 22, height: 5, style: { fontSize: 7, textAlign: "center" } },
        { id: "d-stock", type: "field", dataSource: "articulos", field: "stock", x: 193, y: 0.5, width: 25, height: 5, format: "#,##0", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-precio", type: "field", dataSource: "articulos", field: "precioUnitario", x: 218, y: 0.5, width: 30, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-estado", type: "field", dataSource: "articulos", field: "estado", x: 248, y: 0.5, width: 25, height: 5, style: { fontSize: 7, textAlign: "center" } },
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
          x: 0, y: 1, width: 273, height: 0,
          x2: 273, y2: 1,
          lineStyle: { color: "#e67e22", width: 1.5, style: "solid" },
        },
        {
          id: "rf-count-label",
          type: "text",
          content: "Total articulos:",
          x: 0, y: 4, width: 30, height: 5,
          style: { fontSize: 8, fontWeight: "bold" },
        },
        {
          id: "rf-count",
          type: "field",
          dataSource: "header",
          field: "totalArticulos",
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
