/**
 * Layout JSON para el reporte "Caja Chica".
 *
 * Diseñado para A4 portrait — columnas: Codigo, Nombre, Responsable, Monto Asignado, Monto Disponible, Estado.
 * Compatible con @zentto/report-core ReportLayout.
 *
 * DataSources esperados:
 *  - header (object): empresa, totalCajas
 *  - cajas (array): codigo, nombre, responsable, montoAsignado, montoDisponible, estado
 */
export const CAJA_CHICA_LAYOUT = {
  version: "1.0",
  name: "Caja Chica",
  description: "Listado tabular de cajas chicas con montos asignados y disponibles",
  pageSize: { width: 210, height: 297, unit: "mm" },
  margins: { top: 15, right: 15, bottom: 15, left: 15 },
  orientation: "portrait" as const,
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object" as const,
      endpoint: "/v1/bancos/caja-chica",
      fields: [
        { name: "empresa", label: "Empresa", type: "string" },
        { name: "totalCajas", label: "Total Cajas", type: "number" },
      ],
    },
    {
      id: "cajas",
      name: "Cajas",
      type: "array" as const,
      endpoint: "/v1/bancos/caja-chica",
      fields: [
        { name: "codigo", label: "Codigo", type: "string" },
        { name: "nombre", label: "Nombre", type: "string" },
        { name: "responsable", label: "Responsable", type: "string" },
        { name: "montoAsignado", label: "Monto Asignado", type: "currency" },
        { name: "montoDisponible", label: "Monto Disponible", type: "currency" },
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
          content: "CAJA CHICA",
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
        { id: "ch-codigo", type: "text", content: "Codigo", x: 0, y: 1, width: 18, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-nombre", type: "text", content: "Nombre", x: 18, y: 1, width: 35, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-responsable", type: "text", content: "Responsable", x: 53, y: 1, width: 40, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-asignado", type: "text", content: "Monto Asignado", x: 93, y: 1, width: 30, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-disponible", type: "text", content: "Monto Disponible", x: 123, y: 1, width: 35, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-estado", type: "text", content: "Estado", x: 158, y: 1, width: 22, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
      ],
    },

    /* -- Detail (one row per caja) ------------------------------------- */
    {
      id: "det",
      type: "detail",
      height: 6,
      dataSource: "cajas",
      elements: [
        { id: "d-codigo", type: "field", dataSource: "cajas", field: "codigo", x: 0, y: 0.5, width: 18, height: 5, style: { fontSize: 7 } },
        { id: "d-nombre", type: "field", dataSource: "cajas", field: "nombre", x: 18, y: 0.5, width: 35, height: 5, style: { fontSize: 7 } },
        { id: "d-responsable", type: "field", dataSource: "cajas", field: "responsable", x: 53, y: 0.5, width: 40, height: 5, style: { fontSize: 7 } },
        { id: "d-asignado", type: "field", dataSource: "cajas", field: "montoAsignado", x: 93, y: 0.5, width: 30, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-disponible", type: "field", dataSource: "cajas", field: "montoDisponible", x: 123, y: 0.5, width: 35, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-estado", type: "field", dataSource: "cajas", field: "estado", x: 158, y: 0.5, width: 22, height: 5, style: { fontSize: 7, textAlign: "center" } },
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
          content: "Total cajas:",
          x: 0, y: 4, width: 25, height: 5,
          style: { fontSize: 8, fontWeight: "bold" },
        },
        {
          id: "rf-count",
          type: "field",
          dataSource: "header",
          field: "totalCajas",
          x: 26, y: 4, width: 20, height: 5,
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
