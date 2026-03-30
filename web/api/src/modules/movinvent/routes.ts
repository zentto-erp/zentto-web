import { Router } from "express";
import { z } from "zod";
import { createMovInvent, deleteMovInvent, getMovInvent, listMovInvent, listMovInventMes, updateMovInvent } from "./service.js";

export const movInventRouter = Router();
const qSchema = z.object({ search: z.string().optional(), tipo: z.string().optional(), page: z.string().optional(), limit: z.string().optional() });
const qMesSchema = z.object({ periodo: z.string().optional(), codigo: z.string().optional(), page: z.string().optional(), limit: z.string().optional() });

movInventRouter.get("/", async (req, res) => { try { const q = qSchema.safeParse(req.query); if (!q.success) return res.status(400).json({ error: "invalid_query" }); res.json(await listMovInvent(q.data)); } catch (err: any) { return res.status(500).json({ error: String(err.message ?? err) }); } });
movInventRouter.get("/mes/list", async (req, res) => { try { const q = qMesSchema.safeParse(req.query); if (!q.success) return res.status(400).json({ error: "invalid_query" }); res.json(await listMovInventMes(q.data)); } catch (err: any) { return res.status(500).json({ error: String(err.message ?? err) }); } });
movInventRouter.post("/", async (req, res) => { try { res.status(201).json(await createMovInvent(req.body ?? {})); } catch (err) { res.status(400).json({ error: String(err) }); } });
movInventRouter.put("/:id", async (req, res) => { try { res.json(await updateMovInvent(req.params.id, req.body ?? {})); } catch (err) { res.status(400).json({ error: String(err) }); } });
movInventRouter.delete("/:id", async (req, res) => { try { res.json(await deleteMovInvent(req.params.id)); } catch (err) { res.status(400).json({ error: String(err) }); } });
movInventRouter.get("/:id", async (req, res) => { try { const row = await getMovInvent(req.params.id); if (!row) return res.status(404).json({ error: "not_found" }); res.json(row); } catch (err: any) { return res.status(500).json({ error: String(err.message ?? err) }); } });
