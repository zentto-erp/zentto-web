/**
 * Proxy del ERP al microservicio zentto-payments.
 * El ERP autentica al usuario (JWT), valida que es admin, y delega la operación
 * al microservicio usando ZENTTO_PAYMENTS_API_KEY del server.
 *
 * Endpoints:
 *   GET    /v1/payment-accounts/providers              — lista providers disponibles
 *   GET    /v1/payment-accounts/providers/:code/config — fields para el form
 *   GET    /v1/payment-accounts                        — accounts del companyId del scope
 *   POST   /v1/payment-accounts                        — crea/actualiza account
 *   GET    /v1/payment-accounts/:id/preview            — credenciales enmascaradas
 *   DELETE /v1/payment-accounts/:id                    — soft-delete
 */
import { Router, type Request, type Response } from "express";
import { requireJwt, requireAdmin, type AuthenticatedRequest } from "../../middleware/auth.js";

export const paymentAccountsRouter = Router();
paymentAccountsRouter.use(requireJwt);

const PAYMENTS_URL = process.env.ZENTTO_PAYMENTS_URL || "https://payments.zentto.net";
const PAYMENTS_KEY = process.env.ZENTTO_PAYMENTS_API_KEY || "";

async function paymentsFetch(method: string, path: string, body?: unknown) {
  if (!PAYMENTS_KEY) throw new Error("ZENTTO_PAYMENTS_API_KEY no configurado en el server");
  const res = await fetch(`${PAYMENTS_URL}${path}`, {
    method,
    headers: {
      "Content-Type": "application/json",
      "X-API-Key": PAYMENTS_KEY,
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const json = await res.json().catch(() => ({}));
  return { status: res.status, body: json as Record<string, unknown> };
}

paymentAccountsRouter.get("/providers", async (req: Request, res: Response) => {
  try {
    const qs = new URLSearchParams(req.query as Record<string, string>).toString();
    const r = await paymentsFetch("GET", `/v1/admin/providers${qs ? `?${qs}` : ""}`);
    res.status(r.status).json(r.body);
  } catch (err: unknown) {
    res.status(502).json({ error: "payments_unavailable", message: err instanceof Error ? err.message : String(err) });
  }
});

paymentAccountsRouter.get("/providers/:code/config", async (req: Request, res: Response) => {
  try {
    const r = await paymentsFetch("GET", `/v1/admin/providers/${req.params.code}/config-fields`);
    res.status(r.status).json(r.body);
  } catch (err: unknown) {
    res.status(502).json({ error: "payments_unavailable" });
  }
});

paymentAccountsRouter.get("/", async (req: Request, res: Response) => {
  try {
    const companyId = (req as AuthenticatedRequest).scope?.companyId;
    if (!companyId) {
      res.status(401).json({ error: "no_scope" });
      return;
    }
    const r = await paymentsFetch("GET", `/v1/admin/accounts?companyId=${companyId}`);
    res.status(r.status).json(r.body);
  } catch (err: unknown) {
    res.status(502).json({ error: "payments_unavailable" });
  }
});

paymentAccountsRouter.post("/", requireAdmin, async (req: Request, res: Response) => {
  try {
    const companyId = (req as AuthenticatedRequest).scope?.companyId;
    if (!companyId) {
      res.status(401).json({ error: "no_scope" });
      return;
    }
    // Forzar companyId del scope autenticado (no del body) — seguridad
    const payload = { ...req.body, companyId };
    const r = await paymentsFetch("POST", "/v1/admin/accounts", payload);
    res.status(r.status).json(r.body);
  } catch (err: unknown) {
    res.status(502).json({ error: "payments_unavailable", message: err instanceof Error ? err.message : "" });
  }
});

paymentAccountsRouter.get("/:id/preview", requireAdmin, async (req: Request, res: Response) => {
  try {
    const r = await paymentsFetch("GET", `/v1/admin/accounts/${req.params.id}/preview`);
    res.status(r.status).json(r.body);
  } catch (err: unknown) {
    res.status(502).json({ error: "payments_unavailable" });
  }
});

paymentAccountsRouter.delete("/:id", requireAdmin, async (req: Request, res: Response) => {
  try {
    const r = await paymentsFetch("DELETE", `/v1/admin/accounts/${req.params.id}`);
    res.status(r.status).json(r.body);
  } catch (err: unknown) {
    res.status(502).json({ error: "payments_unavailable" });
  }
});
