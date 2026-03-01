import { Router } from "express";
import { getPool } from "../../db/mssql.js";

export const healthRouter = Router();

healthRouter.get("/", async (_req, res) => {
    try {
        const pool = await getPool();
        const result = await pool.request().query("SELECT 1 AS ok");
        res.json({ status: "ok", db: "connected", timestamp: new Date().toISOString() });
    } catch (err) {
        res.status(503).json({ status: "error", db: "disconnected", error: String(err) });
    }
});
