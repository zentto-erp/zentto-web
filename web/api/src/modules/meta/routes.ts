import { Router } from "express";
import { getRelations, getTablesAndColumns } from "./service.js";

export const metaRouter = Router();

metaRouter.get("/relations", async (_req, res) => {
  try {
    res.json(await getRelations());
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

metaRouter.get("/schema", async (_req, res) => {
  try {
    res.json(await getTablesAndColumns());
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});
