import { Router } from "express";
import { z } from "zod";
import {
  createCotizacion,
  createCotizacionTx,
  deleteCotizacion,
  getCotizacion,
  getCotizacionDetalle,
  listCotizaciones,
  updateCotizacion
} from "./service.js";

export const cotizacionesRouter = Router();
const qSchema = z.object({ search: z.string().optional(), codigo: z.string().optional(), page: z.string().optional(), limit: z.string().optional() });
const txSchema = z.object({ cotizacion: z.record(z.any()), detalle: z.array(z.record(z.any())).default([]) });

cotizacionesRouter.get("/", async (req, res) => { const q = qSchema.safeParse(req.query); if (!q.success) return res.status(400).json({ error: "invalid_query" }); res.json(await listCotizaciones(q.data)); });
cotizacionesRouter.post("/tx", async (req, res) => { const p = txSchema.safeParse(req.body); if (!p.success) return res.status(400).json({ error: "invalid_payload" }); try { res.status(201).json(await createCotizacionTx(p.data)); } catch (err) { res.status(400).json({ error: String(err) }); } });
cotizacionesRouter.get("/:numFact", async (req, res) => {
  const data = await getCotizacion(req.params.numFact);
  if (!data.row) return res.status(404).json({ error: "not_found" });
  res.json(data.executionMode ? { ...data.row, executionMode: data.executionMode } : data.row);
});
cotizacionesRouter.get("/:numFact/detalle", async (req, res) => res.json(await getCotizacionDetalle(req.params.numFact)));
cotizacionesRouter.post("/", async (req, res) => { try { res.status(201).json(await createCotizacion(req.body ?? {})); } catch (err) { res.status(400).json({ error: String(err) }); } });
cotizacionesRouter.put("/:numFact", async (req, res) => { try { res.json(await updateCotizacion(req.params.numFact, req.body ?? {})); } catch (err) { res.status(400).json({ error: String(err) }); } });
cotizacionesRouter.delete("/:numFact", async (req, res) => { try { res.json(await deleteCotizacion(req.params.numFact)); } catch (err) { res.status(400).json({ error: String(err) }); } });
