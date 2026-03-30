/**
 * Layout JSON para el reporte "Listado de Cuentas Bancarias".
 *
 * Diseñado para A4 landscape — columnas: Nro. Cuenta, Banco, Tipo Cuenta, Moneda, Saldo Actual, Estado.
 * Compatible con @zentto/report-core ReportLayout.
 *
 * DataSources esperados:
 *  - header (object): empresa, totalCuentas
 *  - cuentas (array): nroCuenta, banco, tipoCuenta, moneda, saldoActual, estado
 */
export const CUENTAS_BANCARIAS_LAYOUT = {
  version: "1.0",
  name: "Listado de Cuentas Bancarias",
  description: "Listado tabular de cuentas bancarias con saldos",
  pageSize: { width: 297, height: 210, unit: "mm" },
  margins: { top: 12, right: 12, bottom: 12, left: 12 },
  orientation: "landscape" as const,
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object" as const,
      endpoint: "/v1/bancos/cuentas/list",
      fields: [
        { name: "empresa", label: "Empresa", type: "string" },
        { name: "totalCuentas", label: "Total Cuentas", type: "number" },
      ],
    },
    {
      id: "cuentas",
      name: "Cuentas",
      type: "array" as const,
      endpoint: "/v1/bancos/cuentas/list",
      fields: [
        { name: "nroCuenta", label: "Nro. Cuenta", type: "string" },
        { name: "banco", label: "Banco", type: "string" },
        { name: "tipoCuenta", label: "Tipo Cuenta", type: "string" },
        { name: "moneda", label: "Moneda", type: "string" },
        { name: "saldoActual", label: "Saldo Actual", type: "currency" },
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
          content: "LISTADO DE CUENTAS BANCARIAS",
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
        { id: "ch-nro", type: "text", content: "Nro. Cuenta", x: 0, y: 1, width: 50, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-banco", type: "text", content: "Banco", x: 50, y: 1, width: 60, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-tipo", type: "text", content: "Tipo Cuenta", x: 110, y: 1, width: 45, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-moneda", type: "text", content: "Moneda", x: 155, y: 1, width: 30, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
        { id: "ch-saldo", type: "text", content: "Saldo Actual", x: 185, y: 1, width: 58, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-estado", type: "text", content: "Estado", x: 243, y: 1, width: 30, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
      ],
    },

    /* -- Detail (one row per cuenta) ----------------------------------- */
    {
      id: "det",
      type: "detail",
      height: 6,
      dataSource: "cuentas",
      elements: [
        { id: "d-nro", type: "field", dataSource: "cuentas", field: "nroCuenta", x: 0, y: 0.5, width: 50, height: 5, style: { fontSize: 7 } },
        { id: "d-banco", type: "field", dataSource: "cuentas", field: "banco", x: 50, y: 0.5, width: 60, height: 5, style: { fontSize: 7 } },
        { id: "d-tipo", type: "field", dataSource: "cuentas", field: "tipoCuenta", x: 110, y: 0.5, width: 45, height: 5, style: { fontSize: 7 } },
        { id: "d-moneda", type: "field", dataSource: "cuentas", field: "moneda", x: 155, y: 0.5, width: 30, height: 5, style: { fontSize: 7, textAlign: "center" } },
        { id: "d-saldo", type: "field", dataSource: "cuentas", field: "saldoActual", x: 185, y: 0.5, width: 58, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-estado", type: "field", dataSource: "cuentas", field: "estado", x: 243, y: 0.5, width: 30, height: 5, style: { fontSize: 7, textAlign: "center" } },
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
          content: "Total cuentas:",
          x: 0, y: 4, width: 28, height: 5,
          style: { fontSize: 8, fontWeight: "bold" },
        },
        {
          id: "rf-count",
          type: "field",
          dataSource: "header",
          field: "totalCuentas",
          x: 29, y: 4, width: 20, height: 5,
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

export const CUENTAS_BANCARIAS_LAYOUT_SAMPLE = {
  header: {
    empresa: "Zentto Soluciones Tecnologicas S.L.",
    totalCuentas: 6,
  },
  cuentas: [
    { nroCuenta: "0134-0012-34-0123456789", banco: "Banesco Banco Universal", tipoCuenta: "Corriente", moneda: "VES", saldoActual: 185320.50, estado: "ACTIVO" },
    { nroCuenta: "0105-0088-71-0987654321", banco: "Banco Mercantil", tipoCuenta: "Corriente", moneda: "VES", saldoActual: 42750.00, estado: "ACTIVO" },
    { nroCuenta: "0108-0200-00-0111222333", banco: "Banco Provincial BBVA", tipoCuenta: "Ahorro", moneda: "VES", saldoActual: 8900.75, estado: "ACTIVO" },
    { nroCuenta: "0134-0012-34-0000111222", banco: "Banesco Banco Universal", tipoCuenta: "Corriente", moneda: "USD", saldoActual: 25400.00, estado: "ACTIVO" },
    { nroCuenta: "0102-0345-67-0444555666", banco: "Banco de Venezuela", tipoCuenta: "Corriente", moneda: "VES", saldoActual: 12100.30, estado: "ACTIVO" },
    { nroCuenta: "0115-0100-00-0777888999", banco: "Banco Exterior", tipoCuenta: "Ahorro", moneda: "VES", saldoActual: 0.00, estado: "INACTIVO" },
  ],
};
