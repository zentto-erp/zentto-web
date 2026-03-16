import { Router } from "express";
import { z } from "zod";
import {
  listAuditLogs,
  getAuditLog,
  getDashboard,
  listFiscalRecords,
} from "./service.js";

export const auditoriaRouter = Router();

const listLogsSchema = z.object({
  fechaDesde: z.string().optional(),
  fechaHasta: z.string().optional(),
  moduleName: z.string().optional(),
  userName: z.string().optional(),
  actionType: z.string().optional(),
  entityName: z.string().optional(),
  search: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional(),
});

const dashboardSchema = z.object({
  fechaDesde: z.string().min(1),
  fechaHasta: z.string().min(1),
});

const fiscalRecordsSchema = z.object({
  fechaDesde: z.string().optional(),
  fechaHasta: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional(),
});

auditoriaRouter.get("/logs", async (req, res) => {
  const parsed = listLogsSchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }
  try {
    const data = await listAuditLogs({
      fechaDesde: parsed.data.fechaDesde,
      fechaHasta: parsed.data.fechaHasta,
      moduleName: parsed.data.moduleName,
      userName: parsed.data.userName,
      actionType: parsed.data.actionType,
      entityName: parsed.data.entityName,
      search: parsed.data.search,
      page: parsed.data.page ? Number(parsed.data.page) : 1,
      limit: parsed.data.limit ? Number(parsed.data.limit) : 50,
    });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

auditoriaRouter.get("/logs/:id", async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id) || id <= 0) {
    return res.status(400).json({ error: "invalid_id" });
  }
  try {
    const log = await getAuditLog(id);
    if (!log) return res.status(404).json({ error: "not_found" });
    return res.json(log);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

auditoriaRouter.get("/dashboard", async (req, res) => {
  const parsed = dashboardSchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }
  try {
    const data = await getDashboard(parsed.data.fechaDesde, parsed.data.fechaHasta);
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

auditoriaRouter.get("/fiscal-records", async (req, res) => {
  const parsed = fiscalRecordsSchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }
  try {
    const data = await listFiscalRecords({
      fechaDesde: parsed.data.fechaDesde,
      fechaHasta: parsed.data.fechaHasta,
      page: parsed.data.page ? Number(parsed.data.page) : 1,
      limit: parsed.data.limit ? Number(parsed.data.limit) : 50,
    });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});
