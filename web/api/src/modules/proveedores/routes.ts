import { Router } from "express";
import { z } from "zod";
import {
  createProveedor,
  deleteProveedor,
  getProveedor,
  listProveedores,
  updateProveedor
} from "./service.js";

export const proveedoresRouter = Router();

const qSchema = z.object({
  search: z.string().optional(),
  estado: z.string().optional(),
  vendedor: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional()
});

proveedoresRouter.get("/", async (req, res) => {
  const parsed = qSchema.safeParse(req.query);
  if (!parsed.success) return res.status(400).json({ error: "invalid_query" });
  res.json(await listProveedores(parsed.data));
});

proveedoresRouter.get("/:codigo", async (req, res) => {
  const data = await getProveedor(req.params.codigo);
  if (!data.row) return res.status(404).json({ error: "not_found" });
  res.json(data.executionMode ? { ...data.row, executionMode: data.executionMode } : data.row);
});

proveedoresRouter.post("/", async (req, res) => {
  try {
    const data = await createProveedor(req.body ?? {});
    res.status(201).json({ ok: true, ...(data.executionMode && { executionMode: data.executionMode }) });
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

proveedoresRouter.put("/:codigo", async (req, res) => {
  try {
    const data = await updateProveedor(req.params.codigo, req.body ?? {});
    res.json({ ok: true, ...(data.executionMode && { executionMode: data.executionMode }) });
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

proveedoresRouter.delete("/:codigo", async (req, res) => {
  try {
    const data = await deleteProveedor(req.params.codigo);
    res.json({ ok: true, ...(data.executionMode && { executionMode: data.executionMode }) });
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});
