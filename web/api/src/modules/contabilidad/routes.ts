import { Router } from "express";
import { z } from "zod";
import {
  anularAsiento,
  balanceComprobacion,
  balanceGeneral,
  crearAjuste,
  crearAsiento,
  estadoResultados,
  generarDepreciacion,
  getAsiento,
  libroMayor,
  listAsientos,
  mayorAnalitico,
  seedPlanCuentas
} from "./service.js";
import { getPool, sql } from "../../db/mssql.js";

export const contabilidadRouter = Router();

const listSchema = z.object({
  fechaDesde: z.string().optional(),
  fechaHasta: z.string().optional(),
  tipoAsiento: z.string().optional(),
  estado: z.string().optional(),
  origenModulo: z.string().optional(),
  origenDocumento: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional()
});

const detalleSchema = z.object({
  codCuenta: z.string().min(1),
  descripcion: z.string().optional(),
  centroCosto: z.string().optional(),
  auxiliarTipo: z.string().optional(),
  auxiliarCodigo: z.string().optional(),
  documento: z.string().optional(),
  debe: z.number().min(0),
  haber: z.number().min(0)
});

const crearAsientoSchema = z.object({
  fecha: z.string().min(1),
  tipoAsiento: z.string().min(1),
  referencia: z.string().optional(),
  concepto: z.string().min(1),
  moneda: z.string().optional(),
  tasa: z.number().optional(),
  origenModulo: z.string().optional(),
  origenDocumento: z.string().optional(),
  detalle: z.array(detalleSchema).min(1)
});

const anularSchema = z.object({
  motivo: z.string().min(1)
});

const ajusteSchema = z.object({
  fecha: z.string().min(1),
  tipoAjuste: z.string().min(1),
  referencia: z.string().optional(),
  motivo: z.string().min(1),
  detalle: z.array(detalleSchema).min(1)
});

const depreciacionSchema = z.object({
  periodo: z.string().regex(/^\d{4}-\d{2}$/),
  centroCosto: z.string().optional()
});

const rangoSchema = z.object({
  fechaDesde: z.string().min(1),
  fechaHasta: z.string().min(1)
});

const mayorAnaliticoSchema = z.object({
  codCuenta: z.string().min(1),
  fechaDesde: z.string().min(1),
  fechaHasta: z.string().min(1)
});

const balanceGeneralSchema = z.object({
  fechaCorte: z.string().min(1)
});

let defaultCompanyIdCache: number | null = null;

async function getDefaultCompanyId() {
  if (defaultCompanyIdCache) return defaultCompanyIdCache;
  const pool = await getPool();
  const rs = await pool
    .request()
    .query(`
      SELECT TOP 1 CompanyId
      FROM cfg.Company
      WHERE CompanyCode = N'DEFAULT'
      ORDER BY CompanyId
    `);
  defaultCompanyIdCache = Number(rs.recordset?.[0]?.CompanyId ?? 1);
  return defaultCompanyIdCache;
}

function normalizeTipoCuenta(value: string | undefined) {
  const tipo = String(value ?? "").trim().toUpperCase();
  if (!tipo) return null;
  const normalized = tipo.charAt(0);
  if (!["A", "P", "C", "I", "G"].includes(normalized)) return null;
  return normalized;
}

contabilidadRouter.get("/asientos", async (req, res) => {
  const parsed = listSchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }

  const data = await listAsientos({
    fechaDesde: parsed.data.fechaDesde,
    fechaHasta: parsed.data.fechaHasta,
    tipoAsiento: parsed.data.tipoAsiento,
    estado: parsed.data.estado,
    origenModulo: parsed.data.origenModulo,
    origenDocumento: parsed.data.origenDocumento,
    page: parsed.data.page ? Number(parsed.data.page) : 1,
    limit: parsed.data.limit ? Number(parsed.data.limit) : 50
  });
  return res.json(data);
});

contabilidadRouter.get("/asientos/:id", async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id) || id <= 0) {
    return res.status(400).json({ error: "invalid_id" });
  }

  const data = await getAsiento(id);
  if (!data.cabecera) return res.status(404).json({ error: "not_found" });
  return res.json(data);
});

contabilidadRouter.post("/asientos", async (req, res) => {
  const parsed = crearAsientoSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  const user = (req as any).user?.username || "API";
  const result = await crearAsiento(parsed.data, user);
  if (!result.ok) return res.status(400).json(result);
  return res.status(201).json(result);
});

contabilidadRouter.post("/asientos/:id/anular", async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id) || id <= 0) {
    return res.status(400).json({ error: "invalid_id" });
  }
  const parsed = anularSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  const user = (req as any).user?.username || "API";
  const result = await anularAsiento(id, parsed.data.motivo, user);
  if (!result.ok) return res.status(400).json(result);
  return res.json(result);
});

contabilidadRouter.post("/ajustes", async (req, res) => {
  const parsed = ajusteSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  const user = (req as any).user?.username || "API";
  const result = await crearAjuste(parsed.data, user);
  if (!result.ok) return res.status(400).json(result);
  return res.status(201).json(result);
});

contabilidadRouter.post("/depreciaciones/generar", async (req, res) => {
  const parsed = depreciacionSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  const user = (req as any).user?.username || "API";
  const result = await generarDepreciacion(parsed.data.periodo, parsed.data.centroCosto, user);
  if (!result.ok) return res.status(400).json(result);
  return res.status(201).json(result);
});

contabilidadRouter.get("/reportes/libro-mayor", async (req, res) => {
  const parsed = rangoSchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }
  const rows = await libroMayor(parsed.data.fechaDesde, parsed.data.fechaHasta);
  return res.json({ rows });
});

contabilidadRouter.get("/reportes/mayor-analitico", async (req, res) => {
  const parsed = mayorAnaliticoSchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }
  const rows = await mayorAnalitico(parsed.data.codCuenta, parsed.data.fechaDesde, parsed.data.fechaHasta);
  return res.json({ rows });
});

contabilidadRouter.get("/reportes/balance-comprobacion", async (req, res) => {
  const parsed = rangoSchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }
  const rows = await balanceComprobacion(parsed.data.fechaDesde, parsed.data.fechaHasta);
  return res.json({ rows });
});

contabilidadRouter.get("/reportes/estado-resultados", async (req, res) => {
  const parsed = rangoSchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }
  const data = await estadoResultados(parsed.data.fechaDesde, parsed.data.fechaHasta);
  return res.json(data);
});

contabilidadRouter.get("/reportes/balance-general", async (req, res) => {
  const parsed = balanceGeneralSchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }
  const data = await balanceGeneral(parsed.data.fechaCorte);
  return res.json(data);
});

contabilidadRouter.post("/setup/seed-plan-cuentas", async (req, res) => {
  const user = (req as any).user?.username || "API";
  const data = await seedPlanCuentas(user);
  return res.status(201).json(data);
});


// GET /v1/contabilidad/cuentas - Listar cuentas contables (canonico acct.Account)
contabilidadRouter.get("/cuentas", async (req, res) => {
  const querySchema = z.object({
    search: z.string().optional(),
    tipo: z.string().optional(),
    nivel: z.string().optional(),
    activo: z.string().optional().default("true"),
    page: z.string().optional().default("1"),
    limit: z.string().optional().default("50"),
  });

  const parsed = querySchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }

  try {
    const companyId = await getDefaultCompanyId();
    const tipo = normalizeTipoCuenta(parsed.data.tipo);
    if (parsed.data.tipo && !tipo) {
      return res.status(400).json({ error: "invalid_tipo", message: "Tipo debe ser A/P/C/I/G" });
    }

    const page = Math.max(1, Number(parsed.data.page ?? "1") || 1);
    const limit = Math.min(200, Math.max(1, Number(parsed.data.limit ?? "50") || 50));
    const offset = (page - 1) * limit;
    const activo = String(parsed.data.activo ?? "true").toLowerCase() === "false" ? 0 : 1;

    const where: string[] = ["CompanyId = @CompanyId", "IsDeleted = 0", "IsActive = @IsActive"];
    if (parsed.data.search?.trim()) where.push("(AccountCode LIKE @Search OR AccountName LIKE @Search)");
    if (tipo) where.push("AccountType = @Tipo");
    if (parsed.data.nivel) where.push("AccountLevel = @Nivel");
    const whereClause = `WHERE ${where.join(" AND ")}`;

    const pool = await getPool();
    const countReq = pool.request().input("CompanyId", sql.Int, companyId).input("IsActive", sql.Bit, activo);
    const dataReq = pool.request().input("CompanyId", sql.Int, companyId).input("IsActive", sql.Bit, activo);

    if (parsed.data.search?.trim()) {
      const search = `%${parsed.data.search.trim()}%`;
      countReq.input("Search", sql.NVarChar(120), search);
      dataReq.input("Search", sql.NVarChar(120), search);
    }
    if (tipo) {
      countReq.input("Tipo", sql.NChar(1), tipo);
      dataReq.input("Tipo", sql.NChar(1), tipo);
    }
    if (parsed.data.nivel) {
      const nivel = Number(parsed.data.nivel);
      if (!Number.isFinite(nivel) || nivel < 1) return res.status(400).json({ error: "invalid_nivel" });
      countReq.input("Nivel", sql.Int, nivel);
      dataReq.input("Nivel", sql.Int, nivel);
    }
    dataReq.input("Offset", sql.Int, offset).input("Limit", sql.Int, limit);

    const countRs = await countReq.query(`
      SELECT COUNT(1) AS total
      FROM acct.Account
      ${whereClause}
    `);
    const total = Number(countRs.recordset?.[0]?.total ?? 0);

    const rs = await dataReq.query(`
      SELECT
        AccountCode,
        AccountName,
        AccountType,
        AccountLevel,
        IsActive
      FROM acct.Account
      ${whereClause}
      ORDER BY AccountCode
      OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY
    `);

    const rows = (rs.recordset || []).map((row: any) => ({
      codCuenta: row.AccountCode,
      descripcion: row.AccountName,
      tipo: row.AccountType,
      nivel: row.AccountLevel,
      activo: row.IsActive,
    }));

    return res.json({ data: rows, page, limit, total });
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

// GET /v1/contabilidad/cuentas/:codCuenta
contabilidadRouter.get("/cuentas/:codCuenta", async (req, res) => {
  try {
    const companyId = await getDefaultCompanyId();
    const pool = await getPool();
    const rs = await pool
      .request()
      .input("CompanyId", sql.Int, companyId)
      .input("CodCuenta", sql.NVarChar(40), req.params.codCuenta)
      .query(`
        SELECT TOP 1
          AccountCode,
          AccountName,
          AccountType,
          AccountLevel,
          IsActive
        FROM acct.Account
        WHERE CompanyId = @CompanyId
          AND AccountCode = @CodCuenta
          AND IsDeleted = 0
      `);

    const row = rs.recordset?.[0];
    if (!row) return res.status(404).json({ error: "not_found" });

    return res.json({
      codCuenta: row.AccountCode,
      descripcion: row.AccountName,
      tipo: row.AccountType,
      nivel: row.AccountLevel,
      activo: row.IsActive,
    });
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

const cuentaBodySchema = z.object({
  codCuenta: z.string().min(1, "Codigo de cuenta requerido"),
  descripcion: z.string().min(1, "Descripcion requerida"),
  tipo: z.string().min(1, "Tipo requerido"),
  nivel: z.number().int().min(1).max(10).default(1),
});

// POST /v1/contabilidad/cuentas
contabilidadRouter.post("/cuentas", async (req, res) => {
  const parsed = cuentaBodySchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const companyId = await getDefaultCompanyId();
    const { codCuenta, descripcion, tipo, nivel } = parsed.data;
    const normalizedTipo = normalizeTipoCuenta(tipo);
    if (!normalizedTipo) {
      return res.status(400).json({ error: "invalid_tipo", message: "Tipo debe ser A/P/C/I/G" });
    }

    const pool = await getPool();
    const exists = await pool
      .request()
      .input("CompanyId", sql.Int, companyId)
      .input("CodCuenta", sql.NVarChar(40), codCuenta)
      .query(`
        SELECT 1
        FROM acct.Account
        WHERE CompanyId = @CompanyId
          AND AccountCode = @CodCuenta
          AND IsDeleted = 0
      `);

    if (exists.recordset.length > 0) {
      return res.status(409).json({ error: "duplicate", message: `La cuenta ${codCuenta} ya existe` });
    }

    await pool
      .request()
      .input("CompanyId", sql.Int, companyId)
      .input("CodCuenta", sql.NVarChar(40), codCuenta)
      .input("Descripcion", sql.NVarChar(200), descripcion)
      .input("Tipo", sql.NChar(1), normalizedTipo)
      .input("Nivel", sql.Int, nivel)
      .query(`
        INSERT INTO acct.Account (
          CompanyId,
          AccountCode,
          AccountName,
          AccountType,
          AccountLevel,
          ParentAccountId,
          AllowsPosting,
          RequiresAuxiliary,
          IsActive,
          CreatedAt,
          UpdatedAt,
          IsDeleted
        )
        VALUES (
          @CompanyId,
          @CodCuenta,
          @Descripcion,
          @Tipo,
          @Nivel,
          NULL,
          1,
          0,
          1,
          SYSUTCDATETIME(),
          SYSUTCDATETIME(),
          0
        )
      `);

    return res.status(201).json({ ok: true, codCuenta });
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

// PUT /v1/contabilidad/cuentas/:codCuenta
contabilidadRouter.put("/cuentas/:codCuenta", async (req, res) => {
  const updateSchema = z.object({
    descripcion: z.string().min(1).optional(),
    tipo: z.string().min(1).optional(),
    nivel: z.number().int().min(1).max(10).optional(),
  });

  const parsed = updateSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const companyId = await getDefaultCompanyId();
    const codCuenta = req.params.codCuenta;
    const normalizedTipo = parsed.data.tipo !== undefined ? normalizeTipoCuenta(parsed.data.tipo) : null;
    if (parsed.data.tipo !== undefined && !normalizedTipo) {
      return res.status(400).json({ error: "invalid_tipo", message: "Tipo debe ser A/P/C/I/G" });
    }

    const pool = await getPool();
    const exists = await pool
      .request()
      .input("CompanyId", sql.Int, companyId)
      .input("CodCuenta", sql.NVarChar(40), codCuenta)
      .query(`
        SELECT 1
        FROM acct.Account
        WHERE CompanyId = @CompanyId
          AND AccountCode = @CodCuenta
          AND IsDeleted = 0
      `);

    if (exists.recordset.length === 0) {
      return res.status(404).json({ error: "not_found", message: `Cuenta ${codCuenta} no encontrada` });
    }

    const sets: string[] = [];
    const request = pool
      .request()
      .input("CompanyId", sql.Int, companyId)
      .input("CodCuenta", sql.NVarChar(40), codCuenta);

    if (parsed.data.descripcion !== undefined) {
      sets.push("AccountName = @Descripcion");
      request.input("Descripcion", sql.NVarChar(200), parsed.data.descripcion);
    }
    if (parsed.data.tipo !== undefined && normalizedTipo) {
      sets.push("AccountType = @Tipo");
      request.input("Tipo", sql.NChar(1), normalizedTipo);
    }
    if (parsed.data.nivel !== undefined) {
      sets.push("AccountLevel = @Nivel");
      request.input("Nivel", sql.Int, parsed.data.nivel);
    }

    if (sets.length === 0) {
      return res.status(400).json({ error: "no_fields", message: "No se proporcionaron campos para actualizar" });
    }

    sets.push("UpdatedAt = SYSUTCDATETIME()");
    await request.query(`
      UPDATE acct.Account
      SET ${sets.join(", ")}
      WHERE CompanyId = @CompanyId
        AND AccountCode = @CodCuenta
        AND IsDeleted = 0
    `);

    return res.json({ ok: true, codCuenta });
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

// DELETE /v1/contabilidad/cuentas/:codCuenta
contabilidadRouter.delete("/cuentas/:codCuenta", async (req, res) => {
  try {
    const companyId = await getDefaultCompanyId();
    const codCuenta = req.params.codCuenta;
    const pool = await getPool();

    const exists = await pool
      .request()
      .input("CompanyId", sql.Int, companyId)
      .input("CodCuenta", sql.NVarChar(40), codCuenta)
      .query(`
        SELECT TOP 1 AccountId
        FROM acct.Account
        WHERE CompanyId = @CompanyId
          AND AccountCode = @CodCuenta
          AND IsDeleted = 0
      `);

    if (exists.recordset.length === 0) {
      return res.status(404).json({ error: "not_found", message: `Cuenta ${codCuenta} no encontrada` });
    }

    const accountId = Number(exists.recordset[0]?.AccountId ?? 0);
    const hasMovements = await pool
      .request()
      .input("AccountId", sql.BigInt, accountId)
      .query(`
        SELECT TOP 1 1
        FROM acct.JournalEntryLine
        WHERE AccountId = @AccountId
      `);

    if (hasMovements.recordset.length > 0) {
      return res.status(409).json({
        error: "has_movements",
        message: "No se puede eliminar: la cuenta tiene movimientos contables",
      });
    }

    await pool
      .request()
      .input("CompanyId", sql.Int, companyId)
      .input("CodCuenta", sql.NVarChar(40), codCuenta)
      .query(`
        UPDATE acct.Account
        SET IsDeleted = 1,
            IsActive = 0,
            DeletedAt = SYSUTCDATETIME(),
            UpdatedAt = SYSUTCDATETIME()
        WHERE CompanyId = @CompanyId
          AND AccountCode = @CodCuenta
          AND IsDeleted = 0
      `);

    return res.json({ ok: true, codCuenta });
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});
