import { Router } from "express";
import { z } from "zod";
import {
  listProveedoresSP as listProveedores,
  getProveedorByCodigoSP,
  insertProveedorSP,
  updateProveedorSP,
  deleteProveedorSP,
} from "./proveedores-sp.service.js";

export const proveedoresRouter = Router();

const qSchema = z.object({
  search: z.string().optional(),
  estado: z.string().optional(),
  vendedor: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional()
});

proveedoresRouter.get("/", async (req, res) => {
  try {
    const parsed = qSchema.safeParse(req.query);
    if (!parsed.success) return res.status(400).json({ error: "invalid_query" });
    res.json(await listProveedores({
      search: parsed.data.search,
      estado: parsed.data.estado,
      vendedor: parsed.data.vendedor,
      page: parsed.data.page ? parseInt(parsed.data.page) : undefined,
      limit: parsed.data.limit ? parseInt(parsed.data.limit) : undefined,
    }));
  } catch (err: any) {
    res.status(500).json({ error: err?.message || "internal_error" });
  }
});

proveedoresRouter.get("/:codigo", async (req, res) => {
  try {
    const row = await getProveedorByCodigoSP(req.params.codigo);
    if (!row) return res.status(404).json({ error: "not_found" });
    res.json(row);
  } catch (err: any) {
    res.status(500).json({ error: err?.message || "internal_error" });
  }
});

proveedoresRouter.post("/", async (req, res) => {
  try {
    const result = await insertProveedorSP(req.body ?? {});
    if (result.success) {
      res.status(201).json({ ok: true, message: result.message });
    } else {
      res.status(400).json({ ok: false, message: result.message });
    }
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

proveedoresRouter.put("/:codigo", async (req, res) => {
  try {
    const result = await updateProveedorSP(req.params.codigo, req.body ?? {});
    if (result.success) {
      res.json({ ok: true, message: result.message });
    } else {
      res.status(400).json({ ok: false, message: result.message });
    }
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

proveedoresRouter.delete("/:codigo", async (req, res) => {
  try {
    const result = await deleteProveedorSP(req.params.codigo);
    if (result.success) {
      res.json({ ok: true, message: result.message });
    } else {
      res.status(400).json({ ok: false, message: result.message });
    }
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});
