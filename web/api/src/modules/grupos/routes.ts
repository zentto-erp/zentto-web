import { Router } from "express";
import { z } from "zod";
import {
  listGruposSP,
  getGrupoByCodigoSP,
  insertGrupoSP,
  updateGrupoSP,
  deleteGrupoSP,
} from "./grupos-sp.service.js";

export const gruposRouter = Router();

const listSchema = z.object({
  search: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional(),
});

const insertSchema = z.object({
  Descripcion: z.string().min(1),
  Co_Usuario: z.string().optional(),
  Porcentaje: z.number().optional(),
});

const updateSchema = z.object({
  Descripcion: z.string().min(1).optional(),
  Co_Usuario: z.string().optional(),
  Porcentaje: z.number().optional(),
});

// GET /v1/grupos - Listar grupos
gruposRouter.get("/", async (req, res) => {
  try {
    const parsed = listSchema.safeParse(req.query);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
    }

    const data = await listGruposSP({
      search: parsed.data.search,
      page: parsed.data.page ? parseInt(parsed.data.page) : 1,
      limit: parsed.data.limit ? parseInt(parsed.data.limit) : 50,
    });

    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

// GET /v1/grupos/:codigo - Obtener grupo por código
gruposRouter.get("/:codigo", async (req, res) => {
  try {
    const codigo = parseInt(req.params.codigo);
    if (isNaN(codigo)) return res.status(400).json({ error: "invalid_codigo" });

    const data = await getGrupoByCodigoSP(codigo);
    if (!data) return res.status(404).json({ error: "not_found" });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

// POST /v1/grupos - Crear grupo
gruposRouter.post("/", async (req, res) => {
  try {
    const parsed = insertSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    }

    const result = await insertGrupoSP(parsed.data);
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

// PUT /v1/grupos/:codigo - Actualizar grupo
gruposRouter.put("/:codigo", async (req, res) => {
  try {
    const codigo = parseInt(req.params.codigo);
    if (isNaN(codigo)) return res.status(400).json({ error: "invalid_codigo" });

    const parsed = updateSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    }

    const result = await updateGrupoSP(codigo, parsed.data);
    if (result.success) {
      return res.json({ success: true, message: result.message });
    } else {
      return res.status(400).json({ success: false, message: result.message });
    }
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

// DELETE /v1/grupos/:codigo - Eliminar grupo
gruposRouter.delete("/:codigo", async (req, res) => {
  try {
    const codigo = parseInt(req.params.codigo);
    if (isNaN(codigo)) return res.status(400).json({ error: "invalid_codigo" });

    const result = await deleteGrupoSP(codigo);
    if (result.success) {
      return res.json({ success: true, message: result.message });
    } else {
      return res.status(400).json({ success: false, message: result.message });
    }
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});
