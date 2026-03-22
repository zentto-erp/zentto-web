import { Router } from "express";
import { z } from "zod";
import { emitBusinessNotification } from "../_shared/notify.js";
import { advancedRouter } from "./routes-advanced.js";
import { legalRouter } from "./routes-legal.js";
import { activosFijosRouter } from "./activos-fijos.routes.js";
import { fiscalTributariaRouter } from "./fiscal-tributaria.routes.js";
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
  seedPlanCuentas,
  getDefaultCompanyId,
  normalizeTipoCuenta,
  listCuentas,
  getCuenta,
  insertCuenta,
  updateCuenta,
  deleteCuenta,
  libroDiario,
  dashboardResumen
} from "./service.js";

export const contabilidadRouter = Router();

contabilidadRouter.use("/", advancedRouter);
contabilidadRouter.use("/", legalRouter);
contabilidadRouter.use("/activos-fijos", activosFijosRouter);
contabilidadRouter.use("/fiscal", fiscalTributariaRouter);

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
  try {
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
  } catch (err: any) { return res.status(500).json({ error: err.message }); }
});

contabilidadRouter.get("/asientos/:id", async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) {
      return res.status(400).json({ error: "invalid_id" });
    }
    const data = await getAsiento(id);
    if (!data.cabecera) return res.status(404).json({ error: "not_found" });
    return res.json(data);
  } catch (err: any) { return res.status(500).json({ error: err.message }); }
});

contabilidadRouter.post("/asientos", async (req, res) => {
  try {
    const parsed = crearAsientoSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    }
    const user = (req as any).user?.username || "API";
    const result = await crearAsiento(parsed.data, user);
    if (!result.ok) return res.status(400).json(result);
    if (result.ok) {
      emitBusinessNotification({
        event: "INVOICE_CREATED",
        to: "contabilidad@empresa.com",
        subject: `Asiento contable ${result.numeroAsiento ?? ""} creado`,
        data: { Asiento: String(result.numeroAsiento ?? ""), Concepto: String(req.body.concepto ?? ""), Debe: String(req.body.totalDebe ?? "0"), Haber: String(req.body.totalHaber ?? "0") },
      }).catch(() => {});
    }
    return res.status(201).json(result);
  } catch (err: any) { return res.status(500).json({ error: err.message }); }
});

contabilidadRouter.post("/asientos/:id/anular", async (req, res) => {
  try {
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
  } catch (err: any) { return res.status(500).json({ error: err.message }); }
});

contabilidadRouter.post("/ajustes", async (req, res) => {
  try {
    const parsed = ajusteSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    }
    const user = (req as any).user?.username || "API";
    const result = await crearAjuste(parsed.data, user);
    if (!result.ok) return res.status(400).json(result);
    return res.status(201).json(result);
  } catch (err: any) { return res.status(500).json({ error: err.message }); }
});

contabilidadRouter.post("/depreciaciones/generar", async (req, res) => {
  try {
    const parsed = depreciacionSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    }
    const user = (req as any).user?.username || "API";
    const result = await generarDepreciacion(parsed.data.periodo, parsed.data.centroCosto, user);
    if (!result.ok) return res.status(400).json(result);
    if (result.ok) {
      emitBusinessNotification({
        event: "PAYROLL_PROCESSED",
        to: "contabilidad@empresa.com",
        subject: `Depreciación ${req.body.periodCode ?? ""} generada`,
        data: { Periodo: String(req.body.periodCode ?? ""), Asientos: String(result.entriesGenerated ?? "0") },
      }).catch(() => {});
    }
    return res.status(201).json(result);
  } catch (err: any) { return res.status(500).json({ error: err.message }); }
});

contabilidadRouter.get("/reportes/libro-mayor", async (req, res) => {
  try {
    const parsed = rangoSchema.safeParse(req.query);
    if (!parsed.success) return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
    const rows = await libroMayor(parsed.data.fechaDesde, parsed.data.fechaHasta);
    return res.json({ rows });
  } catch (err: any) { return res.status(500).json({ error: err.message }); }
});

contabilidadRouter.get("/reportes/mayor-analitico", async (req, res) => {
  try {
    const parsed = mayorAnaliticoSchema.safeParse(req.query);
    if (!parsed.success) return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
    const rows = await mayorAnalitico(parsed.data.codCuenta, parsed.data.fechaDesde, parsed.data.fechaHasta);
    return res.json({ rows });
  } catch (err: any) { return res.status(500).json({ error: err.message }); }
});

contabilidadRouter.get("/reportes/balance-comprobacion", async (req, res) => {
  try {
    const parsed = rangoSchema.safeParse(req.query);
    if (!parsed.success) return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
    const rows = await balanceComprobacion(parsed.data.fechaDesde, parsed.data.fechaHasta);
    return res.json({ rows });
  } catch (err: any) { return res.status(500).json({ error: err.message }); }
});

contabilidadRouter.get("/reportes/estado-resultados", async (req, res) => {
  try {
    const parsed = rangoSchema.safeParse(req.query);
    if (!parsed.success) return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
    const data = await estadoResultados(parsed.data.fechaDesde, parsed.data.fechaHasta);
    return res.json(data);
  } catch (err: any) { return res.status(500).json({ error: err.message }); }
});

contabilidadRouter.get("/reportes/balance-general", async (req, res) => {
  try {
    const parsed = balanceGeneralSchema.safeParse(req.query);
    if (!parsed.success) return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
    const data = await balanceGeneral(parsed.data.fechaCorte);
    return res.json(data);
  } catch (err: any) { return res.status(500).json({ error: err.message }); }
});

contabilidadRouter.get("/reportes/libro-diario", async (req, res) => {
  try {
    const parsed = rangoSchema.safeParse(req.query);
    if (!parsed.success) return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
    const rows = await libroDiario(parsed.data.fechaDesde, parsed.data.fechaHasta);
    return res.json({ rows });
  } catch (err: any) { return res.status(500).json({ error: err.message }); }
});

contabilidadRouter.get("/dashboard/resumen", async (req, res) => {
  try {
    const parsed = rangoSchema.safeParse(req.query);
    if (!parsed.success) return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
    const data = await dashboardResumen(parsed.data.fechaDesde, parsed.data.fechaHasta);
    return res.json(data);
  } catch (err: any) { return res.status(500).json({ error: err.message }); }
});

contabilidadRouter.post("/setup/seed-plan-cuentas", async (req, res) => {
  try {
    const user = (req as any).user?.username || "API";
    const data = await seedPlanCuentas(user);
    return res.status(201).json(data);
  } catch (err: any) { return res.status(500).json({ error: err.message }); }
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

    if (parsed.data.nivel) {
      const nivel = Number(parsed.data.nivel);
      if (!Number.isFinite(nivel) || nivel < 1) return res.status(400).json({ error: "invalid_nivel" });
    }

    const result = await listCuentas({
      companyId,
      search: parsed.data.search,
      tipo: tipo || undefined,
      nivel: parsed.data.nivel ? Number(parsed.data.nivel) : undefined,
      activo: String(parsed.data.activo ?? "true").toLowerCase() !== "false",
      page: Number(parsed.data.page ?? "1") || 1,
      limit: Number(parsed.data.limit ?? "50") || 50
    });

    return res.json(result);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

// GET /v1/contabilidad/cuentas/:codCuenta
contabilidadRouter.get("/cuentas/:codCuenta", async (req, res) => {
  try {
    const companyId = await getDefaultCompanyId();
    const cuenta = await getCuenta(companyId, req.params.codCuenta);

    if (!cuenta) return res.status(404).json({ error: "not_found" });
    return res.json(cuenta);
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

    const result = await insertCuenta({
      companyId,
      codCuenta,
      descripcion,
      tipo: normalizedTipo,
      nivel
    });

    if (!result.ok) {
      // El SP retorna mensaje indicando duplicado
      if (result.mensaje.includes("Ya existe")) {
        return res.status(409).json({ error: "duplicate", message: result.mensaje });
      }
      return res.status(400).json({ error: "insert_failed", message: result.mensaje });
    }

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

    if (!parsed.data.descripcion && !parsed.data.tipo && parsed.data.nivel === undefined) {
      return res.status(400).json({ error: "no_fields", message: "No se proporcionaron campos para actualizar" });
    }

    const result = await updateCuenta({
      companyId,
      codCuenta,
      descripcion: parsed.data.descripcion,
      tipo: normalizedTipo || undefined,
      nivel: parsed.data.nivel
    });

    if (!result.ok) {
      if (result.mensaje.includes("No se encontro")) {
        return res.status(404).json({ error: "not_found", message: result.mensaje });
      }
      return res.status(400).json({ error: "update_failed", message: result.mensaje });
    }

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

    const result = await deleteCuenta({ companyId, codCuenta });

    if (!result.ok) {
      if (result.mensaje.includes("No se encontro") || result.mensaje.includes("ya fue eliminada")) {
        return res.status(404).json({ error: "not_found", message: result.mensaje });
      }
      if (result.mensaje.includes("cuentas hijas")) {
        return res.status(409).json({ error: "has_children", message: result.mensaje });
      }
      return res.status(400).json({ error: "delete_failed", message: result.mensaje });
    }

    return res.json({ ok: true, codCuenta });
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});
