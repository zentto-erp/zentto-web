/**
 * Layout JSON para el reporte "Movimientos de Inventario".
 *
 * Diseñado para A4 landscape — columnas: Fecha, Tipo Mov., Cod. Articulo, Nombre Articulo, Almacen, Cantidad, Costo Unit., Costo Total.
 * Compatible con @zentto/report-core ReportLayout.
 *
 * DataSources esperados:
 *  - header (object): empresa, fechaDesde, fechaHasta, totalMovimientos
 *  - movimientos (array): fecha, tipoMovimiento, codArticulo, nombreArticulo, almacen, cantidad, costoUnitario, costoTotal
 */
export const MOVIMIENTOS_INVENTARIO_LAYOUT = {
  version: "1.0",
  name: "Movimientos de Inventario",
  description: "Listado tabular de movimientos de inventario con costos",
  pageSize: { width: 297, height: 210, unit: "mm" },
  margins: { top: 12, right: 12, bottom: 12, left: 12 },
  orientation: "landscape" as const,
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object" as const,
      endpoint: "/v1/inventario/movimientos",
      fields: [
        { name: "empresa", label: "Empresa", type: "string" },
        { name: "fechaDesde", label: "Fecha desde", type: "string" },
        { name: "fechaHasta", label: "Fecha hasta", type: "string" },
        { name: "totalMovimientos", label: "Total Movimientos", type: "number" },
      ],
    },
    {
      id: "movimientos",
      name: "Movimientos",
      type: "array" as const,
      endpoint: "/v1/inventario/movimientos",
      fields: [
        { name: "fecha", label: "Fecha", type: "string" },
        { name: "tipoMovimiento", label: "Tipo Mov.", type: "string" },
        { name: "codArticulo", label: "Cod. Articulo", type: "string" },
        { name: "nombreArticulo", label: "Nombre Articulo", type: "string" },
        { name: "almacen", label: "Almacen", type: "string" },
        { name: "cantidad", label: "Cantidad", type: "number" },
        { name: "costoUnitario", label: "Costo Unit.", type: "currency" },
        { name: "costoTotal", label: "Costo Total", type: "currency" },
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
          content: "MOVIMIENTOS DE INVENTARIO",
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
          id: "rh-rango-label",
          type: "text",
          content: "Periodo:",
          x: 180, y: 10, width: 16, height: 5,
          style: { fontSize: 8, fontWeight: "bold", color: "#555" },
        },
        {
          id: "rh-desde",
          type: "field",
          dataSource: "header",
          field: "fechaDesde",
          x: 197, y: 10, width: 30, height: 5,
          style: { fontSize: 8, color: "#555" },
        },
        {
          id: "rh-sep",
          type: "text",
          content: "\u2014",
          x: 228, y: 10, width: 6, height: 5,
          style: { fontSize: 8, textAlign: "center", color: "#555" },
        },
        {
          id: "rh-hasta",
          type: "field",
          dataSource: "header",
          field: "fechaHasta",
          x: 235, y: 10, width: 38, height: 5,
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
        { id: "ch-fecha", type: "text", content: "Fecha", x: 0, y: 1, width: 25, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-tipo", type: "text", content: "Tipo Mov.", x: 25, y: 1, width: 30, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-cod", type: "text", content: "Cod. Articulo", x: 55, y: 1, width: 28, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-nombre", type: "text", content: "Nombre Articulo", x: 83, y: 1, width: 65, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-almacen", type: "text", content: "Almacen", x: 148, y: 1, width: 35, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "ch-cantidad", type: "text", content: "Cantidad", x: 183, y: 1, width: 25, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-costo-unit", type: "text", content: "Costo Unit.", x: 208, y: 1, width: 30, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "ch-costo-total", type: "text", content: "Costo Total", x: 238, y: 1, width: 35, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
      ],
    },

    /* -- Detail (one row per movimiento) ------------------------------- */
    {
      id: "det",
      type: "detail",
      height: 6,
      dataSource: "movimientos",
      elements: [
        { id: "d-fecha", type: "field", dataSource: "movimientos", field: "fecha", x: 0, y: 0.5, width: 25, height: 5, style: { fontSize: 7 } },
        { id: "d-tipo", type: "field", dataSource: "movimientos", field: "tipoMovimiento", x: 25, y: 0.5, width: 30, height: 5, style: { fontSize: 7 } },
        { id: "d-cod", type: "field", dataSource: "movimientos", field: "codArticulo", x: 55, y: 0.5, width: 28, height: 5, style: { fontSize: 7 } },
        { id: "d-nombre", type: "field", dataSource: "movimientos", field: "nombreArticulo", x: 83, y: 0.5, width: 65, height: 5, style: { fontSize: 7 } },
        { id: "d-almacen", type: "field", dataSource: "movimientos", field: "almacen", x: 148, y: 0.5, width: 35, height: 5, style: { fontSize: 7 } },
        { id: "d-cantidad", type: "field", dataSource: "movimientos", field: "cantidad", x: 183, y: 0.5, width: 25, height: 5, format: "#,##0", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-costo-unit", type: "field", dataSource: "movimientos", field: "costoUnitario", x: 208, y: 0.5, width: 30, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
        { id: "d-costo-total", type: "field", dataSource: "movimientos", field: "costoTotal", x: 238, y: 0.5, width: 35, height: 5, format: "#,##0.00", style: { fontSize: 7, textAlign: "right" } },
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
          content: "Total movimientos:",
          x: 0, y: 4, width: 35, height: 5,
          style: { fontSize: 8, fontWeight: "bold" },
        },
        {
          id: "rf-count",
          type: "field",
          dataSource: "header",
          field: "totalMovimientos",
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

export const MOVIMIENTOS_INVENTARIO_LAYOUT_SAMPLE = {
  header: {
    empresa: "Zentto Soluciones Tecnologicas S.L.",
    fechaDesde: "01/01/2026",
    fechaHasta: "31/03/2026",
    totalMovimientos: 6,
  },
  movimientos: [
    { fecha: "05/01/2026", tipoMovimiento: "ENTRADA", codArticulo: "ART-001", nombreArticulo: "Laptop HP ProBook 450 G10", almacen: "Principal", cantidad: 10, costoUnitario: 4200.00, costoTotal: 42000.00 },
    { fecha: "12/01/2026", tipoMovimiento: "SALIDA", codArticulo: "ART-002", nombreArticulo: "Monitor Dell 27\" 4K", almacen: "Principal", cantidad: 3, costoUnitario: 1700.00, costoTotal: 5100.00 },
    { fecha: "20/02/2026", tipoMovimiento: "ENTRADA", codArticulo: "ART-005", nombreArticulo: "Disco SSD Samsung 1TB", almacen: "Deposito Sur", cantidad: 25, costoUnitario: 350.00, costoTotal: 8750.00 },
    { fecha: "05/03/2026", tipoMovimiento: "TRASLADO", codArticulo: "ART-003", nombreArticulo: "Teclado mecanico Logitech MX", almacen: "Sucursal Norte", cantidad: 12, costoUnitario: 420.00, costoTotal: 5040.00 },
    { fecha: "18/03/2026", tipoMovimiento: "SALIDA", codArticulo: "ART-001", nombreArticulo: "Laptop HP ProBook 450 G10", almacen: "Principal", cantidad: 5, costoUnitario: 4200.00, costoTotal: 21000.00 },
    { fecha: "25/03/2026", tipoMovimiento: "AJUSTE", codArticulo: "ART-004", nombreArticulo: "Cable HDMI 2.1 3m", almacen: "Principal", cantidad: -2, costoUnitario: 32.00, costoTotal: 64.00 },
  ],
};
