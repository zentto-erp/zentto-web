import { Router } from "express";
import { z } from "zod";
import { listProviders, getProvider, createProvider, updateProvider, deleteProvider } from "./service.js";

export const providersRouter = Router();

const qSchema = z.object({ search: z.string().optional(), type: z.string().optional(), status: z.string().optional(), page: z.string().optional(), limit: z.string().optional() });

providersRouter.get("/", async (req, res) => {
    const parsed = qSchema.safeParse(req.query);
    if (!parsed.success) return res.status(400).json({ error: "invalid_query" });
    res.json(await listProviders(parsed.data));
});

providersRouter.get("/:id", async (req, res) => {
    const data = await getProvider(Number(req.params.id));
    if (!data) return res.status(404).json({ error: "not_found" });
    res.json(data);
});

providersRouter.post("/", async (req, res) => {
    try { const r = await createProvider(req.body ?? {}); res.status(201).json(r); }
    catch (err) { res.status(400).json({ error: String(err) }); }
});

providersRouter.put("/:id", async (req, res) => {
    try { res.json(await updateProvider(Number(req.params.id), req.body ?? {})); }
    catch (err) { res.status(400).json({ error: String(err) }); }
});

providersRouter.delete("/:id", async (req, res) => {
    try { res.json(await deleteProvider(Number(req.params.id))); }
    catch (err) { res.status(400).json({ error: String(err) }); }
});
