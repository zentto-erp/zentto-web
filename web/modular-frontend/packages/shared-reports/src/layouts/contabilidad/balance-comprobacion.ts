/**
 * Layout JSON para el reporte "Balance de Comprobacion".
 *
 * Diseñado para A4 landscape — columnas: Cuenta, Descripcion, Tipo, Nivel,
 * Debito Anterior, Credito Anterior, Debito Periodo, Credito Periodo, Debito Final, Credito Final.
 * Compatible con @zentto/report-core ReportLayout.
 *
 * DataSources esperados:
 *  - header (object): empresa, fechaDesde, fechaHasta
 *  - cuentas (array): codCuenta, descripcion, tipo, nivel, debitoAnterior, creditoAnterior,
 *                      debitoPeriodo, creditoPeriodo, debitoFinal, creditoFinal
 */
export const BALANCE_COMPROBACION_LAYOUT = {
  version: "1.0",
  name: "Balance de Comprobacion",
  description: "Reporte de balance de comprobacion con saldos anteriores, del periodo y finales",
  pageSize: { width: 297, height: 210, unit: "mm" },
  margins: { top: 12, right: 12, bottom: 12, left: 12 },
  orientation: "landscape" as const,
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object" as const,
      endpoint: "/v1/contabilidad/reportes/balance-comprobacion",
      fields: [
        { name: "empresa", label: "Empresa", type: "string" },
        { name: "fechaDesde", label: "Fecha desde", type: "string" },
        { name: "fechaHasta", label: "Fecha hasta", type: "string" },
      ],
    },
    {
      id: "cuentas",
      name: "Cuentas",
      type: "array" as const,
      endpoint: "/v1/contabilidad/reportes/balance-comprobacion",
      fields: [
        { name: "codCuenta", label: "Cuenta", type: "string" },
        { name: "descripcion", label: "Descripcion", type: "string" },
        { name: "tipo", label: "Tipo", type: "string" },
        { name: "nivel", label: "Nivel", type: "number" },
        { name: "debitoAnterior", label: "Deb. Anterior", type: "currency" },
        { name: "creditoAnterior", label: "Cred. Anterior", type: "currency" },
        { name: "debitoPeriodo", label: "Deb. Periodo", type: "currency" },
        { name: "creditoPeriodo", label: "Cred. Periodo", type: "currency" },
        { name: "debitoFinal", label: "Deb. Final", type: "currency" },
        { name: "creditoFinal", label: "Cred. Final", type: "currency" },
      ],
    },
  ],
  bands: [
    /* ── Report Header ───────────────────────────────────────── */
    {
      id: "rh",
      type: "reportHeader",
      height: 22,
      elements: [
        {
          id: "rh-title",
          type: "text",
          content: "BALANCE DE COMPROBACION",
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
          content: "—",
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
          id: "rh-line",
          type: "line",
          x: 0, y: 18, width: 273, height: 0,
          x2: 273, y2: 18,
          lineStyle: { color: "#e67e22", width: 1.5, style: "solid" },
        },
      ],
    },

    /* ── Column Header ───────────────────────────────────────── */
    {
      id: "ch",
      type: "columnHeader",
      height: 8,
      repeatOnEveryPage: true,
      backgroundColor: "#e67e22",
      elements: [
        { id: "ch-cuenta", type: "text", content: "Cuenta", x: 0, y: 1, width: 25, height: 6, style: { fontSize: 7, fontWeight: "bold", color: "#fff" } },
        { id: "ch-desc", type: "text", content: "Descripcion", x: 26, y: 1, width: 50, height: 6, style: { fontSize: 7, fontWeight: "bold", color: "#fff" } },
        { id: "ch-tipo", type: "text", content: "Tipo", x: 77, y: 1, width: 18, height: 6, style: { fontSize: 7, fontWeight: "bold", color: "#fff" } },
        { id: "ch-nivel", type: "text", content: "Niv.", x: 96, y: 1, width: 10, height: 6, style: { fontSize: 7, fontWeight: "bold", color: "#fff", textAlign: "center" } },
        { id: "ch-deb-ant", type: "text", content: "Deb. Ant.", x: 107, y: 1, width: 27, height: 6, style: { fontSize: 7, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-cred-ant", type: "text", content: "Cred. Ant.", x: 135, y: 1, width: 27, height: 6, style: { fontSize: 7, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-deb-per", type: "text", content: "Deb. Per.", x: 163, y: 1, width: 27, height: 6, style: { fontSize: 7, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-cred-per", type: "text", content: "Cred. Per.", x: 191, y: 1, width: 27, height: 6, style: { fontSize: 7, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-deb-fin", type: "text", content: "Deb. Final", x: 219, y: 1, width: 27, height: 6, style: { fontSize: 7, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-cred-fin", type: "text", content: "Cred. Final", x: 247, y: 1, width: 26, height: 6, style: { fontSize: 7, fontWeight: "bold", color: "#fff", textAlign: "right" } },
      ],
    },

    /* ── Detail (one row per cuenta) ─────────────────────────── */
    {
      id: "det",
      type: "detail",
      height: 6,
      dataSource: "cuentas",
      elements: [
        { id: "d-cuenta", type: "field", dataSource: "cuentas", field: "codCuenta", x: 0, y: 0.5, width: 25, height: 5, style: { fontSize: 7 } },
        { id: "d-desc", type: "field", dataSource: "cuentas", field: "descripcion", x: 26, y: 0.5, width: 50, height: 5, style: { fontSize: 7 } },
        { id: "d-tipo", type: "field", dataSource: "cuentas", field: "tipo", x: 77, y: 0.5, width: 18, height: 5, style: { fontSize: 7 } },
        { id: "d-nivel", type: "field", dataSource: "cuentas", field: "nivel", x: 96, y: 0.5, width: 10, height: 5, style: { fontSize: 7, textAlign: "center" } },
        { id: "d-deb-ant", type: "field", dataSource: "cuentas", field: "debitoAnterior", x: 107, y: 0.5, width: 27, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-cred-ant", type: "field", dataSource: "cuentas", field: "creditoAnterior", x: 135, y: 0.5, width: 27, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-deb-per", type: "field", dataSource: "cuentas", field: "debitoPeriodo", x: 163, y: 0.5, width: 27, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-cred-per", type: "field", dataSource: "cuentas", field: "creditoPeriodo", x: 191, y: 0.5, width: 27, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-deb-fin", type: "field", dataSource: "cuentas", field: "debitoFinal", x: 219, y: 0.5, width: 27, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-cred-fin", type: "field", dataSource: "cuentas", field: "creditoFinal", x: 247, y: 0.5, width: 26, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
      ],
    },

    /* ── Report Footer (totals) ──────────────────────────────── */
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
          id: "rf-totals-label",
          type: "text",
          content: "Totales:",
          x: 70, y: 4, width: 36, height: 5,
          style: { fontSize: 8, fontWeight: "bold", textAlign: "right" },
        },
        {
          id: "rf-deb-ant",
          type: "aggregation",
          aggregation: "sum",
          dataSource: "cuentas",
          field: "debitoAnterior",
          x: 107, y: 4, width: 27, height: 5,
          format: "#,##0.00",
          style: { fontSize: 8, fontWeight: "bold", textAlign: "right", color: "#e67e22" },
        },
        {
          id: "rf-cred-ant",
          type: "aggregation",
          aggregation: "sum",
          dataSource: "cuentas",
          field: "creditoAnterior",
          x: 135, y: 4, width: 27, height: 5,
          format: "#,##0.00",
          style: { fontSize: 8, fontWeight: "bold", textAlign: "right", color: "#e67e22" },
        },
        {
          id: "rf-deb-per",
          type: "aggregation",
          aggregation: "sum",
          dataSource: "cuentas",
          field: "debitoPeriodo",
          x: 163, y: 4, width: 27, height: 5,
          format: "#,##0.00",
          style: { fontSize: 8, fontWeight: "bold", textAlign: "right", color: "#e67e22" },
        },
        {
          id: "rf-cred-per",
          type: "aggregation",
          aggregation: "sum",
          dataSource: "cuentas",
          field: "creditoPeriodo",
          x: 191, y: 4, width: 27, height: 5,
          format: "#,##0.00",
          style: { fontSize: 8, fontWeight: "bold", textAlign: "right", color: "#e67e22" },
        },
        {
          id: "rf-deb-fin",
          type: "aggregation",
          aggregation: "sum",
          dataSource: "cuentas",
          field: "debitoFinal",
          x: 219, y: 4, width: 27, height: 5,
          format: "#,##0.00",
          style: { fontSize: 8, fontWeight: "bold", textAlign: "right", color: "#e67e22" },
        },
        {
          id: "rf-cred-fin",
          type: "aggregation",
          aggregation: "sum",
          dataSource: "cuentas",
          field: "creditoFinal",
          x: 247, y: 4, width: 26, height: 5,
          format: "#,##0.00",
          style: { fontSize: 8, fontWeight: "bold", textAlign: "right", color: "#e67e22" },
        },
      ],
    },

    /* ── Page Footer ─────────────────────────────────────────── */
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
