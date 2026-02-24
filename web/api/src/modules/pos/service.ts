import { getPool, sql } from "../../db/mssql.js";
import { query } from "../../db/query.js";

// ─── Productos POS ───

export async function listProductosPOS(params: {
    search?: string;
    categoria?: string;
    page?: number;
    limit?: number;
}) {
    const page = Math.max(params.page ?? 1, 1);
    const limit = Math.min(Math.max(params.limit ?? 50, 1), 200);

    try {
        const pool = await getPool();
        const req = pool.request();
        req.input("Search", sql.NVarChar(100), params.search ?? null);
        req.input("Categoria", sql.NVarChar(50), params.categoria ?? null);
        req.input("AlmacenId", sql.NVarChar(10), null);
        req.input("Page", sql.Int, page);
        req.input("Limit", sql.Int, limit);
        req.output("TotalCount", sql.Int);

        const result = await req.execute("usp_POS_Productos_List");
        const total = (req.parameters.TotalCount?.value as number) ?? 0;
        return { page, limit, total, rows: result.recordset ?? [], executionMode: "sp" as const };
    } catch {
        // fallback
    }

    // Fallback directo
    const offset = (page - 1) * limit;
    const where: string[] = ["(EXISTENCIA > 0 OR Servicio = 1)"];
    const sqlParams: Record<string, unknown> = {};

    if (params.search) {
        where.push("(CODIGO LIKE @search OR DESCRIPCION LIKE @search OR Barra LIKE @search)");
        sqlParams.search = `%${params.search}%`;
    }
    if (params.categoria) {
        where.push("Categoria = @categoria");
        sqlParams.categoria = params.categoria;
    }

    const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
    const rows = await query<any>(
        `SELECT CODIGO AS id, CODIGO AS codigo, DESCRIPCION AS nombre, PRECIO_VENTA AS precioDetal,
     EXISTENCIA AS existencia, Categoria AS categoria, ISNULL(PORCENTAJE, 16) AS iva
     FROM Inventario ${clause}
     ORDER BY CODIGO OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`,
        sqlParams
    );
    const totalResult = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM Inventario ${clause}`, sqlParams);
    return { page, limit, total: Number(totalResult[0]?.total ?? 0), rows, executionMode: "ts_fallback" as const };
}

export async function getProductoByCodigo(codigo: string) {
    try {
        const pool = await getPool();
        const req = pool.request();
        req.input("Codigo", sql.NVarChar(20), codigo);
        const result = await req.execute("usp_POS_Producto_GetByCodigo");
        return { row: result.recordset?.[0] ?? null, executionMode: "sp" as const };
    } catch { }

    const rows = await query<any>(
        "SELECT TOP 1 CODIGO AS id, CODIGO AS codigo, DESCRIPCION AS nombre, PRECIO_VENTA AS precioDetal, EXISTENCIA AS existencia FROM Inventario WHERE CODIGO = @codigo OR Barra = @codigo",
        { codigo }
    );
    return { row: rows[0] ?? null, executionMode: "ts_fallback" as const };
}

// ─── Clientes POS ───

export async function searchClientesPOS(search?: string, limit = 20) {
    try {
        const pool = await getPool();
        const req = pool.request();
        req.input("Search", sql.NVarChar(100), search ?? null);
        req.input("Limit", sql.Int, limit);
        const result = await req.execute("usp_POS_Clientes_Search");
        return { rows: result.recordset ?? [], executionMode: "sp" as const };
    } catch { }

    const where = search
        ? "WHERE CODIGO LIKE @search OR NOMBRE LIKE @search OR RIF LIKE @search"
        : "";
    const rows = await query<any>(
        `SELECT TOP ${limit} CODIGO AS id, CODIGO AS codigo, NOMBRE AS nombre, RIF AS rif, TELEFONO AS telefono, EMAIL AS email, DIRECCION AS direccion, 'Detal' AS tipoPrecio, 0 AS credito FROM Clientes ${where} ORDER BY NOMBRE`,
        search ? { search: `%${search}%` } : {}
    );
    return { rows, executionMode: "ts_fallback" as const };
}

// ─── Categorías POS ───

export async function listCategoriasPOS() {
    try {
        const pool = await getPool();
        const req = pool.request();
        const result = await req.execute("usp_POS_Categorias_List");
        return { rows: result.recordset ?? [], executionMode: "sp" as const };
    } catch { }

    const rows = await query<any>(
        "SELECT RTRIM(ISNULL(Categoria, '(Sin Categoría)')) AS id, RTRIM(ISNULL(Categoria, '(Sin Categoría)')) AS nombre, COUNT(1) AS productCount FROM Inventario WHERE EXISTENCIA > 0 OR Servicio = 1 GROUP BY Categoria ORDER BY Categoria"
    );
    return { rows, executionMode: "ts_fallback" as const };
}

// ─── Reportes POS ───

function normalizeRange(from?: string, to?: string) {
    const today = new Date();
    const todayIso = today.toISOString().slice(0, 10);
    const fromDate = from && from.trim().length > 0 ? from : todayIso;
    const toDate = to && to.trim().length > 0 ? to : todayIso;
    return { fromDate, toDate };
}

async function hasPosSalesTables() {
    const rows = await query<{ ok: number }>(
        "SELECT CASE WHEN OBJECT_ID('dbo.PosVentas', 'U') IS NOT NULL AND OBJECT_ID('dbo.PosVentasDetalle', 'U') IS NOT NULL THEN 1 ELSE 0 END AS ok"
    );
    return Number(rows[0]?.ok ?? 0) === 1;
}

async function hasCorrelativoTable() {
    const rows = await query<{ ok: number }>(
        "SELECT CASE WHEN OBJECT_ID('dbo.Correlativo', 'U') IS NOT NULL THEN 1 ELSE 0 END AS ok"
    );
    return Number(rows[0]?.ok ?? 0) === 1;
}

function inferSerialFromTrama(raw: unknown): string | null {
    if (!raw) return null;
    const trama = String(raw);
    const patterns = [
        /serial\s*[:=]\s*([A-Z0-9\-]+)/i,
        /registeredmachinenumber\s*[:=]\s*([A-Z0-9\-]+)/i,
        /fiscal\s*serial\s*[:=]\s*([A-Z0-9\-]+)/i,
    ];
    for (const pattern of patterns) {
        const match = trama.match(pattern);
        if (match?.[1]) return match[1].trim();
    }
    return null;
}

function correlativoTipoPorCaja(cajaId: string) {
    return `FACTURA|CAJA:${cajaId.trim().toUpperCase()}`;
}

export async function listCorrelativosFiscales(params: { cajaId?: string }) {
    if (!(await hasCorrelativoTable())) {
        return { rows: [], executionMode: "ts_fallback" as const };
    }

    const rows = await query<any>(
        `
        SELECT
            Tipo AS tipo,
            CASE
                WHEN Tipo LIKE 'FACTURA|CAJA:%' THEN SUBSTRING(Tipo, LEN('FACTURA|CAJA:') + 1, 50)
                ELSE NULL
            END AS cajaId,
            Serie AS serialFiscal,
            Valor AS correlativoActual,
            Descripcion AS descripcion
        FROM Correlativo
        WHERE Tipo = 'FACTURA'
           OR Tipo LIKE 'FACTURA|CAJA:%'
           OR Tipo = 'CONTROL'
           OR Tipo LIKE 'CONTROL%'
        ORDER BY CASE WHEN Tipo = 'FACTURA' THEN 1 WHEN Tipo LIKE 'FACTURA|CAJA:%' THEN 2 ELSE 3 END, Tipo
        `
    );

    if (!params.cajaId) {
        return { rows, executionMode: "ts_fallback" as const };
    }

    const caja = params.cajaId.trim().toUpperCase();
    return {
        rows: rows.filter((r: any) => !r.cajaId || String(r.cajaId).trim().toUpperCase() === caja),
        executionMode: "ts_fallback" as const,
    };
}

export async function upsertCorrelativoFiscal(params: {
    cajaId?: string;
    serialFiscal: string;
    correlativoActual?: number;
    descripcion?: string;
}) {
    if (!(await hasCorrelativoTable())) {
        throw new Error("table_not_found:Correlativo");
    }

    const tipo = params.cajaId && params.cajaId.trim().length > 0
        ? correlativoTipoPorCaja(params.cajaId)
        : "FACTURA";

    const serialFiscal = params.serialFiscal.trim();
    const correlativoActual = Number.isFinite(Number(params.correlativoActual))
        ? Number(params.correlativoActual)
        : 0;

    await query(
        `
        MERGE Correlativo AS target
        USING (SELECT @tipo AS Tipo) AS source
        ON target.Tipo = source.Tipo
        WHEN MATCHED THEN
            UPDATE SET
                Serie = @serie,
                Valor = @valor,
                Descripcion = @descripcion
        WHEN NOT MATCHED THEN
            INSERT (Tipo, Serie, Descripcion, Valor)
            VALUES (@tipo, @serie, @descripcion, @valor);
        `,
        {
            tipo,
            serie: serialFiscal,
            valor: correlativoActual,
            descripcion: params.descripcion ?? "",
        }
    );

    return {
        ok: true,
        row: {
            tipo,
            cajaId: params.cajaId?.trim().toUpperCase() ?? null,
            serialFiscal,
            correlativoActual,
            descripcion: params.descripcion ?? "",
        },
    };
}

export async function getPosReportResumen(params: { from?: string; to?: string; cajaId?: string }) {
    const { fromDate, toDate } = normalizeRange(params.from, params.to);
    const cajaId = params.cajaId?.trim() || null;
    if (!(await hasPosSalesTables())) {
        return {
            from: fromDate,
            to: toDate,
            row: {
                totalVentas: 0,
                transacciones: 0,
                productosVendidos: 0,
                productosDiferentes: 0,
                ticketPromedio: 0,
            },
            executionMode: "ts_fallback" as const,
        };
    }

    const rows = await query<any>(
        `
        WITH ventas AS (
            SELECT Id, Total
            FROM PosVentas
            WHERE CAST(FechaVenta AS date) BETWEEN @fromDate AND @toDate
              AND (@cajaId IS NULL OR UPPER(LTRIM(RTRIM(CajaId))) = UPPER(LTRIM(RTRIM(@cajaId))))
        ),
        detalle AS (
            SELECT d.ProductoId, d.Cantidad
            FROM PosVentasDetalle d
            INNER JOIN ventas v ON v.Id = d.VentaId
        )
        SELECT
            ISNULL((SELECT SUM(Total) FROM ventas), 0) AS totalVentas,
            ISNULL((SELECT COUNT(1) FROM ventas), 0) AS transacciones,
            ISNULL((SELECT SUM(Cantidad) FROM detalle), 0) AS productosVendidos,
            ISNULL((SELECT COUNT(DISTINCT ProductoId) FROM detalle), 0) AS productosDiferentes,
            CASE
                WHEN (SELECT COUNT(1) FROM ventas) = 0 THEN 0
                ELSE ISNULL((SELECT SUM(Total) FROM ventas), 0) / NULLIF((SELECT COUNT(1) FROM ventas), 0)
            END AS ticketPromedio
        `,
        { fromDate, toDate, cajaId }
    );

    return {
        from: fromDate,
        to: toDate,
        row: rows[0] ?? {
            totalVentas: 0,
            transacciones: 0,
            productosVendidos: 0,
            productosDiferentes: 0,
            ticketPromedio: 0,
        },
        executionMode: "ts_fallback" as const,
    };
}

export async function listPosReportVentas(params: { from?: string; to?: string; limit?: number; cajaId?: string }) {
    const { fromDate, toDate } = normalizeRange(params.from, params.to);
    const cajaId = params.cajaId?.trim() || null;
    const limit = Math.min(Math.max(params.limit ?? 200, 1), 500);
    if (!(await hasPosSalesTables())) {
        return { from: fromDate, to: toDate, rows: [], executionMode: "ts_fallback" as const };
    }

    const rowsRaw = await query<any>(
        `
        SELECT TOP ${limit}
            v.Id AS id,
            v.NumFactura AS numFactura,
            v.FechaVenta AS fecha,
            ISNULL(NULLIF(LTRIM(RTRIM(v.ClienteNombre)), ''), 'Consumidor Final') AS cliente,
            v.CajaId AS cajaId,
            v.Total AS total,
            'Completada' AS estado,
            v.MetodoPago AS metodoPago,
            v.TramaFiscal AS tramaFiscal,
            corr.Serie AS serialFiscal,
            corr.Valor AS correlativoFiscal
        FROM PosVentas v
        OUTER APPLY (
            SELECT TOP 1 c.Serie, c.Valor
            FROM Correlativo c
            WHERE c.Tipo IN (
                CONCAT('FACTURA|CAJA:', UPPER(LTRIM(RTRIM(v.CajaId)))),
                'FACTURA'
            )
            ORDER BY CASE WHEN c.Tipo = CONCAT('FACTURA|CAJA:', UPPER(LTRIM(RTRIM(v.CajaId)))) THEN 0 ELSE 1 END
        ) corr
        WHERE CAST(v.FechaVenta AS date) BETWEEN @fromDate AND @toDate
                    AND (@cajaId IS NULL OR UPPER(LTRIM(RTRIM(v.CajaId))) = UPPER(LTRIM(RTRIM(@cajaId))))
        ORDER BY v.FechaVenta DESC, v.Id DESC
        `,
                { fromDate, toDate, cajaId }
    );

    const rows = rowsRaw.map((row) => ({
        ...row,
        serialFiscal: row.serialFiscal ?? inferSerialFromTrama(row.tramaFiscal),
    }));

    return { from: fromDate, to: toDate, rows, executionMode: "ts_fallback" as const };
}

export async function listPosReportProductosTop(params: { from?: string; to?: string; limit?: number; cajaId?: string }) {
    const { fromDate, toDate } = normalizeRange(params.from, params.to);
    const cajaId = params.cajaId?.trim() || null;
    const limit = Math.min(Math.max(params.limit ?? 20, 1), 100);
    if (!(await hasPosSalesTables())) {
        return { from: fromDate, to: toDate, rows: [], executionMode: "ts_fallback" as const };
    }

    const rows = await query<any>(
        `
        SELECT TOP ${limit}
            d.ProductoId AS productoId,
            ISNULL(NULLIF(LTRIM(RTRIM(d.Codigo)), ''), d.ProductoId) AS codigo,
            d.Nombre AS nombre,
            SUM(d.Cantidad) AS cantidad,
            SUM(d.Subtotal + (d.Subtotal * d.IVA / 100.0)) AS total
        FROM PosVentasDetalle d
        INNER JOIN PosVentas v ON v.Id = d.VentaId
        WHERE CAST(v.FechaVenta AS date) BETWEEN @fromDate AND @toDate
                    AND (@cajaId IS NULL OR UPPER(LTRIM(RTRIM(v.CajaId))) = UPPER(LTRIM(RTRIM(@cajaId))))
        GROUP BY d.ProductoId, d.Codigo, d.Nombre
        ORDER BY total DESC, cantidad DESC
        `,
                { fromDate, toDate, cajaId }
    );

    return { from: fromDate, to: toDate, rows, executionMode: "ts_fallback" as const };
}

export async function listPosReportFormasPago(params: { from?: string; to?: string; cajaId?: string }) {
    const { fromDate, toDate } = normalizeRange(params.from, params.to);
    const cajaId = params.cajaId?.trim() || null;
    if (!(await hasPosSalesTables())) {
        return { from: fromDate, to: toDate, rows: [], executionMode: "ts_fallback" as const };
    }

    const rows = await query<any>(
        `
        SELECT
            ISNULL(NULLIF(LTRIM(RTRIM(v.MetodoPago)), ''), 'No especificado') AS metodoPago,
            COUNT(1) AS transacciones,
            SUM(v.Total) AS total
        FROM PosVentas v
        WHERE CAST(v.FechaVenta AS date) BETWEEN @fromDate AND @toDate
                    AND (@cajaId IS NULL OR UPPER(LTRIM(RTRIM(v.CajaId))) = UPPER(LTRIM(RTRIM(@cajaId))))
        GROUP BY ISNULL(NULLIF(LTRIM(RTRIM(v.MetodoPago)), ''), 'No especificado')
        ORDER BY total DESC
        `,
                { fromDate, toDate, cajaId }
    );

    return { from: fromDate, to: toDate, rows, executionMode: "ts_fallback" as const };
}

export async function listPosReportCajas(params: { from?: string; to?: string }) {
    const { fromDate, toDate } = normalizeRange(params.from, params.to);
    if (!(await hasPosSalesTables())) {
        return { from: fromDate, to: toDate, rows: [], executionMode: "ts_fallback" as const };
    }

    const rows = await query<any>(
        `
        SELECT
            UPPER(LTRIM(RTRIM(v.CajaId))) AS cajaId,
            COUNT(1) AS transacciones,
            SUM(v.Total) AS total,
            MAX(ISNULL(corr.Serie, '')) AS serialFiscal
        FROM PosVentas v
        OUTER APPLY (
            SELECT TOP 1 c.Serie
            FROM Correlativo c
            WHERE c.Tipo IN (
                CONCAT('FACTURA|CAJA:', UPPER(LTRIM(RTRIM(v.CajaId)))),
                'FACTURA'
            )
            ORDER BY CASE WHEN c.Tipo = CONCAT('FACTURA|CAJA:', UPPER(LTRIM(RTRIM(v.CajaId)))) THEN 0 ELSE 1 END
        ) corr
        WHERE CAST(v.FechaVenta AS date) BETWEEN @fromDate AND @toDate
        GROUP BY UPPER(LTRIM(RTRIM(v.CajaId)))
        ORDER BY cajaId
        `,
        { fromDate, toDate }
    );

    return { from: fromDate, to: toDate, rows, executionMode: "ts_fallback" as const };
}
