/**
 * Layout JSON para el reporte "Listado de Clientes".
 *
 * Diseñado para A4 landscape — columnas: Codigo, Nombre, RIF, Direccion,
 * Telefono, Email, Vendedor, Saldo, Estado.
 * Compatible con @zentto/report-core ReportLayout.
 *
 * Endpoint: /v1/clientes
 *
 * DataSources esperados:
 *  - header (object): empresa, totalClientes
 *  - clientes (array): codigo, nombre, rif, direccion, telefono, email,
 *    vendedor, saldo, estado
 */
export const CLIENTES_LAYOUT = {
  version: "1.0",
  name: "Listado de Clientes",
  description: "Listado tabular de clientes con saldos y datos de contacto",
  pageSize: { width: 297, height: 210, unit: "mm" },
  margins: { top: 12, right: 12, bottom: 12, left: 12 },
  orientation: "landscape" as const,
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object" as const,
      endpoint: "/v1/clientes",
      fields: [
        { name: "empresa", label: "Empresa", type: "string" },
        { name: "totalClientes", label: "Total Clientes", type: "number" },
      ],
    },
    {
      id: "clientes",
      name: "Clientes",
      type: "array" as const,
      endpoint: "/v1/clientes",
      fields: [
        { name: "codigo", label: "Codigo", type: "string" },
        { name: "nombre", label: "Nombre", type: "string" },
        { name: "rif", label: "RIF", type: "string" },
        { name: "direccion", label: "Direccion", type: "string" },
        { name: "telefono", label: "Telefono", type: "string" },
        { name: "email", label: "Email", type: "string" },
        { name: "vendedor", label: "Vendedor", type: "string" },
        { name: "saldo", label: "Saldo", type: "currency" },
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
          content: "LISTADO DE CLIENTES",
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
          id: "rh-total-label",
          type: "text",
          content: "Total clientes:",
          x: 210, y: 10, width: 30, height: 5,
          style: { fontSize: 8, fontWeight: "bold", color: "#555" },
        },
        {
          id: "rh-total",
          type: "field",
          dataSource: "header",
          field: "totalClientes",
          x: 241, y: 10, width: 32, height: 5,
          format: "#,##0",
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

    /* -- Column Header ------------------------------------------------- */
    {
      id: "ch",
      type: "columnHeader",
      height: 8,
      repeatOnEveryPage: true,
      backgroundColor: "#e67e22",
      elements: [
        { id: "ch-codigo", type: "text", content: "Codigo", x: 0, y: 1, width: 20, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-nombre", type: "text", content: "Nombre", x: 21, y: 1, width: 52, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-rif", type: "text", content: "RIF", x: 74, y: 1, width: 26, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-direccion", type: "text", content: "Direccion", x: 101, y: 1, width: 48, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-telefono", type: "text", content: "Telefono", x: 150, y: 1, width: 26, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-email", type: "text", content: "Email", x: 177, y: 1, width: 34, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-vendedor", type: "text", content: "Vendedor", x: 212, y: 1, width: 26, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-saldo", type: "text", content: "Saldo", x: 239, y: 1, width: 22, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-estado", type: "text", content: "Estado", x: 262, y: 1, width: 11, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
      ],
    },

    /* -- Detail (one row per cliente) ---------------------------------- */
    {
      id: "det",
      type: "detail",
      height: 6,
      dataSource: "clientes",
      elements: [
        { id: "d-codigo", type: "field", dataSource: "clientes", field: "codigo", x: 0, y: 0.5, width: 20, height: 5, style: { fontSize: 7 } },
        { id: "d-nombre", type: "field", dataSource: "clientes", field: "nombre", x: 21, y: 0.5, width: 52, height: 5, style: { fontSize: 7 } },
        { id: "d-rif", type: "field", dataSource: "clientes", field: "rif", x: 74, y: 0.5, width: 26, height: 5, style: { fontSize: 7 } },
        { id: "d-direccion", type: "field", dataSource: "clientes", field: "direccion", x: 101, y: 0.5, width: 48, height: 5, style: { fontSize: 7 } },
        { id: "d-telefono", type: "field", dataSource: "clientes", field: "telefono", x: 150, y: 0.5, width: 26, height: 5, style: { fontSize: 7 } },
        { id: "d-email", type: "field", dataSource: "clientes", field: "email", x: 177, y: 0.5, width: 34, height: 5, style: { fontSize: 7 } },
        { id: "d-vendedor", type: "field", dataSource: "clientes", field: "vendedor", x: 212, y: 0.5, width: 26, height: 5, style: { fontSize: 7 } },
        { id: "d-saldo", type: "field", dataSource: "clientes", field: "saldo", x: 239, y: 0.5, width: 22, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-estado", type: "field", dataSource: "clientes", field: "estado", x: 262, y: 0.5, width: 11, height: 5, style: { fontSize: 7, textAlign: "center" } },
      ],
    },

    /* -- Report Footer (totals) ---------------------------------------- */
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
          content: "Total clientes:",
          x: 0, y: 4, width: 30, height: 5,
          style: { fontSize: 8, fontWeight: "bold" },
        },
        {
          id: "rf-count",
          type: "field",
          dataSource: "header",
          field: "totalClientes",
          x: 31, y: 4, width: 20, height: 5,
          format: "#,##0",
          style: { fontSize: 8, fontWeight: "bold" },
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
