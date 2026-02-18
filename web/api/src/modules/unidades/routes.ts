import { Router } from "express";
import { z } from "zod";
import {
  listUnidadesSP,
  getUnidadByIdSP,
  insertUnidadSP,
  updateUnidadSP,
  deleteUnidadSP,
} from "./unidades-sp.service.js";

export const unidadesRouter = Router();

const listSchema = z.object({
  search: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional(),
});

const insertSchema = z.object({
  Unidad: z.string().min(1),
  Cantidad: z.number().optional(),
});

const updateSchema = z.object({
  Unidad: z.string().min(1).optional(),
  Cantidad: z.number().optional(),
});

// GET /v1/unidades - Listar unidades
unidadesRouter.get("/", async (req, res) => {
  const parsed = listSchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }

  const data = await listUnidadesSP({
    search: parsed.data.search,
    page: parsed.data.page ? parseInt(parsed.data.page) : 1,
    limit: parsed.data.limit ? parseInt(parsed.data.limit) : 50,
  });

  return res.json(data);
});

// GET /v1/unidades/:id - Obtener unidad por id
unidadesRouter.get("/:id", async (req, res) => {
  const id = parseInt(req.params.id);
  if (isNaN(id)) return res.status(400).json({ error: "invalid_id" });

  const data = await getUnidadByIdSP(id);
  if (!data) return res.status(404).json({ error: "not_found" });
  return res.json(data);
});

// POST /v1/unidades - Crear unidad
unidadesRouter.post("/", async (req, res) => {
  const parsed = insertSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  const result = await insertUnidadSP(parsed.data);
  if (result.success) {
    return res.status(201).json({ 
      success: true, 
      message: result.message,
      id: result.nuevoId 
    });
  } else {
    return res.status(400).json({ success: false, message: result.message });
  }
});

// PUT /v1/unidades/:id - Actualizar unidad
unidadesRouter.put("/:id", async (req, res) => {
  const id = parseInt(req.params.id);
  if (isNaN(id)) return res.status(400).json({ error: "invalid_id" });

  const parsed = updateSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  const result = await updateUnidadSP(id, parsed.data);
  if (result.success) {
    return res.json({ success: true, message: result.message });
  } else {
    return res.status(400).json({ success: false, message: result.message });
  }
});

// DELETE /v1/unidades/:id - Eliminar unidad
unidadesRouter.delete("/:id", async (req, res) => {
  const id = parseInt(req.params.id);
  if (isNaN(id)) return res.status(400).json({ error: "invalid_id" });

  const result = await deleteUnidadSP(id);
  if (result.success) {
    return res.json({ success: true, message: result.message });
  } else {
    return res.status(400).json({ success: false, message: result.message });
  }
});
