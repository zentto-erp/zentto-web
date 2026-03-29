import { Router } from "express";
import { z } from "zod";
import {
  createRow,
  deleteRow,
  describeTable,
  executeMasterCrudAction,
  encodeKeyObject,
  getByKey,
  listTables,
  queryTable,
  updateRow
} from "./crud.service.js";

export const crudRouter = Router();

const qpSchema = z.object({
  schema: z.string().default("dbo"),
  page: z.coerce.number().optional(),
  pageSize: z.coerce.number().optional(),
  sort: z.string().optional(),
  desc: z
    .union([z.literal("true"), z.literal("false"), z.boolean()])
    .optional()
    .transform((v) => v === true || v === "true")
});

crudRouter.get("/tables", async (_req, res) => {
  const rows = await listTables();
  res.json(rows);
});

crudRouter.get("/:table/describe", async (req, res) => {
  const q = qpSchema.safeParse(req.query);
  if (!q.success) return res.status(400).json({ error: "invalid_query" });

  try {
    const meta = await describeTable(q.data.schema, req.params.table);
    if (!meta) return res.status(404).json({ error: "table_not_found" });
    res.json(meta);
  } catch (err) {
    console.error("[crud] describeTable error:", err);
    res.status(404).json({ error: "table_not_found" });
  }
});

crudRouter.post("/:table/query", async (req, res) => {
  const q = qpSchema.safeParse(req.query);
  if (!q.success) return res.status(400).json({ error: "invalid_query" });

  try {
    const data = await queryTable({
      schema: q.data.schema,
      table: req.params.table,
      page: q.data.page,
      pageSize: q.data.pageSize,
      sort: q.data.sort,
      desc: q.data.desc,
      filters: (req.body?.filters ?? {}) as Record<string, unknown>
    });

    res.json(data);
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

crudRouter.post("/master/:table/:action", async (req, res) => {
  const q = qpSchema.safeParse(req.query);
  if (!q.success) return res.status(400).json({ error: "invalid_query" });
  const action = String(req.params.action || "").toLowerCase();
  if (!["insert", "update", "delete", "list"].includes(action)) {
    return res.status(400).json({ error: "invalid_action" });
  }

  try {
    const result = await executeMasterCrudAction({
      schema: q.data.schema,
      table: req.params.table,
      action: action as "insert" | "update" | "delete" | "list",
      row: (req.body?.row ?? {}) as Record<string, unknown>,
      key: (req.body?.key ?? {}) as Record<string, unknown>,
      page: q.data.page,
      pageSize: q.data.pageSize
    });
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

crudRouter.get("/:table/:key", async (req, res) => {
  const q = qpSchema.safeParse(req.query);
  if (!q.success) return res.status(400).json({ error: "invalid_query" });

  try {
    const row = await getByKey(q.data.schema, req.params.table, req.params.key);
    if (!row) return res.status(404).json({ error: "not_found" });
    res.json(row);
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

crudRouter.post("/:table", async (req, res) => {
  const q = qpSchema.safeParse(req.query);
  if (!q.success) return res.status(400).json({ error: "invalid_query" });

  try {
    const result = await createRow(q.data.schema, req.params.table, req.body ?? {});
    res.status(201).json(result);
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

crudRouter.put("/:table/:key", async (req, res) => {
  const q = qpSchema.safeParse(req.query);
  if (!q.success) return res.status(400).json({ error: "invalid_query" });

  try {
    const result = await updateRow(q.data.schema, req.params.table, req.params.key, req.body ?? {});
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

crudRouter.delete("/:table/:key", async (req, res) => {
  const q = qpSchema.safeParse(req.query);
  if (!q.success) return res.status(400).json({ error: "invalid_query" });

  try {
    const result = await deleteRow(q.data.schema, req.params.table, req.params.key);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

crudRouter.post("/:table/key", async (_req, res) => {
  const key = (_req.body ?? {}) as Record<string, unknown>;
  res.json({ key: encodeKeyObject(key) });
});
