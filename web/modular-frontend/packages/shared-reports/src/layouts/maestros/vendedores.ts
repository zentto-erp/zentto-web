/**
 * Layout JSON para el reporte "Listado de Vendedores".
 *
 * Diseñado para A4 landscape — columnas: Codigo, Nombre, Zona, Comision%, Telefono, Email, Estado.
 * Compatible con @zentto/report-core ReportLayout.
 *
 * DataSources esperados:
 *  - header (object): empresa, totalVendedores
 *  - vendedores (array): codigo, nombre, zona, comisionPct, telefono, email, estado
 */
export const VENDEDORES_LAYOUT = {
  version: "1.0",
  name: "Listado de Vendedores",
  description: "Listado tabular de vendedores con zona, comision y datos de contacto",
  pageSize: { width: 297, height: 210, unit: "mm" },
  margins: { top: 12, right: 12, bottom: 12, left: 12 },
  orientation: "landscape" as const,
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object" as const,
      endpoint: "/v1/vendedores",
      fields: [
        { name: "empresa", label: "Empresa", type: "string" },
        { name: "totalVendedores", label: "Total Vendedores", type: "number" },
      ],
    },
    {
      id: "vendedores",
      name: "Vendedores",
      type: "array" as const,
      endpoint: "/v1/vendedores",
      fields: [
        { name: "codigo", label: "Codigo", type: "string" },
        { name: "nombre", label: "Nombre", type: "string" },
        { name: "zona", label: "Zona", type: "string" },
        { name: "comisionPct", label: "Comision %", type: "number" },
        { name: "telefono", label: "Telefono", type: "string" },
        { name: "email", label: "Email", type: "string" },
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
          content: "LISTADO DE VENDEDORES",
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
        { id: "ch-codigo", type: "text", content: "Codigo", x: 0, y: 1, width: 25, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-nombre", type: "text", content: "Nombre", x: 26, y: 1, width: 60, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-zona", type: "text", content: "Zona", x: 87, y: 1, width: 40, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-comision", type: "text", content: "Comision %", x: 128, y: 1, width: 28, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-tel", type: "text", content: "Telefono", x: 157, y: 1, width: 35, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-email", type: "text", content: "Email", x: 193, y: 1, width: 55, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-estado", type: "text", content: "Estado", x: 249, y: 1, width: 24, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
      ],
    },

    /* -- Detail (one row per vendedor) --------------------------------- */
    {
      id: "det",
      type: "detail",
      height: 6,
      dataSource: "vendedores",
      elements: [
        { id: "d-codigo", type: "field", dataSource: "vendedores", field: "codigo", x: 0, y: 0.5, width: 25, height: 5, style: { fontSize: 7 } },
        { id: "d-nombre", type: "field", dataSource: "vendedores", field: "nombre", x: 26, y: 0.5, width: 60, height: 5, style: { fontSize: 7 } },
        { id: "d-zona", type: "field", dataSource: "vendedores", field: "zona", x: 87, y: 0.5, width: 40, height: 5, style: { fontSize: 7 } },
        { id: "d-comision", type: "field", dataSource: "vendedores", field: "comisionPct", x: 128, y: 0.5, width: 28, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-tel", type: "field", dataSource: "vendedores", field: "telefono", x: 157, y: 0.5, width: 35, height: 5, style: { fontSize: 7 } },
        { id: "d-email", type: "field", dataSource: "vendedores", field: "email", x: 193, y: 0.5, width: 55, height: 5, style: { fontSize: 7 } },
        { id: "d-estado", type: "field", dataSource: "vendedores", field: "estado", x: 249, y: 0.5, width: 24, height: 5, style: { fontSize: 7, textAlign: "center" } },
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
          content: "Total vendedores:",
          x: 0, y: 4, width: 35, height: 5,
          style: { fontSize: 8, fontWeight: "bold" },
        },
        {
          id: "rf-count",
          type: "field",
          dataSource: "header",
          field: "totalVendedores",
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

export const VENDEDORES_LAYOUT_SAMPLE = {
  header: {
    empresa: "Zentto Soluciones Tecnologicas S.L.",
    totalVendedores: 6,
  },
  vendedores: [
    { codigo: "VND-001", nombre: "Juan Perez Gomez", zona: "Zona Central", comisionPct: 5.00, telefono: "0412-1234567", email: "jperez@zentto.net", estado: "ACTIVO" },
    { codigo: "VND-002", nombre: "Maria Lopez Diaz", zona: "Zona Occidente", comisionPct: 4.50, telefono: "0414-2345678", email: "mlopez@zentto.net", estado: "ACTIVO" },
    { codigo: "VND-003", nombre: "Carlos Ruiz Navarro", zona: "Zona Andes", comisionPct: 5.00, telefono: "0416-3456789", email: "cruiz@zentto.net", estado: "ACTIVO" },
    { codigo: "VND-004", nombre: "Luis Torres Martinez", zona: "Zona Oriental", comisionPct: 4.00, telefono: "0424-4567890", email: "ltorres@zentto.net", estado: "ACTIVO" },
    { codigo: "VND-005", nombre: "Patricia Herrera Blanco", zona: "Zona Capital", comisionPct: 6.00, telefono: "0412-5678901", email: "pherrera@zentto.net", estado: "ACTIVO" },
    { codigo: "VND-006", nombre: "Roberto Sanchez Gil", zona: "Zona Sur", comisionPct: 4.50, telefono: "0414-6789012", email: "rsanchez@zentto.net", estado: "INACTIVO" },
  ],
};
