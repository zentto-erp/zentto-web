import { Router } from "express";
import { listPromotions, createPromotion, updatePromotion, deletePromotion, validatePromoCode } from "./service.js";

export const promotionsRouter = Router();

promotionsRouter.get("/", async (req, res) => { res.json(await listPromotions(req.query as any)); });
promotionsRouter.post("/", async (req, res) => {
    try { res.status(201).json(await createPromotion(req.body ?? {})); }
    catch (err) { res.status(400).json({ error: String(err) }); }
});
promotionsRouter.put("/:id", async (req, res) => {
    try { res.json(await updatePromotion(Number(req.params.id), req.body ?? {})); }
    catch (err) { res.status(400).json({ error: String(err) }); }
});
promotionsRouter.delete("/:id", async (req, res) => {
    try { res.json(await deletePromotion(Number(req.params.id))); }
    catch (err) { res.status(400).json({ error: String(err) }); }
});
promotionsRouter.get("/validate/:code", async (req, res) => {
    res.json(await validatePromoCode(req.params.code));
});
