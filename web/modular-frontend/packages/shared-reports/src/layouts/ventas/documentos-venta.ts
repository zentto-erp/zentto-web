/**
 * Layout JSON para el reporte "Listado de Documentos de Venta".
 *
 * Diseñado para A4 landscape — columnas: Numero, Fecha, Tipo Op., Cod. Cliente,
 * Nombre Cliente, Subtotal, Impuesto, Total, Estado.
 * Compatible con @zentto/report-core ReportLayout.
 *
 * Endpoint: /v1/documentos-venta
 *
 * DataSources esperados:
 *  - header (object): empresa, totalDocumentos, totalMonto
 *  - documentos (array): numero, fecha, tipoOperacion, codCliente, nombreCliente,
 *    subtotal, impuesto, total, estado
 */
export const DOCUMENTOS_VENTA_LAYOUT = {
  version: "1.0",
  name: "Listado de Documentos de Venta",
  description: "Listado tabular de documentos de venta con totales",
  pageSize: { width: 297, height: 210, unit: "mm" },
  margins: { top: 12, right: 12, bottom: 12, left: 12 },
  orientation: "landscape" as const,
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object" as const,
      endpoint: "/v1/documentos-venta",
      fields: [
        { name: "empresa", label: "Empresa", type: "string" },
        { name: "totalDocumentos", label: "Total Documentos", type: "number" },
        { name: "totalMonto", label: "Total Monto", type: "currency" },
      ],
    },
    {
      id: "documentos",
      name: "Documentos",
      type: "array" as const,
      endpoint: "/v1/documentos-venta",
      fields: [
        { name: "numero", label: "Numero", type: "string" },
        { name: "fecha", label: "Fecha", type: "string" },
        { name: "tipoOperacion", label: "Tipo Op.", type: "string" },
        { name: "codCliente", label: "Cod. Cliente", type: "string" },
        { name: "nombreCliente", label: "Nombre Cliente", type: "string" },
        { name: "subtotal", label: "Subtotal", type: "currency" },
        { name: "impuesto", label: "Impuesto", type: "currency" },
        { name: "total", label: "Total", type: "currency" },
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
          content: "LISTADO DE DOCUMENTOS DE VENTA",
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
          id: "rh-total-docs-label",
          type: "text",
          content: "Documentos:",
          x: 200, y: 10, width: 25, height: 5,
          style: { fontSize: 8, fontWeight: "bold", color: "#555" },
        },
        {
          id: "rh-total-docs",
          type: "field",
          dataSource: "header",
          field: "totalDocumentos",
          x: 226, y: 10, width: 47, height: 5,
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
        { id: "ch-numero", type: "text", content: "Numero", x: 0, y: 1, width: 25, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-fecha", type: "text", content: "Fecha", x: 26, y: 1, width: 22, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-tipo", type: "text", content: "Tipo Op.", x: 49, y: 1, width: 24, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-cod-cli", type: "text", content: "Cod. Cliente", x: 74, y: 1, width: 24, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-nombre", type: "text", content: "Nombre Cliente", x: 99, y: 1, width: 62, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-subtotal", type: "text", content: "Subtotal", x: 162, y: 1, width: 28, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-impuesto", type: "text", content: "Impuesto", x: 191, y: 1, width: 26, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-total", type: "text", content: "Total", x: 218, y: 1, width: 30, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-estado", type: "text", content: "Estado", x: 249, y: 1, width: 24, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
      ],
    },

    /* -- Detail (one row per documento) -------------------------------- */
    {
      id: "det",
      type: "detail",
      height: 6,
      dataSource: "documentos",
      elements: [
        { id: "d-numero", type: "field", dataSource: "documentos", field: "numero", x: 0, y: 0.5, width: 25, height: 5, style: { fontSize: 7 } },
        { id: "d-fecha", type: "field", dataSource: "documentos", field: "fecha", x: 26, y: 0.5, width: 22, height: 5, style: { fontSize: 7 } },
        { id: "d-tipo", type: "field", dataSource: "documentos", field: "tipoOperacion", x: 49, y: 0.5, width: 24, height: 5, style: { fontSize: 7 } },
        { id: "d-cod-cli", type: "field", dataSource: "documentos", field: "codCliente", x: 74, y: 0.5, width: 24, height: 5, style: { fontSize: 7 } },
        { id: "d-nombre", type: "field", dataSource: "documentos", field: "nombreCliente", x: 99, y: 0.5, width: 62, height: 5, style: { fontSize: 7 } },
        { id: "d-subtotal", type: "field", dataSource: "documentos", field: "subtotal", x: 162, y: 0.5, width: 28, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-impuesto", type: "field", dataSource: "documentos", field: "impuesto", x: 191, y: 0.5, width: 26, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-total", type: "field", dataSource: "documentos", field: "total", x: 218, y: 0.5, width: 30, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-estado", type: "field", dataSource: "documentos", field: "estado", x: 249, y: 0.5, width: 24, height: 5, style: { fontSize: 7, textAlign: "center" } },
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
          content: "Total documentos:",
          x: 0, y: 4, width: 35, height: 5,
          style: { fontSize: 8, fontWeight: "bold" },
        },
        {
          id: "rf-count",
          type: "field",
          dataSource: "header",
          field: "totalDocumentos",
          x: 36, y: 4, width: 20, height: 5,
          format: "#,##0",
          style: { fontSize: 8, fontWeight: "bold" },
        },
        {
          id: "rf-totals-label",
          type: "text",
          content: "Total:",
          x: 185, y: 4, width: 32, height: 5,
          style: { fontSize: 9, fontWeight: "bold", textAlign: "right" },
        },
        {
          id: "rf-total-monto",
          type: "field",
          dataSource: "header",
          field: "totalMonto",
          x: 218, y: 4, width: 30, height: 5,
          format: "#,##0.00",
          style: { fontSize: 9, fontWeight: "bold", textAlign: "right", color: "#e67e22" },
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

export const DOCUMENTOS_VENTA_LAYOUT_SAMPLE = {
  header: {
    empresa: "Zentto Soluciones Tecnologicas S.L.",
    totalDocumentos: 6,
    totalMonto: 187440.00,
  },
  documentos: [
    { numero: "FV-0001", fecha: "08/01/2026", tipoOperacion: "FACTURA", codCliente: "CLI-001", nombreCliente: "Distribuidora Norte C.A.", subtotal: 25000.00, impuesto: 4000.00, total: 29000.00, estado: "PAGADA" },
    { numero: "FV-0002", fecha: "15/01/2026", tipoOperacion: "FACTURA", codCliente: "CLI-003", nombreCliente: "Inversiones Oriente S.A.", subtotal: 18500.00, impuesto: 2960.00, total: 21460.00, estado: "PAGADA" },
    { numero: "FV-0008", fecha: "10/02/2026", tipoOperacion: "FACTURA", codCliente: "CLI-002", nombreCliente: "Comercial Bolivar S.R.L.", subtotal: 38000.00, impuesto: 6080.00, total: 44080.00, estado: "PAGADA" },
    { numero: "NC-0001", fecha: "12/02/2026", tipoOperacion: "NOTA_CREDITO", codCliente: "CLI-002", nombreCliente: "Comercial Bolivar S.R.L.", subtotal: 3000.00, impuesto: 480.00, total: 3480.00, estado: "APLICADA" },
    { numero: "FV-0015", fecha: "05/03/2026", tipoOperacion: "FACTURA", codCliente: "CLI-005", nombreCliente: "Tecnologia Global C.A.", subtotal: 42000.00, impuesto: 6720.00, total: 48720.00, estado: "PENDIENTE" },
    { numero: "FV-0018", fecha: "22/03/2026", tipoOperacion: "FACTURA", codCliente: "CLI-001", nombreCliente: "Distribuidora Norte C.A.", subtotal: 40000.00, impuesto: 6400.00, total: 46400.00, estado: "PENDIENTE" },
  ],
};
