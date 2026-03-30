/**
 * Layout JSON para el reporte "Listado de Empleados".
 *
 * Diseñado para A4 landscape — columnas: Cedula, Nombre, Cargo, Departamento, Fecha Ingreso, Sueldo, Status.
 * Compatible con @zentto/report-core ReportLayout.
 *
 * DataSources esperados:
 *  - header (object): empresa, totalEmpleados
 *  - empleados (array): cedula, nombre, cargo, departamento, fechaIngreso, sueldo, status
 */
export const EMPLEADOS_LAYOUT = {
  version: "1.0",
  name: "Listado de Empleados",
  description: "Listado tabular de empleados con datos basicos y sueldo",
  pageSize: { width: 297, height: 210, unit: "mm" },
  margins: { top: 12, right: 12, bottom: 12, left: 12 },
  orientation: "landscape" as const,
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object" as const,
      endpoint: "/v1/empleados",
      fields: [
        { name: "empresa", label: "Empresa", type: "string" },
        { name: "totalEmpleados", label: "Total Empleados", type: "number" },
      ],
    },
    {
      id: "empleados",
      name: "Empleados",
      type: "array" as const,
      endpoint: "/v1/empleados",
      fields: [
        { name: "cedula", label: "Cedula", type: "string" },
        { name: "nombre", label: "Nombre", type: "string" },
        { name: "cargo", label: "Cargo", type: "string" },
        { name: "departamento", label: "Departamento", type: "string" },
        { name: "fechaIngreso", label: "Fecha Ingreso", type: "string" },
        { name: "sueldo", label: "Sueldo", type: "currency" },
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
          content: "LISTADO DE EMPLEADOS",
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
        { id: "ch-cedula", type: "text", content: "Cedula", x: 0, y: 1, width: 30, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-nombre", type: "text", content: "Nombre", x: 31, y: 1, width: 60, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-cargo", type: "text", content: "Cargo", x: 92, y: 1, width: 45, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-depto", type: "text", content: "Departamento", x: 138, y: 1, width: 45, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-fecha", type: "text", content: "Fecha Ingreso", x: 184, y: 1, width: 30, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-sueldo", type: "text", content: "Sueldo", x: 215, y: 1, width: 30, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-status", type: "text", content: "Status", x: 246, y: 1, width: 27, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
      ],
    },

    /* -- Detail (one row per empleado) --------------------------------- */
    {
      id: "det",
      type: "detail",
      height: 6,
      dataSource: "empleados",
      elements: [
        { id: "d-cedula", type: "field", dataSource: "empleados", field: "cedula", x: 0, y: 0.5, width: 30, height: 5, style: { fontSize: 7 } },
        { id: "d-nombre", type: "field", dataSource: "empleados", field: "nombre", x: 31, y: 0.5, width: 60, height: 5, style: { fontSize: 7 } },
        { id: "d-cargo", type: "field", dataSource: "empleados", field: "cargo", x: 92, y: 0.5, width: 45, height: 5, style: { fontSize: 7 } },
        { id: "d-depto", type: "field", dataSource: "empleados", field: "departamento", x: 138, y: 0.5, width: 45, height: 5, style: { fontSize: 7 } },
        { id: "d-fecha", type: "field", dataSource: "empleados", field: "fechaIngreso", x: 184, y: 0.5, width: 30, height: 5, style: { fontSize: 7 } },
        { id: "d-sueldo", type: "field", dataSource: "empleados", field: "sueldo", x: 215, y: 0.5, width: 30, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-status", type: "field", dataSource: "empleados", field: "status", x: 246, y: 0.5, width: 27, height: 5, style: { fontSize: 7, textAlign: "center" } },
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
          content: "Total empleados:",
          x: 0, y: 4, width: 35, height: 5,
          style: { fontSize: 8, fontWeight: "bold" },
        },
        {
          id: "rf-count",
          type: "field",
          dataSource: "header",
          field: "totalEmpleados",
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

export const EMPLEADOS_LAYOUT_SAMPLE = {
  header: {
    empresa: "Zentto Soluciones Tecnologicas S.L.",
    totalEmpleados: 7,
  },
  empleados: [
    { cedula: "V-12345678", nombre: "Maria Fernandez Garcia", cargo: "Gerente Administrativo", departamento: "Administracion", fechaIngreso: "15/03/2020", sueldo: 8500.00, status: "ACTIVO" },
    { cedula: "V-23456789", nombre: "Carlos Mendoza Rodriguez", cargo: "Jefe de Ventas", departamento: "Ventas", fechaIngreso: "01/06/2021", sueldo: 6200.00, status: "ACTIVO" },
    { cedula: "V-34567890", nombre: "Ana Gutierrez Lopez", cargo: "Contador Senior", departamento: "Contabilidad", fechaIngreso: "10/01/2019", sueldo: 7800.00, status: "ACTIVO" },
    { cedula: "V-45678901", nombre: "Pedro Ramirez Silva", cargo: "Almacenista", departamento: "Almacen", fechaIngreso: "20/08/2022", sueldo: 3500.00, status: "ACTIVO" },
    { cedula: "V-56789012", nombre: "Luis Torres Martinez", cargo: "Vendedor", departamento: "Ventas", fechaIngreso: "05/11/2023", sueldo: 4000.00, status: "ACTIVO" },
    { cedula: "V-67890123", nombre: "Rosa Diaz Hernandez", cargo: "Asistente RRHH", departamento: "Recursos Humanos", fechaIngreso: "15/02/2024", sueldo: 3800.00, status: "ACTIVO" },
    { cedula: "V-78901234", nombre: "Jorge Morales Bravo", cargo: "Programador", departamento: "Tecnologia", fechaIngreso: "01/09/2021", sueldo: 7000.00, status: "VACACIONES" },
  ],
};
