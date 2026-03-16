import { Router } from "express";
import { z } from "zod";
import { createAbono, createAbonoTx, deleteAbono, getAbono, getAbonoDetalle, listAbonos, updateAbono } from "./service.js";

export const abonosRouter = Router();
const qSchema = z.object({ search: z.string().optional(), codigo: z.string().optional(), page: z.string().optional(), limit: z.string().optional() });
const txSchema = z.object({ abono: z.record(z.any()), detalle: z.array(z.record(z.any())).default([]) });

function errMsg(err: unknown) {
  return err instanceof Error ? err.message : String(err);
}

abonosRouter.get("/", async (req, res) => {
  const q = qSchema.safeParse(req.query);
  if (!q.success) return res.status(400).json({ error: "invalid_query" });
  try {
    res.json(await listAbonos(q.data));
  } catch (err) {
    res.status(400).json({ error: errMsg(err) });
  }
});

abonosRouter.post("/tx", async (req, res) => {
  const p = txSchema.safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: "invalid_payload" });
  try {
    res.status(201).json(await createAbonoTx(p.data));
  } catch (err) {
    res.status(400).json({ error: errMsg(err) });
  }
});

abonosRouter.get("/:id", async (req, res) => {
  try {
    const r = await getAbono(req.params.id);
    if (!r) return res.status(404).json({ error: "not_found" });
    res.json(r);
  } catch (err) {
    res.status(400).json({ error: errMsg(err) });
  }
});

abonosRouter.get("/:id/detalle", async (req, res) => {
  try {
    res.json(await getAbonoDetalle(req.params.id));
  } catch (err) {
    res.status(400).json({ error: errMsg(err) });
  }
});

abonosRouter.post("/", async (req, res) => {
  try {
    res.status(201).json(await createAbono(req.body ?? {}));
  } catch (err) {
    res.status(400).json({ error: errMsg(err) });
  }
});

abonosRouter.put("/:id", async (req, res) => {
  try {
    res.json(await updateAbono(req.params.id, req.body ?? {}));
  } catch (err) {
    res.status(400).json({ error: errMsg(err) });
  }
});

abonosRouter.delete("/:id", async (req, res) => {
  try {
    res.json(await deleteAbono(req.params.id));
  } catch (err) {
    const message = errMsg(err);
    if (message === "not_found") return res.status(404).json({ error: message });
    res.status(400).json({ error: message });
  }
});
