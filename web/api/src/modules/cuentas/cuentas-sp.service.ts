import { callSp, callSpOut, sql } from "../../db/query.js";

export interface CuentaRow {
  COD_CUENTA?: string;
  DESCRIPCION?: string;
  TIPO?: string;
  PRESUPUESTO?: number;
  SALDO?: number;
  COD_USUARIO?: string;
  grupo?: string;
  LINEA?: string;
  USO?: string;
  Nivel?: number;
  Porcentaje?: number;
  [key: string]: unknown;
}

export interface ListCuentasParams {
  search?: string;
  tipo?: string;
  grupo?: string;
  page?: number;
  limit?: number;
}

export interface ListCuentasResult {
  rows: CuentaRow[];
  total: number;
  page: number;
  limit: number;
}

export interface SpResult {
  success: boolean;
  message: string;
}

/** Resolve default CompanyId via usp_Cfg_ResolveContext */
async function getDefaultCompanyId(): Promise<number> {
  const rows = await callSp<{ CompanyId: number }>("usp_Cfg_ResolveContext");
  const companyId = Number(rows[0]?.CompanyId ?? 0);
  if (!Number.isFinite(companyId) || companyId <= 0) throw new Error("company_not_found");
  return companyId;
}

function inferLevel(accountCode: string, level?: number) {
  if (Number.isFinite(level) && Number(level) > 0) return Number(level);
  const normalized = String(accountCode || "").trim();
  if (!normalized) return 1;
  return normalized.split(".").filter(Boolean).length || 1;
}

function mapCanonicalRow(row: Record<string, unknown>): CuentaRow {
  return {
    COD_CUENTA: String(row.AccountCode ?? ""),
    DESCRIPCION: String(row.AccountName ?? ""),
    TIPO: String(row.AccountType ?? ""),
    Nivel: Number(row.AccountLevel ?? 1),
    grupo: String(row.AccountCode ?? "").split(".")[0] || "",
    LINEA: "",
    USO: Number(row.AllowsPosting ?? 0) ? "M" : "T",
    Porcentaje: 0,
    SALDO: 0,
    PRESUPUESTO: 0,
    IsActive: row.IsActive,
    AccountId: row.AccountId
  };
}

export async function listCuentasSP(params: ListCuentasParams = {}): Promise<ListCuentasResult> {
  const companyId = await getDefaultCompanyId();
  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const tipo = params.tipo
    ? String(params.tipo).trim().toUpperCase().charAt(0)
    : undefined;

  const { rows, output } = await callSpOut<Record<string, unknown>>(
    "usp_Acct_Account_List",
    {
      CompanyId: companyId,
      Search: params.search || null,
      Tipo: tipo || null,
      Grupo: params.grupo || null,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return {
    rows: rows.map(mapCanonicalRow),
    total: Number(output.TotalCount ?? 0),
    page,
    limit,
  };
}

export async function getCuentaByCodigoSP(codCuenta: string): Promise<CuentaRow | null> {
  const companyId = await getDefaultCompanyId();
  const rows = await callSp<Record<string, unknown>>(
    "usp_Acct_Account_Get",
    { CompanyId: companyId, AccountCode: codCuenta }
  );
  return rows[0] ? mapCanonicalRow(rows[0]) : null;
}

export async function insertCuentaSP(row: CuentaRow): Promise<SpResult> {
  const companyId = await getDefaultCompanyId();
  const codCuenta = String(row.COD_CUENTA ?? "").trim();
  const descripcion = String(row.DESCRIPCION ?? "").trim();
  if (!codCuenta) return { success: false, message: "COD_CUENTA requerido" };
  if (!descripcion) return { success: false, message: "DESCRIPCION requerida" };

  const tipo = String(row.TIPO ?? "A").trim().toUpperCase().charAt(0) || "A";
  const nivel = inferLevel(codCuenta, row.Nivel);
  const allowsPosting = String(row.USO ?? "").trim().toUpperCase() === "M" || nivel >= 3 ? 1 : 0;

  const { output } = await callSpOut<never>(
    "usp_Acct_Account_Insert",
    {
      CompanyId: companyId,
      AccountCode: codCuenta,
      AccountName: descripcion,
      AccountType: tipo,
      AccountLevel: nivel,
      AllowsPosting: allowsPosting,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  const success = Number(output.Resultado) === 1;
  return {
    success,
    message: String(output.Mensaje ?? (success ? "Cuenta creada" : "Error al crear cuenta")),
  };
}

export async function updateCuentaSP(codCuenta: string, row: Partial<CuentaRow>): Promise<SpResult> {
  const companyId = await getDefaultCompanyId();

  const tipo = row.TIPO ? String(row.TIPO).trim().toUpperCase().charAt(0) : null;
  const nivel = row.Nivel ? Number(row.Nivel) : null;
  const allowsPosting = row.USO !== undefined
    ? (String(row.USO).trim().toUpperCase() === "M" ? 1 : 0)
    : null;

  const { output } = await callSpOut<never>(
    "usp_Acct_Account_Update",
    {
      CompanyId: companyId,
      AccountCode: codCuenta,
      AccountName: row.DESCRIPCION ?? null,
      AccountType: tipo,
      AccountLevel: nivel,
      AllowsPosting: allowsPosting,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  const success = Number(output.Resultado) === 1;
  return {
    success,
    message: String(output.Mensaje ?? (success ? "Cuenta actualizada" : "Error al actualizar cuenta")),
  };
}

export async function deleteCuentaSP(codCuenta: string): Promise<SpResult> {
  const companyId = await getDefaultCompanyId();

  const { output } = await callSpOut<never>(
    "usp_Acct_Account_Delete",
    { CompanyId: companyId, AccountCode: codCuenta },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  const success = Number(output.Resultado) === 1;
  return {
    success,
    message: String(output.Mensaje ?? (success ? "Cuenta eliminada" : "Error al eliminar cuenta")),
  };
}
