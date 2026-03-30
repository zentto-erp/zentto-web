/**
 * Layout JSON para el reporte "Listado de Actividades CRM".
 *
 * Diseñado para A4 landscape — columnas: Tipo, Titulo, Lead, Cliente, Asignado, Fecha Programada, Completada.
 * Compatible con @zentto/report-core ReportLayout.
 *
 * DataSources esperados:
 *  - header (object): empresa, totalActividades
 *  - actividades (array): tipo, titulo, lead, cliente, asignado, fechaProgramada, completada
 */
export const ACTIVIDADES_CRM_LAYOUT = {
  version: "1.0",
  name: "Listado de Actividades CRM",
  description: "Listado tabular de actividades del CRM con lead, cliente y estado de completitud",
  pageSize: { width: 297, height: 210, unit: "mm" },
  margins: { top: 12, right: 12, bottom: 12, left: 12 },
  orientation: "landscape" as const,
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object" as const,
      endpoint: "/v1/crm/actividades",
      fields: [
        { name: "empresa", label: "Empresa", type: "string" },
        { name: "totalActividades", label: "Total Actividades", type: "number" },
      ],
    },
    {
      id: "actividades",
      name: "Actividades",
      type: "array" as const,
      endpoint: "/v1/crm/actividades",
      fields: [
        { name: "tipo", label: "Tipo", type: "string" },
        { name: "titulo", label: "Titulo", type: "string" },
        { name: "lead", label: "Lead", type: "string" },
        { name: "cliente", label: "Cliente", type: "string" },
        { name: "asignado", label: "Asignado", type: "string" },
        { name: "fechaProgramada", label: "Fecha Programada", type: "string" },
        { name: "completada", label: "Completada", type: "string" },
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
          content: "LISTADO DE ACTIVIDADES CRM",
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
        { id: "ch-tipo", type: "text", content: "Tipo", x: 0, y: 1, width: 28, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-titulo", type: "text", content: "Titulo", x: 29, y: 1, width: 60, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-lead", type: "text", content: "Lead", x: 90, y: 1, width: 40, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-cliente", type: "text", content: "Cliente", x: 131, y: 1, width: 45, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-asignado", type: "text", content: "Asignado", x: 177, y: 1, width: 35, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-fecha", type: "text", content: "Fecha Programada", x: 213, y: 1, width: 35, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-completada", type: "text", content: "Completada", x: 249, y: 1, width: 24, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
      ],
    },

    /* -- Detail (one row per actividad) -------------------------------- */
    {
      id: "det",
      type: "detail",
      height: 6,
      dataSource: "actividades",
      elements: [
        { id: "d-tipo", type: "field", dataSource: "actividades", field: "tipo", x: 0, y: 0.5, width: 28, height: 5, style: { fontSize: 7 } },
        { id: "d-titulo", type: "field", dataSource: "actividades", field: "titulo", x: 29, y: 0.5, width: 60, height: 5, style: { fontSize: 7 } },
        { id: "d-lead", type: "field", dataSource: "actividades", field: "lead", x: 90, y: 0.5, width: 40, height: 5, style: { fontSize: 7 } },
        { id: "d-cliente", type: "field", dataSource: "actividades", field: "cliente", x: 131, y: 0.5, width: 45, height: 5, style: { fontSize: 7 } },
        { id: "d-asignado", type: "field", dataSource: "actividades", field: "asignado", x: 177, y: 0.5, width: 35, height: 5, style: { fontSize: 7 } },
        { id: "d-fecha", type: "field", dataSource: "actividades", field: "fechaProgramada", x: 213, y: 0.5, width: 35, height: 5, style: { fontSize: 7 } },
        { id: "d-completada", type: "field", dataSource: "actividades", field: "completada", x: 249, y: 0.5, width: 24, height: 5, style: { fontSize: 7, textAlign: "center" } },
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
          content: "Total actividades:",
          x: 0, y: 4, width: 35, height: 5,
          style: { fontSize: 8, fontWeight: "bold" },
        },
        {
          id: "rf-count",
          type: "field",
          dataSource: "header",
          field: "totalActividades",
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

export const ACTIVIDADES_CRM_LAYOUT_SAMPLE = {
  header: {
    empresa: "Zentto Soluciones Tecnologicas S.L.",
    totalActividades: 7,
  },
  actividades: [
    { tipo: "LLAMADA", titulo: "Seguimiento propuesta ERP", lead: "Proyecto ERP Multinacional", cliente: "Multinacional C.A.", asignado: "Carlos Mendoza", fechaProgramada: "28/03/2026", completada: "SI" },
    { tipo: "REUNION", titulo: "Demo sistema POS", lead: "Implementacion POS Cadena", cliente: "Cadena Comercial S.A.", asignado: "Maria Lopez", fechaProgramada: "30/03/2026", completada: "NO" },
    { tipo: "EMAIL", titulo: "Enviar cotizacion migracion", lead: "Migracion contable PyME", cliente: "PyME Contable S.R.L.", asignado: "Carlos Mendoza", fechaProgramada: "25/03/2026", completada: "SI" },
    { tipo: "REUNION", titulo: "Firma contrato soporte", lead: "Soporte anual corporativo", cliente: "Corp Global C.A.", asignado: "Luis Torres", fechaProgramada: "01/04/2026", completada: "NO" },
    { tipo: "LLAMADA", titulo: "Primer contacto logistica", lead: "Desarrollo modulo logistica", cliente: "Logistica Express C.A.", asignado: "Maria Lopez", fechaProgramada: "02/04/2026", completada: "NO" },
    { tipo: "TAREA", titulo: "Preparar presentacion tecnica", lead: "Proyecto ERP Multinacional", cliente: "Multinacional C.A.", asignado: "Carlos Mendoza", fechaProgramada: "27/03/2026", completada: "SI" },
    { tipo: "VISITA", titulo: "Visita instalaciones cliente", lead: "Implementacion POS Cadena", cliente: "Cadena Comercial S.A.", asignado: "Maria Lopez", fechaProgramada: "05/04/2026", completada: "NO" },
  ],
};
