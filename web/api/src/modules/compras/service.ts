import { query } from "../../db/query.js";
import { getPool, sql } from "../../db/mssql.js";
import { createRow, deleteRow, encodeKeyObject, updateRow } from "../crud/crud.service.js";

export type ListComprasParams = {
  search?: string;
  proveedor?: string;
  estado?: string;
  fechaDesde?: string;
  fechaHasta?: string;
  page?: string;
  limit?: string;
};

export type ListComprasResult = {
  page: number;
  limit: number;
  total: number;
  rows: any[];
  executionMode?: "sp" | "ts_fallback";
};

export async function listCompras(params: ListComprasParams): Promise<ListComprasResult> {
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);

  try {
    const pool = await getPool();
    const req = pool.request();
    req.input("Search", sql.NVarChar(100), params.search ?? null);
    req.input("Proveedor", sql.NVarChar(10), params.proveedor ?? null);
    req.input("Estado", sql.NVarChar(50), params.estado ?? null);
    req.input("FechaDesde", sql.Date, params.fechaDesde ?? null);
    req.input("FechaHasta", sql.Date, params.fechaHasta ?? null);
    req.input("Page", sql.Int, page);
    req.input("Limit", sql.Int, limit);
    req.output("TotalCount", sql.Int);

    const result = await req.execute("usp_Compras_List");
    const total = (req.parameters.TotalCount?.value as number) ?? 0;
    const rows = (result.recordset ?? []) as any[];
    return { page, limit, total, rows, executionMode: "sp" };
  } catch {
    // Fallback
  }

  const offset = (page - 1) * limit;
  const where: string[] = [];
  const sqlParams: Record<string, unknown> = {};

  if (params.search) {
    where.push("(NUM_FACT LIKE @search OR NOMBRE LIKE @search OR RIF LIKE @search)");
    sqlParams.search = `%${params.search}%`;
  }
  if (params.proveedor) {
    where.push("COD_PROVEEDOR = @proveedor");
    sqlParams.proveedor = params.proveedor;
  }
  if (params.estado) {
    where.push("TIPO = @estado");
    sqlParams.estado = params.estado;
  }
  if (params.fechaDesde) {
    where.push("FECHA >= @fechaDesde");
    sqlParams.fechaDesde = params.fechaDesde;
  }
  if (params.fechaHasta) {
    where.push("FECHA <= @fechaHasta");
    sqlParams.fechaHasta = params.fechaHasta;
  }

  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const rows = await query<any>(
    `SELECT * FROM Compras ${clause} ORDER BY FECHA DESC OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`,
    sqlParams
  );

  const totalResult = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM Compras ${clause}`, sqlParams);
  const total = Number(totalResult[0]?.total ?? 0);
  return { page, limit, total, rows, executionMode: "ts_fallback" };
}

export async function getCompra(numFact: string): Promise<{ row: any; executionMode?: "sp" | "ts_fallback" } | { row: null; executionMode?: "sp" | "ts_fallback" }> {
  try {
    const pool = await getPool();
    const req = pool.request();
    req.input("NumFact", sql.NVarChar(25), numFact);
    const result = await req.execute("usp_Compras_GetByNumFact");
    const rows = (result.recordset ?? []) as any[];
    const row = rows[0] ?? null;
    return { row, executionMode: "sp" };
  } catch {
    // Fallback
  }

  const rows = await query<any>("SELECT TOP 1 * FROM Compras WHERE NUM_FACT = @numFact", { numFact });
  return { row: rows[0] ?? null, executionMode: "ts_fallback" };
}

export async function getDetalleCompra(numFact: string) {
  return query<any>("SELECT * FROM Detalle_Compras WHERE NUM_FACT = @numFact ORDER BY id", { numFact });
}

export async function getIndicadoresCompra(numFact: string) {
  const compra = await query<any>(
    "SELECT TOP 1 NUM_FACT, COD_PROVEEDOR, TIPO, TOTAL, ANULADA FROM Compras WHERE NUM_FACT = @numFact",
    { numFact }
  );
  if (!compra[0]) return null;

  const mov = await query<{ total: number }>(
    "SELECT COUNT(1) AS total FROM MovInvent WHERE DOCUMENTO = @numFact AND TIPO = 'Ingreso'",
    { numFact }
  );
  const cxp = await query<{ total: number; pendiente: number }>(
    `SELECT COUNT(1) AS total, COALESCE(SUM(COALESCE(PEND, 0)), 0) AS pendiente
       FROM P_Pagar
      WHERE DOCUMENTO = @numFact AND TIPO = 'FACT'`,
    { numFact }
  );

  return {
    numFact,
    codProveedor: compra[0].COD_PROVEEDOR ?? null,
    tipoCompra: compra[0].TIPO ?? null,
    totalCompra: Number(compra[0].TOTAL ?? 0),
    anulado: Number(compra[0].ANULADA ?? 0) === 1,
    inventario: {
      movimientos: Number(mov[0]?.total ?? 0),
      impactado: Number(mov[0]?.total ?? 0) > 0
    },
    cxp: {
      registros: Number(cxp[0]?.total ?? 0),
      generado: Number(cxp[0]?.total ?? 0) > 0,
      pendienteTotal: Number(cxp[0]?.pendiente ?? 0)
    }
  };
}

export async function createCompra(body: Record<string, unknown>) {
  return createRow("dbo", "Compras", body);
}

export async function updateCompra(numFact: string, body: Record<string, unknown>) {
  const key = encodeKeyObject({ NUM_FACT: numFact });
  return updateRow("dbo", "Compras", key, body);
}

export async function deleteCompra(numFact: string) {
  const key = encodeKeyObject({ NUM_FACT: numFact });
  return deleteRow("dbo", "Compras", key);
}

// ============================================
// Funciones auxiliares para convertir a XML
// ============================================
function compraToXml(compra: Record<string, unknown>): string {
  const attrs = Object.entries(compra)
    .map(([key, val]) => {
      if (val == null) return "";
      const escaped = String(val).replace(/"/g, "&quot;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
      return `${key}="${escaped}"`;
    })
    .filter(Boolean)
    .join(" ");
  return `<compra ${attrs}/>`;
}

function detalleToXml(detalle: Record<string, unknown>[]): string {
  const rows = detalle
    .map((row) => {
      const attrs = Object.entries(row)
        .map(([key, val]) => {
          if (val == null) return "";
          const escaped = String(val).replace(/"/g, "&quot;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
          return `${key}="${escaped}"`;
        })
        .filter(Boolean)
        .join(" ");
      return `  <row ${attrs}/>`;
    })
    .join("\n");
  return `<detalles>\n${rows}\n</detalles>`;
}

// ============================================
// Transacciones Optimizadas con SP
// ============================================

export type EmitirCompraPayload = {
  compra: Record<string, unknown>;
  detalle: Record<string, unknown>[];
  options?: {
    actualizarInventario?: boolean;
    generarCxP?: boolean;
    actualizarSaldosProveedor?: boolean;
    cxpTable?: "P_Pagar";
  };
};

/**
 * Emite una compra completa usando Stored Procedure (SQL Server 2012 compatible)
 * Optimizado: Una sola llamada a BD en lugar de múltiples queries
 */
export async function emitirCompraTx(payload: EmitirCompraPayload) {
  const compra = payload.compra ?? {};
  const detalle = payload.detalle ?? [];
  const options = payload.options ?? {};

  const numFact = String(compra.NUM_FACT || "");
  if (!numFact) throw new Error("missing_num_fact");
  if (!detalle.length) throw new Error("missing_detalle");

  const pool = await getPool();
  const request = new sql.Request(pool);
  request.input("CompraXml", sql.NVarChar(sql.MAX), compraToXml(compra));
  request.input("DetalleXml", sql.NVarChar(sql.MAX), detalleToXml(detalle));
  request.input("ActualizarInventario", sql.Bit, options.actualizarInventario !== false ? 1 : 0);
  request.input("GenerarCxP", sql.Bit, options.generarCxP !== false ? 1 : 0);
  request.input("ActualizarSaldosProveedor", sql.Bit, options.actualizarSaldosProveedor !== false ? 1 : 0);

  const result = await request.execute("sp_emitir_compra_tx");
  const output = result.recordset?.[0];

  return {
    ok: output?.ok === true,
    numFact: output?.numFact || numFact,
    detalleRows: output?.detalleRows || detalle.length,
    inventoryUpdated: output?.inventoryUpdated === true,
    cxp: {
      generated: output?.cxpGenerated === true,
      totalPendiente: options.generarCxP !== false && compra.TIPO === "CREDITO" ? compra.TOTAL : 0,
    },
  };
}

/**
 * Crea compra + detalle (simple, sin inventario ni CxP)
 * Mantiene compatibilidad hacia atrás
 */
export async function createCompraTx(payload: {
  compra: Record<string, unknown>;
  detalle: Record<string, unknown>[];
}) {
  // Por defecto no actualiza inventario ni genera CxP para createCompraTx simple
  return emitirCompraTx({
    ...payload,
    options: {
      actualizarInventario: false,
      generarCxP: false,
      actualizarSaldosProveedor: false,
    },
  });
}


// ============================================
// ANULACIÓN DE COMPRAS - Stored Procedure
// ============================================

export interface AnularCompraInput {
  numFact: string;
  codUsuario?: string;
  motivo?: string;
}

export interface AnularCompraResult {
  success: boolean;
  numFact?: string;
  codProveedor?: string;
  message: string;
}

/**
 * Anula una compra usando Stored Procedure (SQL Server 2012 compatible)
 * Revierte inventario, anula CxP y registra movimiento de anulación
 */
export async function anularCompraTx(input: AnularCompraInput): Promise<AnularCompraResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);
  request.input("NumFact", sql.NVarChar(60), input.numFact);
  request.input("CodUsuario", sql.NVarChar(60), input.codUsuario || "API");
  request.input("Motivo", sql.NVarChar(500), input.motivo || "");

  const result = await request.execute("sp_anular_compra_tx");
  const output = result.recordset?.[0];

  return {
    success: output?.ok === true,
    numFact: output?.numFact,
    codProveedor: output?.codProveedor,
    message: output?.mensaje || "Compra anulada",
  };
}

