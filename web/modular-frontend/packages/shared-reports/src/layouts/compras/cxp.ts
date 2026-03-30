/**
 * Layout JSON para el reporte "Cuentas por Pagar".
 *
 * Diseñado para A4 landscape — columnas: Tipo Doc, Numero, Fecha, Fecha Vence,
 * Cod. Proveedor, Nombre Proveedor, Monto Original, Monto Pagado, Saldo, Estado.
 * Compatible con @zentto/report-core ReportLayout.
 *
 * Endpoint: /v1/cxp/documentos
 *
 * DataSources esperados:
 *  - header (object): empresa, totalPendiente
 *  - documentos (array): tipoDoc, numero, fecha, fechaVence, codProveedor,
 *    nombreProveedor, montoOriginal, montoPagado, saldo, estado
 */
export const CXP_DOCUMENTOS_LAYOUT = {
  version: "1.0",
  name: "Cuentas por Pagar",
  description: "Listado tabular de documentos de cuentas por pagar con saldos pendientes",
  pageSize: { width: 297, height: 210, unit: "mm" },
  margins: { top: 12, right: 12, bottom: 12, left: 12 },
  orientation: "landscape" as const,
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object" as const,
      endpoint: "/v1/cxp/documentos",
      fields: [
        { name: "empresa", label: "Empresa", type: "string" },
        { name: "totalPendiente", label: "Total Pendiente", type: "currency" },
      ],
    },
    {
      id: "documentos",
      name: "Documentos",
      type: "array" as const,
      endpoint: "/v1/cxp/documentos",
      fields: [
        { name: "tipoDoc", label: "Tipo Doc", type: "string" },
        { name: "numero", label: "Numero", type: "string" },
        { name: "fecha", label: "Fecha", type: "string" },
        { name: "fechaVence", label: "Fecha Vence", type: "string" },
        { name: "codProveedor", label: "Cod. Proveedor", type: "string" },
        { name: "nombreProveedor", label: "Nombre Proveedor", type: "string" },
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
          content: "CUENTAS POR PAGAR",
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
        { id: "ch-cod-prov", type: "text", content: "Cod. Proveedor", x: 88, y: 1, width: 22, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-nombre", type: "text", content: "Nombre Proveedor", x: 111, y: 1, width: 52, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
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
        { id: "d-cod-prov", type: "field", dataSource: "documentos", field: "codProveedor", x: 88, y: 0.5, width: 22, height: 5, style: { fontSize: 7 } },
        { id: "d-nombre", type: "field", dataSource: "documentos", field: "nombreProveedor", x: 111, y: 0.5, width: 52, height: 5, style: { fontSize: 7 } },
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

export const CXP_DOCUMENTOS_LAYOUT_SAMPLE = {
  header: {
    empresa: "Zentto Soluciones Tecnologicas S.L.",
    totalPendiente: 93960.00,
  },
  documentos: [
    { tipoDoc: "FAC", numero: "FC-0012", fecha: "15/02/2026", fechaVence: "17/03/2026", codProveedor: "PRV-002", nombreProveedor: "Distribuidora Nacional C.A.", montoOriginal: 25520.00, montoPagado: 0.00, saldo: 25520.00, estado: "VENCIDA" },
    { tipoDoc: "FAC", numero: "FC-0018", fecha: "01/03/2026", fechaVence: "31/03/2026", codProveedor: "PRV-001", nombreProveedor: "Importadora Tech C.A.", montoOriginal: 40600.00, montoPagado: 0.00, saldo: 40600.00, estado: "PENDIENTE" },
    { tipoDoc: "FAC", numero: "FC-0025", fecha: "20/03/2026", fechaVence: "19/04/2026", codProveedor: "PRV-004", nombreProveedor: "Servicios Integrados C.A.", montoOriginal: 27840.00, montoPagado: 0.00, saldo: 27840.00, estado: "PENDIENTE" },
    { tipoDoc: "FAC", numero: "FC-0001", fecha: "10/01/2026", fechaVence: "09/02/2026", codProveedor: "PRV-001", nombreProveedor: "Importadora Tech C.A.", montoOriginal: 48720.00, montoPagado: 48720.00, saldo: 0.00, estado: "PAGADA" },
    { tipoDoc: "FAC", numero: "FC-0005", fecha: "25/01/2026", fechaVence: "24/02/2026", codProveedor: "PRV-003", nombreProveedor: "Suministros Express S.A.", montoOriginal: 9860.00, montoPagado: 9860.00, saldo: 0.00, estado: "PAGADA" },
    { tipoDoc: "N/C", numero: "NC-P001", fecha: "10/03/2026", fechaVence: "10/03/2026", codProveedor: "PRV-003", nombreProveedor: "Suministros Express S.A.", montoOriginal: 1740.00, montoPagado: 1740.00, saldo: 0.00, estado: "APLICADA" },
  ],
};
