import { Router } from "express";
import { z } from "zod";
import {
  listMarcasSP,
  getMarcaByCodigoSP,
  insertMarcaSP,
  updateMarcaSP,
  deleteMarcaSP,
} from "./marcas-sp.service.js";

export const marcasRouter = Router();

const listSchema = z.object({
  search: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional(),
});

const insertSchema = z.object({
  Descripcion: z.string().min(1),
});

const updateSchema = z.object({
  Descripcion: z.string().min(1).optional(),
});

// GET /v1/marcas - Listar marcas
marcasRouter.get("/", async (req, res) => {
  try {
    const parsed = listSchema.safeParse(req.query);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
    }

    const data = await listMarcasSP({
      search: parsed.data.search,
      page: parsed.data.page ? parseInt(parsed.data.page) : 1,
      limit: parsed.data.limit ? parseInt(parsed.data.limit) : 50,
    });

    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

// GET /v1/marcas/:codigo - Obtener marca por código
marcasRouter.get("/:codigo", async (req, res) => {
  try {
    const codigo = parseInt(req.params.codigo);
    if (isNaN(codigo)) return res.status(400).json({ error: "invalid_codigo" });

    const data = await getMarcaByCodigoSP(codigo);
    if (!data) return res.status(404).json({ error: "not_found" });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

// POST /v1/marcas - Crear marca
marcasRouter.post("/", async (req, res) => {
  try {
    const parsed = insertSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    }

    const result = await insertMarcaSP(parsed.data);
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

// PUT /v1/marcas/:codigo - Actualizar marca
marcasRouter.put("/:codigo", async (req, res) => {
  try {
    const codigo = parseInt(req.params.codigo);
    if (isNaN(codigo)) return res.status(400).json({ error: "invalid_codigo" });

    const parsed = updateSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    }

    const result = await updateMarcaSP(codigo, parsed.data);
    if (result.success) {
      return res.json({ success: true, message: result.message });
    } else {
      return res.status(400).json({ success: false, message: result.message });
    }
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

// DELETE /v1/marcas/:codigo - Eliminar marca
marcasRouter.delete("/:codigo", async (req, res) => {
  try {
    const codigo = parseInt(req.params.codigo);
    if (isNaN(codigo)) return res.status(400).json({ error: "invalid_codigo" });

    const result = await deleteMarcaSP(codigo);
    if (result.success) {
      return res.json({ success: true, message: result.message });
    } else {
      return res.status(400).json({ success: false, message: result.message });
    }
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});
