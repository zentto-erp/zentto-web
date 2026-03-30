/**
 * Layout JSON para el reporte "Movimientos Bancarios".
 *
 * Diseñado para A4 landscape — columnas: Fecha, Referencia, Concepto, Debito, Credito, Saldo.
 * Compatible con @zentto/report-core ReportLayout.
 *
 * DataSources esperados:
 *  - header (object): empresa, nroCuenta, banco, fechaDesde, fechaHasta, saldoInicial, saldoFinal
 *  - movimientos (array): fecha, referencia, concepto, debito, credito, saldo
 */
export const MOVIMIENTOS_BANCARIOS_LAYOUT = {
  version: "1.0",
  name: "Movimientos Bancarios",
  description: "Listado tabular de movimientos de una cuenta bancaria con saldos",
  pageSize: { width: 297, height: 210, unit: "mm" },
  margins: { top: 12, right: 12, bottom: 12, left: 12 },
  orientation: "landscape" as const,
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object" as const,
      endpoint: "/v1/bancos/cuentas/:nroCta/movimientos",
      fields: [
        { name: "empresa", label: "Empresa", type: "string" },
        { name: "nroCuenta", label: "Nro. Cuenta", type: "string" },
        { name: "banco", label: "Banco", type: "string" },
        { name: "fechaDesde", label: "Fecha desde", type: "string" },
        { name: "fechaHasta", label: "Fecha hasta", type: "string" },
        { name: "saldoInicial", label: "Saldo Inicial", type: "currency" },
        { name: "saldoFinal", label: "Saldo Final", type: "currency" },
      ],
    },
    {
      id: "movimientos",
      name: "Movimientos",
      type: "array" as const,
      endpoint: "/v1/bancos/cuentas/:nroCta/movimientos",
      fields: [
        { name: "fecha", label: "Fecha", type: "string" },
        { name: "referencia", label: "Referencia", type: "string" },
        { name: "concepto", label: "Concepto", type: "string" },
        { name: "debito", label: "Debito", type: "currency" },
        { name: "credito", label: "Credito", type: "currency" },
        { name: "saldo", label: "Saldo", type: "currency" },
      ],
    },
  ],
  bands: [
    /* -- Report Header ------------------------------------------------- */
    {
      id: "rh",
      type: "reportHeader",
      height: 28,
      elements: [
        {
          id: "rh-title",
          type: "text",
          content: "MOVIMIENTOS BANCARIOS",
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
          id: "rh-banco-label",
          type: "text",
          content: "Banco:",
          x: 0, y: 16, width: 14, height: 5,
          style: { fontSize: 8, fontWeight: "bold", color: "#555" },
        },
        {
          id: "rh-banco",
          type: "field",
          dataSource: "header",
          field: "banco",
          x: 15, y: 16, width: 60, height: 5,
          style: { fontSize: 8, color: "#555" },
        },
        {
          id: "rh-cuenta-label",
          type: "text",
          content: "Cuenta:",
          x: 80, y: 16, width: 16, height: 5,
          style: { fontSize: 8, fontWeight: "bold", color: "#555" },
        },
        {
          id: "rh-cuenta",
          type: "field",
          dataSource: "header",
          field: "nroCuenta",
          x: 97, y: 16, width: 50, height: 5,
          style: { fontSize: 8, color: "#555" },
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
          content: "\u2014",
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
          id: "rh-saldo-ini-label",
          type: "text",
          content: "Saldo Inicial:",
          x: 180, y: 16, width: 28, height: 5,
          style: { fontSize: 8, fontWeight: "bold", color: "#555" },
        },
        {
          id: "rh-saldo-ini",
          type: "field",
          dataSource: "header",
          field: "saldoInicial",
          x: 209, y: 16, width: 64, height: 5,
          format: "#,##0.00",
          style: { fontSize: 8, textAlign: "right", color: "#555" },
        },
        {
          id: "rh-line",
          type: "line",
          x: 0, y: 24, width: 273, height: 0,
          x2: 273, y2: 24,
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
        { id: "ch-fecha", type: "text", content: "Fecha", x: 0, y: 1, width: 28, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-ref", type: "text", content: "Referencia", x: 28, y: 1, width: 40, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-concepto", type: "text", content: "Concepto", x: 68, y: 1, width: 90, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-debito", type: "text", content: "Debito", x: 158, y: 1, width: 35, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-credito", type: "text", content: "Credito", x: 193, y: 1, width: 35, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-saldo", type: "text", content: "Saldo", x: 228, y: 1, width: 45, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
      ],
    },

    /* -- Detail (one row per movimiento) ------------------------------- */
    {
      id: "det",
      type: "detail",
      height: 6,
      dataSource: "movimientos",
      elements: [
        { id: "d-fecha", type: "field", dataSource: "movimientos", field: "fecha", x: 0, y: 0.5, width: 28, height: 5, style: { fontSize: 7 } },
        { id: "d-ref", type: "field", dataSource: "movimientos", field: "referencia", x: 28, y: 0.5, width: 40, height: 5, style: { fontSize: 7 } },
        { id: "d-concepto", type: "field", dataSource: "movimientos", field: "concepto", x: 68, y: 0.5, width: 90, height: 5, style: { fontSize: 7 } },
        { id: "d-debito", type: "field", dataSource: "movimientos", field: "debito", x: 158, y: 0.5, width: 35, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-credito", type: "field", dataSource: "movimientos", field: "credito", x: 193, y: 0.5, width: 35, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-saldo", type: "field", dataSource: "movimientos", field: "saldo", x: 228, y: 0.5, width: 45, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
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
          id: "rf-saldo-label",
          type: "text",
          content: "Saldo Final:",
          x: 180, y: 4, width: 47, height: 5,
          style: { fontSize: 9, fontWeight: "bold", textAlign: "right" },
        },
        {
          id: "rf-saldo",
          type: "field",
          dataSource: "header",
          field: "saldoFinal",
          x: 228, y: 4, width: 45, height: 5,
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

export const MOVIMIENTOS_BANCARIOS_LAYOUT_SAMPLE = {
  header: {
    empresa: "Zentto Soluciones Tecnologicas S.L.",
    nroCuenta: "0134-0012-34-0123456789",
    banco: "Banesco Banco Universal",
    fechaDesde: "01/01/2026",
    fechaHasta: "31/03/2026",
    saldoInicial: 120000.00,
    saldoFinal: 185320.50,
  },
  movimientos: [
    { fecha: "05/01/2026", referencia: "DEP-0001", concepto: "Deposito cobro factura FV-001", debito: 28750.00, credito: 0.00, saldo: 148750.00 },
    { fecha: "10/01/2026", referencia: "CHQ-0455", concepto: "Pago alquiler oficina enero", debito: 0.00, credito: 3500.00, saldo: 145250.00 },
    { fecha: "28/01/2026", referencia: "TRF-0012", concepto: "Pago nomina enero 2026", debito: 0.00, credito: 18200.00, saldo: 127050.00 },
    { fecha: "15/02/2026", referencia: "DEP-0015", concepto: "Deposito cobro factura FV-008", debito: 45000.00, credito: 0.00, saldo: 172050.00 },
    { fecha: "28/02/2026", referencia: "TRF-0028", concepto: "Pago nomina febrero 2026", debito: 0.00, credito: 18200.00, saldo: 153850.00 },
    { fecha: "10/03/2026", referencia: "DEP-0022", concepto: "Cobro cliente Distribuidora Norte", debito: 35000.00, credito: 0.00, saldo: 188850.00 },
    { fecha: "20/03/2026", referencia: "CHQ-0480", concepto: "Pago servicios publicos marzo", debito: 0.00, credito: 3529.50, saldo: 185320.50 },
  ],
};
