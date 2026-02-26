import { query } from "../../db/query.js";

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
  if (scopeCache) return scopeCache;

  const rows = await query<{ companyId: number; systemUserId: number | null }>(
    `
    SELECT TOP 1
      c.CompanyId AS companyId,
      su.UserId AS systemUserId
    FROM cfg.Company c
    LEFT JOIN sec.[User] su
      ON su.UserCode = N'SYSTEM'
    WHERE c.CompanyCode = N'DEFAULT'
    ORDER BY c.CompanyId
    `
  );

  const first = rows[0];
  scopeCache = {
    companyId: Number(first?.companyId ?? 1),
    systemUserId: first?.systemUserId == null ? null : Number(first.systemUserId),
  };
  return scopeCache;
}

async function resolveUserId(userCode?: string): Promise<number | null> {
  const code = String(userCode ?? "").trim();
  if (!code) {
    return (await getScope()).systemUserId;
  }

  const rows = await query<{ userId: number }>(
    `
    SELECT TOP 1 UserId AS userId
    FROM sec.[User]
    WHERE UPPER(UserCode) = UPPER(@code)
    ORDER BY UserId
    `,
    { code }
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

  const where: string[] = ["CompanyId = @companyId", "IsActive = 1"];
  const sqlParams: Record<string, unknown> = {
    companyId: scope.companyId,
    offset,
    limit,
  };

  if (params.search?.trim()) {
    where.push("(BankName LIKE @search OR ContactName LIKE @search)");
    sqlParams.search = `%${params.search.trim()}%`;
  }

  const clause = `WHERE ${where.join(" AND ")}`;
  const rows = await query<BancoRow>(
    `
    SELECT
      BankName AS Nombre,
      ContactName AS Contacto,
      AddressLine AS Direccion,
      Phones AS Telefonos
    FROM fin.Bank
    ${clause}
    ORDER BY BankName
    OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
    `,
    sqlParams
  );

  const totalRows = await query<{ total: number }>(
    `
    SELECT COUNT(1) AS total
    FROM fin.Bank
    ${clause}
    `,
    sqlParams
  );

  return {
    rows,
    total: Number(totalRows[0]?.total ?? 0),
    page,
    limit,
  };
}

export async function getBancoByNombreSP(nombre: string): Promise<BancoRow | null> {
  const scope = await getScope();
  const rows = await query<BancoRow>(
    `
    SELECT TOP 1
      BankName AS Nombre,
      ContactName AS Contacto,
      AddressLine AS Direccion,
      Phones AS Telefonos
    FROM fin.Bank
    WHERE CompanyId = @companyId
      AND IsActive = 1
      AND BankName = @nombre
    ORDER BY BankId DESC
    `,
    {
      companyId: scope.companyId,
      nombre: String(nombre ?? "").trim(),
    }
  );

  return rows[0] ?? null;
}

export async function insertBancoSP(row: BancoRow): Promise<SpResult> {
  const scope = await getScope();
  const bankName = String(row.Nombre ?? "").trim();
  if (!bankName) return { success: false, message: "Nombre es obligatorio" };

  const exists = await query<{ found: number }>(
    `
    SELECT TOP 1 1 AS found
    FROM fin.Bank
    WHERE CompanyId = @companyId
      AND BankName = @bankName
    `,
    { companyId: scope.companyId, bankName }
  );
  if (exists[0]?.found === 1) {
    return { success: false, message: "Banco ya existe" };
  }

  const userId = await resolveUserId(String(row.Co_Usuario ?? ""));
  await query(
    `
    INSERT INTO fin.Bank (
      CompanyId,
      BankCode,
      BankName,
      ContactName,
      AddressLine,
      Phones,
      IsActive,
      CreatedByUserId,
      UpdatedByUserId
    )
    VALUES (
      @companyId,
      @bankCode,
      @bankName,
      @contacto,
      @direccion,
      @telefonos,
      1,
      @userId,
      @userId
    )
    `,
    {
      companyId: scope.companyId,
      bankCode: toBankCode(bankName),
      bankName,
      contacto: row.Contacto ?? null,
      direccion: row.Direccion ?? null,
      telefonos: row.Telefonos ?? null,
      userId,
    }
  );

  return { success: true, message: "Banco creado" };
}

export async function updateBancoSP(nombre: string, row: Partial<BancoRow>): Promise<SpResult> {
  const scope = await getScope();
  const currentName = String(nombre ?? "").trim();
  if (!currentName) return { success: false, message: "Nombre invalido" };

  const userId = await resolveUserId(String(row.Co_Usuario ?? ""));
  const affected = await query<{ affected: number }>(
    `
    UPDATE fin.Bank
    SET
      ContactName = COALESCE(@contacto, ContactName),
      AddressLine = COALESCE(@direccion, AddressLine),
      Phones = COALESCE(@telefonos, Phones),
      UpdatedAt = SYSUTCDATETIME(),
      UpdatedByUserId = @userId
    WHERE CompanyId = @companyId
      AND BankName = @bankName
      AND IsActive = 1;

    SELECT @@ROWCOUNT AS affected;
    `,
    {
      companyId: scope.companyId,
      bankName: currentName,
      contacto: row.Contacto ?? null,
      direccion: row.Direccion ?? null,
      telefonos: row.Telefonos ?? null,
      userId,
    }
  );

  if (Number(affected[0]?.affected ?? 0) <= 0) {
    return { success: false, message: "Banco no encontrado" };
  }
  return { success: true, message: "Banco actualizado" };
}

export async function deleteBancoSP(nombre: string): Promise<SpResult> {
  const scope = await getScope();
  const bankName = String(nombre ?? "").trim();
  if (!bankName) return { success: false, message: "Nombre invalido" };

  const userId = (await getScope()).systemUserId;
  const affected = await query<{ affected: number }>(
    `
    UPDATE fin.Bank
    SET
      IsActive = 0,
      UpdatedAt = SYSUTCDATETIME(),
      UpdatedByUserId = @userId
    WHERE CompanyId = @companyId
      AND BankName = @bankName
      AND IsActive = 1;

    SELECT @@ROWCOUNT AS affected;
    `,
    {
      companyId: scope.companyId,
      bankName,
      userId,
    }
  );

  if (Number(affected[0]?.affected ?? 0) <= 0) {
    return { success: false, message: "Banco no encontrado" };
  }
  return { success: true, message: "Banco eliminado" };
}
