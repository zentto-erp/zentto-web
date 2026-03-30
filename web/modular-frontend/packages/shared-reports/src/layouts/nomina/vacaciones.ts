/**
 * Layout JSON para el reporte "Solicitudes de Vacaciones".
 *
 * Diseñado para A4 landscape — columnas: Empleado, Nombre, Fecha Solicitud, Inicio, Fin, Dias, Status.
 * Compatible con @zentto/report-core ReportLayout.
 *
 * DataSources esperados:
 *  - header (object): empresa, totalSolicitudes
 *  - solicitudes (array): empleado, nombreEmpleado, fechaSolicitud, fechaInicio, fechaFin, dias, status
 */
export const VACACIONES_LAYOUT = {
  version: "1.0",
  name: "Solicitudes de Vacaciones",
  description: "Listado tabular de solicitudes de vacaciones con dias y estado",
  pageSize: { width: 297, height: 210, unit: "mm" },
  margins: { top: 12, right: 12, bottom: 12, left: 12 },
  orientation: "landscape" as const,
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object" as const,
      endpoint: "/v1/nomina/vacaciones/solicitudes",
      fields: [
        { name: "empresa", label: "Empresa", type: "string" },
        { name: "totalSolicitudes", label: "Total Solicitudes", type: "number" },
      ],
    },
    {
      id: "solicitudes",
      name: "Solicitudes",
      type: "array" as const,
      endpoint: "/v1/nomina/vacaciones/solicitudes",
      fields: [
        { name: "empleado", label: "Empleado", type: "string" },
        { name: "nombreEmpleado", label: "Nombre", type: "string" },
        { name: "fechaSolicitud", label: "Fecha Solicitud", type: "string" },
        { name: "fechaInicio", label: "Inicio", type: "string" },
        { name: "fechaFin", label: "Fin", type: "string" },
        { name: "dias", label: "Dias", type: "number" },
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
          content: "SOLICITUDES DE VACACIONES",
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
        { id: "ch-empl", type: "text", content: "Empleado", x: 0, y: 1, width: 25, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-nombre", type: "text", content: "Nombre", x: 26, y: 1, width: 65, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-fsol", type: "text", content: "Fecha Solicitud", x: 92, y: 1, width: 35, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-inicio", type: "text", content: "Inicio", x: 128, y: 1, width: 35, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-fin", type: "text", content: "Fin", x: 164, y: 1, width: 35, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-dias", type: "text", content: "Dias", x: 200, y: 1, width: 20, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-status", type: "text", content: "Status", x: 221, y: 1, width: 52, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
      ],
    },

    /* -- Detail (one row per solicitud) -------------------------------- */
    {
      id: "det",
      type: "detail",
      height: 6,
      dataSource: "solicitudes",
      elements: [
        { id: "d-empl", type: "field", dataSource: "solicitudes", field: "empleado", x: 0, y: 0.5, width: 25, height: 5, style: { fontSize: 7 } },
        { id: "d-nombre", type: "field", dataSource: "solicitudes", field: "nombreEmpleado", x: 26, y: 0.5, width: 65, height: 5, style: { fontSize: 7 } },
        { id: "d-fsol", type: "field", dataSource: "solicitudes", field: "fechaSolicitud", x: 92, y: 0.5, width: 35, height: 5, style: { fontSize: 7 } },
        { id: "d-inicio", type: "field", dataSource: "solicitudes", field: "fechaInicio", x: 128, y: 0.5, width: 35, height: 5, style: { fontSize: 7 } },
        { id: "d-fin", type: "field", dataSource: "solicitudes", field: "fechaFin", x: 164, y: 0.5, width: 35, height: 5, style: { fontSize: 7 } },
        { id: "d-dias", type: "field", dataSource: "solicitudes", field: "dias", x: 200, y: 0.5, width: 20, height: 5, format: "#,##0", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-status", type: "field", dataSource: "solicitudes", field: "status", x: 221, y: 0.5, width: 52, height: 5, style: { fontSize: 7, textAlign: "center" } },
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
          content: "Total solicitudes:",
          x: 0, y: 4, width: 35, height: 5,
          style: { fontSize: 8, fontWeight: "bold" },
        },
        {
          id: "rf-count",
          type: "field",
          dataSource: "header",
          field: "totalSolicitudes",
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

export const VACACIONES_LAYOUT_SAMPLE = {
  header: {
    empresa: "Zentto Soluciones Tecnologicas S.L.",
    totalSolicitudes: 6,
  },
  solicitudes: [
    { empleado: "V-12345678", nombreEmpleado: "Maria Fernandez Garcia", fechaSolicitud: "10/01/2026", fechaInicio: "02/02/2026", fechaFin: "16/02/2026", dias: 15, status: "APROBADA" },
    { empleado: "V-78901234", nombreEmpleado: "Jorge Morales Bravo", fechaSolicitud: "15/02/2026", fechaInicio: "16/03/2026", fechaFin: "30/03/2026", dias: 15, status: "APROBADA" },
    { empleado: "V-23456789", nombreEmpleado: "Carlos Mendoza Rodriguez", fechaSolicitud: "01/03/2026", fechaInicio: "06/04/2026", fechaFin: "17/04/2026", dias: 12, status: "PENDIENTE" },
    { empleado: "V-56789012", nombreEmpleado: "Luis Torres Martinez", fechaSolicitud: "05/03/2026", fechaInicio: "20/04/2026", fechaFin: "01/05/2026", dias: 12, status: "PENDIENTE" },
    { empleado: "V-34567890", nombreEmpleado: "Ana Gutierrez Lopez", fechaSolicitud: "20/01/2026", fechaInicio: "03/03/2026", fechaFin: "10/03/2026", dias: 8, status: "DISFRUTADA" },
    { empleado: "V-67890123", nombreEmpleado: "Rosa Diaz Hernandez", fechaSolicitud: "18/03/2026", fechaInicio: "01/06/2026", fechaFin: "15/06/2026", dias: 15, status: "RECHAZADA" },
  ],
};
