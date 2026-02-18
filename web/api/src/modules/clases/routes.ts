import { Router } from "express";
import { z } from "zod";
import {
  listClasesSP,
  getClaseByCodigoSP,
  insertClaseSP,
  updateClaseSP,
  deleteClaseSP,
} from "./clases-sp.service.js";

export const clasesRouter = Router();

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

// GET /v1/clases - Listar clases
clasesRouter.get("/", async (req, res) => {
  const parsed = listSchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }

  const data = await listClasesSP({
    search: parsed.data.search,
    page: parsed.data.page ? parseInt(parsed.data.page) : 1,
    limit: parsed.data.limit ? parseInt(parsed.data.limit) : 50,
  });

  return res.json(data);
});

// GET /v1/clases/:codigo - Obtener clase por código
clasesRouter.get("/:codigo", async (req, res) => {
  const codigo = parseInt(req.params.codigo);
  if (isNaN(codigo)) return res.status(400).json({ error: "invalid_codigo" });

  const data = await getClaseByCodigoSP(codigo);
  if (!data) return res.status(404).json({ error: "not_found" });
  return res.json(data);
});

// POST /v1/clases - Crear clase
clasesRouter.post("/", async (req, res) => {
  const parsed = insertSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  const result = await insertClaseSP(parsed.data);
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

// PUT /v1/clases/:codigo - Actualizar clase
clasesRouter.put("/:codigo", async (req, res) => {
  const codigo = parseInt(req.params.codigo);
  if (isNaN(codigo)) return res.status(400).json({ error: "invalid_codigo" });

  const parsed = updateSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  const result = await updateClaseSP(codigo, parsed.data);
  if (result.success) {
    return res.json({ success: true, message: result.message });
  } else {
    return res.status(400).json({ success: false, message: result.message });
  }
});

// DELETE /v1/clases/:codigo - Eliminar clase
clasesRouter.delete("/:codigo", async (req, res) => {
  const codigo = parseInt(req.params.codigo);
  if (isNaN(codigo)) return res.status(400).json({ error: "invalid_codigo" });

  const result = await deleteClaseSP(codigo);
  if (result.success) {
    return res.json({ success: true, message: result.message });
  } else {
    return res.status(400).json({ success: false, message: result.message });
  }
});
