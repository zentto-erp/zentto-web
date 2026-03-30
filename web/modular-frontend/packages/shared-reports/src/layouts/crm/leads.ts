/**
 * Layout JSON para el reporte "Listado de Leads".
 *
 * Diseñado para A4 landscape — columnas: Nombre, Contacto, Email, Telefono, Pipeline, Stage, Valor, Prioridad, Asignado, Status.
 * Compatible con @zentto/report-core ReportLayout.
 *
 * DataSources esperados:
 *  - header (object): empresa, totalLeads
 *  - leads (array): nombre, contacto, email, telefono, pipeline, stage, valor, prioridad, asignado, status
 */
export const LEADS_LAYOUT = {
  version: "1.0",
  name: "Listado de Leads",
  description: "Listado tabular de leads del CRM con pipeline, valor y estado",
  pageSize: { width: 297, height: 210, unit: "mm" },
  margins: { top: 12, right: 12, bottom: 12, left: 12 },
  orientation: "landscape" as const,
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object" as const,
      endpoint: "/v1/crm/leads",
      fields: [
        { name: "empresa", label: "Empresa", type: "string" },
        { name: "totalLeads", label: "Total Leads", type: "number" },
      ],
    },
    {
      id: "leads",
      name: "Leads",
      type: "array" as const,
      endpoint: "/v1/crm/leads",
      fields: [
        { name: "nombre", label: "Nombre", type: "string" },
        { name: "contacto", label: "Contacto", type: "string" },
        { name: "email", label: "Email", type: "string" },
        { name: "telefono", label: "Telefono", type: "string" },
        { name: "pipeline", label: "Pipeline", type: "string" },
        { name: "stage", label: "Stage", type: "string" },
        { name: "valor", label: "Valor", type: "currency" },
        { name: "prioridad", label: "Prioridad", type: "string" },
        { name: "asignado", label: "Asignado", type: "string" },
        { name: "status", label: "Status", type: "string" },
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
          content: "LISTADO DE LEADS",
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
        { id: "ch-nombre", type: "text", content: "Nombre", x: 0, y: 1, width: 35, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-contacto", type: "text", content: "Contacto", x: 36, y: 1, width: 30, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-email", type: "text", content: "Email", x: 67, y: 1, width: 38, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-tel", type: "text", content: "Telefono", x: 106, y: 1, width: 25, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-pipeline", type: "text", content: "Pipeline", x: 132, y: 1, width: 25, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-stage", type: "text", content: "Stage", x: 158, y: 1, width: 25, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-valor", type: "text", content: "Valor", x: 184, y: 1, width: 25, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-prior", type: "text", content: "Prioridad", x: 210, y: 1, width: 22, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
        { id: "ch-asignado", type: "text", content: "Asignado", x: 233, y: 1, width: 22, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-status", type: "text", content: "Status", x: 256, y: 1, width: 17, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
      ],
    },

    /* -- Detail (one row per lead) ------------------------------------- */
    {
      id: "det",
      type: "detail",
      height: 6,
      dataSource: "leads",
      elements: [
        { id: "d-nombre", type: "field", dataSource: "leads", field: "nombre", x: 0, y: 0.5, width: 35, height: 5, style: { fontSize: 7 } },
        { id: "d-contacto", type: "field", dataSource: "leads", field: "contacto", x: 36, y: 0.5, width: 30, height: 5, style: { fontSize: 7 } },
        { id: "d-email", type: "field", dataSource: "leads", field: "email", x: 67, y: 0.5, width: 38, height: 5, style: { fontSize: 7 } },
        { id: "d-tel", type: "field", dataSource: "leads", field: "telefono", x: 106, y: 0.5, width: 25, height: 5, style: { fontSize: 7 } },
        { id: "d-pipeline", type: "field", dataSource: "leads", field: "pipeline", x: 132, y: 0.5, width: 25, height: 5, style: { fontSize: 7 } },
        { id: "d-stage", type: "field", dataSource: "leads", field: "stage", x: 158, y: 0.5, width: 25, height: 5, style: { fontSize: 7 } },
        { id: "d-valor", type: "field", dataSource: "leads", field: "valor", x: 184, y: 0.5, width: 25, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-prior", type: "field", dataSource: "leads", field: "prioridad", x: 210, y: 0.5, width: 22, height: 5, style: { fontSize: 7, textAlign: "center" } },
        { id: "d-asignado", type: "field", dataSource: "leads", field: "asignado", x: 233, y: 0.5, width: 22, height: 5, style: { fontSize: 7 } },
        { id: "d-status", type: "field", dataSource: "leads", field: "status", x: 256, y: 0.5, width: 17, height: 5, style: { fontSize: 7, textAlign: "center" } },
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
          content: "Total leads:",
          x: 0, y: 4, width: 28, height: 5,
          style: { fontSize: 8, fontWeight: "bold" },
        },
        {
          id: "rf-count",
          type: "field",
          dataSource: "header",
          field: "totalLeads",
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

export const LEADS_LAYOUT_SAMPLE = {
  header: {
    empresa: "Zentto Soluciones Tecnologicas S.L.",
    totalLeads: 6,
  },
  leads: [
    { nombre: "Proyecto ERP Multinacional", contacto: "Fernando Alvarez", email: "falvarez@multinac.com", telefono: "0212-9551234", pipeline: "Ventas", stage: "Negociacion", valor: 45000.00, prioridad: "ALTA", asignado: "Carlos Mendoza", status: "ACTIVO" },
    { nombre: "Implementacion POS Cadena", contacto: "Gabriela Reyes", email: "greyes@cadena.com", telefono: "0241-8221000", pipeline: "Ventas", stage: "Propuesta", valor: 28000.00, prioridad: "ALTA", asignado: "Maria Lopez", status: "ACTIVO" },
    { nombre: "Migracion contable PyME", contacto: "Roberto Sanchez", email: "rsanchez@pymecont.com", telefono: "0261-7621500", pipeline: "Consultoria", stage: "Contacto", valor: 12000.00, prioridad: "MEDIA", asignado: "Carlos Mendoza", status: "ACTIVO" },
    { nombre: "Soporte anual corporativo", contacto: "Laura Martinez", email: "lmartinez@corpglobal.com", telefono: "0212-2381500", pipeline: "Soporte", stage: "Cierre", valor: 18500.00, prioridad: "MEDIA", asignado: "Luis Torres", status: "ACTIVO" },
    { nombre: "Desarrollo modulo logistica", contacto: "Andres Perez", email: "aperez@logistica.com", telefono: "0243-2461000", pipeline: "Desarrollo", stage: "Calificacion", valor: 35000.00, prioridad: "BAJA", asignado: "Maria Lopez", status: "ACTIVO" },
    { nombre: "Licencia SaaS restaurante", contacto: "Carmen Flores", email: "cflores@restobar.com", telefono: "0251-2531500", pipeline: "Ventas", stage: "Perdido", valor: 8000.00, prioridad: "BAJA", asignado: "Luis Torres", status: "CERRADO" },
  ],
};
