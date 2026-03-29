/**
 * DatqBox Payment Gateway — API Routes
 *
 * /v1/payments/...
 */

import { Router } from "express";
import { z } from "zod";
import * as configSvc from "./config.service.js";
import { processPayment, searchTransactions } from "./engine.js";
import type { SourceType, CurrencyCode, CapabilityType } from "./types.js";

export const paymentsRouter = Router();

// ══════════════════════════════════════════════════════════════
// Payment Methods (catálogo global)
// ══════════════════════════════════════════════════════════════

paymentsRouter.get("/methods", async (req, res) => {
  try {
    const methods = await configSvc.listPaymentMethods(req.query.countryCode as string | undefined);
    res.json(methods);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

paymentsRouter.post("/methods", async (req, res) => {
  try {
    await configSvc.upsertPaymentMethod(req.body);
    res.json({ success: true });
  } catch (err: any) {
    res.status(400).json({ error: err.message });
  }
});

// ══════════════════════════════════════════════════════════════
// Payment Providers
// ══════════════════════════════════════════════════════════════

paymentsRouter.get("/providers", async (req, res) => {
  try {
    const providers = await configSvc.listProviders(req.query.countryCode as string | undefined);
    res.json(providers);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

paymentsRouter.get("/providers/:code", async (req, res) => {
  try {
    const provider = await configSvc.getProviderByCode(req.params.code);
    if (!provider) return res.status(404).json({ error: "Provider not found" });
    const capabilities = await configSvc.getProviderCapabilities(req.params.code);
    const configFields = configSvc.getProviderConfigFields(req.params.code);
    res.json({ ...provider, capabilities, configFields });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

paymentsRouter.get("/providers/:code/fields", async (req, res) => {
  const fields = configSvc.getProviderConfigFields(req.params.code);
  res.json(fields);
});

paymentsRouter.get("/plugins", async (_req, res) => {
  res.json(configSvc.listAvailablePlugins());
});

// ══════════════════════════════════════════════════════════════
// Company Payment Config
// ══════════════════════════════════════════════════════════════

const configSchema = z.object({
  empresaId: z.number(),
  sucursalId: z.number().default(0),
  countryCode: z.string().length(2),
  providerCode: z.string().min(1),
  environment: z.enum(["sandbox", "production"]).default("sandbox"),
  clientId: z.string().optional(),
  clientSecret: z.string().optional(),
  merchantId: z.string().optional(),
  terminalId: z.string().optional(),
  integratorId: z.string().optional(),
  certificatePath: z.string().optional(),
  extraConfig: z.record(z.unknown()).optional(),
  autoCapture: z.boolean().optional(),
  allowRefunds: z.boolean().optional(),
  maxRefundDays: z.number().optional(),
});

paymentsRouter.get("/config", async (req, res) => {
  try {
    const empresaId = Number(req.query.empresaId);
    const sucursalId = req.query.sucursalId != null ? Number(req.query.sucursalId) : undefined;
    if (!empresaId) return res.status(400).json({ error: "empresaId required" });
    const configs = await configSvc.listCompanyConfigs(empresaId, sucursalId);
    res.json(configs);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

paymentsRouter.post("/config", async (req, res) => {
  const parsed = configSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "validation_error", issues: parsed.error.flatten() });
  try {
    await configSvc.upsertCompanyConfig(parsed.data as any);
    res.json({ success: true });
  } catch (err: any) {
    res.status(400).json({ error: err.message });
  }
});

paymentsRouter.delete("/config/:id", async (req, res) => {
  try {
    await configSvc.deleteCompanyConfig(Number(req.params.id));
    res.json({ success: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// ══════════════════════════════════════════════════════════════
// Accepted Payment Methods (per company)
// ══════════════════════════════════════════════════════════════

paymentsRouter.get("/accepted", async (req, res) => {
  try {
    const empresaId = Number(req.query.empresaId);
    const sucursalId = Number(req.query.sucursalId ?? 0);
    const channel = req.query.channel as "POS" | "WEB" | "RESTAURANT" | undefined;
    if (!empresaId) return res.status(400).json({ error: "empresaId required" });
    const methods = await configSvc.listAcceptedMethods(empresaId, sucursalId, channel);
    res.json(methods);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

paymentsRouter.post("/accepted", async (req, res) => {
  try {
    await configSvc.upsertAcceptedMethod(req.body);
    res.json({ success: true });
  } catch (err: any) {
    res.status(400).json({ error: err.message });
  }
});

paymentsRouter.delete("/accepted/:id", async (req, res) => {
  try {
    await configSvc.removeAcceptedMethod(Number(req.params.id));
    res.json({ success: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// ══════════════════════════════════════════════════════════════
// Card Reader Devices
// ══════════════════════════════════════════════════════════════

paymentsRouter.get("/card-readers", async (req, res) => {
  try {
    const empresaId = Number(req.query.empresaId);
    if (!empresaId || isNaN(empresaId)) return res.status(400).json({ error: "empresaId required" });
    const sucursalId = req.query.sucursalId != null ? Number(req.query.sucursalId) : undefined;
    const readers = await configSvc.listCardReaders(empresaId, sucursalId);
    res.json(readers);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

paymentsRouter.post("/card-readers", async (req, res) => {
  try {
    await configSvc.upsertCardReader(req.body);
    res.json({ success: true });
  } catch (err: any) {
    res.status(400).json({ error: err.message });
  }
});

// ══════════════════════════════════════════════════════════════
// Process Payment (execute through gateway)
// ══════════════════════════════════════════════════════════════

const processSchema = z.object({
  empresaId: z.number(),
  sucursalId: z.number().default(0),
  providerCode: z.string().min(1),
  sourceType: z.string() as z.ZodType<SourceType>,
  sourceId: z.number().optional(),
  sourceNumber: z.string().optional(),
  stationId: z.string().optional(),
  cashierId: z.string().optional(),
  request: z.object({
    capability: z.string() as z.ZodType<CapabilityType>,
    paymentMethodCode: z.string(),
    amount: z.number().positive(),
    currency: z.string() as z.ZodType<CurrencyCode>,
    invoiceNumber: z.string().optional(),
    card: z.object({
      number: z.string(),
      expirationDate: z.string(),
      cvv: z.string(),
      holderName: z.string().optional(),
    }).optional(),
    mobile: z.object({
      originNumber: z.string(),
      destinationNumber: z.string().optional(),
      destinationId: z.string().optional(),
      destinationBankId: z.string().optional(),
      twoFactorAuth: z.string().optional(),
    }).optional(),
    transfer: z.record(z.unknown()).optional(),
    crypto: z.record(z.unknown()).optional(),
    clientInfo: z.object({
      ipAddress: z.string(),
      browserAgent: z.string(),
      mobile: z.record(z.unknown()).optional(),
    }).optional(),
    extra: z.record(z.unknown()).optional(),
  }),
});

paymentsRouter.post("/process", async (req, res) => {
  const parsed = processSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "validation_error", issues: parsed.error.flatten() });
  try {
    const result = await processPayment({
      ...parsed.data,
      ipAddress: (req.headers["x-forwarded-for"] as string) || req.socket.remoteAddress || "unknown",
    });
    const httpStatus = result.response.success ? 200
      : result.response.status === "DECLINED" ? 402
      : 500;
    res.status(httpStatus).json(result);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// ══════════════════════════════════════════════════════════════
// Search Transactions
// ══════════════════════════════════════════════════════════════

paymentsRouter.get("/transactions", async (req, res) => {
  try {
    const empresaId = Number(req.query.empresaId);
    if (!empresaId || isNaN(empresaId)) return res.status(400).json({ error: "empresaId required" });
    const result = await searchTransactions({
      empresaId,
      sucursalId: req.query.sucursalId != null ? Number(req.query.sucursalId) : undefined,
      providerCode: req.query.providerCode as string | undefined,
      sourceType: req.query.sourceType as string | undefined,
      sourceNumber: req.query.sourceNumber as string | undefined,
      status: req.query.status as string | undefined,
      dateFrom: req.query.dateFrom as string | undefined,
      dateTo: req.query.dateTo as string | undefined,
      page: req.query.page ? Number(req.query.page) : undefined,
      limit: req.query.limit ? Number(req.query.limit) : undefined,
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});
