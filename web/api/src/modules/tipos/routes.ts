import { Router } from "express";
import { z } from "zod";
import {
  listTiposSP,
  getTipoByCodigoSP,
  insertTipoSP,
  updateTipoSP,
  deleteTipoSP,
} from "./tipos-sp.service.js";

export const tiposRouter = Router();

const listSchema = z.object({
  search: z.string().optional(),
  categoria: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional(),
});

const insertSchema = z.object({
  Categoria: z.string().min(1),
  Nombre: z.string().min(1),
  Co_Usuario: z.string().optional(),
});

const updateSchema = z.object({
  Categoria: z.string().min(1).optional(),
  Nombre: z.string().min(1).optional(),
  Co_Usuario: z.string().optional(),
});

// GET /v1/tipos - Listar tipos
tiposRouter.get("/", async (req, res) => {
  const parsed = listSchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }

  const data = await listTiposSP({
    search: parsed.data.search,
    categoria: parsed.data.categoria,
    page: parsed.data.page ? parseInt(parsed.data.page) : 1,
    limit: parsed.data.limit ? parseInt(parsed.data.limit) : 50,
  });

  return res.json(data);
});

// GET /v1/tipos/:codigo - Obtener tipo por código
tiposRouter.get("/:codigo", async (req, res) => {
  const codigo = parseInt(req.params.codigo);
  if (isNaN(codigo)) return res.status(400).json({ error: "invalid_codigo" });

  const data = await getTipoByCodigoSP(codigo);
  if (!data) return res.status(404).json({ error: "not_found" });
  return res.json(data);
});

// POST /v1/tipos - Crear tipo
tiposRouter.post("/", async (req, res) => {
  const parsed = insertSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  const result = await insertTipoSP(parsed.data);
  if (result.success) {
    return res.status(201).json({ 
      success: true, 
      message: result.message,
      codigo: result.nuevoCodigo 
    });
  } else {
    return res.status(400).json({ success: false, message: result.message });
  }
});

// PUT /v1/tipos/:codigo - Actualizar tipo
tiposRouter.put("/:codigo", async (req, res) => {
  const codigo = parseInt(req.params.codigo);
  if (isNaN(codigo)) return res.status(400).json({ error: "invalid_codigo" });

  const parsed = updateSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  const result = await updateTipoSP(codigo, parsed.data);
  if (result.success) {
    return res.json({ success: true, message: result.message });
  } else {
    return res.status(400).json({ success: false, message: result.message });
  }
});

// DELETE /v1/tipos/:codigo - Eliminar tipo
tiposRouter.delete("/:codigo", async (req, res) => {
  const codigo = parseInt(req.params.codigo);
  if (isNaN(codigo)) return res.status(400).json({ error: "invalid_codigo" });

  const result = await deleteTipoSP(codigo);
  if (result.success) {
    return res.json({ success: true, message: result.message });
  } else {
    return res.status(400).json({ success: false, message: result.message });
  }
});
