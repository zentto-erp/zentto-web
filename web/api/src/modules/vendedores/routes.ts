import { Router } from "express";
import { z } from "zod";
import {
  listVendedoresSP,
  getVendedorByCodigoSP,
  insertVendedorSP,
  updateVendedorSP,
  deleteVendedorSP,
} from "./vendedores-sp.service.js";

export const vendedoresRouter = Router();

const listSchema = z.object({
  search: z.string().optional(),
  status: z.enum(["true", "false"]).optional(),
  tipo: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional(),
});

const insertSchema = z.object({
  Codigo: z.string().min(1).max(10),
  Nombre: z.string().min(1),
  Comision: z.number().optional(),
  Direccion: z.string().optional(),
  Telefonos: z.string().optional(),
  Email: z.string().email().optional(),
  Status: z.boolean().optional().default(true),
  Tipo: z.string().optional(),
  clave: z.string().optional(),
});

const updateSchema = z.object({
  Nombre: z.string().min(1).optional(),
  Comision: z.number().optional(),
  Direccion: z.string().optional(),
  Telefonos: z.string().optional(),
  Email: z.string().email().optional(),
  Status: z.boolean().optional(),
  Tipo: z.string().optional(),
  clave: z.string().optional(),
});

// GET /v1/vendedores - Listar vendedores
vendedoresRouter.get("/", async (req, res) => {
  try {
    const parsed = listSchema.safeParse(req.query);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
    }

    const data = await listVendedoresSP({
      search: parsed.data.search,
      status: parsed.data.status === "true" ? true : parsed.data.status === "false" ? false : undefined,
      tipo: parsed.data.tipo,
      page: parsed.data.page ? parseInt(parsed.data.page) : 1,
      limit: parsed.data.limit ? parseInt(parsed.data.limit) : 50,
    });

    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

// GET /v1/vendedores/:codigo - Obtener vendedor por código
vendedoresRouter.get("/:codigo", async (req, res) => {
  try {
    const data = await getVendedorByCodigoSP(req.params.codigo);
    if (!data) return res.status(404).json({ error: "not_found" });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

// POST /v1/vendedores - Crear vendedor
vendedoresRouter.post("/", async (req, res) => {
  try {
    const parsed = insertSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    }

    const result = await insertVendedorSP(parsed.data);
    if (result.success) {
      return res.status(201).json({ success: true, message: result.message });
    } else {
      return res.status(400).json({ success: false, message: result.message });
    }
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

// PUT /v1/vendedores/:codigo - Actualizar vendedor
vendedoresRouter.put("/:codigo", async (req, res) => {
  try {
    const parsed = updateSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    }

    const result = await updateVendedorSP(req.params.codigo, parsed.data);
    if (result.success) {
      return res.json({ success: true, message: result.message });
    } else {
      return res.status(400).json({ success: false, message: result.message });
    }
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

// DELETE /v1/vendedores/:codigo - Eliminar vendedor
vendedoresRouter.delete("/:codigo", async (req, res) => {
  try {
    const result = await deleteVendedorSP(req.params.codigo);
    if (result.success) {
      return res.json({ success: true, message: result.message });
    } else {
      return res.status(400).json({ success: false, message: result.message });
    }
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});
