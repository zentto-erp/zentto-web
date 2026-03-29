import { callSp } from "../../db/query.js";
import { env } from "../../config/env.js";
import { getRequestScope } from "../../context/request-context.js";

// ────────────────────────────────────────────────────────────
// Tipos
// ────────────────────────────────────────────────────────────

export interface InsertAuditLogParams {
  userId?: number | null;
  userName?: string | null;
  moduleName: string;
  entityName: string;
  entityId?: string | number | null;
  actionType: string;
  summary?: string | null;
  oldValues?: string | null;
  newValues?: string | null;
  ipAddress?: string | null;
}

export interface ListAuditLogsFilter {
  fechaDesde?: string;
  fechaHasta?: string;
  moduleName?: string;
  userName?: string;
  actionType?: string;
  entityName?: string;
  search?: string;
  page?: number;
  limit?: number;
}

export interface ListFiscalRecordsFilter {
  fechaDesde?: string;
  fechaHasta?: string;
  page?: number;
  limit?: number;
}

// ────────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────────

function resolveScope() {
  const scope = getRequestScope();
  const companyId = scope?.companyId ?? 0;
  const branchId = scope?.branchId ?? 0;
  if (!companyId) throw new Error("company_not_found");
  if (!branchId) throw new Error("branch_not_found");
  return { companyId, branchId };
}

const usePg = () => env.dbType === "postgres";

/** Ejecuta SP y retorna todos los recordsets (SQL Server multi-recordset o PG flat) */
async function callSpMulti(spName: string, inputs: Record<string, unknown>): Promise<any[][]> {
  if (usePg()) {
    // PG: callSp retorna un array plano; TotalCount viene en cada fila
    const rows = await callSp<any>(spName, inputs);
    return [rows]; // devolver como recordset[0]
  }
  // SQL Server: multi-recordset via mssql pool
  const { getPool } = await import("../../db/mssql.js");
  const pool = await getPool();
  const request = pool.request();
  for (const [key, value] of Object.entries(inputs)) {
    if (value !== undefined) request.input(key, value as any);
  }
  const result = await request.execute(spName);
  return result.recordsets as any[][];
}

// ────────────────────────────────────────────────────────────
// insertAuditLog
// ────────────────────────────────────────────────────────────

export async function insertAuditLog(params: InsertAuditLogParams) {
  const { companyId, branchId } = resolveScope();

  const rows = await callSp<any>("dbo.usp_Audit_Log_Insert", {
    CompanyId: companyId,
    BranchId: branchId,
    UserId: params.userId ?? null,
    UserName: params.userName ?? null,
    ModuleName: params.moduleName,
    EntityName: params.entityName,
    EntityId: params.entityId != null ? String(params.entityId) : null,
    ActionType: params.actionType,
    Summary: params.summary || null,
    OldValues: params.oldValues || null,
    NewValues: params.newValues || null,
    IpAddress: params.ipAddress || null,
  });

  return rows[0] || { ok: true };
}

// ────────────────────────────────────────────────────────────
// listAuditLogs (SP retorna 2 recordsets: count + data)
// ────────────────────────────────────────────────────────────

export async function listAuditLogs(filter: ListAuditLogsFilter) {
  const { companyId, branchId } = resolveScope();
  const page = Math.max(1, Number(filter.page || 1));
  const limit = Math.min(500, Math.max(1, Number(filter.limit || 50)));

  const spParams = {
    CompanyId: companyId,
    BranchId: branchId,
    FechaDesde: filter.fechaDesde || null,
    FechaHasta: filter.fechaHasta || null,
    ModuleName: filter.moduleName || null,
    UserName: filter.userName || null,
    ActionType: filter.actionType || null,
    EntityName: filter.entityName || null,
    Search: filter.search || null,
    Page: page,
    Limit: limit,
  };

  if (usePg()) {
    // PG: funcion retorna tabla plana con TotalCount en cada fila
    const rows = await callSp<any>("usp_Audit_Log_List", spParams);
    const total = rows[0]?.TotalCount ?? 0;
    const data = rows.map((r: any) => {
      const { TotalCount: _, ...rest } = r;
      return rest;
    });
    return { data, total: Number(total), page, limit };
  }

  const recordsets = await callSpMulti("dbo.usp_Audit_Log_List", spParams);
  const total = recordsets[0]?.[0]?.TotalCount ?? 0;
  const data = recordsets[1] ?? [];

  return { data, total: Number(total), page, limit };
}

// ────────────────────────────────────────────────────────────
// getAuditLog
// ────────────────────────────────────────────────────────────

export async function getAuditLog(id: number) {
  const rows = await callSp<any>("dbo.usp_Audit_Log_GetById", {
    AuditLogId: id,
  });
  return rows[0] || null;
}

// ────────────────────────────────────────────────────────────
// getDashboard (SP retorna 3 recordsets: totales, top módulos, últimos logs)
// ────────────────────────────────────────────────────────────

export async function getDashboard(fechaDesde: string, fechaHasta: string) {
  const { companyId, branchId } = resolveScope();

  const dashParams = {
    CompanyId: companyId,
    BranchId: branchId,
    FechaDesde: fechaDesde,
    FechaHasta: fechaHasta,
  };

  if (usePg()) {
    // PG: 3 funciones separadas en lugar de 1 SP con 3 recordsets
    const [totalesRows, modulosRows, ultimosRows] = await Promise.all([
      callSp<any>("usp_Audit_Dashboard_Totales", dashParams),
      callSp<any>("usp_Audit_Dashboard_TopModulos", dashParams),
      callSp<any>("usp_Audit_Dashboard_UltimosLogs", dashParams),
    ]);
    const totales = totalesRows[0] ?? {};
    return { ...totales, modulosActivos: modulosRows, ultimosLogs: ultimosRows };
  }

  const recordsets = await callSpMulti("dbo.usp_Audit_Dashboard_Resumen", dashParams);
  const totales = recordsets[0]?.[0] ?? {};
  const modulosActivos = recordsets[1] ?? [];
  const ultimosLogs = recordsets[2] ?? [];

  return { ...totales, modulosActivos, ultimosLogs };
}

// ────────────────────────────────────────────────────────────
// listFiscalRecords (SP retorna 2 recordsets: count + data)
// ────────────────────────────────────────────────────────────

export async function listFiscalRecords(filter: ListFiscalRecordsFilter) {
  const { companyId, branchId } = resolveScope();
  const page = Math.max(1, Number(filter.page || 1));
  const limit = Math.min(500, Math.max(1, Number(filter.limit || 50)));

  const spParams = {
    CompanyId: companyId,
    BranchId: branchId,
    FechaDesde: filter.fechaDesde || null,
    FechaHasta: filter.fechaHasta || null,
    Page: page,
    Limit: limit,
  };

  if (usePg()) {
    const rows = await callSp<any>("usp_Audit_FiscalRecord_List", spParams);
    const total = rows[0]?.TotalCount ?? 0;
    const data = rows.map((r: any) => {
      const { TotalCount: _, ...rest } = r;
      return rest;
    });
    return { data, total: Number(total), page, limit };
  }

  const recordsets = await callSpMulti("dbo.usp_Audit_FiscalRecord_List", spParams);
  const total = recordsets[0]?.[0]?.TotalCount ?? 0;
  const data = recordsets[1] ?? [];

  return { data, total: Number(total), page, limit };
}
