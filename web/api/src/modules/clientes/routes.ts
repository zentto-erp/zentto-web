import { Router } from "express";
import { z } from "zod";
import {
  listClientesSP as listClientes,
  getClienteByCodigoSP,
  insertClienteSP,
  updateClienteSP,
  deleteClienteSP,
} from "./clientes-sp.service.js";
import { obs } from "../integrations/observability.js";

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
  res.json(await listClientes({
    search: parsed.data.search,
    estado: parsed.data.estado,
    vendedor: parsed.data.vendedor,
    page: parsed.data.page ? parseInt(parsed.data.page) : undefined,
    limit: parsed.data.limit ? parseInt(parsed.data.limit) : undefined,
  }));
});

clientesRouter.get("/:codigo", async (req, res) => {
  const row = await getClienteByCodigoSP(req.params.codigo);
  if (!row) return res.status(404).json({ error: "not_found" });
  res.json(row);
});

clientesRouter.post("/", async (req, res) => {
  try {
    const result = await insertClienteSP(req.body ?? {});
    if (result.success) {
      res.status(201).json({ ok: true, message: result.message });
      try { obs.event('crm.cliente.created', {
        codigo: req.body?.codigo,
        userId: (req as any).user?.userId,
        userName: (req as any).user?.userName,
        companyId: (req as any).user?.companyId,
        module: 'clientes'
      }); } catch { /* never blocks */ }
    } else {
      res.status(400).json({ ok: false, message: result.message });
    }
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

clientesRouter.put("/:codigo", async (req, res) => {
  try {
    const result = await updateClienteSP(req.params.codigo, req.body ?? {});
    if (result.success) {
      res.json({ ok: true, message: result.message });
      try { obs.event('crm.cliente.updated', {
        codigo: req.params.codigo,
        userId: (req as any).user?.userId,
        userName: (req as any).user?.userName,
        companyId: (req as any).user?.companyId,
        module: 'clientes'
      }); } catch { /* never blocks */ }
    } else {
      res.status(400).json({ ok: false, message: result.message });
    }
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

clientesRouter.delete("/:codigo", async (req, res) => {
  try {
    const result = await deleteClienteSP(req.params.codigo);
    if (result.success) {
      res.json({ ok: true, message: result.message });
    } else {
      res.status(400).json({ ok: false, message: result.message });
    }
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});
