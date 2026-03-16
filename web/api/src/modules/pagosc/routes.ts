import { Router } from "express";
import { z } from "zod";
import { createPagoC, createPagoCTx, deletePagoC, getPagoC, getPagoCDetalle, listPagosC, updatePagoC } from "./service.js";

export const pagosCRouter = Router();
const qSchema = z.object({ search: z.string().optional(), codigo: z.string().optional(), page: z.string().optional(), limit: z.string().optional() });
const txSchema = z.object({ pago: z.record(z.any()), detalle: z.array(z.record(z.any())).default([]) });

function errMsg(err: unknown) {
  return err instanceof Error ? err.message : String(err);
}

pagosCRouter.get("/", async (req, res) => {
  const q = qSchema.safeParse(req.query);
  if (!q.success) return res.status(400).json({ error: "invalid_query" });
  try {
    res.json(await listPagosC(q.data));
  } catch (err) {
    res.status(400).json({ error: errMsg(err) });
  }
});

pagosCRouter.post("/tx", async (req, res) => {
  const p = txSchema.safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: "invalid_payload" });
  try {
    res.status(201).json(await createPagoCTx(p.data));
  } catch (err) {
    res.status(400).json({ error: errMsg(err) });
  }
});

pagosCRouter.get("/:id", async (req, res) => {
  try {
    const row = await getPagoC(req.params.id);
    if (!row) return res.status(404).json({ error: "not_found" });
    res.json(row);
  } catch (err) {
    res.status(400).json({ error: errMsg(err) });
  }
});

pagosCRouter.get("/:id/detalle", async (req, res) => {
  try {
    res.json(await getPagoCDetalle(req.params.id));
  } catch (err) {
    res.status(400).json({ error: errMsg(err) });
  }
});

pagosCRouter.post("/", async (req, res) => {
  try {
    res.status(201).json(await createPagoC(req.body ?? {}));
  } catch (err) {
    res.status(400).json({ error: errMsg(err) });
  }
});

pagosCRouter.put("/:id", async (req, res) => {
  try {
    res.json(await updatePagoC(req.params.id, req.body ?? {}));
  } catch (err) {
    res.status(400).json({ error: errMsg(err) });
  }
});

pagosCRouter.delete("/:id", async (req, res) => {
  try {
    res.json(await deletePagoC(req.params.id));
  } catch (err) {
    const message = errMsg(err);
    if (message === "not_found") return res.status(404).json({ error: message });
    res.status(400).json({ error: message });
  }
});
