/**
 * Endpoints públicos que aceptan `X-Tenant-Key` y resuelven el tenant por
 * la PublicApiKey (cfg.PublicApiKey). Cada endpoint exige un scope distinto
 * de la key antes de ejecutar.
 *
 * Diseñados para que sitios externos de tenants clientes (acme.com) puedan
 * usar notify/cache sin usar el master key de la plataforma.
 *
 * Scopes requeridos por endpoint:
 *   POST /notify/email/send       → notify:email:send
 *   POST /notify/otp/send         → notify:otp:send
 *   POST /notify/otp/verify       → notify:otp:send
 *   POST /notify/contacts/upsert  → notify:contacts:upsert
 *   GET  /cache/:resource/:id     → cache:read
 *   PUT  /cache/:resource/:id     → cache:write
 */
import { Router, Request, Response, NextFunction } from "express";
import { notify } from "@zentto/platform-client";
import { resolvePublicApiKeyScope } from "../landing/service.js";

const notifyClient = notify.notifyFromEnv({
  onError: (err, ctx) => console.warn(`[tenant-public/notify] ${ctx.path} attempt=${ctx.attempt}: ${err.message}`),
});

export const tenantPublicRouter = Router();

/**
 * Middleware: valida X-Tenant-Key con scope exigido y expone
 * req._tenantCompanyId. Si falta o no tiene el scope, 401/403.
 */
function requireScope(scope: string) {
  return async (req: Request, res: Response, next: NextFunction) => {
    const key = (req.headers["x-tenant-key"] as string | undefined)?.trim();
    if (!key) {
      res.status(401).json({ ok: false, error: "Missing X-Tenant-Key" });
      return;
    }
    const companyId = await resolvePublicApiKeyScope(key, scope);
    if (!companyId) {
      res.status(403).json({ ok: false, error: `Key inválida o sin scope requerido: ${scope}` });
      return;
    }
    (req as any)._tenantCompanyId = companyId;
    next();
  };
}

// ── Notify ─────────────────────────────────────────────────────────────────
tenantPublicRouter.post("/notify/email/send", requireScope("notify:email:send"), async (req, res) => {
  const r = await notifyClient.email.send(req.body);
  res.status(r.ok ? 200 : 502).json(r);
});

tenantPublicRouter.post("/notify/otp/send", requireScope("notify:otp:send"), async (req, res) => {
  const r = await notifyClient.otp.send(req.body);
  res.status(r.ok ? 200 : 502).json(r);
});

tenantPublicRouter.post("/notify/otp/verify", requireScope("notify:otp:send"), async (req, res) => {
  const r = await notifyClient.otp.verify(req.body);
  res.status(r.ok ? 200 : 400).json(r);
});

tenantPublicRouter.post("/notify/contacts/upsert", requireScope("notify:contacts:upsert"), async (req, res) => {
  const r = await notifyClient.contacts.upsert(req.body);
  res.status(r.ok ? 200 : 502).json(r);
});
