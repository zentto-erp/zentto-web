/**
 * Layout JSON para el reporte "Listado de Bancos".
 *
 * Diseñado para A4 portrait — columnas: Codigo, Nombre, Direccion, Telefono, Contacto, Estado.
 * Compatible con @zentto/report-core ReportLayout.
 *
 * DataSources esperados:
 *  - header (object): empresa, totalBancos
 *  - bancos (array): codigo, nombre, direccion, telefono, contacto, estado
 */
export const BANCOS_LIST_LAYOUT = {
  version: "1.0",
  name: "Listado de Bancos",
  description: "Listado tabular de bancos registrados",
  pageSize: { width: 210, height: 297, unit: "mm" },
  margins: { top: 15, right: 15, bottom: 15, left: 15 },
  orientation: "portrait" as const,
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object" as const,
      endpoint: "/v1/bancos",
      fields: [
        { name: "empresa", label: "Empresa", type: "string" },
        { name: "totalBancos", label: "Total Bancos", type: "number" },
      ],
    },
    {
      id: "bancos",
      name: "Bancos",
      type: "array" as const,
      endpoint: "/v1/bancos",
      fields: [
        { name: "codigo", label: "Codigo", type: "string" },
        { name: "nombre", label: "Nombre", type: "string" },
        { name: "direccion", label: "Direccion", type: "string" },
        { name: "telefono", label: "Telefono", type: "string" },
        { name: "contacto", label: "Contacto", type: "string" },
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
          content: "LISTADO DE BANCOS",
          x: 0, y: 0, width: 180, height: 9,
          style: { fontSize: 14, fontWeight: "bold", textAlign: "center", color: "#1a1a1a" },
        },
        {
          id: "rh-empresa",
          type: "field",
          dataSource: "header",
          field: "empresa",
          x: 0, y: 10, width: 140, height: 5,
          style: { fontSize: 9, fontWeight: "bold", color: "#555" },
        },
        {
          id: "rh-line",
          type: "line",
          x: 0, y: 18, width: 180, height: 0,
          x2: 180, y2: 18,
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
        { id: "ch-nombre", type: "text", content: "Nombre", x: 20, y: 1, width: 40, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-direccion", type: "text", content: "Direccion", x: 60, y: 1, width: 45, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-telefono", type: "text", content: "Telefono", x: 105, y: 1, width: 25, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-contacto", type: "text", content: "Contacto", x: 130, y: 1, width: 30, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-estado", type: "text", content: "Estado", x: 160, y: 1, width: 20, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
      ],
    },

    /* -- Detail (one row per banco) ------------------------------------ */
    {
      id: "det",
      type: "detail",
      height: 6,
      dataSource: "bancos",
      elements: [
        { id: "d-codigo", type: "field", dataSource: "bancos", field: "codigo", x: 0, y: 0.5, width: 20, height: 5, style: { fontSize: 7 } },
        { id: "d-nombre", type: "field", dataSource: "bancos", field: "nombre", x: 20, y: 0.5, width: 40, height: 5, style: { fontSize: 7 } },
        { id: "d-direccion", type: "field", dataSource: "bancos", field: "direccion", x: 60, y: 0.5, width: 45, height: 5, style: { fontSize: 7 } },
        { id: "d-telefono", type: "field", dataSource: "bancos", field: "telefono", x: 105, y: 0.5, width: 25, height: 5, style: { fontSize: 7 } },
        { id: "d-contacto", type: "field", dataSource: "bancos", field: "contacto", x: 130, y: 0.5, width: 30, height: 5, style: { fontSize: 7 } },
        { id: "d-estado", type: "field", dataSource: "bancos", field: "estado", x: 160, y: 0.5, width: 20, height: 5, style: { fontSize: 7, textAlign: "center" } },
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
          x: 0, y: 1, width: 180, height: 0,
          x2: 180, y2: 1,
          lineStyle: { color: "#e67e22", width: 1.5, style: "solid" },
        },
        {
          id: "rf-count-label",
          type: "text",
          content: "Total bancos:",
          x: 0, y: 4, width: 28, height: 5,
          style: { fontSize: 8, fontWeight: "bold" },
        },
        {
          id: "rf-count",
          type: "field",
          dataSource: "header",
          field: "totalBancos",
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
          x: 0, y: 0, width: 180, height: 0,
          x2: 180, y2: 0,
          lineStyle: { color: "#ccc", width: 0.5, style: "solid" },
        },
        {
          id: "pf-page",
          type: "pageNumber",
          format: "Pagina {page} de {pages}",
          x: 55, y: 2, width: 70, height: 5,
          style: { fontSize: 7, textAlign: "center", color: "#999" },
        },
        {
          id: "pf-date",
          type: "currentDate",
          format: "dd/MM/yyyy HH:mm",
          x: 120, y: 2, width: 60, height: 5,
          style: { fontSize: 7, textAlign: "right", color: "#999" },
        },
      ],
    },
  ],
};

export const BANCOS_LIST_LAYOUT_SAMPLE = {
  header: {
    empresa: "Zentto Soluciones Tecnologicas S.L.",
    totalBancos: 6,
  },
  bancos: [
    { codigo: "BAN-001", nombre: "Banco Nacional de Credito", direccion: "Av. Libertador, Torre BNC, Piso 3", telefono: "0212-5551234", contacto: "Maria Fernandez", estado: "ACTIVO" },
    { codigo: "BAN-002", nombre: "Banesco Banco Universal", direccion: "Av. Principal La Castellana", telefono: "0212-5015000", contacto: "Carlos Mendoza", estado: "ACTIVO" },
    { codigo: "BAN-003", nombre: "Banco Mercantil", direccion: "Av. Andres Bello, Edif. Mercantil", telefono: "0212-6001000", contacto: "Ana Gutierrez", estado: "ACTIVO" },
    { codigo: "BAN-004", nombre: "Banco Provincial BBVA", direccion: "Calle Madrid, Las Mercedes", telefono: "0212-5046111", contacto: "Pedro Ramirez", estado: "ACTIVO" },
    { codigo: "BAN-005", nombre: "Banco de Venezuela", direccion: "Av. Universidad, Esq. Traposos", telefono: "0212-4081111", contacto: "Luis Torres", estado: "ACTIVO" },
    { codigo: "BAN-006", nombre: "Banco Exterior", direccion: "Av. Urdaneta, Esq. Ibarras", telefono: "0212-5031111", contacto: "Rosa Diaz", estado: "INACTIVO" },
  ],
};
