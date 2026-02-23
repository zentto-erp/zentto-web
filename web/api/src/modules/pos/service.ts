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
