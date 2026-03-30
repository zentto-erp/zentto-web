/**
 * Layout JSON para el reporte "Almacenes".
 *
 * Diseñado para A4 portrait — columnas: Codigo, Nombre, Tipo, Direccion, Responsable, Estado.
 * Compatible con @zentto/report-core ReportLayout.
 *
 * DataSources esperados:
 *  - header (object): empresa, totalAlmacenes
 *  - almacenes (array): codigo, nombre, tipo, direccion, responsable, estado
 */
export const ALMACENES_LAYOUT = {
  version: "1.0",
  name: "Almacenes",
  description: "Listado tabular de almacenes con tipo, direccion y responsable",
  pageSize: { width: 210, height: 297, unit: "mm" },
  margins: { top: 15, right: 15, bottom: 15, left: 15 },
  orientation: "portrait" as const,
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object" as const,
      endpoint: "/v1/almacen",
      fields: [
        { name: "empresa", label: "Empresa", type: "string" },
        { name: "totalAlmacenes", label: "Total Almacenes", type: "number" },
      ],
    },
    {
      id: "almacenes",
      name: "Almacenes",
      type: "array" as const,
      endpoint: "/v1/almacen",
      fields: [
        { name: "codigo", label: "Codigo", type: "string" },
        { name: "nombre", label: "Nombre", type: "string" },
        { name: "tipo", label: "Tipo", type: "string" },
        { name: "direccion", label: "Direccion", type: "string" },
        { name: "responsable", label: "Responsable", type: "string" },
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
          content: "ALMACENES",
          x: 0, y: 0, width: 180, height: 9,
          style: { fontSize: 14, fontWeight: "bold", textAlign: "center", color: "#1a1a1a" },
        },
        {
          id: "rh-empresa",
          type: "field",
          dataSource: "header",
          field: "empresa",
          x: 0, y: 10, width: 100, height: 5,
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
        { id: "ch-codigo", type: "text", content: "Codigo", x: 0, y: 1, width: 22, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-nombre", type: "text", content: "Nombre", x: 23, y: 1, width: 38, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-tipo", type: "text", content: "Tipo", x: 62, y: 1, width: 22, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-dir", type: "text", content: "Direccion", x: 85, y: 1, width: 40, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-resp", type: "text", content: "Responsable", x: 126, y: 1, width: 32, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-estado", type: "text", content: "Estado", x: 159, y: 1, width: 21, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
      ],
    },

    /* -- Detail (one row per almacen) ---------------------------------- */
    {
      id: "det",
      type: "detail",
      height: 6,
      dataSource: "almacenes",
      elements: [
        { id: "d-codigo", type: "field", dataSource: "almacenes", field: "codigo", x: 0, y: 0.5, width: 22, height: 5, style: { fontSize: 7 } },
        { id: "d-nombre", type: "field", dataSource: "almacenes", field: "nombre", x: 23, y: 0.5, width: 38, height: 5, style: { fontSize: 7 } },
        { id: "d-tipo", type: "field", dataSource: "almacenes", field: "tipo", x: 62, y: 0.5, width: 22, height: 5, style: { fontSize: 7 } },
        { id: "d-dir", type: "field", dataSource: "almacenes", field: "direccion", x: 85, y: 0.5, width: 40, height: 5, style: { fontSize: 7 } },
        { id: "d-resp", type: "field", dataSource: "almacenes", field: "responsable", x: 126, y: 0.5, width: 32, height: 5, style: { fontSize: 7 } },
        { id: "d-estado", type: "field", dataSource: "almacenes", field: "estado", x: 159, y: 0.5, width: 21, height: 5, style: { fontSize: 7, textAlign: "center" } },
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
          content: "Total almacenes:",
          x: 0, y: 4, width: 35, height: 5,
          style: { fontSize: 8, fontWeight: "bold" },
        },
        {
          id: "rf-count",
          type: "field",
          dataSource: "header",
          field: "totalAlmacenes",
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
          x: 0, y: 0, width: 180, height: 0,
          x2: 180, y2: 0,
          lineStyle: { color: "#ccc", width: 0.5, style: "solid" },
        },
        {
          id: "pf-page",
          type: "pageNumber",
          format: "Pagina {page} de {pages}",
          x: 50, y: 2, width: 80, height: 5,
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

export const ALMACENES_LAYOUT_SAMPLE = {
  header: {
    empresa: "Zentto Soluciones Tecnologicas S.L.",
    totalAlmacenes: 5,
  },
  almacenes: [
    { codigo: "ALM-001", nombre: "Almacen Principal", tipo: "PRINCIPAL", direccion: "Av. Bolivar Norte, Galpón 3, Valencia", responsable: "Pedro Ramirez", estado: "ACTIVO" },
    { codigo: "ALM-002", nombre: "Deposito Sur", tipo: "DEPOSITO", direccion: "Zona Industrial Sur, Galpon 12, Valencia", responsable: "Ana Gutierrez", estado: "ACTIVO" },
    { codigo: "ALM-003", nombre: "Sucursal Norte", tipo: "SUCURSAL", direccion: "Av. Cedeño, Local 5, Barquisimeto", responsable: "Luis Torres", estado: "ACTIVO" },
    { codigo: "ALM-004", nombre: "Almacen Transito", tipo: "TRANSITO", direccion: "Puerto La Guaira, Deposito 8", responsable: "Maria Fernandez", estado: "ACTIVO" },
    { codigo: "ALM-005", nombre: "Almacen Obsoletos", tipo: "OBSOLETO", direccion: "Av. Bolivar Norte, Galpon 5, Valencia", responsable: "Pedro Ramirez", estado: "INACTIVO" },
  ],
};
