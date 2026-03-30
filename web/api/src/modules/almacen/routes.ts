import { Router } from "express";
import { z } from "zod";
import {
  listAlmacenSP,
  getAlmacenByCodigoSP,
  insertAlmacenSP,
  updateAlmacenSP,
  deleteAlmacenSP,
} from "./almacen-sp.service.js";

export const almacenRouter = Router();

const listSchema = z.object({
  search: z.string().optional(),
  tipo: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional(),
});

const insertSchema = z.object({
  Codigo: z.string().min(1).max(10),
  Descripcion: z.string().min(1),
  Tipo: z.string().optional(),
});

const updateSchema = z.object({
  Descripcion: z.string().min(1).optional(),
  Tipo: z.string().optional(),
});

// GET /v1/almacen - Listar almacenes
almacenRouter.get("/", async (req, res) => {
  try {
    const parsed = listSchema.safeParse(req.query);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
    }

    const data = await listAlmacenSP({
      search: parsed.data.search,
      tipo: parsed.data.tipo,
      page: parsed.data.page ? parseInt(parsed.data.page) : 1,
      limit: parsed.data.limit ? parseInt(parsed.data.limit) : 50,
    });

    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

// GET /v1/almacen/:codigo - Obtener almacén por código
almacenRouter.get("/:codigo", async (req, res) => {
  try {
    const data = await getAlmacenByCodigoSP(req.params.codigo);
    if (!data) return res.status(404).json({ error: "not_found" });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

// POST /v1/almacen - Crear almacén
almacenRouter.post("/", async (req, res) => {
  try {
    const parsed = insertSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    }

    const result = await insertAlmacenSP(parsed.data);
    if (result.success) {
      return res.status(201).json({ success: true, message: result.message });
    } else {
      return res.status(400).json({ success: false, message: result.message });
    }
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

// PUT /v1/almacen/:codigo - Actualizar almacén
almacenRouter.put("/:codigo", async (req, res) => {
  try {
    const parsed = updateSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    }

    const result = await updateAlmacenSP(req.params.codigo, parsed.data);
    if (result.success) {
      return res.json({ success: true, message: result.message });
    } else {
      return res.status(400).json({ success: false, message: result.message });
    }
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

// DELETE /v1/almacen/:codigo - Eliminar almacén
almacenRouter.delete("/:codigo", async (req, res) => {
  try {
    const result = await deleteAlmacenSP(req.params.codigo);
    if (result.success) {
      return res.json({ success: true, message: result.message });
    } else {
      return res.status(400).json({ success: false, message: result.message });
    }
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});
