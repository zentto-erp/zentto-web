import { execute, query } from "../../db/query.js";

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

async function getDefaultCompanyId() {
  const rows = await query<{ CompanyId: number }>(
    `SELECT TOP 1 CompanyId
       FROM cfg.Company
      WHERE IsDeleted = 0
      ORDER BY CASE WHEN CompanyCode = 'DEFAULT' THEN 0 ELSE 1 END, CompanyId`
  );
  const companyId = Number(rows[0]?.CompanyId ?? 0);
  if (!Number.isFinite(companyId) || companyId <= 0) throw new Error("company_not_found");
  return companyId;
}

async function getParentAccountId(companyId: number, accountCode: string) {
  const parts = accountCode.split(".");
  if (parts.length <= 1) return null;
  parts.pop();
  const parentCode = parts.join(".");
  const rows = await query<{ AccountId: number }>(
    `SELECT TOP 1 AccountId
       FROM acct.Account
      WHERE CompanyId = @companyId
        AND AccountCode = @parentCode
        AND IsDeleted = 0`,
    { companyId, parentCode }
  );
  const parentId = Number(rows[0]?.AccountId ?? 0);
  return Number.isFinite(parentId) && parentId > 0 ? parentId : null;
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
  const offset = (page - 1) * limit;
  const where: string[] = ["CompanyId = @companyId", "IsDeleted = 0"];
  const sqlParams: Record<string, unknown> = { companyId };

  if (params.search) {
    where.push("(AccountCode LIKE @search OR AccountName LIKE @search)");
    sqlParams.search = `%${params.search}%`;
  }
  if (params.tipo) {
    where.push("AccountType = @tipo");
    sqlParams.tipo = String(params.tipo).trim().toUpperCase().charAt(0);
  }
  if (params.grupo) {
    where.push("AccountCode LIKE @grupo");
    sqlParams.grupo = `${params.grupo}%`;
  }
  const clause = `WHERE ${where.join(" AND ")}`;

  const rows = await query<any>(
    `SELECT AccountId, AccountCode, AccountName, AccountType, AccountLevel, AllowsPosting, IsActive
       FROM acct.Account
      ${clause}
      ORDER BY AccountCode
      OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`,
    sqlParams
  );

  const totalRows = await query<{ total: number }>(
    `SELECT COUNT(1) AS total
       FROM acct.Account
      ${clause}`,
    sqlParams
  );

  return {
    rows: rows.map(mapCanonicalRow),
    total: Number(totalRows[0]?.total ?? 0),
    page,
    limit,
  };
}

export async function getCuentaByCodigoSP(codCuenta: string): Promise<CuentaRow | null> {
  const companyId = await getDefaultCompanyId();
  const rows = await query<any>(
    `SELECT TOP 1 AccountId, AccountCode, AccountName, AccountType, AccountLevel, AllowsPosting, IsActive
       FROM acct.Account
      WHERE CompanyId = @companyId
        AND AccountCode = @codCuenta
        AND IsDeleted = 0`,
    { companyId, codCuenta }
  );
  return rows[0] ? mapCanonicalRow(rows[0]) : null;
}

export async function insertCuentaSP(row: CuentaRow): Promise<SpResult> {
  const companyId = await getDefaultCompanyId();
  const codCuenta = String(row.COD_CUENTA ?? "").trim();
  const descripcion = String(row.DESCRIPCION ?? "").trim();
  if (!codCuenta) return { success: false, message: "COD_CUENTA requerido" };
  if (!descripcion) return { success: false, message: "DESCRIPCION requerida" };

  const exists = await query<{ AccountId: number }>(
    `SELECT TOP 1 AccountId
       FROM acct.Account
      WHERE CompanyId = @companyId
        AND AccountCode = @codCuenta
        AND IsDeleted = 0`,
    { companyId, codCuenta }
  );
  if (exists[0]?.AccountId) return { success: false, message: "La cuenta ya existe" };

  const parentAccountId = await getParentAccountId(companyId, codCuenta);
  if (codCuenta.includes(".") && !parentAccountId) {
    return { success: false, message: "Cuenta padre no encontrada" };
  }

  const tipo = String(row.TIPO ?? "A").trim().toUpperCase().charAt(0) || "A";
  const nivel = inferLevel(codCuenta, row.Nivel);
  const allowsPosting = String(row.USO ?? "").trim().toUpperCase() === "M" || nivel >= 3 ? 1 : 0;

  await execute(
    `INSERT INTO acct.Account
      (CompanyId, AccountCode, AccountName, AccountType, AccountLevel, ParentAccountId,
       AllowsPosting, RequiresAuxiliary, IsActive, CreatedAt, UpdatedAt, IsDeleted)
     VALUES
      (@companyId, @accountCode, @accountName, @accountType, @accountLevel, @parentAccountId,
       @allowsPosting, 0, 1, SYSUTCDATETIME(), SYSUTCDATETIME(), 0)`,
    {
      companyId,
      accountCode: codCuenta,
      accountName: descripcion,
      accountType: tipo,
      accountLevel: nivel,
      parentAccountId,
      allowsPosting
    }
  );

  return {
    success: true,
    message: "Cuenta creada",
  };
}

export async function updateCuentaSP(codCuenta: string, row: Partial<CuentaRow>): Promise<SpResult> {
  const companyId = await getDefaultCompanyId();
  const current = await query<any>(
    `SELECT TOP 1 AccountCode
       FROM acct.Account
      WHERE CompanyId = @companyId
        AND AccountCode = @codCuenta
        AND IsDeleted = 0`,
    { companyId, codCuenta }
  );
  if (!current[0]) return { success: false, message: "Cuenta no encontrada" };

  const tipo = row.TIPO ? String(row.TIPO).trim().toUpperCase().charAt(0) : null;
  const nivel = row.Nivel ? Number(row.Nivel) : null;
  const allowsPosting = row.USO !== undefined
    ? (String(row.USO).trim().toUpperCase() === "M" ? 1 : 0)
    : null;

  await execute(
    `UPDATE acct.Account
        SET AccountName = COALESCE(@accountName, AccountName),
            AccountType = COALESCE(@accountType, AccountType),
            AccountLevel = COALESCE(@accountLevel, AccountLevel),
            AllowsPosting = COALESCE(@allowsPosting, AllowsPosting),
            IsActive = 1,
            UpdatedAt = SYSUTCDATETIME()
      WHERE CompanyId = @companyId
        AND AccountCode = @codCuenta
        AND IsDeleted = 0`,
    {
      companyId,
      codCuenta,
      accountName: row.DESCRIPCION ?? null,
      accountType: tipo,
      accountLevel: nivel,
      allowsPosting
    }
  );

  return {
    success: true,
    message: "Cuenta actualizada",
  };
}

export async function deleteCuentaSP(codCuenta: string): Promise<SpResult> {
  const companyId = await getDefaultCompanyId();
  const hasChildren = await query<{ total: number }>(
    `SELECT COUNT(1) AS total
       FROM acct.Account
      WHERE CompanyId = @companyId
        AND IsDeleted = 0
        AND ParentAccountId = (
          SELECT TOP 1 AccountId
          FROM acct.Account
          WHERE CompanyId = @companyId
            AND AccountCode = @codCuenta
            AND IsDeleted = 0
        )`,
    { companyId, codCuenta }
  );
  if (Number(hasChildren[0]?.total ?? 0) > 0) {
    return { success: false, message: "No se puede eliminar: tiene cuentas hijas" };
  }

  await execute(
    `UPDATE acct.Account
        SET IsDeleted = 1,
            IsActive = 0,
            DeletedAt = SYSUTCDATETIME(),
            UpdatedAt = SYSUTCDATETIME()
      WHERE CompanyId = @companyId
        AND AccountCode = @codCuenta
        AND IsDeleted = 0`,
    { companyId, codCuenta }
  );

  return {
    success: true,
    message: "Cuenta eliminada",
  };
}
