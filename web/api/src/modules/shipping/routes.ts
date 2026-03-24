/**
 * Zentto Shipping — Routes
 * Portal de paquetería para clientes finales.
 * Montado en /shipping/*
 */
import { Router } from "express";
import { z } from "zod";
import { verifyJwt } from "../../auth/jwt.js";
import type { Request, Response, NextFunction } from "express";
import { obs } from "../integrations/observability.js";
import { validateCaptchaToken } from "../usuarios/captcha.service.js";
import { getClientIp } from "../../middleware/rate-limit.js";
import {
  registerCustomer,
  loginCustomer,
  getCustomerProfile,
  listAddresses,
  upsertAddress,
  listCarriers,
  getQuotes,
  createShipment,
  listShipments,
  getShipment,
  updateShipmentStatus,
  trackPublic,
  upsertCustoms,
  getDashboard,
} from "./service.js";

export const shippingRouter = Router();

// ─── Middleware: verify shipping customer JWT ─────────────────
function shippingAuth(req: Request, res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header?.startsWith("Bearer ")) return res.status(401).json({ error: "No autorizado" });
  try {
    const payload = verifyJwt(header.slice(7));
    (req as any).shippingCustomerId = payload.userId;
    (req as any).shippingEmail = payload.email;
    next();
  } catch {
    return res.status(401).json({ error: "Token inválido o expirado" });
  }
}

function customerId(req: Request): number {
  return (req as any).shippingCustomerId;
}

// ════════════════════════════════════════════════════════════
// PUBLIC ROUTES (no auth)
// ════════════════════════════════════════════════════════════

// ─── Auth ────────────────────────────────────────────────────

const registerSchema = z.object({
  email: z.string().email().max(200),
  password: z.string().min(6).max(100),
  displayName: z.string().min(1).max(200),
  phone: z.string().max(60).optional(),
  fiscalId: z.string().max(30).optional(),
  companyName: z.string().max(200).optional(),
  countryCode: z.string().max(3).optional(),
});

shippingRouter.post("/auth/register", async (req, res) => {
  try {
    const parsed = registerSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });
    const result = await registerCustomer(parsed.data);
    if (!result.ok) return res.status(409).json({ error: result.error });
    try { obs.event('shipping.customer.registered', { email: parsed.data.email, module: 'shipping' }); } catch { /* never blocks */ }
    res.status(201).json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

shippingRouter.post("/auth/login", async (req, res) => {
  try {
    const parsed = loginSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body" });
    const result = await loginCustomer(parsed.data.email, parsed.data.password);
    if (!result.ok) return res.status(401).json({ error: result.error });
    try { obs.event('shipping.customer.login', { email: parsed.data.email, module: 'shipping' }); } catch { /* never blocks */ }
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Public Tracking ─────────────────────────────────────────

shippingRouter.get("/track/:trackingNumber", async (req, res) => {
  try {
    // Validate Turnstile anti-bot token (header o query param)
    const captchaToken = (req.headers["x-captcha-token"] as string) || (req.query.captchaToken as string);
    const captchaResult = await validateCaptchaToken(captchaToken, getClientIp(req), "track_public");
    if (!captchaResult.ok && !captchaResult.skipped) {
      return res.status(403).json({ error: "captcha_required", reason: captchaResult.reason });
    }

    const result = await trackPublic(req.params.trackingNumber);
    if (!result.shipment) return res.status(404).json({ error: "Envío no encontrado" });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Carrier Webhook (receives tracking updates from carriers) ─
shippingRouter.post("/webhooks/carrier/:carrierCode", async (req, res) => {
  try {
    const { carrierCode } = req.params;
    const body = req.body;

    // Map carrier webhook payload to our status update
    const trackingNumber = body.trackingNumber || body.tracking_number || body.guia;
    const status = body.status || body.estado;
    const description = body.description || body.descripcion || `Update from ${carrierCode}`;

    if (!trackingNumber || !status) {
      return res.status(400).json({ error: "missing_fields" });
    }

    // Find shipment by tracking number
    const trackResult = await trackPublic(trackingNumber);
    if (!trackResult.shipment) return res.status(404).json({ error: "shipment_not_found" });

    await updateShipmentStatus(
      trackResult.shipment.ShipmentId,
      status,
      description,
      {
        location: body.location || body.ubicacion,
        city: body.city || body.ciudad,
        countryCode: body.countryCode || body.pais,
        carrierEventCode: body.eventCode || body.codigo,
        source: "CARRIER",
      }
    );
    try { obs.event('shipping.shipment.status_updated', { trackingNumber, status, carrierCode, module: 'shipping' }); } catch { /* never blocks */ }
    res.json({ ok: true });
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ════════════════════════════════════════════════════════════
// PROTECTED ROUTES (require shipping customer auth)
// ════════════════════════════════════════════════════════════

shippingRouter.use("/my", shippingAuth);

// ─── Profile ─────────────────────────────────────────────────

shippingRouter.get("/my/profile", async (req, res) => {
  try {
    const profile = await getCustomerProfile(customerId(req));
    if (!profile) return res.status(404).json({ error: "not_found" });
    res.json(profile);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Addresses ───────────────────────────────────────────────

shippingRouter.get("/my/addresses", async (req, res) => {
  try {
    res.json(await listAddresses(customerId(req)));
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

const addressSchema = z.object({
  shippingAddressId: z.number().optional(),
  label: z.string().max(60).optional(),
  contactName: z.string().min(1).max(150),
  phone: z.string().max(60).optional(),
  addressLine1: z.string().min(1).max(300),
  addressLine2: z.string().max(300).optional(),
  city: z.string().min(1).max(100),
  state: z.string().max(100).optional(),
  postalCode: z.string().max(20).optional(),
  countryCode: z.string().max(3).optional(),
  isDefault: z.boolean().optional(),
});

shippingRouter.post("/my/addresses", async (req, res) => {
  try {
    const parsed = addressSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });
    const result = await upsertAddress(customerId(req), parsed.data);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Carriers ────────────────────────────────────────────────

shippingRouter.get("/my/carriers", async (_req, res) => {
  try {
    res.json(await listCarriers());
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Quotes ──────────────────────────────────────────────────

const quoteSchema = z.object({
  originCity: z.string().min(1),
  originState: z.string().optional(),
  originPostalCode: z.string().optional(),
  originCountryCode: z.string().max(3),
  destCity: z.string().min(1),
  destState: z.string().optional(),
  destPostalCode: z.string().optional(),
  destCountryCode: z.string().max(3),
  packages: z.array(z.object({
    weight: z.number().min(0),
    weightUnit: z.string().optional(),
    length: z.number().optional(),
    width: z.number().optional(),
    height: z.number().optional(),
    dimensionUnit: z.string().optional(),
    declaredValue: z.number().optional(),
  })).min(1),
  serviceType: z.string().optional(),
  declaredValue: z.number().optional(),
  currency: z.string().optional(),
});

shippingRouter.post("/my/quotes", async (req, res) => {
  try {
    const parsed = quoteSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });
    const rates = await getQuotes(parsed.data);
    res.json({ rates });
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Shipments ───────────────────────────────────────────────

shippingRouter.get("/my/shipments", async (req, res) => {
  try {
    const { status, search, page, limit } = req.query;
    const result = await listShipments(customerId(req), {
      status: status as string,
      search: search as string,
      page: page ? Number(page) : 1,
      limit: limit ? Number(limit) : 20,
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

const createShipmentSchema = z.object({
  carrierCode: z.string().optional(),
  serviceType: z.string().optional(),
  origin: z.object({
    contactName: z.string().min(1),
    phone: z.string().optional(),
    address: z.string().min(1),
    city: z.string().min(1),
    state: z.string().optional(),
    postalCode: z.string().optional(),
    countryCode: z.string().max(3).optional(),
  }),
  destination: z.object({
    contactName: z.string().min(1),
    phone: z.string().optional(),
    address: z.string().min(1),
    city: z.string().min(1),
    state: z.string().optional(),
    postalCode: z.string().optional(),
    countryCode: z.string().max(3).optional(),
  }),
  packages: z.array(z.object({
    weight: z.number().min(0),
    weightUnit: z.string().optional(),
    length: z.number().optional(),
    width: z.number().optional(),
    height: z.number().optional(),
    dimensionUnit: z.string().optional(),
    contentDescription: z.string().optional(),
    declaredValue: z.number().optional(),
    hsCode: z.string().optional(),
    countryOfOrigin: z.string().optional(),
  })).optional(),
  declaredValue: z.number().optional(),
  currency: z.string().optional(),
  description: z.string().optional(),
  notes: z.string().optional(),
  reference: z.string().optional(),
});

shippingRouter.post("/my/shipments", async (req, res) => {
  try {
    const parsed = createShipmentSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });
    const result = await createShipment(customerId(req), parsed.data);
    if (!result.ok) return res.status(400).json({ error: result.error });
    try { obs.event('shipping.shipment.created', { shipmentId: result.shipmentId, customerId: customerId(req), carrier: parsed.data.carrierCode, module: 'shipping' }); } catch { /* never blocks */ }
    res.status(201).json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

shippingRouter.get("/my/shipments/:id", async (req, res) => {
  try {
    const result = await getShipment(Number(req.params.id), customerId(req));
    if (!result.shipment) return res.status(404).json({ error: "not_found" });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Customs ─────────────────────────────────────────────────

const customsSchema = z.object({
  contentType: z.string().optional(),
  totalDeclaredValue: z.number().min(0),
  currency: z.string().optional(),
  exporterName: z.string().optional(),
  exporterFiscalId: z.string().optional(),
  importerName: z.string().optional(),
  importerFiscalId: z.string().optional(),
  originCountryCode: z.string().max(3),
  destCountryCode: z.string().max(3),
  hsCode: z.string().optional(),
  itemDescription: z.string().min(1),
  quantity: z.number().optional(),
  weightKg: z.number().optional(),
  notes: z.string().optional(),
});

shippingRouter.post("/my/shipments/:id/customs", async (req, res) => {
  try {
    const parsed = customsSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });
    const result = await upsertCustoms(Number(req.params.id), parsed.data);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Dashboard ───────────────────────────────────────────────

shippingRouter.get("/my/dashboard", async (req, res) => {
  try {
    const data = await getDashboard(customerId(req));
    res.json(data || {});
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});
