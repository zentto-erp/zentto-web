import { Router } from "express";
import { z } from "zod";
import { pCobrarService } from "./service.js";

export const pCobrarRouter = Router();
const qSchema = z.object({ search: z.string().optional(), codigo: z.string().optional(), page: z.string().optional(), limit: z.string().optional() });

pCobrarRouter.get("/", async (req, res) => { try { const q = qSchema.safeParse(req.query); if (!q.success) return res.status(400).json({ error: "invalid_query" }); res.json(await pCobrarService.list(q.data)); } catch (err: any) { return res.status(500).json({ error: String(err.message ?? err) }); } });
pCobrarRouter.get("/c/list", async (req, res) => { try { const q = qSchema.safeParse(req.query); if (!q.success) return res.status(400).json({ error: "invalid_query" }); res.json(await pCobrarService.listC(q.data)); } catch (err: any) { return res.status(500).json({ error: String(err.message ?? err) }); } });
pCobrarRouter.post("/c", async (req, res) => { try { res.status(201).json(await pCobrarService.createC(req.body ?? {})); } catch (err) { res.status(400).json({ error: String(err) }); } });
pCobrarRouter.put("/c/:id", async (req, res) => { try { res.json(await pCobrarService.updateC(req.params.id, req.body ?? {})); } catch (err) { res.status(400).json({ error: String(err) }); } });
pCobrarRouter.delete("/c/:id", async (req, res) => { try { res.json(await pCobrarService.deleteC(req.params.id)); } catch (err) { res.status(400).json({ error: String(err) }); } });
pCobrarRouter.get("/c/:id", async (req, res) => { try { const row = await pCobrarService.getC(req.params.id); if (!row) return res.status(404).json({ error: "not_found" }); res.json(row); } catch (err: any) { return res.status(500).json({ error: String(err.message ?? err) }); } });

pCobrarRouter.post("/", async (req, res) => { try { res.status(201).json(await pCobrarService.create(req.body ?? {})); } catch (err) { res.status(400).json({ error: String(err) }); } });
pCobrarRouter.put("/:id", async (req, res) => { try { res.json(await pCobrarService.update(req.params.id, req.body ?? {})); } catch (err) { res.status(400).json({ error: String(err) }); } });
pCobrarRouter.delete("/:id", async (req, res) => { try { res.json(await pCobrarService.delete(req.params.id)); } catch (err) { res.status(400).json({ error: String(err) }); } });
pCobrarRouter.get("/:id", async (req, res) => { try { const row = await pCobrarService.get(req.params.id); if (!row) return res.status(404).json({ error: "not_found" }); res.json(row); } catch (err: any) { return res.status(500).json({ error: String(err.message ?? err) }); } });
