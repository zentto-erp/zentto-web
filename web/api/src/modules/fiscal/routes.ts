import { Router } from "express";
import { z } from "zod";
import { getFiscalPlugin, listFiscalPlugins } from "./engine.js";
import {
  getCountryInvoiceTypes,
  getCountryMilestones,
  getCountryProfile,
  getCountrySources,
  getCountryTaxRates,
  getFiscalConfig,
  listCountries,
  upsertFiscalConfig
} from "./service.js";

const countryCodeSchema = z.enum(["VE", "ES"]);

const fiscalConfigSchema = z.object({
  empresaId: z.number().int().positive(),
  sucursalId: z.number().int().nonnegative().optional(),
  countryCode: countryCodeSchema,
  currency: z.string().min(1).optional(),
  taxRegime: z.string().min(1).optional(),
  defaultTaxCode: z.string().min(1).optional(),
  defaultTaxRate: z.number().min(0).max(1).optional(),
  fiscalPrinterEnabled: z.boolean().optional(),
  printerBrand: z.string().optional(),
  printerPort: z.string().optional(),
  verifactuEnabled: z.boolean().optional(),
  verifactuMode: z.enum(["auto", "manual"]).optional(),
  certificatePath: z.string().optional(),
  certificatePassword: z.string().optional(),
  aeatEndpoint: z.string().url().optional().or(z.literal("")),
  senderNIF: z.string().optional(),
  senderRIF: z.string().optional(),
  softwareId: z.string().optional(),
  softwareName: z.string().optional(),
  softwareVersion: z.string().optional(),
  posEnabled: z.boolean().optional(),
  restaurantEnabled: z.boolean().optional()
});

export const fiscalRouter = Router();

fiscalRouter.get("/plugins", async (_req, res) => {
  return res.json({ ok: true, data: listFiscalPlugins() });
});

fiscalRouter.get("/countries", async (_req, res) => {
  return res.json({ ok: true, data: listCountries() });
});

fiscalRouter.get("/countries/:countryCode", async (req, res) => {
  const parsed = countryCodeSchema.safeParse(String(req.params.countryCode).toUpperCase());
  if (!parsed.success) {
    return res.status(400).json({ ok: false, error: "invalid_country_code" });
  }
  return res.json({ ok: true, data: getCountryProfile(parsed.data) });
});

fiscalRouter.get("/countries/:countryCode/default-config", async (req, res) => {
  const parsed = countryCodeSchema.safeParse(String(req.params.countryCode).toUpperCase());
  if (!parsed.success) {
    return res.status(400).json({ ok: false, error: "invalid_country_code" });
  }
  const plugin = getFiscalPlugin(parsed.data);
  return res.json({ ok: true, data: plugin.getDefaultConfig() });
});

fiscalRouter.get("/countries/:countryCode/tax-rates", async (req, res) => {
  const parsed = countryCodeSchema.safeParse(String(req.params.countryCode).toUpperCase());
  if (!parsed.success) {
    return res.status(400).json({ ok: false, error: "invalid_country_code" });
  }
  return res.json({ ok: true, data: getCountryTaxRates(parsed.data) });
});

fiscalRouter.get("/countries/:countryCode/invoice-types", async (req, res) => {
  const parsed = countryCodeSchema.safeParse(String(req.params.countryCode).toUpperCase());
  if (!parsed.success) {
    return res.status(400).json({ ok: false, error: "invalid_country_code" });
  }
  return res.json({ ok: true, data: getCountryInvoiceTypes(parsed.data) });
});

fiscalRouter.get("/countries/:countryCode/milestones", async (req, res) => {
  const parsed = countryCodeSchema.safeParse(String(req.params.countryCode).toUpperCase());
  if (!parsed.success) {
    return res.status(400).json({ ok: false, error: "invalid_country_code" });
  }
  return res.json({ ok: true, data: getCountryMilestones(parsed.data) });
});

fiscalRouter.get("/countries/:countryCode/sources", async (req, res) => {
  const parsed = countryCodeSchema.safeParse(String(req.params.countryCode).toUpperCase());
  if (!parsed.success) {
    return res.status(400).json({ ok: false, error: "invalid_country_code" });
  }
  return res.json({ ok: true, data: getCountrySources(parsed.data) });
});

fiscalRouter.get("/config", async (req, res) => {
  const empresaId = Number(req.query.empresaId ?? 1);
  const sucursalId = Number(req.query.sucursalId ?? 0);
  const countryCodeRaw = String(req.query.countryCode ?? "VE").toUpperCase();
  const parsedCountry = countryCodeSchema.safeParse(countryCodeRaw);

  if (!Number.isFinite(empresaId) || empresaId <= 0) {
    return res.status(400).json({ ok: false, error: "invalid_empresa_id" });
  }
  if (!Number.isFinite(sucursalId) || sucursalId < 0) {
    return res.status(400).json({ ok: false, error: "invalid_sucursal_id" });
  }
  if (!parsedCountry.success) {
    return res.status(400).json({ ok: false, error: "invalid_country_code" });
  }

  const data = await getFiscalConfig({
    empresaId,
    sucursalId,
    countryCode: parsedCountry.data
  });

  return res.json({ ok: true, data });
});

fiscalRouter.put("/config", async (req, res) => {
  const parsed = fiscalConfigSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({
      ok: false,
      error: "invalid_payload",
      issues: parsed.error.flatten()
    });
  }

  const payload = parsed.data;
  const data = await upsertFiscalConfig({
    ...payload,
    sucursalId: payload.sucursalId ?? 0,
    aeatEndpoint: payload.aeatEndpoint || undefined
  });

  return res.json({ ok: true, data });
});
