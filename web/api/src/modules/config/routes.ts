import { Router } from "express";
import { getTasasBCV, triggerSyncTasas } from "./service.js";

export const configRouter = Router();

// /api/config/tasas
configRouter.get("/tasas", async (_req, res) => {
    try {
        const tasas = await getTasasBCV();
        res.json({ success: true, ...tasas });
    } catch (err: any) {
        res.status(500).json({ success: false, error: err.message });
    }
});

// /api/config/tasas/sync (Trigger manual for immediate sync)
configRouter.post("/tasas/sync", async (_req, res) => {
    try {
        const result = await triggerSyncTasas();
        res.json({ success: true, result });
    } catch (err: any) {
        res.status(500).json({ success: false, error: err.message });
    }
});
