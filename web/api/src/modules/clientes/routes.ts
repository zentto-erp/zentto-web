import { Router } from "express";
import { z } from "zod";
import { createCliente, deleteCliente, getCliente, listClientes, updateCliente } from "./service.js";

export const clientesRouter = Router();

const qSchema = z.object({
  search: z.string().optional(),
  estado: z.string().optional(),
  vendedor: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional()
});

clientesRouter.get("/", async (req, res) => {
  const parsed = qSchema.safeParse(req.query);
  if (!parsed.success) return res.status(400).json({ error: "invalid_query" });
  res.json(await listClientes(parsed.data));
});

clientesRouter.get("/:codigo", async (req, res) => {
  const data = await getCliente(req.params.codigo);
  if (!data.row) return res.status(404).json({ error: "not_found" });
  res.json(data.row);
});

clientesRouter.post("/", async (req, res) => {
  try {
    const data = await createCliente(req.body ?? {});
    res.status(201).json({ ok: true, data });
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

clientesRouter.put("/:codigo", async (req, res) => {
  try {
    const data = await updateCliente(req.params.codigo, req.body ?? {});
    res.json({ ok: true, data });
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

clientesRouter.delete("/:codigo", async (req, res) => {
  try {
    const data = await deleteCliente(req.params.codigo);
    res.json({ ok: true, data });
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});
