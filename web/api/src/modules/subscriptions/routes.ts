/**
 * subscriptions/routes.ts — Self-service de suscripción del tenant.
 *
 * Endpoints (requieren JWT del tenant):
 *   GET    /v1/subscriptions/me            estado actual + items activos
 *   GET    /v1/subscriptions/entitlements  módulos efectivos del tenant
 *   POST   /v1/subscriptions/items         añade un addon (checkout Paddle)
 *   DELETE /v1/subscriptions/items/:id     cancela un addon
 */
import { Router, type Request } from "express";
import { callSp } from "../../db/query.js";
import { getPlanBySlug } from "../catalog/service.js";
import { paddleApi } from "../billing/paddle.client.js";

export const subscriptionsRouter = Router();

function getCompanyId(req: Request): number | null {
  const fromJwt = (req as any).user?.companyId ?? (req as any).user?.CompanyId;
  if (fromJwt) return Number(fromJwt);
  const fromHeader = req.headers["x-company-id"];
  if (fromHeader) return Number(fromHeader);
  return null;
}

// GET /v1/subscriptions/me
subscriptionsRouter.get("/me", async (req, res) => {
  try {
    const companyId = getCompanyId(req);
    if (!companyId) {
      res.status(401).json({ ok: false, error: "company_not_resolved" });
      return;
    }
    const rows = await callSp<any>("usp_sys_subscription_get_by_company", { CompanyId: companyId });
    const sub = rows[0] ?? null;
    res.json({ ok: true, subscription: sub });
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

// GET /v1/subscriptions/entitlements
subscriptionsRouter.get("/entitlements", async (req, res) => {
  try {
    const companyId = getCompanyId(req);
    if (!companyId) {
      res.status(401).json({ ok: false, error: "company_not_resolved" });
      return;
    }
    const rows = await callSp<{
      CompanyId: number;
      ModuleCodes: string[];
      Plans: string[];
      ExpiresAt: string;
      IsActive: boolean;
    }>("usp_sys_subscription_entitlements", { CompanyId: companyId });
    res.json({ ok: true, entitlements: rows[0] });
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

// POST /v1/subscriptions/items — body: { addonSlug, billingCycle: 'monthly'|'annual' }
subscriptionsRouter.post("/items", async (req, res) => {
  try {
    const companyId = getCompanyId(req);
    if (!companyId) {
      res.status(401).json({ ok: false, error: "company_not_resolved" });
      return;
    }
    const b = req.body ?? {};
    if (!b.addonSlug) {
      res.status(400).json({ ok: false, error: "addonSlug_required" });
      return;
    }
    const plan = await getPlanBySlug(b.addonSlug);
    if (!plan || !plan.IsActive) {
      res.status(404).json({ ok: false, error: "plan_not_found" });
      return;
    }
    const sub = (await callSp<any>("usp_sys_subscription_get_by_company", { CompanyId: companyId }))[0];
    if (!sub) {
      res.status(400).json({ ok: false, error: "no_active_subscription" });
      return;
    }

    const billingCycle: "monthly" | "annual" = b.billingCycle === "annual" ? "annual" : "monthly";
    const priceId = billingCycle === "annual" ? plan.PaddlePriceIdAnnual : plan.PaddlePriceIdMonthly;

    // Si la suscripción es pagada (Paddle), creamos transacción para cobrar el addon.
    // Si es trial, añadimos el item directo sin cobro (el upgrade se hace al convertir a paid).
    if (sub.Source === "paddle" && sub.PaddleSubscriptionId && priceId) {
      const transaction = await paddleApi.post<{ id: string; checkout?: { url: string } }>("/transactions", {
        items: [{ price_id: priceId, quantity: 1 }],
        customer: { id: sub.PaddleCustomerId },
        custom_data: {
          companyId,
          subscriptionId: sub.SubscriptionId,
          addonSlug: b.addonSlug,
          action: "add_addon",
          billingCycle,
        },
      });
      res.json({ ok: true, mode: "paddle_checkout", transactionId: transaction.id, checkoutUrl: transaction.checkout?.url });
      return;
    }

    // Trial o manual: añadir item sin cobro
    await callSp("usp_sys_subscription_item_add", {
      SubscriptionId: sub.SubscriptionId,
      CompanyId: companyId,
      PricingPlanId: plan.PricingPlanId,
      Quantity: 1,
      PaddleSubscriptionItemId: "",
      PaddlePriceId: "",
      UnitPrice: billingCycle === "annual" ? plan.AnnualPrice : plan.MonthlyPrice,
      BillingCycle: billingCycle,
    });
    res.json({ ok: true, mode: "direct_add", mensaje: "Addon añadido sin cobro (trial)" });
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

// DELETE /v1/subscriptions/items/:id
subscriptionsRouter.delete("/items/:id", async (req, res) => {
  try {
    const companyId = getCompanyId(req);
    if (!companyId) {
      res.status(401).json({ ok: false, error: "company_not_resolved" });
      return;
    }
    const itemId = Number(req.params.id);
    if (!itemId) {
      res.status(400).json({ ok: false, error: "id_inválido" });
      return;
    }
    const rows = await callSp<{ ok: boolean; mensaje: string }>(
      "usp_sys_subscription_item_remove",
      { SubscriptionItemId: itemId }
    );
    res.json(rows[0] ?? { ok: false, mensaje: "error" });
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});
