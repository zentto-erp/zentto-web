import { Router } from "express";
import { getRelations, getTablesAndColumns } from "./service.js";

export const metaRouter = Router();

metaRouter.get("/relations", async (_req, res) => {
  res.json(await getRelations());
});

metaRouter.get("/schema", async (_req, res) => {
  res.json(await getTablesAndColumns());
});
