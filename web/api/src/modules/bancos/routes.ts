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
  getMovimientoById,
  insertCuentaBancaria,
  updateCuentaBancaria,
  deleteCuentaBancaria,
} from "./conciliacion.service.js";
import { emitBankMovementAccountingEntry, linkMovementToEntry, getLinkedEntries } from "./bancos-contabilidad.service.js";
import { emitBusinessNotification } from "../_shared/notify.js";
import {
  listCajaChicaBoxes,
  createCajaChicaBox,
  openSession,
  closeSession,
  getActiveSession,
  addExpense,
  listExpenses,
  getCajaChicaSummary,
} from "./caja-chica.service.js";

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

// POST /v1/bancos/cuentas - Crear cuenta bancaria
bancosRouter.post("/cuentas", async (req, res) => {
  try {
    const result = await insertCuentaBancaria(req.body);
    if (result.ok) return res.json({ success: true, message: result.mensaje, id: result.id });
    return res.status(400).json({ success: false, message: result.mensaje });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// PUT /v1/bancos/cuentas/:id - Actualizar cuenta bancaria
bancosRouter.put("/cuentas/:id", async (req, res) => {
  try {
    const result = await updateCuentaBancaria(Number(req.params.id), req.body);
    if (result.ok) return res.json({ success: true, message: result.mensaje });
    return res.status(400).json({ success: false, message: result.mensaje });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// DELETE /v1/bancos/cuentas/:id - Desactivar cuenta bancaria
bancosRouter.delete("/cuentas/:id", async (req, res) => {
  try {
    const result = await deleteCuentaBancaria(Number(req.params.id));
    if (result.ok) return res.json({ success: true, message: result.mensaje });
    return res.status(400).json({ success: false, message: result.mensaje });
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

// GET /v1/bancos/movimientos/:id - Obtener movimiento por ID (voucher)
bancosRouter.get("/movimientos/:id", async (req, res) => {
  try {
    const id = parseInt(req.params.id);
    if (isNaN(id)) return res.status(400).json({ error: "invalid_id" });
    const data = await getMovimientoById(id);
    if (!data) return res.status(404).json({ error: "not_found" });
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
      // Generate accounting entry (best effort, never blocks)
      let contabilidad: { ok: boolean; asientoId?: number | null; numeroAsiento?: string | null } = { ok: false };
      try {
        if (result.movimientoId) {
          contabilidad = await emitBankMovementAccountingEntry({
            movimientoId: result.movimientoId,
            nroCta: parsed.data.Nro_Cta,
            tipo: parsed.data.Tipo,
            monto: parsed.data.Monto,
            beneficiario: parsed.data.Beneficiario,
            concepto: parsed.data.Concepto,
            nroRef: parsed.data.Nro_Ref,
          }, codUsuario);
          // Link movement to journal entry
          if (contabilidad.ok && contabilidad.asientoId && result.movimientoId) {
            await linkMovementToEntry(result.movimientoId, contabilidad.asientoId);
          }
        }
      } catch {
        // Never block the bank operation
      }
      // Notify: movimiento bancario (best-effort)
      emitBusinessNotification({
        event: "BANK_MOVEMENT_RECORDED",
        to: String(parsed.data.Beneficiario ?? ""),
        subject: `Movimiento bancario ${parsed.data.Tipo} registrado`,
        data: { Tipo: parsed.data.Tipo, Cuenta: parsed.data.Nro_Cta, Monto: String(parsed.data.Monto), Beneficiario: String(parsed.data.Beneficiario ?? ""), Referencia: String(parsed.data.Nro_Ref ?? "") },
      }).catch(() => {});
      return res.status(201).json({ ...result, contabilidad });
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

// POST /v1/bancos/conciliaciones - Alias de /conciliaciones/crear
bancosRouter.post("/conciliaciones", async (req, res) => {
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

// GET /v1/bancos/conciliaciones/:id/asientos - Asientos vinculados a conciliacion
bancosRouter.get("/conciliaciones/:id/asientos", async (req, res) => {
  const id = parseInt(req.params.id);
  if (isNaN(id)) return res.status(400).json({ error: "invalid_id" });
  try {
    const rows = await getLinkedEntries(id);
    res.json({ rows });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ============================================
// CAJA CHICA
// ============================================

// GET /v1/bancos/caja-chica - Listar cajas chicas
bancosRouter.get("/caja-chica", async (req, res) => {
  try {
    const data = await listCajaChicaBoxes();
    res.json({ rows: data });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/bancos/caja-chica - Crear caja chica
const cajaChicaCreateSchema = z.object({
  name: z.string().min(1),
  accountCode: z.string().optional(),
  maxAmount: z.number().min(0),
  responsible: z.string().optional(),
});

bancosRouter.post("/caja-chica", async (req, res) => {
  const parsed = cajaChicaCreateSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const codUsuario = (req as any).user?.username || "API";
    const result = await createCajaChicaBox(parsed.data, codUsuario);
    res.status(201).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/bancos/caja-chica/:boxId/abrir - Abrir sesión
const abrirSesionSchema = z.object({
  openingAmount: z.number().min(0),
});

bancosRouter.post("/caja-chica/:boxId/abrir", async (req, res) => {
  const parsed = abrirSesionSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const boxId = parseInt(req.params.boxId);
    if (isNaN(boxId)) return res.status(400).json({ error: "invalid_boxId" });
    const codUsuario = (req as any).user?.username || "API";
    const result = await openSession(boxId, parsed.data.openingAmount, codUsuario);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/bancos/caja-chica/:boxId/cerrar - Cerrar sesión
const cerrarSesionSchema = z.object({
  notes: z.string().optional(),
});

bancosRouter.post("/caja-chica/:boxId/cerrar", async (req, res) => {
  const parsed = cerrarSesionSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const boxId = parseInt(req.params.boxId);
    if (isNaN(boxId)) return res.status(400).json({ error: "invalid_boxId" });
    const codUsuario = (req as any).user?.username || "API";
    const result = await closeSession(boxId, parsed.data.notes, codUsuario);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/bancos/caja-chica/:boxId/sesion-activa - Sesión activa
bancosRouter.get("/caja-chica/:boxId/sesion-activa", async (req, res) => {
  try {
    const boxId = parseInt(req.params.boxId);
    if (isNaN(boxId)) return res.status(400).json({ error: "invalid_boxId" });
    const data = await getActiveSession(boxId);
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/bancos/caja-chica/:boxId/gastos - Registrar gasto
const gastoSchema = z.object({
  sessionId: z.number(),
  category: z.string().min(1),
  description: z.string().min(1),
  amount: z.number().positive(),
  beneficiary: z.string().optional(),
  receiptNumber: z.string().optional(),
  accountCode: z.string().optional(),
});

bancosRouter.post("/caja-chica/:boxId/gastos", async (req, res) => {
  const parsed = gastoSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const boxId = parseInt(req.params.boxId);
    if (isNaN(boxId)) return res.status(400).json({ error: "invalid_boxId" });
    const codUsuario = (req as any).user?.username || "API";
    const result = await addExpense({ ...parsed.data, boxId }, codUsuario);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/bancos/caja-chica/:boxId/gastos - Listar gastos
bancosRouter.get("/caja-chica/:boxId/gastos", async (req, res) => {
  try {
    const boxId = parseInt(req.params.boxId);
    if (isNaN(boxId)) return res.status(400).json({ error: "invalid_boxId" });
    const sessionId = req.query.sessionId ? parseInt(req.query.sessionId as string) : undefined;
    const data = await listExpenses(boxId, sessionId);
    res.json({ rows: data });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/bancos/caja-chica/:boxId/resumen - Resumen caja chica
bancosRouter.get("/caja-chica/:boxId/resumen", async (req, res) => {
  try {
    const boxId = parseInt(req.params.boxId);
    if (isNaN(boxId)) return res.status(400).json({ error: "invalid_boxId" });
    const data = await getCajaChicaSummary(boxId);
    res.json(data);
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
