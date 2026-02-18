import { Router } from "express";
import { z } from "zod";
import {
  listBancosSP,
  getBancoByNombreSP,
  insertBancoSP,
  updateBancoSP,
  deleteBancoSP,
} from "./bancos-sp.service.js";
import {
  generarMovimientoBancario,
  crearConciliacion,
  listConciliaciones,
  getConciliacion,
  importarExtracto,
  conciliarMovimientos,
  generarAjusteBancario,
  cerrarConciliacion,
  getCuentasBancarias,
  getMovimientosCuenta,
} from "./conciliacion.service.js";

export const bancosRouter = Router();

const listSchema = z.object({
  search: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional(),
});

const insertSchema = z.object({
  Nombre: z.string().min(1),
  Contacto: z.string().optional(),
  Direccion: z.string().optional(),
  Telefonos: z.string().optional(),
  Co_Usuario: z.string().optional(),
});

const updateSchema = z.object({
  Contacto: z.string().optional(),
  Direccion: z.string().optional(),
  Telefonos: z.string().optional(),
  Co_Usuario: z.string().optional(),
});

// GET /v1/bancos - Listar bancos
bancosRouter.get("/", async (req, res) => {
  const parsed = listSchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }

  const data = await listBancosSP({
    search: parsed.data.search,
    page: parsed.data.page ? parseInt(parsed.data.page) : 1,
    limit: parsed.data.limit ? parseInt(parsed.data.limit) : 50,
  });

  return res.json(data);
});

// POST /v1/bancos - Crear banco
bancosRouter.post("/", async (req, res) => {
  const parsed = insertSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  const result = await insertBancoSP(parsed.data);
  if (result.success) {
    return res.status(201).json({ success: true, message: result.message });
  } else {
    return res.status(400).json({ success: false, message: result.message });
  }
});

// PUT /v1/bancos/:nombre - Actualizar banco
bancosRouter.put("/:nombre", async (req, res) => {
  const parsed = updateSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  const result = await updateBancoSP(req.params.nombre, parsed.data);
  if (result.success) {
    return res.json({ success: true, message: result.message });
  } else {
    return res.status(400).json({ success: false, message: result.message });
  }
});

// ============================================
// CUENTAS BANCARIAS
// ============================================

// GET /v1/bancos/cuentas/list - Listar cuentas bancarias
bancosRouter.get("/cuentas/list", async (req, res) => {
  try {
    const data = await getCuentasBancarias();
    res.json({ rows: data });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/bancos/cuentas/:nroCta/movimientos - Movimientos de cuenta
bancosRouter.get("/cuentas/:nroCta/movimientos", async (req, res) => {
  try {
    const { desde, hasta, page, limit } = req.query;
    const data = await getMovimientosCuenta(
      req.params.nroCta,
      desde as string,
      hasta as string,
      page ? parseInt(page as string) : 1,
      limit ? parseInt(limit as string) : 50
    );
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ============================================
// MOVIMIENTOS BANCARIOS
// ============================================

const movimientoSchema = z.object({
  Nro_Cta: z.string().min(1),
  Tipo: z.enum(["PCH", "DEP", "NCR", "NDB", "IDB"]),
  Nro_Ref: z.string().min(1),
  Beneficiario: z.string().min(1),
  Monto: z.number().positive(),
  Concepto: z.string().min(1),
  Categoria: z.string().optional(),
  Documento_Relacionado: z.string().optional(),
  Tipo_Doc_Rel: z.string().optional(),
});

// POST /v1/bancos/movimientos/generar - Generar movimiento
bancosRouter.post("/movimientos/generar", async (req, res) => {
  const parsed = movimientoSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const codUsuario = (req as any).user?.username || "API";
    const result = await generarMovimientoBancario(parsed.data, codUsuario);
    if (result.ok) {
      return res.status(201).json(result);
    } else {
      return res.status(400).json(result);
    }
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ============================================
// CONCILIACION BANCARIA
// ============================================

const conciliacionCreateSchema = z.object({
  Nro_Cta: z.string().min(1),
  Fecha_Desde: z.string().min(1),
  Fecha_Hasta: z.string().min(1),
});

// POST /v1/bancos/conciliaciones/crear - Crear conciliacion
bancosRouter.post("/conciliaciones/crear", async (req, res) => {
  const parsed = conciliacionCreateSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const codUsuario = (req as any).user?.username || "API";
    const result = await crearConciliacion(
      parsed.data.Nro_Cta,
      parsed.data.Fecha_Desde,
      parsed.data.Fecha_Hasta,
      codUsuario
    );
    res.status(201).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/bancos/conciliaciones - Listar conciliaciones
bancosRouter.get("/conciliaciones", async (req, res) => {
  try {
    const { Nro_Cta, Estado, page, limit } = req.query;
    const data = await listConciliaciones({
      Nro_Cta: Nro_Cta as string,
      Estado: Estado as string,
      page: page ? parseInt(page as string) : 1,
      limit: limit ? parseInt(limit as string) : 50,
    });
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/bancos/conciliaciones/:id - Obtener conciliacion
bancosRouter.get("/conciliaciones/:id", async (req, res) => {
  try {
    const id = parseInt(req.params.id);
    if (isNaN(id)) return res.status(400).json({ error: "invalid_id" });

    const data = await getConciliacion(id);
    if (!data.cabecera) return res.status(404).json({ error: "not_found" });
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/bancos/conciliaciones/:id/importar-extracto - Importar extracto
const extractoSchema = z.object({
  extracto: z.array(z.object({
    Fecha: z.string(),
    Descripcion: z.string().optional(),
    Referencia: z.string().optional(),
    Tipo: z.enum(["DEBITO", "CREDITO"]),
    Monto: z.number(),
    Saldo: z.number().optional(),
  })),
});

bancosRouter.post("/conciliaciones/:id/importar-extracto", async (req, res) => {
  const parsed = extractoSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const conciliacionId = parseInt(req.params.id);
    // Obtener Nro_Cta de la conciliacion
    const conc = await getConciliacion(conciliacionId);
    if (!conc.cabecera) return res.status(404).json({ error: "conciliacion_not_found" });

    const codUsuario = (req as any).user?.username || "API";
    const result = await importarExtracto(
      conc.cabecera.Nro_Cta!,
      parsed.data.extracto,
      codUsuario
    );
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/bancos/conciliaciones/conciliar - Conciliar movimientos
const conciliarSchema = z.object({
  Conciliacion_ID: z.number(),
  MovimientoSistema_ID: z.number(),
  Extracto_ID: z.number().optional(),
});

bancosRouter.post("/conciliaciones/conciliar", async (req, res) => {
  const parsed = conciliarSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const codUsuario = (req as any).user?.username || "API";
    const result = await conciliarMovimientos(
      parsed.data.Conciliacion_ID,
      parsed.data.MovimientoSistema_ID,
      parsed.data.Extracto_ID,
      codUsuario
    );
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/bancos/conciliaciones/ajuste - Generar ajuste
const ajusteSchema = z.object({
  Conciliacion_ID: z.number(),
  Tipo_Ajuste: z.enum(["NOTA_CREDITO", "NOTA_DEBITO"]),
  Monto: z.number().positive(),
  Descripcion: z.string().min(1),
});

bancosRouter.post("/conciliaciones/ajuste", async (req, res) => {
  const parsed = ajusteSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const codUsuario = (req as any).user?.username || "API";
    const result = await generarAjusteBancario(parsed.data, codUsuario);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/bancos/conciliaciones/cerrar - Cerrar conciliacion
const cerrarSchema = z.object({
  Conciliacion_ID: z.number(),
  Saldo_Final_Banco: z.number(),
  Observaciones: z.string().optional(),
});

bancosRouter.post("/conciliaciones/cerrar", async (req, res) => {
  const parsed = cerrarSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const codUsuario = (req as any).user?.username || "API";
    const result = await cerrarConciliacion(
      parsed.data.Conciliacion_ID,
      parsed.data.Saldo_Final_Banco,
      parsed.data.Observaciones,
      codUsuario
    );
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ============================================
// OPERACIONES CRUD INDIVIDUALES (DEBEN IR AL FINAL)
// ============================================

// GET /v1/bancos/:nombre - Obtener banco por nombre
bancosRouter.get("/:nombre", async (req, res) => {
  const data = await getBancoByNombreSP(req.params.nombre);
  if (!data) return res.status(404).json({ error: "not_found" });
  return res.json(data);
});

// PUT /v1/bancos/:nombre - Actualizar banco
bancosRouter.put("/:nombre", async (req, res) => {
  const parsed = updateSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  const result = await updateBancoSP(req.params.nombre, parsed.data);
  if (result.success) {
    return res.json({ success: true, message: result.message });
  } else {
    return res.status(400).json({ success: false, message: result.message });
  }
});

// DELETE /v1/bancos/:nombre - Eliminar banco
bancosRouter.delete("/:nombre", async (req, res) => {
  const result = await deleteBancoSP(req.params.nombre);
  if (result.success) {
    return res.json({ success: true, message: result.message });
  } else {
    return res.status(400).json({ success: false, message: result.message });
  }
});
