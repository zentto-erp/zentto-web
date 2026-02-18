import { Router } from "express";
import { z } from "zod";
import {
  listCentroCostoSP,
  getCentroCostoByCodigoSP,
  insertCentroCostoSP,
  updateCentroCostoSP,
  deleteCentroCostoSP,
} from "./centro-costo-sp.service.js";

export const centroCostoRouter = Router();

const listSchema = z.object({
  search: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional(),
});

const insertSchema = z.object({
  Codigo: z.string().min(1),
  Descripcion: z.string().min(1),
  Presupuestado: z.string().optional(),
  Saldo_Real: z.string().optional(),
});

const updateSchema = z.object({
  Descripcion: z.string().min(1).optional(),
  Presupuestado: z.string().optional(),
  Saldo_Real: z.string().optional(),
});

// GET /v1/centro-costo - Listar centros de costo
centroCostoRouter.get("/", async (req, res) => {
  const parsed = listSchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }

  const data = await listCentroCostoSP({
    search: parsed.data.search,
    page: parsed.data.page ? parseInt(parsed.data.page) : 1,
    limit: parsed.data.limit ? parseInt(parsed.data.limit) : 50,
  });

  return res.json(data);
});

// GET /v1/centro-costo/:codigo - Obtener centro de costo por código
centroCostoRouter.get("/:codigo", async (req, res) => {
  const data = await getCentroCostoByCodigoSP(req.params.codigo);
  if (!data) return res.status(404).json({ error: "not_found" });
  return res.json(data);
});

// POST /v1/centro-costo - Crear centro de costo
centroCostoRouter.post("/", async (req, res) => {
  const parsed = insertSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  const result = await insertCentroCostoSP(parsed.data);
  if (result.success) {
    return res.status(201).json({ success: true, message: result.message });
  } else {
    return res.status(400).json({ success: false, message: result.message });
  }
});

// PUT /v1/centro-costo/:codigo - Actualizar centro de costo
centroCostoRouter.put("/:codigo", async (req, res) => {
  const parsed = updateSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  const result = await updateCentroCostoSP(req.params.codigo, parsed.data);
  if (result.success) {
    return res.json({ success: true, message: result.message });
  } else {
    return res.status(400).json({ success: false, message: result.message });
  }
});

// DELETE /v1/centro-costo/:codigo - Eliminar centro de costo
centroCostoRouter.delete("/:codigo", async (req, res) => {
  const result = await deleteCentroCostoSP(req.params.codigo);
  if (result.success) {
    return res.json({ success: true, message: result.message });
  } else {
    return res.status(400).json({ success: false, message: result.message });
  }
});
