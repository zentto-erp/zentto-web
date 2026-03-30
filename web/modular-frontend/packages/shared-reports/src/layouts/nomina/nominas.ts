/**
 * Layout JSON para el reporte "Listado de Periodos de Nomina".
 *
 * Diseñado para A4 landscape — columnas: CoNomina, Descripcion, Desde, Hasta, Asignaciones, Deducciones, Neto, Estado.
 * Compatible con @zentto/report-core ReportLayout.
 *
 * DataSources esperados:
 *  - header (object): empresa, totalNominas
 *  - nominas (array): coNomina, descripcion, fechaDesde, fechaHasta, totalAsignaciones, totalDeducciones, neto, estado
 */
export const NOMINAS_LAYOUT = {
  version: "1.0",
  name: "Listado de Periodos de Nomina",
  description: "Listado tabular de periodos de nomina con totales de asignaciones, deducciones y neto",
  pageSize: { width: 297, height: 210, unit: "mm" },
  margins: { top: 12, right: 12, bottom: 12, left: 12 },
  orientation: "landscape" as const,
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object" as const,
      endpoint: "/v1/nomina",
      fields: [
        { name: "empresa", label: "Empresa", type: "string" },
        { name: "totalNominas", label: "Total Nominas", type: "number" },
      ],
    },
    {
      id: "nominas",
      name: "Nominas",
      type: "array" as const,
      endpoint: "/v1/nomina",
      fields: [
        { name: "coNomina", label: "Codigo", type: "string" },
        { name: "descripcion", label: "Descripcion", type: "string" },
        { name: "fechaDesde", label: "Desde", type: "string" },
        { name: "fechaHasta", label: "Hasta", type: "string" },
        { name: "totalAsignaciones", label: "Asignaciones", type: "currency" },
        { name: "totalDeducciones", label: "Deducciones", type: "currency" },
        { name: "neto", label: "Neto", type: "currency" },
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
          content: "LISTADO DE PERIODOS DE NOMINA",
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
        { id: "ch-codigo", type: "text", content: "Codigo", x: 0, y: 1, width: 22, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-desc", type: "text", content: "Descripcion", x: 23, y: 1, width: 60, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-desde", type: "text", content: "Desde", x: 84, y: 1, width: 28, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-hasta", type: "text", content: "Hasta", x: 113, y: 1, width: 28, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-asig", type: "text", content: "Asignaciones", x: 142, y: 1, width: 35, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-ded", type: "text", content: "Deducciones", x: 178, y: 1, width: 35, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-neto", type: "text", content: "Neto", x: 214, y: 1, width: 35, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-estado", type: "text", content: "Estado", x: 250, y: 1, width: 23, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
      ],
    },

    /* -- Detail (one row per nomina) ----------------------------------- */
    {
      id: "det",
      type: "detail",
      height: 6,
      dataSource: "nominas",
      elements: [
        { id: "d-codigo", type: "field", dataSource: "nominas", field: "coNomina", x: 0, y: 0.5, width: 22, height: 5, style: { fontSize: 7 } },
        { id: "d-desc", type: "field", dataSource: "nominas", field: "descripcion", x: 23, y: 0.5, width: 60, height: 5, style: { fontSize: 7 } },
        { id: "d-desde", type: "field", dataSource: "nominas", field: "fechaDesde", x: 84, y: 0.5, width: 28, height: 5, style: { fontSize: 7 } },
        { id: "d-hasta", type: "field", dataSource: "nominas", field: "fechaHasta", x: 113, y: 0.5, width: 28, height: 5, style: { fontSize: 7 } },
        { id: "d-asig", type: "field", dataSource: "nominas", field: "totalAsignaciones", x: 142, y: 0.5, width: 35, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-ded", type: "field", dataSource: "nominas", field: "totalDeducciones", x: 178, y: 0.5, width: 35, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-neto", type: "field", dataSource: "nominas", field: "neto", x: 214, y: 0.5, width: 35, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-estado", type: "field", dataSource: "nominas", field: "estado", x: 250, y: 0.5, width: 23, height: 5, style: { fontSize: 7, textAlign: "center" } },
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
          content: "Total nominas:",
          x: 0, y: 4, width: 30, height: 5,
          style: { fontSize: 8, fontWeight: "bold" },
        },
        {
          id: "rf-count",
          type: "field",
          dataSource: "header",
          field: "totalNominas",
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

export const NOMINAS_LAYOUT_SAMPLE = {
  header: {
    empresa: "Zentto Soluciones Tecnologicas S.L.",
    totalNominas: 6,
  },
  nominas: [
    { coNomina: "NOM-2026-01Q1", descripcion: "Nomina Quincenal 1ra Enero 2026", fechaDesde: "01/01/2026", fechaHasta: "15/01/2026", totalAsignaciones: 22400.00, totalDeducciones: 4200.00, neto: 18200.00, estado: "PAGADA" },
    { coNomina: "NOM-2026-01Q2", descripcion: "Nomina Quincenal 2da Enero 2026", fechaDesde: "16/01/2026", fechaHasta: "31/01/2026", totalAsignaciones: 22400.00, totalDeducciones: 4200.00, neto: 18200.00, estado: "PAGADA" },
    { coNomina: "NOM-2026-02Q1", descripcion: "Nomina Quincenal 1ra Febrero 2026", fechaDesde: "01/02/2026", fechaHasta: "15/02/2026", totalAsignaciones: 22400.00, totalDeducciones: 4200.00, neto: 18200.00, estado: "PAGADA" },
    { coNomina: "NOM-2026-02Q2", descripcion: "Nomina Quincenal 2da Febrero 2026", fechaDesde: "16/02/2026", fechaHasta: "28/02/2026", totalAsignaciones: 22400.00, totalDeducciones: 4200.00, neto: 18200.00, estado: "PAGADA" },
    { coNomina: "NOM-2026-03Q1", descripcion: "Nomina Quincenal 1ra Marzo 2026", fechaDesde: "01/03/2026", fechaHasta: "15/03/2026", totalAsignaciones: 22400.00, totalDeducciones: 4200.00, neto: 18200.00, estado: "PAGADA" },
    { coNomina: "NOM-2026-03Q2", descripcion: "Nomina Quincenal 2da Marzo 2026", fechaDesde: "16/03/2026", fechaHasta: "31/03/2026", totalAsignaciones: 22400.00, totalDeducciones: 4200.00, neto: 18200.00, estado: "PROCESANDO" },
  ],
};
