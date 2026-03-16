import { Router } from "express";
import { listReviews, createReview, replyToReview, updateReviewStatus, deleteReview } from "./service.js";

export const reviewsRouter = Router();

reviewsRouter.get("/", async (req, res) => { res.json(await listReviews(req.query as any)); });

reviewsRouter.post("/", async (req, res) => {
    try { res.status(201).json(await createReview(req.body ?? {})); }
    catch (err) { res.status(400).json({ error: String(err) }); }
});

reviewsRouter.patch("/:id/reply", async (req, res) => {
    try { res.json(await replyToReview(Number(req.params.id), req.body.response)); }
    catch (err) { res.status(400).json({ error: String(err) }); }
});

reviewsRouter.patch("/:id/status", async (req, res) => {
    try { res.json(await updateReviewStatus(Number(req.params.id), req.body.status)); }
    catch (err) { res.status(400).json({ error: String(err) }); }
});

reviewsRouter.delete("/:id", async (req, res) => {
    try { res.json(await deleteReview(Number(req.params.id))); }
    catch (err) { res.status(400).json({ error: String(err) }); }
});
