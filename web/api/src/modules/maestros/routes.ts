import { Router } from "express";
import { z } from "zod";
import {
  createMaestroRow,
  deleteMaestroRow,
  getMaestroRow,
  listMaestroRows,
  listMasterTables,
  updateMaestroRow,
} from "./service.js";

export const maestrosRouter = Router();

const listQuerySchema = z.object({
  search: z.string().optional(),
  page: z.coerce.number().optional(),
  limit: z.coerce.number().optional(),
});

function statusFromError(error: unknown): number {
  const text = String(error ?? "");
  if (text.includes("table_not_found")) return 404;
  if (text.includes("not_found")) return 404;
  if (text.includes("master_table_not_allowed")) return 404;
  if (text.includes("invalid_pk_value")) return 400;
  if (text.includes("table_without_pk")) return 400;
  if (text.includes("composite_pk_not_supported")) return 400;
  return 400;
}

maestrosRouter.get("/", async (_req, res) => {
  res.json({ items: listMasterTables() });
});

maestrosRouter.get("/:slug", async (req, res) => {
  const parsed = listQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }

  try {
    const data = await listMaestroRows(req.params.slug, parsed.data);
    return res.json(data);
  } catch (error) {
    return res.status(statusFromError(error)).json({ error: String(error) });
  }
});

maestrosRouter.get("/:slug/:key", async (req, res) => {
  try {
    const data = await getMaestroRow(req.params.slug, req.params.key);
    if (!data) return res.status(404).json({ error: "not_found" });
    return res.json(data);
  } catch (error) {
    return res.status(statusFromError(error)).json({ error: String(error) });
  }
});

maestrosRouter.post("/:slug", async (req, res) => {
  try {
    const result = await createMaestroRow(req.params.slug, req.body ?? {});
    return res.status(201).json(result);
  } catch (error) {
    return res.status(statusFromError(error)).json({ error: String(error) });
  }
});

maestrosRouter.put("/:slug/:key", async (req, res) => {
  try {
    const result = await updateMaestroRow(req.params.slug, req.params.key, req.body ?? {});
    return res.json(result);
  } catch (error) {
    return res.status(statusFromError(error)).json({ error: String(error) });
  }
});

maestrosRouter.delete("/:slug/:key", async (req, res) => {
  try {
    const result = await deleteMaestroRow(req.params.slug, req.params.key);
    return res.json(result);
  } catch (error) {
    return res.status(statusFromError(error)).json({ error: String(error) });
  }
});
