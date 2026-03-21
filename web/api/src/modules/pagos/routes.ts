import { Router } from "express";
import { z } from "zod";
import { createPago, createPagoTx, deletePago, getPago, getPagoDetalle, listPagos, updatePago } from "./service.js";

export const pagosRouter = Router();
const qSchema = z.object({ search: z.string().optional(), codigo: z.string().optional(), page: z.string().optional(), limit: z.string().optional() });
const txSchema = z.object({ pago: z.record(z.any()), detalle: z.array(z.record(z.any())).default([]) });

function errMsg(err: unknown) {
  return err instanceof Error ? err.message : String(err);
}

pagosRouter.get("/", async (req, res) => {
  const q = qSchema.safeParse(req.query);
  if (!q.success) return res.status(400).json({ error: "invalid_query" });
  try {
    res.json(await listPagos(q.data));
  } catch (err) {
    console.error("[pagos] listPagos error:", err);
    res.status(400).json({ error: errMsg(err) });
  }
});

pagosRouter.post("/tx", async (req, res) => {
  const p = txSchema.safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: "invalid_payload" });
  try {
    res.status(201).json(await createPagoTx(p.data));
  } catch (err) {
    res.status(400).json({ error: errMsg(err) });
  }
});

pagosRouter.get("/:id", async (req, res) => {
  try {
    const r = await getPago(req.params.id);
    if (!r) return res.status(404).json({ error: "not_found" });
    res.json(r);
  } catch (err) {
    res.status(400).json({ error: errMsg(err) });
  }
});

pagosRouter.get("/:id/detalle", async (req, res) => {
  try {
    res.json(await getPagoDetalle(req.params.id));
  } catch (err) {
    res.status(400).json({ error: errMsg(err) });
  }
});

pagosRouter.post("/", async (req, res) => {
  try {
    res.status(201).json(await createPago(req.body ?? {}));
  } catch (err) {
    res.status(400).json({ error: errMsg(err) });
  }
});

pagosRouter.put("/:id", async (req, res) => {
  try {
    res.json(await updatePago(req.params.id, req.body ?? {}));
  } catch (err) {
    res.status(400).json({ error: errMsg(err) });
  }
});

pagosRouter.delete("/:id", async (req, res) => {
  try {
    res.json(await deletePago(req.params.id));
  } catch (err) {
    const message = errMsg(err);
    if (message === "not_found") return res.status(404).json({ error: message });
    res.status(400).json({ error: message });
  }
});
