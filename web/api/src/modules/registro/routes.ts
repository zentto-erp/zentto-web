import { Router, Request, Response, NextFunction } from "express";
import { startTrial, startCheckout } from "./service.js";
import { callSp } from "../../db/query.js";

export const registroRouter = Router();

// Rate limiter in-memory simple (20 intentos/hora por IP). Suficiente para
// endpoints públicos hasta que se añada redis. Nginx ya hace throttling adicional.
const attempts = new Map<string, { count: number; resetAt: number }>();
const WINDOW_MS = 60 * 60 * 1000;
const MAX_ATTEMPTS = 20;

function registroLimiter(req: Request, res: Response, next: NextFunction): void {
  const ip = (req.ip || req.socket.remoteAddress || "unknown").toString();
  const now = Date.now();
  const entry = attempts.get(ip);
  if (!entry || entry.resetAt < now) {
    attempts.set(ip, { count: 1, resetAt: now + WINDOW_MS });
    next();
    return;
  }
  if (entry.count >= MAX_ATTEMPTS) {
    res.status(429).json({ ok: false, error: "rate_limited", message: "Demasiados intentos, intenta en 1 hora" });
    return;
  }
  entry.count += 1;
  next();
}

registroRouter.use(registroLimiter);

function validateRegistroBody(body: any): { ok: true } | { ok: false; error: string } {
  if (!body) return { ok: false, error: "body_required" };
  if (!body.email || typeof body.email !== "string" || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(body.email)) {
    return { ok: false, error: "email_inválido" };
  }
  if (!body.fullName || typeof body.fullName !== "string" || body.fullName.length < 2) {
    return { ok: false, error: "fullName_required" };
  }
  if (!body.companyName || typeof body.companyName !== "string" || body.companyName.length < 2) {
    return { ok: false, error: "companyName_required" };
  }
  if (!body.subdomain || !/^[a-z0-9]([a-z0-9-]*[a-z0-9])?$/.test(body.subdomain) || body.subdomain.length < 3 || body.subdomain.length > 63) {
    return { ok: false, error: "subdomain_inválido" };
  }
  if (!body.planSlug || typeof body.planSlug !== "string") {
    return { ok: false, error: "planSlug_required" };
  }
  return { ok: true };
}

// POST /v1/registro/lead
// Captura un lead antes del registro completo (formulario corto en landing)
registroRouter.post("/lead", async (req, res) => {
  try {
    const b = req.body ?? {};
    if (!b.email || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(b.email)) {
      res.status(400).json({ ok: false, error: "email_inválido" });
      return;
    }
    const rows = await callSp<{ ok: boolean; mensaje: string; LeadId: number }>(
      "usp_public_lead_upsert",
      {
        Email: b.email.toLowerCase(),
        FullName: b.fullName || "",
        Company: b.companyName || "",
        Country: b.country || "",
        Source: b.source || "lead-form",
        VerticalInterest: b.vertical || "",
        PlanSlug: b.planSlug || "",
        AddonSlugs: JSON.stringify(b.addonSlugs || []),
        IntendedSubdomain: b.subdomain || "",
        UtmSource: b.utm?.source || "",
        UtmMedium: b.utm?.medium || "",
        UtmCampaign: b.utm?.campaign || "",
      }
    );
    res.json({ ok: true, leadId: rows[0]?.LeadId });
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

// POST /v1/registro/trial
registroRouter.post("/trial", async (req, res) => {
  try {
    const validation = validateRegistroBody(req.body);
    if (!validation.ok) {
      res.status(400).json({ ok: false, error: validation.error });
      return;
    }
    const result = await startTrial(req.body);
    if (!result.ok) {
      res.status(400).json(result);
      return;
    }
    res.status(201).json(result);
  } catch (err: any) {
    console.error("[registro/trial]", err);
    res.status(500).json({ ok: false, error: err.message });
  }
});

// POST /v1/registro/checkout
registroRouter.post("/checkout", async (req, res) => {
  try {
    const validation = validateRegistroBody(req.body);
    if (!validation.ok) {
      res.status(400).json({ ok: false, error: validation.error });
      return;
    }
    const billingCycle = req.body.billingCycle === "annual" ? "annual" : "monthly";
    const result = await startCheckout({ ...req.body, billingCycle });
    if (!result.ok) {
      res.status(400).json(result);
      return;
    }
    res.status(201).json(result);
  } catch (err: any) {
    console.error("[registro/checkout]", err);
    res.status(500).json({ ok: false, error: err.message });
  }
});
