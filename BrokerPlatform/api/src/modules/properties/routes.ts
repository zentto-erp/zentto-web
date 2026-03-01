import { Router } from "express";
import { z } from "zod";
import { listProperties, getProperty, createProperty, updateProperty, deleteProperty, getAvailability, setAvailability } from "./service.js";

export const propertiesRouter = Router();

const qSchema = z.object({ search: z.string().optional(), type: z.string().optional(), provider_id: z.string().optional(), city: z.string().optional(), country: z.string().optional(), min_price: z.string().optional(), max_price: z.string().optional(), guests: z.string().optional(), page: z.string().optional(), limit: z.string().optional() });

propertiesRouter.get("/", async (req, res) => {
    const parsed = qSchema.safeParse(req.query);
    if (!parsed.success) return res.status(400).json({ error: "invalid_query" });
    res.json(await listProperties(parsed.data));
});

propertiesRouter.get("/:id", async (req, res) => {
    const data = await getProperty(Number(req.params.id));
    if (!data) return res.status(404).json({ error: "not_found" });
    res.json(data);
});

propertiesRouter.post("/", async (req, res) => {
    try { res.status(201).json(await createProperty(req.body ?? {})); }
    catch (err) { res.status(400).json({ error: String(err) }); }
});

propertiesRouter.put("/:id", async (req, res) => {
    try { res.json(await updateProperty(Number(req.params.id), req.body ?? {})); }
    catch (err) { res.status(400).json({ error: String(err) }); }
});

propertiesRouter.delete("/:id", async (req, res) => {
    try { res.json(await deleteProperty(Number(req.params.id))); }
    catch (err) { res.status(400).json({ error: String(err) }); }
});

// Availability sub-routes
propertiesRouter.get("/:id/availability", async (req, res) => {
    const from = (req.query.from as string) || new Date().toISOString().slice(0, 10);
    const to = (req.query.to as string) || new Date(Date.now() + 30 * 86400000).toISOString().slice(0, 10);
    res.json(await getAvailability(Number(req.params.id), from, to));
});

propertiesRouter.put("/:id/availability", async (req, res) => {
    try { res.json(await setAvailability(Number(req.params.id), req.body?.entries ?? [])); }
    catch (err) { res.status(400).json({ error: String(err) }); }
});
