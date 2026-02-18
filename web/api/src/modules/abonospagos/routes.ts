import { Router } from "express";
import { z } from "zod";
import { createAbonosPagos, deleteAbonosPagos, getAbonosPagos, listAbonosPagos, updateAbonosPagos } from "./service.js";

export const abonosPagosRouter = Router();
const qSchema = z.object({ search: z.string().optional(), codigo: z.string().optional(), page: z.string().optional(), limit: z.string().optional() });

abonosPagosRouter.get("/", async (req, res) => { const q = qSchema.safeParse(req.query); if (!q.success) return res.status(400).json({ error: "invalid_query" }); res.json(await listAbonosPagos(q.data)); });
abonosPagosRouter.get("/:id", async (req, res) => { const row = await getAbonosPagos(req.params.id); if (!row) return res.status(404).json({ error: "not_found" }); res.json(row); });
abonosPagosRouter.post("/", async (req, res) => { try { res.status(201).json(await createAbonosPagos(req.body ?? {})); } catch (err) { res.status(400).json({ error: String(err) }); } });
abonosPagosRouter.put("/:id", async (req, res) => { try { res.json(await updateAbonosPagos(req.params.id, req.body ?? {})); } catch (err) { res.status(400).json({ error: String(err) }); } });
abonosPagosRouter.delete("/:id", async (req, res) => { try { res.json(await deleteAbonosPagos(req.params.id)); } catch (err) { res.status(400).json({ error: String(err) }); } });
