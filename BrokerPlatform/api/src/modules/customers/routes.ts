import { Router } from "express";
import { z } from "zod";
import { listCustomers, getCustomer, createCustomer, updateCustomer, deleteCustomer } from "./service.js";

export const customersRouter = Router();

const qSchema = z.object({ search: z.string().optional(), status: z.string().optional(), page: z.string().optional(), limit: z.string().optional() });

customersRouter.get("/", async (req, res) => {
    const parsed = qSchema.safeParse(req.query);
    if (!parsed.success) return res.status(400).json({ error: "invalid_query" });
    res.json(await listCustomers(parsed.data));
});

customersRouter.get("/:id", async (req, res) => {
    const data = await getCustomer(Number(req.params.id));
    if (!data) return res.status(404).json({ error: "not_found" });
    res.json(data);
});

customersRouter.post("/", async (req, res) => {
    try { res.status(201).json(await createCustomer(req.body ?? {})); }
    catch (err) { res.status(400).json({ error: String(err) }); }
});

customersRouter.put("/:id", async (req, res) => {
    try { res.json(await updateCustomer(Number(req.params.id), req.body ?? {})); }
    catch (err) { res.status(400).json({ error: String(err) }); }
});

customersRouter.delete("/:id", async (req, res) => {
    try { res.json(await deleteCustomer(Number(req.params.id))); }
    catch (err) { res.status(400).json({ error: String(err) }); }
});
