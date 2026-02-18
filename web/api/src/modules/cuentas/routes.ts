import { Router } from "express";
import { z } from "zod";
import {
  listCuentasSP,
  getCuentaByCodigoSP,
  insertCuentaSP,
  updateCuentaSP,
  deleteCuentaSP,
} from "./cuentas-sp.service.js";

export const cuentasRouter = Router();

const listSchema = z.object({
  search: z.string().optional(),
  tipo: z.string().optional(),
  grupo: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional(),
});

const insertSchema = z.object({
  COD_CUENTA: z.string().min(1),
  DESCRIPCION: z.string().min(1),
  TIPO: z.string().optional(),
  grupo: z.string().optional(),
  LINEA: z.string().optional(),
  USO: z.string().optional(),
  Nivel: z.number().optional(),
  Porcentaje: z.number().optional(),
});

const updateSchema = z.object({
  DESCRIPCION: z.string().min(1).optional(),
  TIPO: z.string().optional(),
  grupo: z.string().optional(),
  LINEA: z.string().optional(),
  USO: z.string().optional(),
  Nivel: z.number().optional(),
  Porcentaje: z.number().optional(),
});

// GET /v1/cuentas - Listar cuentas
cuentasRouter.get("/", async (req, res) => {
  const parsed = listSchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }

  const data = await listCuentasSP({
    search: parsed.data.search,
    tipo: parsed.data.tipo,
    grupo: parsed.data.grupo,
    page: parsed.data.page ? parseInt(parsed.data.page) : 1,
    limit: parsed.data.limit ? parseInt(parsed.data.limit) : 50,
  });

  return res.json(data);
});

// GET /v1/cuentas/:codCuenta - Obtener cuenta por código
cuentasRouter.get("/:codCuenta", async (req, res) => {
  const data = await getCuentaByCodigoSP(req.params.codCuenta);
  if (!data) return res.status(404).json({ error: "not_found" });
  return res.json(data);
});

// POST /v1/cuentas - Crear cuenta
cuentasRouter.post("/", async (req, res) => {
  const parsed = insertSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  const result = await insertCuentaSP(parsed.data);
  if (result.success) {
    return res.status(201).json({ success: true, message: result.message });
  } else {
    return res.status(400).json({ success: false, message: result.message });
  }
});

// PUT /v1/cuentas/:codCuenta - Actualizar cuenta
cuentasRouter.put("/:codCuenta", async (req, res) => {
  const parsed = updateSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  const result = await updateCuentaSP(req.params.codCuenta, parsed.data);
  if (result.success) {
    return res.json({ success: true, message: result.message });
  } else {
    return res.status(400).json({ success: false, message: result.message });
  }
});

// DELETE /v1/cuentas/:codCuenta - Eliminar cuenta
cuentasRouter.delete("/:codCuenta", async (req, res) => {
  const result = await deleteCuentaSP(req.params.codCuenta);
  if (result.success) {
    return res.json({ success: true, message: result.message });
  } else {
    return res.status(400).json({ success: false, message: result.message });
  }
});
