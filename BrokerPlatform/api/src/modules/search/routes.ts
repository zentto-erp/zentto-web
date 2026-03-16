import { Router } from "express";
import { z } from "zod";
import { searchProperties } from "./service.js";

export const searchRouter = Router();

const searchQuerySchema = z.object({
    q: z.string().optional(),
    type: z.string().optional(),
    city: z.string().optional(),
    country: z.string().optional(),
    check_in: z.string().optional(),
    check_out: z.string().optional(),
    guests: z.string().optional(),
    min_price: z.string().optional(),
    max_price: z.string().optional(),
    min_lat: z.string().optional(),
    max_lat: z.string().optional(),
    min_lng: z.string().optional(),
    max_lng: z.string().optional(),
    lat: z.string().optional(),
    lng: z.string().optional(),
    radius_km: z.string().optional(),
    sort: z.string().optional(),
    page: z.string().optional(),
    limit: z.string().optional(),
});

searchRouter.get("/", async (req, res) => {
    try {
        const parsed = searchQuerySchema.safeParse(req.query);
        if (!parsed.success) {
            return res.status(400).json({
                error: "validation_error",
                details: parsed.error.flatten(),
            });
        }
        res.json(await searchProperties(parsed.data));
    } catch (err) {
        res.status(500).json({ error: String(err) });
    }
});
