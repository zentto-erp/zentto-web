/**
 * Layout JSON para el reporte "Listado de Proveedores".
 *
 * Diseñado para A4 landscape — columnas: Codigo, Nombre, RIF, Direccion,
 * Telefono, Email, Saldo, Estado.
 * Compatible con @zentto/report-core ReportLayout.
 *
 * Endpoint: /v1/proveedores
 *
 * DataSources esperados:
 *  - header (object): empresa, totalProveedores
 *  - proveedores (array): codigo, nombre, rif, direccion, telefono, email,
 *    saldo, estado
 */
export const PROVEEDORES_LAYOUT = {
  version: "1.0",
  name: "Listado de Proveedores",
  description: "Listado tabular de proveedores con saldos y datos de contacto",
  pageSize: { width: 297, height: 210, unit: "mm" },
  margins: { top: 12, right: 12, bottom: 12, left: 12 },
  orientation: "landscape" as const,
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object" as const,
      endpoint: "/v1/proveedores",
      fields: [
        { name: "empresa", label: "Empresa", type: "string" },
        { name: "totalProveedores", label: "Total Proveedores", type: "number" },
      ],
    },
    {
      id: "proveedores",
      name: "Proveedores",
      type: "array" as const,
      endpoint: "/v1/proveedores",
      fields: [
        { name: "codigo", label: "Codigo", type: "string" },
        { name: "nombre", label: "Nombre", type: "string" },
        { name: "rif", label: "RIF", type: "string" },
        { name: "direccion", label: "Direccion", type: "string" },
        { name: "telefono", label: "Telefono", type: "string" },
        { name: "email", label: "Email", type: "string" },
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
          content: "LISTADO DE PROVEEDORES",
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
          id: "rh-total-label",
          type: "text",
          content: "Total proveedores:",
          x: 200, y: 10, width: 35, height: 5,
          style: { fontSize: 8, fontWeight: "bold", color: "#555" },
        },
        {
          id: "rh-total",
          type: "field",
          dataSource: "header",
          field: "totalProveedores",
          x: 236, y: 10, width: 37, height: 5,
          format: "#,##0",
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

    /* -- Column Header ------------------------------------------------- */
    {
      id: "ch",
      type: "columnHeader",
      height: 8,
      repeatOnEveryPage: true,
      backgroundColor: "#e67e22",
      elements: [
        { id: "ch-codigo", type: "text", content: "Codigo", x: 0, y: 1, width: 20, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-nombre", type: "text", content: "Nombre", x: 21, y: 1, width: 58, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-rif", type: "text", content: "RIF", x: 80, y: 1, width: 28, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-direccion", type: "text", content: "Direccion", x: 109, y: 1, width: 55, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-telefono", type: "text", content: "Telefono", x: 165, y: 1, width: 28, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-email", type: "text", content: "Email", x: 194, y: 1, width: 38, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-saldo", type: "text", content: "Saldo", x: 233, y: 1, width: 26, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-estado", type: "text", content: "Estado", x: 260, y: 1, width: 13, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
      ],
    },

    /* -- Detail (one row per proveedor) -------------------------------- */
    {
      id: "det",
      type: "detail",
      height: 6,
      dataSource: "proveedores",
      elements: [
        { id: "d-codigo", type: "field", dataSource: "proveedores", field: "codigo", x: 0, y: 0.5, width: 20, height: 5, style: { fontSize: 7 } },
        { id: "d-nombre", type: "field", dataSource: "proveedores", field: "nombre", x: 21, y: 0.5, width: 58, height: 5, style: { fontSize: 7 } },
        { id: "d-rif", type: "field", dataSource: "proveedores", field: "rif", x: 80, y: 0.5, width: 28, height: 5, style: { fontSize: 7 } },
        { id: "d-direccion", type: "field", dataSource: "proveedores", field: "direccion", x: 109, y: 0.5, width: 55, height: 5, style: { fontSize: 7 } },
        { id: "d-telefono", type: "field", dataSource: "proveedores", field: "telefono", x: 165, y: 0.5, width: 28, height: 5, style: { fontSize: 7 } },
        { id: "d-email", type: "field", dataSource: "proveedores", field: "email", x: 194, y: 0.5, width: 38, height: 5, style: { fontSize: 7 } },
        { id: "d-saldo", type: "field", dataSource: "proveedores", field: "saldo", x: 233, y: 0.5, width: 26, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-estado", type: "field", dataSource: "proveedores", field: "estado", x: 260, y: 0.5, width: 13, height: 5, style: { fontSize: 7, textAlign: "center" } },
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
          id: "rf-count-label",
          type: "text",
          content: "Total proveedores:",
          x: 0, y: 4, width: 35, height: 5,
          style: { fontSize: 8, fontWeight: "bold" },
        },
        {
          id: "rf-count",
          type: "field",
          dataSource: "header",
          field: "totalProveedores",
          x: 36, y: 4, width: 20, height: 5,
          format: "#,##0",
          style: { fontSize: 8, fontWeight: "bold" },
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

export const PROVEEDORES_LAYOUT_SAMPLE = {
  header: {
    empresa: "Zentto Soluciones Tecnologicas S.L.",
    totalProveedores: 6,
  },
  proveedores: [
    { codigo: "PRV-001", nombre: "Importadora Tech C.A.", rif: "J-30112233-5", direccion: "Av. Francisco de Miranda, Caracas", telefono: "0212-2641000", email: "ventas@importech.com", saldo: 40600.00, estado: "ACTIVO" },
    { codigo: "PRV-002", nombre: "Distribuidora Nacional C.A.", rif: "J-40223344-9", direccion: "Zona Industrial Sur, Valencia", telefono: "0241-8335500", email: "pedidos@distnacional.com", saldo: 25520.00, estado: "ACTIVO" },
    { codigo: "PRV-003", nombre: "Suministros Express S.A.", rif: "J-50334455-2", direccion: "Calle Comercio, Barquisimeto", telefono: "0251-2531000", email: "info@sumexpress.com", saldo: 0.00, estado: "ACTIVO" },
    { codigo: "PRV-004", nombre: "Servicios Integrados C.A.", rif: "J-60445566-6", direccion: "Av. Bolivar, Maracaibo", telefono: "0261-7921000", email: "contacto@servintegrados.com", saldo: 27840.00, estado: "ACTIVO" },
    { codigo: "PRV-005", nombre: "Materiales del Este S.R.L.", rif: "J-70556677-0", direccion: "Av. Intercomunal, Guarenas", telefono: "0212-3621500", email: "ventas@mateste.com", saldo: 0.00, estado: "ACTIVO" },
    { codigo: "PRV-006", nombre: "Comercial Andina C.A.", rif: "J-80667788-4", direccion: "Calle 10, San Cristobal", telefono: "0276-3561000", email: "admin@comandina.com", saldo: 0.00, estado: "INACTIVO" },
  ],
};
