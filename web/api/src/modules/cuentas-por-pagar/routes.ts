import { Router } from "express";
import { z } from "zod";
import {
  createCuentaPorPagar,
  deleteCuentaPorPagar,
  getCuentaPorPagar,
  listCuentasPorPagar,
  updateCuentaPorPagar
} from "./service.js";

export const cuentasPorPagarRouter = Router();
const qSchema = z.object({ search: z.string().optional(), codigo: z.string().optional(), page: z.string().optional(), limit: z.string().optional() });

cuentasPorPagarRouter.get("/", async (req, res) => {
  const q = qSchema.safeParse(req.query);
  if (!q.success) return res.status(400).json({ error: "invalid_query" });
  res.json(await listCuentasPorPagar(q.data));
});
cuentasPorPagarRouter.get("/:id", async (req, res) => { const r = await getCuentaPorPagar(req.params.id); if (!r) return res.status(404).json({ error: "not_found" }); res.json(r); });
cuentasPorPagarRouter.post("/", async (req, res) => { try { res.status(201).json(await createCuentaPorPagar(req.body ?? {})); } catch (err) { res.status(400).json({ error: String(err) }); } });
cuentasPorPagarRouter.put("/:id", async (req, res) => { try { res.json(await updateCuentaPorPagar(req.params.id, req.body ?? {})); } catch (err) { res.status(400).json({ error: String(err) }); } });
cuentasPorPagarRouter.delete("/:id", async (req, res) => { try { res.json(await deleteCuentaPorPagar(req.params.id)); } catch (err) { res.status(400).json({ error: String(err) }); } });
