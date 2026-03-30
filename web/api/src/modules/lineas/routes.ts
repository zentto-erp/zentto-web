import { Router } from "express";
import { z } from "zod";
import {
  listLineasSP,
  getLineaByCodigoSP,
  insertLineaSP,
  updateLineaSP,
  deleteLineaSP,
} from "./lineas-sp.service.js";

export const lineasRouter = Router();

const listSchema = z.object({
  search: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional(),
});

const insertSchema = z.object({
  DESCRIPCION: z.string().min(1),
});

const updateSchema = z.object({
  DESCRIPCION: z.string().min(1).optional(),
});

// GET /v1/lineas - Listar lineas
lineasRouter.get("/", async (req, res) => {
  try {
    const parsed = listSchema.safeParse(req.query);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
    }

    const data = await listLineasSP({
      search: parsed.data.search,
      page: parsed.data.page ? parseInt(parsed.data.page) : 1,
      limit: parsed.data.limit ? parseInt(parsed.data.limit) : 50,
    });

    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

// GET /v1/lineas/:codigo - Obtener linea por código
lineasRouter.get("/:codigo", async (req, res) => {
  try {
    const codigo = parseInt(req.params.codigo);
    if (isNaN(codigo)) return res.status(400).json({ error: "invalid_codigo" });

    const data = await getLineaByCodigoSP(codigo);
    if (!data) return res.status(404).json({ error: "not_found" });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

// POST /v1/lineas - Crear linea
lineasRouter.post("/", async (req, res) => {
  try {
    const parsed = insertSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    }

    const result = await insertLineaSP(parsed.data);
    if (result.success) {
      return res.status(201).json({
        success: true,
        message: result.message,
        codigo: result.nuevoCodigo
      });
    } else {
      return res.status(400).json({ success: false, message: result.message });
    }
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

// PUT /v1/lineas/:codigo - Actualizar linea
lineasRouter.put("/:codigo", async (req, res) => {
  try {
    const codigo = parseInt(req.params.codigo);
    if (isNaN(codigo)) return res.status(400).json({ error: "invalid_codigo" });

    const parsed = updateSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    }

    const result = await updateLineaSP(codigo, parsed.data);
    if (result.success) {
      return res.json({ success: true, message: result.message });
    } else {
      return res.status(400).json({ success: false, message: result.message });
    }
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

// DELETE /v1/lineas/:codigo - Eliminar linea
lineasRouter.delete("/:codigo", async (req, res) => {
  try {
    const codigo = parseInt(req.params.codigo);
    if (isNaN(codigo)) return res.status(400).json({ error: "invalid_codigo" });

    const result = await deleteLineaSP(codigo);
    if (result.success) {
      return res.json({ success: true, message: result.message });
    } else {
      return res.status(400).json({ success: false, message: result.message });
    }
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});
