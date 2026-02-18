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


// GET /v1/contabilidad/cuentas - Listar cuentas contables (Plan de Cuentas)
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
    const pool = await getPool();
    // Consulta simple sin paginación para máxima compatibilidad
    const result = await pool.query(`SELECT TOP 100 * FROM Cuentas ORDER BY Cod_Cuenta`);

    // Mapear columnas dinámicamente - soporta múltiples nombres de columnas
    const rows = (result.recordset || []).map((row: any) => {
      // Debug en desarrollo
      if (process.env.NODE_ENV === "development" && row.COD_CUENTA === "1") {
        console.log("DEBUG - Row keys:", Object.keys(row));
        console.log("DEBUG - DESCRIPCION:", row.DESCRIPCION, "Desc_Cta:", row.Desc_Cta);
      }
      
      return {
        codCuenta: row.Cod_Cuenta || row.COD_CUENTA || row.cod_cuenta,
        descripcion: row.DESCRIPCION || row.Desc_Cta || row.DESC_CTA || row.Desc_Cuenta || row.DESC_CUENTA || row.descripcion || "",
        tipo: row.TIPO || row.Tipo || row.tipo,
        nivel: row.Nivel || row.NIVEL || row.nivel || 1,
      };
    });

    return res.json({
      data: rows,
      page: 1,
      limit: 100,
      total: rows.length,
    });
  } catch (err: any) {
    // Fallback: devolver array vacío con mensaje
    return res.json({
      data: [],
      page: 1,
      limit: 50,
      total: 0,
      message: "Tabla Cuentas no disponible o estructura diferente",
      error: process.env.NODE_ENV === "development" ? String(err) : undefined,
    });
  }
});

// GET /v1/contabilidad/cuentas/:codCuenta - Obtener cuenta específica
contabilidadRouter.get("/cuentas/:codCuenta", async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request()
      .input("CodCuenta", sql.NVarChar(25), req.params.codCuenta)
      .query(`SELECT TOP 1 * FROM Cuentas WHERE Cod_Cuenta = @CodCuenta`);

    if (!result.recordset[0]) {
      return res.status(404).json({ error: "not_found" });
    }

    const row = result.recordset[0];
    return res.json({
      codCuenta: row.Cod_Cuenta || row.COD_CUENTA || row.cod_cuenta,
      descripcion: row.Desc_Cta || row.DESC_CTA || row.Desc_Cuenta || row.DESC_CUENTA || row.descripcion,
      tipo: row.Tipo || row.TIPO || row.tipo,
      nivel: row.Nivel || row.NIVEL || row.nivel,
    });
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

// ─── CRUD Cuentas ─────────────────────────────────────────────────

const cuentaBodySchema = z.object({
  codCuenta: z.string().min(1, "Código de cuenta requerido"),
  descripcion: z.string().min(1, "Descripción requerida"),
  tipo: z.string().min(1, "Tipo requerido"),
  nivel: z.number().int().min(1).max(10).default(1),
});

// POST /v1/contabilidad/cuentas - Crear cuenta contable
contabilidadRouter.post("/cuentas", async (req, res) => {
  const parsed = cuentaBodySchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const pool = await getPool();
    const { codCuenta, descripcion, tipo, nivel } = parsed.data;

    const exists = await pool.request()
      .input("CodCuenta", sql.NVarChar(25), codCuenta)
      .query(`SELECT 1 FROM Cuentas WHERE Cod_Cuenta = @CodCuenta`);

    if (exists.recordset.length > 0) {
      return res.status(409).json({ error: "duplicate", message: `La cuenta ${codCuenta} ya existe` });
    }

    await pool.request()
      .input("CodCuenta", sql.NVarChar(25), codCuenta)
      .input("Descripcion", sql.NVarChar(150), descripcion)
      .input("Tipo", sql.NVarChar(5), tipo)
      .input("Nivel", sql.Int, nivel)
      .query(`INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel) VALUES (@CodCuenta, @Descripcion, @Tipo, @Nivel)`);

    return res.status(201).json({ ok: true, codCuenta });
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

// PUT /v1/contabilidad/cuentas/:codCuenta - Actualizar cuenta contable
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
    const pool = await getPool();
    const codCuenta = req.params.codCuenta;

    const exists = await pool.request()
      .input("CodCuenta", sql.NVarChar(25), codCuenta)
      .query(`SELECT 1 FROM Cuentas WHERE Cod_Cuenta = @CodCuenta`);

    if (exists.recordset.length === 0) {
      return res.status(404).json({ error: "not_found", message: `Cuenta ${codCuenta} no encontrada` });
    }

    const sets: string[] = [];
    const request = pool.request().input("CodCuenta", sql.NVarChar(25), codCuenta);

    if (parsed.data.descripcion !== undefined) {
      sets.push("Desc_Cta = @Descripcion");
      request.input("Descripcion", sql.NVarChar(150), parsed.data.descripcion);
    }
    if (parsed.data.tipo !== undefined) {
      sets.push("Tipo = @Tipo");
      request.input("Tipo", sql.NVarChar(5), parsed.data.tipo);
    }
    if (parsed.data.nivel !== undefined) {
      sets.push("Nivel = @Nivel");
      request.input("Nivel", sql.Int, parsed.data.nivel);
    }

    if (sets.length === 0) {
      return res.status(400).json({ error: "no_fields", message: "No se proporcionaron campos para actualizar" });
    }

    await request.query(`UPDATE Cuentas SET ${sets.join(", ")} WHERE Cod_Cuenta = @CodCuenta`);
    return res.json({ ok: true, codCuenta });
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

// DELETE /v1/contabilidad/cuentas/:codCuenta - Eliminar cuenta contable
contabilidadRouter.delete("/cuentas/:codCuenta", async (req, res) => {
  try {
    const pool = await getPool();
    const codCuenta = req.params.codCuenta;

    const exists = await pool.request()
      .input("CodCuenta", sql.NVarChar(25), codCuenta)
      .query(`SELECT 1 FROM Cuentas WHERE Cod_Cuenta = @CodCuenta`);

    if (exists.recordset.length === 0) {
      return res.status(404).json({ error: "not_found", message: `Cuenta ${codCuenta} no encontrada` });
    }

    const hasMovements = await pool.request()
      .input("CodCuenta", sql.NVarChar(25), codCuenta)
      .query(`SELECT TOP 1 1 FROM DtllAsiento WHERE Cod_Cuenta = @CodCuenta`);

    if (hasMovements.recordset.length > 0) {
      return res.status(409).json({ error: "has_movements", message: "No se puede eliminar: la cuenta tiene movimientos contables" });
    }

    await pool.request()
      .input("CodCuenta", sql.NVarChar(25), codCuenta)
      .query(`DELETE FROM Cuentas WHERE Cod_Cuenta = @CodCuenta`);

    return res.json({ ok: true, codCuenta });
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});
