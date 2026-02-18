import { Router } from "express";
import { getPool } from "../../db/mssql.js";

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
    const pool = await getPool();
    await pool.request().query("SELECT 1 AS ok");
    res.json({ 
      ok: true, 
      database: "connected",
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
