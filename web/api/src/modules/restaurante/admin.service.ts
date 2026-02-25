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
        `
        SELECT
            c.Id AS id,
            c.NumCompra AS numCompra,
            c.ProveedorId AS proveedorId,
            p.NOMBRE AS proveedorNombre,
            c.FechaCompra AS fechaCompra,
            c.Estado AS estado,
            c.Total AS total
        FROM RestauranteCompras c
        LEFT JOIN Proveedores p ON p.CODIGO = c.ProveedorId
        ORDER BY c.FechaCompra DESC
        `
    );
    return { rows: normalizeRowsText(rows), executionMode: "ts_fallback" as const };
}

export async function getCompraDetalle(compraId: number) {
    const header = normalizeRowsText(await query<any>(
        `
        SELECT
            c.Id AS id,
            c.NumCompra AS numCompra,
            c.ProveedorId AS proveedorId,
            p.NOMBRE AS proveedorNombre,
            c.FechaCompra AS fechaCompra,
            c.Estado AS estado,
            c.Subtotal AS subtotal,
            c.IVA AS iva,
            c.Total AS total,
            c.Observaciones AS observaciones,
            c.CodUsuario AS codUsuario
        FROM RestauranteCompras c
        LEFT JOIN Proveedores p ON p.CODIGO = c.ProveedorId
        WHERE c.Id = @compraId
        `,
        { compraId }
    ));

    const detalle = normalizeRowsText(await query<any>(
        `
        SELECT
            d.Id AS id,
            d.CompraId AS compraId,
            d.InventarioId AS inventarioId,
            COALESCE(NULLIF(LTRIM(RTRIM(d.Descripcion)), ''), i.DESCRIPCION, p.Nombre) AS descripcion,
            d.Cantidad AS cantidad,
            d.PrecioUnit AS precioUnit,
            d.Subtotal AS subtotal,
            d.IVA AS iva
        FROM RestauranteComprasDetalle d
        LEFT JOIN Inventario i ON i.CODIGO = d.InventarioId
        LEFT JOIN RestauranteProductos p ON p.ArticuloInventarioId = d.InventarioId OR p.Codigo = d.InventarioId
        WHERE d.CompraId = @compraId
        ORDER BY d.Id
        `,
        { compraId }
    ));
    return { compra: header[0] ?? null, detalle };
}

async function recalcCompraTotales(compraId: number) {
    await query(
        `
        UPDATE RestauranteCompras
        SET
            Subtotal = (SELECT ISNULL(SUM(Subtotal), 0) FROM RestauranteComprasDetalle WHERE CompraId = @compraId),
            IVA = (SELECT ISNULL(SUM(Subtotal * IVA / 100), 0) FROM RestauranteComprasDetalle WHERE CompraId = @compraId),
            Total = (SELECT ISNULL(SUM(Subtotal + Subtotal * IVA / 100), 0) FROM RestauranteComprasDetalle WHERE CompraId = @compraId)
        WHERE Id = @compraId
        `,
        { compraId }
    );
}

async function syncProductoDesdeDetalle(inventarioId: string | undefined, descripcion: string) {
    const codigo = String(inventarioId ?? '').trim();
    const nombre = String(descripcion ?? '').trim();
    if (!codigo || !nombre) return;

    await query(
        `
        UPDATE RestauranteProductos
        SET
            Nombre = @nombre,
            Descripcion = @nombre
        WHERE (Codigo = @codigo OR ArticuloInventarioId = @codigo)
        `,
        { codigo, nombre }
    );
}

async function adjustInventarioExistencia(inventarioId: string | undefined, deltaCantidad: number) {
    const codigo = String(inventarioId ?? '').trim();
    if (!codigo || !Number.isFinite(deltaCantidad) || deltaCantidad === 0) return;

    await query(
        `
        UPDATE Inventario
        SET EXISTENCIA = COALESCE(TRY_CAST(EXISTENCIA AS DECIMAL(18,3)), 0) + @deltaCantidad
        WHERE CODIGO = @codigo
        `,
        {
            codigo,
            deltaCantidad,
        }
    );
}

export async function upsertCompraDetalle(data: {
    id?: number;
    compraId: number;
    inventarioId?: string;
    descripcion: string;
    cantidad: number;
    precioUnit: number;
    iva?: number;
}) {
    const iva = Number(data.iva ?? 16);
    const subtotal = Number(data.cantidad) * Number(data.precioUnit);

    if (data.id && data.id > 0) {
        const prevRows = await query<any>(
            `
            SELECT InventarioId, Cantidad
            FROM RestauranteComprasDetalle
            WHERE Id = @id AND CompraId = @compraId
            `,
            { id: data.id, compraId: data.compraId }
        );
        const prev = prevRows[0] ?? null;
        const prevInventarioId = String(prev?.InventarioId ?? '').trim() || undefined;
        const prevCantidad = Number(prev?.Cantidad ?? 0);

        await query(
            `
            UPDATE RestauranteComprasDetalle
            SET
                InventarioId = @inventarioId,
                Descripcion = @descripcion,
                Cantidad = @cantidad,
                PrecioUnit = @precioUnit,
                Subtotal = @subtotal,
                IVA = @iva
            WHERE Id = @id AND CompraId = @compraId
            `,
            {
                id: data.id,
                compraId: data.compraId,
                inventarioId: data.inventarioId ?? null,
                descripcion: data.descripcion,
                cantidad: data.cantidad,
                precioUnit: data.precioUnit,
                subtotal,
                iva,
            }
        );

        await syncProductoDesdeDetalle(data.inventarioId, data.descripcion);

        const newInventarioId = String(data.inventarioId ?? '').trim() || undefined;
        const newCantidad = Number(data.cantidad ?? 0);

        if (prevInventarioId && newInventarioId && prevInventarioId === newInventarioId) {
            const delta = newCantidad - prevCantidad;
            await adjustInventarioExistencia(newInventarioId, delta);
        } else {
            if (prevInventarioId && prevCantidad > 0) {
                await adjustInventarioExistencia(prevInventarioId, -prevCantidad);
            }
            if (newInventarioId && newCantidad > 0) {
                await adjustInventarioExistencia(newInventarioId, newCantidad);
            }
        }

        await recalcCompraTotales(data.compraId);
        return { ok: true, id: data.id, compraId: data.compraId };
    }

    const inserted = await query<any>(
        `
        INSERT INTO RestauranteComprasDetalle (CompraId, InventarioId, Descripcion, Cantidad, PrecioUnit, Subtotal, IVA)
        OUTPUT INSERTED.Id AS id
        VALUES (@compraId, @inventarioId, @descripcion, @cantidad, @precioUnit, @subtotal, @iva)
        `,
        {
            compraId: data.compraId,
            inventarioId: data.inventarioId ?? null,
            descripcion: data.descripcion,
            cantidad: data.cantidad,
            precioUnit: data.precioUnit,
            subtotal,
            iva,
        }
    );

    await syncProductoDesdeDetalle(data.inventarioId, data.descripcion);
    await adjustInventarioExistencia(data.inventarioId, Number(data.cantidad ?? 0));

    await recalcCompraTotales(data.compraId);
    return { ok: true, id: Number(inserted?.[0]?.id ?? 0), compraId: data.compraId };
}

export async function deleteCompraDetalle(compraId: number, detalleId: number) {
    const prevRows = await query<any>(
        `
        SELECT InventarioId, Cantidad
        FROM RestauranteComprasDetalle
        WHERE Id = @detalleId AND CompraId = @compraId
        `,
        { compraId, detalleId }
    );
    const prev = prevRows[0] ?? null;

    await query(
        `
        DELETE FROM RestauranteComprasDetalle
        WHERE Id = @detalleId AND CompraId = @compraId
        `,
        { compraId, detalleId }
    );

    await adjustInventarioExistencia(
        String(prev?.InventarioId ?? '').trim() || undefined,
        -Number(prev?.Cantidad ?? 0)
    );

    await recalcCompraTotales(compraId);
    return { ok: true, compraId, detalleId };
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
    const tx = new sql.Transaction(pool);

    try {
        await tx.begin();

        const reqSet = new sql.Request(tx);
        await reqSet.batch(`
            SET QUOTED_IDENTIFIER ON;
            SET ANSI_NULLS ON;
            SET ANSI_PADDING ON;
            SET ANSI_WARNINGS ON;
            SET ARITHABORT ON;
            SET CONCAT_NULL_YIELDS_NULL ON;
            SET NUMERIC_ROUNDABORT OFF;
        `);

        const req = new sql.Request(tx);
        req.input("ProveedorId", sql.NVarChar(12), data.proveedorId ?? null);
        req.input("Observaciones", sql.NVarChar(500), data.observaciones ?? null);
        req.input("CodUsuario", sql.NVarChar(10), data.codUsuario ?? null);
        req.input("DetalleXml", sql.Xml, xmlStr);
        req.output("CompraId", sql.Int);
        await req.execute("usp_REST_Compra_Crear");

        for (const item of data.detalle) {
            const codigo = String(item.inventarioId ?? '').trim();
            const cantidad = Number(item.cantidad ?? 0);
            if (!codigo || !Number.isFinite(cantidad) || cantidad === 0) continue;

            const reqInv = new sql.Request(tx);
            reqInv.input('Codigo', sql.NVarChar(15), codigo);
            reqInv.input('Delta', sql.Decimal(18, 3), cantidad);
            await reqInv.query(`
                UPDATE Inventario
                SET EXISTENCIA = COALESCE(TRY_CAST(EXISTENCIA AS DECIMAL(18,3)), 0) + @Delta
                WHERE CODIGO = @Codigo
            `);
        }

        await tx.commit();
        const compraId = req.parameters.CompraId?.value as number;
        return { ok: true, compraId };
    } catch (error: any) {
        try {
            await tx.rollback();
        } catch {
        }

        const errorMsg = String(error?.message ?? error ?? '').toUpperCase();
        const isQuotedIdentifierError = errorMsg.includes('QUOTED_IDENTIFIER');
        if (!isQuotedIdentifierError) {
            throw error;
        }

        const txFallback = new sql.Transaction(pool);
        await txFallback.begin();
        try {
            const reqSeq = new sql.Request(txFallback);
            const seqResult = await reqSeq.query(`SELECT ISNULL(MAX(Id), 0) + 1 AS Seq FROM RestauranteCompras`);
            const seq = Number(seqResult.recordset?.[0]?.Seq ?? 1);

            const now = new Date();
            const y = now.getFullYear();
            const m = String(now.getMonth() + 1).padStart(2, '0');
            const numCompra = `RC-${y}${m}-${String(seq).padStart(4, '0')}`;

            const reqHeader = new sql.Request(txFallback);
            reqHeader.input('NumCompra', sql.NVarChar(20), numCompra);
            reqHeader.input('ProveedorId', sql.NVarChar(12), data.proveedorId ?? null);
            reqHeader.input('Estado', sql.NVarChar(20), 'pendiente');
            reqHeader.input('Observaciones', sql.NVarChar(500), data.observaciones ?? null);
            reqHeader.input('CodUsuario', sql.NVarChar(10), data.codUsuario ?? null);
            const headerResult = await reqHeader.query(`
                INSERT INTO RestauranteCompras (NumCompra, ProveedorId, Estado, Observaciones, CodUsuario)
                OUTPUT INSERTED.Id AS CompraId
                VALUES (@NumCompra, @ProveedorId, @Estado, @Observaciones, @CodUsuario)
            `);

            const compraId = Number(headerResult.recordset?.[0]?.CompraId ?? 0);
            if (!compraId) {
                throw new Error('No se pudo crear la cabecera de compra.');
            }

            for (const item of data.detalle) {
                const cantidad = Number(item.cantidad ?? 0);
                const precio = Number(item.precioUnit ?? 0);
                const iva = Number(item.iva ?? 16);
                const subtotal = cantidad * precio;

                const reqDet = new sql.Request(txFallback);
                reqDet.input('CompraId', sql.Int, compraId);
                reqDet.input('InventarioId', sql.NVarChar(15), item.inventarioId ?? null);
                reqDet.input('Descripcion', sql.NVarChar(200), item.descripcion);
                reqDet.input('Cantidad', sql.Decimal(10, 3), cantidad);
                reqDet.input('PrecioUnit', sql.Decimal(18, 2), precio);
                reqDet.input('Subtotal', sql.Decimal(18, 2), subtotal);
                reqDet.input('IVA', sql.Decimal(5, 2), iva);
                await reqDet.query(`
                    INSERT INTO RestauranteComprasDetalle (CompraId, InventarioId, Descripcion, Cantidad, PrecioUnit, Subtotal, IVA)
                    VALUES (@CompraId, @InventarioId, @Descripcion, @Cantidad, @PrecioUnit, @Subtotal, @IVA)
                `);

                const codigoInv = String(item.inventarioId ?? '').trim();
                if (codigoInv && Number.isFinite(cantidad) && cantidad !== 0) {
                    const reqInv = new sql.Request(txFallback);
                    reqInv.input('Codigo', sql.NVarChar(15), codigoInv);
                    reqInv.input('Delta', sql.Decimal(18, 3), cantidad);
                    await reqInv.query(`
                        UPDATE Inventario
                        SET EXISTENCIA = COALESCE(TRY_CAST(EXISTENCIA AS DECIMAL(18,3)), 0) + @Delta
                        WHERE CODIGO = @Codigo
                    `);
                }
            }

            const reqTotals = new sql.Request(txFallback);
            reqTotals.input('CompraId', sql.Int, compraId);
            await reqTotals.query(`
                UPDATE RestauranteCompras
                SET
                    Subtotal = (SELECT ISNULL(SUM(Subtotal), 0) FROM RestauranteComprasDetalle WHERE CompraId = @CompraId),
                    IVA = (SELECT ISNULL(SUM(Subtotal * IVA / 100), 0) FROM RestauranteComprasDetalle WHERE CompraId = @CompraId),
                    Total = (SELECT ISNULL(SUM(Subtotal + Subtotal * IVA / 100), 0) FROM RestauranteComprasDetalle WHERE CompraId = @CompraId)
                WHERE Id = @CompraId
            `);

            await txFallback.commit();
            return { ok: true, compraId, executionMode: 'ts_fallback' as const };
        } catch (fallbackError) {
            try {
                await txFallback.rollback();
            } catch {
            }
            throw fallbackError;
        }
    }
}

export async function updateCompra(
    compraId: number,
    data: { proveedorId?: string; estado?: string; observaciones?: string }
) {
    await query(
        `
        UPDATE RestauranteCompras
        SET
            ProveedorId = COALESCE(@proveedorId, ProveedorId),
            Estado = COALESCE(@estado, Estado),
            Observaciones = COALESCE(@observaciones, Observaciones)
        WHERE Id = @compraId
        `,
        {
            compraId,
            proveedorId: data.proveedorId ?? null,
            estado: data.estado ?? null,
            observaciones: data.observaciones ?? null,
        }
    );

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

// ═════════════════════════════════════════════════════
// INSUMOS RESTAURANTE (catálogo para recetas)
// ═════════════════════════════════════════════════════

export async function searchInsumosRestaurante(search?: string, limit = 30) {
    const safeLimit = Number.isFinite(limit) ? Math.max(1, Math.min(100, Number(limit))) : 30;

    // Solo insumos con movimiento en compras en los últimos 90 días (JOIN con cabecera para FechaCompra)
    const whereCompras = [
        "WHERE c.FechaCompra >= DATEADD(DAY, -90, GETDATE())",
        search ? "AND (d.InventarioId LIKE @search OR d.Descripcion LIKE @search)" : ""
    ].join(" ");

    const fromCompras = await query<any>(
        `
        SELECT TOP ${safeLimit}
            d.InventarioId AS codigo,
            MAX(LTRIM(RTRIM(ISNULL(d.Descripcion, '')))) AS descripcion,
            CAST(NULL AS NVARCHAR(20)) AS unidad,
            CAST(NULL AS DECIMAL(18,3)) AS existencia,
            CAST(1 AS INT) AS prioridad
        FROM RestauranteComprasDetalle d
        JOIN RestauranteCompras c ON c.Id = d.CompraId
        ${whereCompras}
        GROUP BY d.InventarioId
        ORDER BY codigo
        `,
        search ? { search: `%${search}%` } : {}
    );

    const whereProductos = search
        ? "WHERE p.Activo = 1 AND p.ArticuloInventarioId IS NOT NULL AND (p.ArticuloInventarioId LIKE @search OR p.Nombre LIKE @search)"
        : "WHERE p.Activo = 1 AND p.ArticuloInventarioId IS NOT NULL";


    // Incluye productos/platos activos como insumos (para combos)
    const fromProductos = await query<any>(
        `
        SELECT TOP ${safeLimit}
            p.Codigo AS codigo,
            LTRIM(RTRIM(ISNULL(p.Nombre, ''))) AS descripcion,
            '' AS unidad,
            NULL AS existencia,
            CAST(3 AS INT) AS prioridad
        FROM RestauranteProductos p
        WHERE p.Activo = 1
        ${search ? 'AND (p.Codigo LIKE @search OR p.Nombre LIKE @search)' : ''}
        ORDER BY p.Codigo
        `,
        search ? { search: `%${search}%` } : {}
    );

    // También incluye productos vinculados a inventario (como antes)
    const fromProductosInventario = await query<any>(
        `
        SELECT TOP ${safeLimit}
            p.ArticuloInventarioId AS codigo,
            LTRIM(RTRIM(ISNULL(i.DESCRIPCION, p.Nombre))) AS descripcion,
            LTRIM(RTRIM(ISNULL(i.Unidad, ''))) AS unidad,
            TRY_CAST(i.EXISTENCIA AS DECIMAL(18,3)) AS existencia,
            CAST(2 AS INT) AS prioridad
        FROM RestauranteProductos p
        LEFT JOIN Inventario i ON i.CODIGO = p.ArticuloInventarioId
        ${whereProductos}
        ORDER BY codigo
        `,
        search ? { search: `%${search}%` } : {}
    );

    const merged = [...fromCompras, ...fromProductosInventario, ...fromProductos]
        .map((row) => ({
            codigo: String(row.codigo ?? '').trim(),
            descripcion: String(row.descripcion ?? '').trim(),
            unidad: String(row.unidad ?? '').trim() || undefined,
            existencia: row.existencia == null ? undefined : Number(row.existencia),
            prioridad: Number(row.prioridad ?? 9),
        }))
        .filter((row) => row.codigo.length > 0);

    const dedup = new Map<string, { codigo: string; descripcion: string; unidad?: string; existencia?: number; prioridad: number }>();
    for (const row of merged) {
        const prev = dedup.get(row.codigo);
        if (!prev || row.prioridad < prev.prioridad) {
            dedup.set(row.codigo, row);
        }
    }

    const rows = Array.from(dedup.values())
        .sort((a, b) => a.codigo.localeCompare(b.codigo))
        .slice(0, safeLimit)
        .map(({ prioridad, ...rest }) => rest);

    return { rows: normalizeRowsText(rows as any[]) };
}
