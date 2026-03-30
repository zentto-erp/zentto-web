import { Router } from "express";
import { z } from "zod";
import { createRetencion, deleteRetencion, getRetencion, listRetenciones, updateRetencion } from "./service.js";

export const retencionesRouter = Router();
const qSchema = z.object({ search: z.string().optional(), tipo: z.string().optional(), page: z.string().optional(), limit: z.string().optional() });

retencionesRouter.get("/", async (req, res) => { try { const q = qSchema.safeParse(req.query); if (!q.success) return res.status(400).json({ error: "invalid_query" }); res.json(await listRetenciones(q.data)); } catch (err: any) { return res.status(500).json({ error: String(err.message ?? err) }); } });
retencionesRouter.get("/:codigo", async (req, res) => { try { const row = await getRetencion(req.params.codigo); if (!row) return res.status(404).json({ error: "not_found" }); res.json(row); } catch (err: any) { return res.status(500).json({ error: String(err.message ?? err) }); } });
retencionesRouter.post("/", async (req, res) => { try { res.status(201).json(await createRetencion(req.body ?? {})); } catch (err) { res.status(400).json({ error: String(err) }); } });
retencionesRouter.put("/:codigo", async (req, res) => { try { res.json(await updateRetencion(req.params.codigo, req.body ?? {})); } catch (err) { res.status(400).json({ error: String(err) }); } });
retencionesRouter.delete("/:codigo", async (req, res) => { try { res.json(await deleteRetencion(req.params.codigo)); } catch (err) { res.status(400).json({ error: String(err) }); } });
