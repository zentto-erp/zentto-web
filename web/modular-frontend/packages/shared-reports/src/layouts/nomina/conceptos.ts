/**
 * Layout JSON para el reporte "Conceptos de Nomina".
 *
 * Diseñado para A4 landscape — columnas: Codigo, Descripcion, Tipo, Formula, Porcentaje, Estado.
 * Compatible con @zentto/report-core ReportLayout.
 *
 * DataSources esperados:
 *  - header (object): empresa, totalConceptos
 *  - conceptos (array): codigo, descripcion, tipo, formula, porcentaje, estado
 */
export const CONCEPTOS_NOMINA_LAYOUT = {
  version: "1.0",
  name: "Conceptos de Nomina",
  description: "Listado tabular de conceptos de nomina con formulas y porcentajes",
  pageSize: { width: 297, height: 210, unit: "mm" },
  margins: { top: 12, right: 12, bottom: 12, left: 12 },
  orientation: "landscape" as const,
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object" as const,
      endpoint: "/v1/nomina/conceptos",
      fields: [
        { name: "empresa", label: "Empresa", type: "string" },
        { name: "totalConceptos", label: "Total Conceptos", type: "number" },
      ],
    },
    {
      id: "conceptos",
      name: "Conceptos",
      type: "array" as const,
      endpoint: "/v1/nomina/conceptos",
      fields: [
        { name: "codigo", label: "Codigo", type: "string" },
        { name: "descripcion", label: "Descripcion", type: "string" },
        { name: "tipo", label: "Tipo", type: "string" },
        { name: "formula", label: "Formula", type: "string" },
        { name: "porcentaje", label: "Porcentaje", type: "number" },
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
          content: "CONCEPTOS DE NOMINA",
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
        { id: "ch-desc", type: "text", content: "Descripcion", x: 26, y: 1, width: 80, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-tipo", type: "text", content: "Tipo", x: 107, y: 1, width: 40, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-formula", type: "text", content: "Formula", x: 148, y: 1, width: 60, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-pct", type: "text", content: "Porcentaje", x: 209, y: 1, width: 30, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-estado", type: "text", content: "Estado", x: 240, y: 1, width: 33, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
      ],
    },

    /* -- Detail (one row per concepto) --------------------------------- */
    {
      id: "det",
      type: "detail",
      height: 6,
      dataSource: "conceptos",
      elements: [
        { id: "d-codigo", type: "field", dataSource: "conceptos", field: "codigo", x: 0, y: 0.5, width: 25, height: 5, style: { fontSize: 7 } },
        { id: "d-desc", type: "field", dataSource: "conceptos", field: "descripcion", x: 26, y: 0.5, width: 80, height: 5, style: { fontSize: 7 } },
        { id: "d-tipo", type: "field", dataSource: "conceptos", field: "tipo", x: 107, y: 0.5, width: 40, height: 5, style: { fontSize: 7 } },
        { id: "d-formula", type: "field", dataSource: "conceptos", field: "formula", x: 148, y: 0.5, width: 60, height: 5, style: { fontSize: 7 } },
        { id: "d-pct", type: "field", dataSource: "conceptos", field: "porcentaje", x: 209, y: 0.5, width: 30, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-estado", type: "field", dataSource: "conceptos", field: "estado", x: 240, y: 0.5, width: 33, height: 5, style: { fontSize: 7, textAlign: "center" } },
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
          content: "Total conceptos:",
          x: 0, y: 4, width: 35, height: 5,
          style: { fontSize: 8, fontWeight: "bold" },
        },
        {
          id: "rf-count",
          type: "field",
          dataSource: "header",
          field: "totalConceptos",
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

export const CONCEPTOS_NOMINA_LAYOUT_SAMPLE = {
  header: {
    empresa: "Zentto Soluciones Tecnologicas S.L.",
    totalConceptos: 7,
  },
  conceptos: [
    { codigo: "ASG-001", descripcion: "Sueldo Basico", tipo: "ASIGNACION", formula: "SUELDO_BASE", porcentaje: 100.00, estado: "ACTIVO" },
    { codigo: "ASG-002", descripcion: "Bono de Alimentacion", tipo: "ASIGNACION", formula: "CESTATICKET * DIAS_LAB", porcentaje: 0.00, estado: "ACTIVO" },
    { codigo: "ASG-003", descripcion: "Horas Extras", tipo: "ASIGNACION", formula: "HORA_EXTRA * CANT_HE", porcentaje: 150.00, estado: "ACTIVO" },
    { codigo: "DED-001", descripcion: "Seguro Social Obligatorio", tipo: "DEDUCCION", formula: "SUELDO_BASE * PCT", porcentaje: 4.00, estado: "ACTIVO" },
    { codigo: "DED-002", descripcion: "Regimen Prestacional de Empleo", tipo: "DEDUCCION", formula: "SUELDO_BASE * PCT", porcentaje: 0.50, estado: "ACTIVO" },
    { codigo: "DED-003", descripcion: "Fondo Ahorro Habitacional", tipo: "DEDUCCION", formula: "SUELDO_INTEGRAL * PCT", porcentaje: 1.00, estado: "ACTIVO" },
    { codigo: "DED-004", descripcion: "ISLR Retenido", tipo: "DEDUCCION", formula: "TABLA_ISLR(SUELDO_ANUAL)", porcentaje: 0.00, estado: "ACTIVO" },
  ],
};
