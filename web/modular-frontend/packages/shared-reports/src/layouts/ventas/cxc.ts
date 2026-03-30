/**
 * Layout JSON para el reporte "Cuentas por Cobrar".
 *
 * Diseñado para A4 landscape — columnas: Tipo Doc, Numero, Fecha, Fecha Vence,
 * Cod. Cliente, Nombre Cliente, Monto Original, Monto Pagado, Saldo, Estado.
 * Compatible con @zentto/report-core ReportLayout.
 *
 * Endpoint: /v1/cxc/documentos
 *
 * DataSources esperados:
 *  - header (object): empresa, totalPendiente
 *  - documentos (array): tipoDoc, numero, fecha, fechaVence, codCliente,
 *    nombreCliente, montoOriginal, montoPagado, saldo, estado
 */
export const CXC_DOCUMENTOS_LAYOUT = {
  version: "1.0",
  name: "Cuentas por Cobrar",
  description: "Listado tabular de documentos de cuentas por cobrar con saldos pendientes",
  pageSize: { width: 297, height: 210, unit: "mm" },
  margins: { top: 12, right: 12, bottom: 12, left: 12 },
  orientation: "landscape" as const,
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object" as const,
      endpoint: "/v1/cxc/documentos",
      fields: [
        { name: "empresa", label: "Empresa", type: "string" },
        { name: "totalPendiente", label: "Total Pendiente", type: "currency" },
      ],
    },
    {
      id: "documentos",
      name: "Documentos",
      type: "array" as const,
      endpoint: "/v1/cxc/documentos",
      fields: [
        { name: "tipoDoc", label: "Tipo Doc", type: "string" },
        { name: "numero", label: "Numero", type: "string" },
        { name: "fecha", label: "Fecha", type: "string" },
        { name: "fechaVence", label: "Fecha Vence", type: "string" },
        { name: "codCliente", label: "Cod. Cliente", type: "string" },
        { name: "nombreCliente", label: "Nombre Cliente", type: "string" },
        { name: "montoOriginal", label: "Monto Original", type: "currency" },
        { name: "montoPagado", label: "Monto Pagado", type: "currency" },
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
          content: "CUENTAS POR COBRAR",
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
          id: "rh-pendiente-label",
          type: "text",
          content: "Total pendiente:",
          x: 195, y: 10, width: 35, height: 5,
          style: { fontSize: 8, fontWeight: "bold", color: "#555" },
        },
        {
          id: "rh-pendiente",
          type: "field",
          dataSource: "header",
          field: "totalPendiente",
          x: 231, y: 10, width: 42, height: 5,
          format: "#,##0.00",
          style: { fontSize: 8, fontWeight: "bold", color: "#e67e22" },
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
        { id: "ch-tipo", type: "text", content: "Tipo Doc", x: 0, y: 1, width: 18, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-numero", type: "text", content: "Numero", x: 19, y: 1, width: 22, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-fecha", type: "text", content: "Fecha", x: 42, y: 1, width: 22, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-vence", type: "text", content: "Vence", x: 65, y: 1, width: 22, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-cod-cli", type: "text", content: "Cod. Cliente", x: 88, y: 1, width: 22, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-nombre", type: "text", content: "Nombre Cliente", x: 111, y: 1, width: 52, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-original", type: "text", content: "Monto Original", x: 164, y: 1, width: 28, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-pagado", type: "text", content: "Monto Pagado", x: 193, y: 1, width: 28, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-saldo", type: "text", content: "Saldo", x: 222, y: 1, width: 28, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-estado", type: "text", content: "Estado", x: 251, y: 1, width: 22, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
      ],
    },

    /* -- Detail (one row per documento) -------------------------------- */
    {
      id: "det",
      type: "detail",
      height: 6,
      dataSource: "documentos",
      elements: [
        { id: "d-tipo", type: "field", dataSource: "documentos", field: "tipoDoc", x: 0, y: 0.5, width: 18, height: 5, style: { fontSize: 7 } },
        { id: "d-numero", type: "field", dataSource: "documentos", field: "numero", x: 19, y: 0.5, width: 22, height: 5, style: { fontSize: 7 } },
        { id: "d-fecha", type: "field", dataSource: "documentos", field: "fecha", x: 42, y: 0.5, width: 22, height: 5, style: { fontSize: 7 } },
        { id: "d-vence", type: "field", dataSource: "documentos", field: "fechaVence", x: 65, y: 0.5, width: 22, height: 5, style: { fontSize: 7 } },
        { id: "d-cod-cli", type: "field", dataSource: "documentos", field: "codCliente", x: 88, y: 0.5, width: 22, height: 5, style: { fontSize: 7 } },
        { id: "d-nombre", type: "field", dataSource: "documentos", field: "nombreCliente", x: 111, y: 0.5, width: 52, height: 5, style: { fontSize: 7 } },
        { id: "d-original", type: "field", dataSource: "documentos", field: "montoOriginal", x: 164, y: 0.5, width: 28, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-pagado", type: "field", dataSource: "documentos", field: "montoPagado", x: 193, y: 0.5, width: 28, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-saldo", type: "field", dataSource: "documentos", field: "saldo", x: 222, y: 0.5, width: 28, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-estado", type: "field", dataSource: "documentos", field: "estado", x: 251, y: 0.5, width: 22, height: 5, style: { fontSize: 7, textAlign: "center" } },
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
          id: "rf-totals-label",
          type: "text",
          content: "Total pendiente:",
          x: 185, y: 4, width: 36, height: 5,
          style: { fontSize: 9, fontWeight: "bold", textAlign: "right" },
        },
        {
          id: "rf-total-pendiente",
          type: "field",
          dataSource: "header",
          field: "totalPendiente",
          x: 222, y: 4, width: 28, height: 5,
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

export const CXC_DOCUMENTOS_LAYOUT_SAMPLE = {
  header: {
    empresa: "Zentto Soluciones Tecnologicas S.L.",
    totalPendiente: 107620.00,
  },
  documentos: [
    { tipoDoc: "FAC", numero: "FV-0015", fecha: "05/03/2026", fechaVence: "04/04/2026", codCliente: "CLI-005", nombreCliente: "Tecnologia Global C.A.", montoOriginal: 48720.00, montoPagado: 0.00, saldo: 48720.00, estado: "PENDIENTE" },
    { tipoDoc: "FAC", numero: "FV-0018", fecha: "22/03/2026", fechaVence: "21/04/2026", codCliente: "CLI-001", nombreCliente: "Distribuidora Norte C.A.", montoOriginal: 46400.00, montoPagado: 0.00, saldo: 46400.00, estado: "PENDIENTE" },
    { tipoDoc: "FAC", numero: "FV-0010", fecha: "18/02/2026", fechaVence: "20/03/2026", codCliente: "CLI-004", nombreCliente: "Grupo Andino C.A.", montoOriginal: 12500.00, montoPagado: 0.00, saldo: 12500.00, estado: "VENCIDA" },
    { tipoDoc: "FAC", numero: "FV-0001", fecha: "08/01/2026", fechaVence: "07/02/2026", codCliente: "CLI-001", nombreCliente: "Distribuidora Norte C.A.", montoOriginal: 29000.00, montoPagado: 29000.00, saldo: 0.00, estado: "PAGADA" },
    { tipoDoc: "FAC", numero: "FV-0002", fecha: "15/01/2026", fechaVence: "14/02/2026", codCliente: "CLI-003", nombreCliente: "Inversiones Oriente S.A.", montoOriginal: 21460.00, montoPagado: 21460.00, saldo: 0.00, estado: "PAGADA" },
    { tipoDoc: "N/C", numero: "NC-0001", fecha: "12/02/2026", fechaVence: "12/02/2026", codCliente: "CLI-002", nombreCliente: "Comercial Bolivar S.R.L.", montoOriginal: 3480.00, montoPagado: 3480.00, saldo: 0.00, estado: "APLICADA" },
  ],
};
