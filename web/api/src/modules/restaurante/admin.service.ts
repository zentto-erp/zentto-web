import { getPool, sql } from "../../db/mssql.js";
import { query } from "../../db/query.js";

const MOJIBAKE_PATTERN = /(Ã.|Â.|â.|�)/;

function repairMojibakeText(value: string): string {
    if (!value || !MOJIBAKE_PATTERN.test(value)) {
        return value;
    }

    try {
        const fixed = Buffer.from(value, "latin1").toString("utf8");
        if (!fixed || fixed.includes("�")) {
            return value;
        }
        return fixed;
    } catch {
        return value;
    }
}

function normalizeRowText<T extends Record<string, unknown>>(row: T): T {
    const normalized = { ...row };

    for (const key of Object.keys(normalized)) {
        const value = normalized[key];
        if (typeof value === "string") {
            normalized[key as keyof T] = repairMojibakeText(value) as T[keyof T];
        }
    }

    return normalized;
}

function normalizeRowsText<T extends Record<string, unknown>>(rows: T[]): T[] {
    return rows.map((row) => normalizeRowText(row));
}

// ═════════════════════════════════════════════════════
// AMBIENTES
// ═════════════════════════════════════════════════════

export async function listAmbientes() {
    try {
        const pool = await getPool();
        const result = await pool.request().execute("usp_REST_Ambientes_List");
        return { rows: normalizeRowsText(result.recordset ?? []), executionMode: "sp" as const };
    } catch { }
    const rows = await query<any>("SELECT Id AS id, Nombre AS nombre, Color AS color, Orden AS orden FROM RestauranteAmbientes WHERE Activo=1 ORDER BY Orden");
    return { rows: normalizeRowsText(rows), executionMode: "ts_fallback" as const };
}

export async function upsertAmbiente(data: { id?: number; nombre: string; color?: string; orden?: number }) {
    const pool = await getPool();
    const req = pool.request();
    req.input("Id", sql.Int, data.id ?? 0);
    req.input("Nombre", sql.NVarChar(50), data.nombre);
    req.input("Color", sql.NVarChar(10), data.color ?? "#4CAF50");
    req.input("Orden", sql.Int, data.orden ?? 0);
    req.output("ResultId", sql.Int);
    await req.execute("usp_REST_Ambiente_Upsert");
    return { ok: true, id: req.parameters.ResultId?.value as number };
}

// ═════════════════════════════════════════════════════
// CATEGORÍAS DEL MENÚ
// ═════════════════════════════════════════════════════

export async function listCategoriasMenu() {
    try {
        const pool = await getPool();
        const result = await pool.request().execute("usp_REST_Categorias_List");
        return { rows: normalizeRowsText(result.recordset ?? []), executionMode: "sp" as const };
    } catch { }
    const rows = await query<any>(
        "SELECT Id AS id, Nombre AS nombre, Color AS color, Orden AS orden FROM RestauranteCategorias WHERE Activa=1 ORDER BY Orden"
    );
    return { rows: normalizeRowsText(rows), executionMode: "ts_fallback" as const };
}

export async function upsertCategoriaMenu(data: { id?: number; nombre: string; descripcion?: string; color?: string; orden?: number }) {
    const pool = await getPool();
    const req = pool.request();
    req.input("Id", sql.Int, data.id ?? 0);
    req.input("Nombre", sql.NVarChar(50), data.nombre);
    req.input("Descripcion", sql.NVarChar(200), data.descripcion ?? null);
    req.input("Color", sql.NVarChar(10), data.color ?? null);
    req.input("Orden", sql.Int, data.orden ?? 0);
    req.output("ResultId", sql.Int);
    await req.execute("usp_REST_Categoria_Upsert");
    return { ok: true, id: req.parameters.ResultId?.value as number };
}

// ═════════════════════════════════════════════════════
// PRODUCTOS DEL MENÚ
// ═════════════════════════════════════════════════════

export async function listProductosMenu(params: { categoriaId?: number; search?: string; soloDisponibles?: boolean }) {
    try {
        const pool = await getPool();
        const req = pool.request();
        req.input("CategoriaId", sql.Int, params.categoriaId ?? null);
        req.input("Search", sql.NVarChar(100), params.search ?? null);
        req.input("SoloDisponibles", sql.Bit, params.soloDisponibles ?? true);
        const result = await req.execute("usp_REST_Productos_List");
        return { rows: normalizeRowsText(result.recordset ?? []), executionMode: "sp" as const };
    } catch { }
    const rows = await query<any>(
        "SELECT Id AS id, Codigo AS codigo, Nombre AS nombre, Precio AS precio, CategoriaId AS categoriaId, EsCompuesto AS esCompuesto, Disponible AS disponible FROM RestauranteProductos WHERE Activo=1 ORDER BY Nombre"
    );
    return { rows: normalizeRowsText(rows), executionMode: "ts_fallback" as const };
}

export async function getProductoMenu(id: number) {
    try {
        const pool = await getPool();
        const req = pool.request();
        req.input("Id", sql.Int, id);
        const result = await req.execute("usp_REST_Producto_Get");
        const sets = result.recordsets as any[][];
        const producto = sets?.[0]?.[0] ? normalizeRowText(sets[0][0]) : null;
        const componentesRaw = normalizeRowsText(sets?.[1] ?? []);
        const receta = normalizeRowsText(sets?.[2] ?? []);

        // Agrupar componentes con sus opciones
        const componentesMap: Record<number, any> = {};
        for (const row of componentesRaw) {
            if (!componentesMap[row.id]) {
                componentesMap[row.id] = {
                    id: row.id,
                    nombre: row.nombre,
                    obligatorio: row.obligatorio,
                    orden: row.orden,
                    opciones: [],
                };
            }
            if (row.opcionId) {
                componentesMap[row.id].opciones.push({
                    id: row.opcionId,
                    nombre: row.opcionNombre,
                    precioExtra: row.precioExtra,
                    orden: row.opcionOrden,
                });
            }
        }

        return {
            producto,
            componentes: Object.values(componentesMap),
            receta,
            executionMode: "sp" as const,
        };
    } catch (e: any) {
        return { producto: null, componentes: [], receta: [], error: e.message, executionMode: "sp" as const };
    }
}

export async function upsertProductoMenu(data: {
    id?: number; codigo: string; nombre: string; descripcion?: string;
    categoriaId?: number; precio?: number; costoEstimado?: number;
    iva?: number; esCompuesto?: boolean; tiempoPreparacion?: number;
    imagen?: string; esSugerenciaDelDia?: boolean; disponible?: boolean;
    articuloInventarioId?: string;
}) {
    const pool = await getPool();
    const req = pool.request();
    req.input("Id", sql.Int, data.id ?? 0);
    req.input("Codigo", sql.NVarChar(20), data.codigo);
    req.input("Nombre", sql.NVarChar(200), data.nombre);
    req.input("Descripcion", sql.NVarChar(500), data.descripcion ?? null);
    req.input("CategoriaId", sql.Int, data.categoriaId ?? null);
    req.input("Precio", sql.Decimal(18, 2), data.precio ?? 0);
    req.input("CostoEstimado", sql.Decimal(18, 2), data.costoEstimado ?? 0);
    req.input("IVA", sql.Decimal(5, 2), data.iva ?? 16);
    req.input("EsCompuesto", sql.Bit, data.esCompuesto ?? false);
    req.input("TiempoPreparacion", sql.Int, data.tiempoPreparacion ?? 0);
    req.input("Imagen", sql.NVarChar(500), data.imagen ?? null);
    req.input("EsSugerenciaDelDia", sql.Bit, data.esSugerenciaDelDia ?? false);
    req.input("Disponible", sql.Bit, data.disponible ?? true);
    req.input("ArticuloInventarioId", sql.NVarChar(15), data.articuloInventarioId ?? null);
    req.output("ResultId", sql.Int);
    await req.execute("usp_REST_Producto_Upsert");
    return { ok: true, id: req.parameters.ResultId?.value as number };
}

export async function deleteProductoMenu(id: number) {
    const pool = await getPool();
    const req = pool.request();
    req.input("Id", sql.Int, id);
    await req.execute("usp_REST_Producto_Delete");
    return { ok: true };
}

// ═════════════════════════════════════════════════════
// COMPONENTES Y OPCIONES
// ═════════════════════════════════════════════════════

export async function upsertComponente(data: { id?: number; productoId: number; nombre: string; obligatorio?: boolean; orden?: number }) {
    const pool = await getPool();
    const req = pool.request();
    req.input("Id", sql.Int, data.id ?? 0);
    req.input("ProductoId", sql.Int, data.productoId);
    req.input("Nombre", sql.NVarChar(100), data.nombre);
    req.input("Obligatorio", sql.Bit, data.obligatorio ?? false);
    req.input("Orden", sql.Int, data.orden ?? 0);
    req.output("ResultId", sql.Int);
    await req.execute("usp_REST_Componente_Upsert");
    return { ok: true, id: req.parameters.ResultId?.value as number };
}

export async function upsertOpcion(data: { id?: number; componenteId: number; nombre: string; precioExtra?: number; orden?: number }) {
    const pool = await getPool();
    const req = pool.request();
    req.input("Id", sql.Int, data.id ?? 0);
    req.input("ComponenteId", sql.Int, data.componenteId);
    req.input("Nombre", sql.NVarChar(100), data.nombre);
    req.input("PrecioExtra", sql.Decimal(18, 2), data.precioExtra ?? 0);
    req.input("Orden", sql.Int, data.orden ?? 0);
    req.output("ResultId", sql.Int);
    await req.execute("usp_REST_Opcion_Upsert");
    return { ok: true, id: req.parameters.ResultId?.value as number };
}

// ═════════════════════════════════════════════════════
// RECETAS (ingredientes del inventario)
// ═════════════════════════════════════════════════════

export async function upsertRecetaItem(data: { id?: number; productoId: number; inventarioId: string; cantidad: number; unidad?: string; comentario?: string }) {
    const pool = await getPool();
    const req = pool.request();
    req.input("Id", sql.Int, data.id ?? 0);
    req.input("ProductoId", sql.Int, data.productoId);
    req.input("InventarioId", sql.NVarChar(15), data.inventarioId);
    req.input("Cantidad", sql.Decimal(10, 3), data.cantidad);
    req.input("Unidad", sql.NVarChar(20), data.unidad ?? null);
    req.input("Comentario", sql.NVarChar(200), data.comentario ?? null);
    req.output("ResultId", sql.Int);
    await req.execute("usp_REST_Receta_Upsert");
    return { ok: true, id: req.parameters.ResultId?.value as number };
}

export async function deleteRecetaItem(id: number) {
    await query("DELETE FROM RestauranteRecetas WHERE Id = @id", { id });
    return { ok: true };
}

// ═════════════════════════════════════════════════════
// COMPRAS RESTAURANTE
// ═════════════════════════════════════════════════════

export async function listCompras(params: { estado?: string; from?: string; to?: string }) {
    try {
        const pool = await getPool();
        const req = pool.request();
        req.input("Estado", sql.NVarChar(20), params.estado ?? null);
        req.input("From", sql.DateTime, params.from ? new Date(params.from) : null);
        req.input("To", sql.DateTime, params.to ? new Date(params.to) : null);
        const result = await req.execute("usp_REST_Compras_List");
        return { rows: normalizeRowsText(result.recordset ?? []), executionMode: "sp" as const };
    } catch { }
    const rows = await query<any>(
        "SELECT Id AS id, NumCompra AS numCompra, ProveedorId AS proveedorId, FechaCompra AS fechaCompra, Estado AS estado, Total AS total FROM RestauranteCompras ORDER BY FechaCompra DESC"
    );
    return { rows: normalizeRowsText(rows), executionMode: "ts_fallback" as const };
}

export async function getCompraDetalle(compraId: number) {
    const header = normalizeRowsText(await query<any>("SELECT * FROM RestauranteCompras WHERE Id = @compraId", { compraId }));
    const detalle = normalizeRowsText(await query<any>("SELECT * FROM RestauranteComprasDetalle WHERE CompraId = @compraId", { compraId }));
    return { compra: header[0] ?? null, detalle };
}

export async function crearCompra(data: {
    proveedorId?: string; observaciones?: string; codUsuario?: string;
    detalle: Array<{ descripcion: string; cantidad: number; precioUnit: number; iva?: number; inventarioId?: string }>;
}) {
    // Construir XML para el SP
    const xmlItems = data.detalle.map(d =>
        `<item desc="${escXml(d.descripcion)}" cant="${d.cantidad}" precio="${d.precioUnit}" iva="${d.iva ?? 16}" invId="${d.inventarioId ?? ''}" />`
    ).join("");
    const xmlStr = `<items>${xmlItems}</items>`;

    const pool = await getPool();
    const req = pool.request();
    req.input("ProveedorId", sql.NVarChar(12), data.proveedorId ?? null);
    req.input("Observaciones", sql.NVarChar(500), data.observaciones ?? null);
    req.input("CodUsuario", sql.NVarChar(10), data.codUsuario ?? null);
    req.input("DetalleXml", sql.Xml, xmlStr);
    req.output("CompraId", sql.Int);
    await req.execute("usp_REST_Compra_Crear");
    const compraId = req.parameters.CompraId?.value as number;
    return { ok: true, compraId };
}

function escXml(v: unknown): string {
    if (v === null || v === undefined) return "";
    return String(v).replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/'/g, "&apos;");
}

// ═════════════════════════════════════════════════════
// PROVEEDORES — Usa la tabla Proveedores compartida
// ═════════════════════════════════════════════════════

export async function searchProveedores(search?: string, limit = 20) {
    const where = search ? "WHERE CODIGO LIKE @search OR NOMBRE LIKE @search OR RIF LIKE @search" : "";
    const rows = await query<any>(
        `SELECT TOP ${limit} CODIGO AS id, CODIGO AS codigo, NOMBRE AS nombre, RIF AS rif, TELEFONO AS telefono, DIRECCION AS direccion FROM Proveedores ${where} ORDER BY NOMBRE`,
        search ? { search: `%${search}%` } : {}
    );
    return { rows: normalizeRowsText(rows) };
}
