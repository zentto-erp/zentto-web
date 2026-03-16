import { Router } from "express";
import { callSp } from "../../db/query.js";

export const healthRouter = Router();

// Health check básico - no requiere BD
healthRouter.get("/", async (_req, res) => {
  res.json({
    ok: true,
    timestamp: new Date().toISOString(),
    service: "datqbox-api",
    version: "1.0.0"
  });
});

// Health check con verificación de BD
healthRouter.get("/db", async (_req, res) => {
  try {
    const rows = await callSp<{ ok: number; serverTime: Date; dbName: string }>("usp_Sys_HealthCheck");
    res.json({
      ok: true,
      database: "connected",
      serverTime: rows[0]?.serverTime,
      dbName: rows[0]?.dbName,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    res.status(500).json({
      ok: false,
      database: "disconnected",
      error: String(err),
      timestamp: new Date().toISOString()
    });
  }
});
