import { callSp, callSpOut, sql } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

export interface BancoRow {
  Nombre?: string;
  Contacto?: string;
  Direccion?: string;
  Telefonos?: string;
  Co_Usuario?: string;
  [key: string]: unknown;
}

export interface ListBancosParams {
  search?: string;
  page?: number;
  limit?: number;
}

export interface ListBancosResult {
  rows: BancoRow[];
  total: number;
  page: number;
  limit: number;
}

export interface SpResult {
  success: boolean;
  message: string;
}

type Scope = {
  companyId: number;
  systemUserId: number | null;
};

let scopeCache: Scope | null = null;

async function getScope(): Promise<Scope> {
  const activeScope = getActiveScope();
  if (scopeCache && activeScope) {
    return {
      ...scopeCache,
      companyId: activeScope.companyId,
    };
  }
  if (scopeCache) return scopeCache;

  const rows = await callSp<{ companyId: number; systemUserId: number | null }>(
    "usp_Cfg_Scope_GetDefaultCompanyUser"
  );

  const first = rows[0];
  scopeCache = {
    companyId: Number(first?.companyId ?? 1),
    systemUserId: first?.systemUserId == null ? null : Number(first.systemUserId),
  };
  if (activeScope) {
    return {
      ...scopeCache,
      companyId: activeScope.companyId,
    };
  }
  return scopeCache;
}

async function resolveUserId(userCode?: string): Promise<number | null> {
  const code = String(userCode ?? "").trim();
  if (!code) {
    return (await getScope()).systemUserId;
  }

  const rows = await callSp<{ userId: number }>(
    "usp_Sec_User_ResolveByCode",
    { Code: code }
  );

  if (rows[0]?.userId != null) return Number(rows[0].userId);
  return (await getScope()).systemUserId;
}

function toBankCode(name: string) {
  const normalized = name
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^A-Za-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "")
    .toUpperCase();
  return (normalized || "BANCO").slice(0, 30);
}

export async function listBancosSP(params: ListBancosParams = {}): Promise<ListBancosResult> {
  const scope = await getScope();
  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);
  const offset = (page - 1) * limit;

  const search = params.search?.trim() ? `%${params.search.trim()}%` : null;

  const { rows, output } = await callSpOut<BancoRow>(
    "usp_Fin_Bank_List",
    {
      CompanyId: scope.companyId,
      Search: search,
      Offset: offset,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return {
    rows,
    total: Number(output.TotalCount ?? 0),
    page,
    limit,
  };
}

export async function getBancoByNombreSP(nombre: string): Promise<BancoRow | null> {
  const scope = await getScope();
  const rows = await callSp<BancoRow>(
    "usp_Fin_Bank_GetByName",
    {
      CompanyId: scope.companyId,
      BankName: String(nombre ?? "").trim(),
    }
  );

  return rows[0] ?? null;
}

export async function insertBancoSP(row: BancoRow): Promise<SpResult> {
  const scope = await getScope();
  const bankName = String(row.Nombre ?? "").trim();
  if (!bankName) return { success: false, message: "Nombre es obligatorio" };

  const userId = await resolveUserId(String(row.Co_Usuario ?? ""));

  const { output } = await callSpOut(
    "usp_Fin_Bank_Insert",
    {
      CompanyId: scope.companyId,
      BankCode: toBankCode(bankName),
      BankName: bankName,
      ContactName: row.Contacto ?? null,
      AddressLine: row.Direccion ?? null,
      Phones: row.Telefonos ?? null,
      UserId: userId,
    },
    { Success: sql.Bit, Message: sql.NVarChar(200) }
  );

  return {
    success: Boolean(output.Success),
    message: String(output.Message ?? ""),
  };
}

export async function updateBancoSP(nombre: string, row: Partial<BancoRow>): Promise<SpResult> {
  const scope = await getScope();
  const currentName = String(nombre ?? "").trim();
  if (!currentName) return { success: false, message: "Nombre invalido" };

  const userId = await resolveUserId(String(row.Co_Usuario ?? ""));

  const { output } = await callSpOut(
    "usp_Fin_Bank_Update",
    {
      CompanyId: scope.companyId,
      BankName: currentName,
      ContactName: row.Contacto ?? null,
      AddressLine: row.Direccion ?? null,
      Phones: row.Telefonos ?? null,
      UserId: userId,
    },
    { Success: sql.Bit, Message: sql.NVarChar(200) }
  );

  return {
    success: Boolean(output.Success),
    message: String(output.Message ?? ""),
  };
}

export async function deleteBancoSP(nombre: string): Promise<SpResult> {
  const scope = await getScope();
  const bankName = String(nombre ?? "").trim();
  if (!bankName) return { success: false, message: "Nombre invalido" };

  const userId = (await getScope()).systemUserId;

  const { output } = await callSpOut(
    "usp_Fin_Bank_Delete",
    {
      CompanyId: scope.companyId,
      BankName: bankName,
      UserId: userId,
    },
    { Success: sql.Bit, Message: sql.NVarChar(200) }
  );

  return {
    success: Boolean(output.Success),
    message: String(output.Message ?? ""),
  };
}
