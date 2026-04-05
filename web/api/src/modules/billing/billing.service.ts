/**
 * billing.service.ts — Lógica de negocio para facturación SaaS via Paddle
 */

import { randomBytes } from "node:crypto";
import { paddleApi } from "./paddle.client.js";
import { PLANS, type WebhookEvent } from "./billing.types.js";
import { callSp, callSpOut } from "../../db/query.js";
import { invalidateSubscriptionCache } from "../../middleware/subscription.js";
import { provisionTenant, sendWelcomeEmail } from "../tenants/tenant.service.js";
import { syncPlanModules } from "../iam/enforcement/plan-sync.service.js";

// ── Planes ───────────────────────────────────────────────────────────────────

export function getPlans() {
  return PLANS;
}

// ── Checkout ─────────────────────────────────────────────────────────────────

interface PaddleTransaction {
  id: string;
  checkout?: { url?: string };
}

/**
 * Crea una transacción en Paddle para iniciar el checkout.
 * El frontend puede usar el checkout URL o el price_id con Paddle.js overlay.
 */
export async function createCheckout(
  companyId: number,
  priceId: string,
  customerEmail: string
) {
  // Validar que el priceId es de un plan conocido
  const plan = PLANS.find((p) => p.priceId === priceId);
  if (!plan) {
    throw new Error("Plan no válido");
  }

  const transaction = await paddleApi.post<PaddleTransaction>(
    "/transactions",
    {
      items: [{ price_id: priceId, quantity: 1 }],
      customer: { email: customerEmail },
      custom_data: { companyId: String(companyId) },
    }
  );

  return {
    transactionId: transaction.id,
    checkoutUrl: transaction.checkout?.url ?? null,
    priceId,
    planName: plan.name,
  };
}

// ── Webhook ──────────────────────────────────────────────────────────────────

/**
 * Procesa eventos de webhook de Paddle.
 * Eventos manejados:
 *  - transaction.completed
 *  - subscription.created
 *  - subscription.updated
 *  - subscription.canceled
 */
export async function handleWebhookEvent(
  event: WebhookEvent
): Promise<{ handled: boolean; reason?: string }> {
  const { event_type, data } = event;

  switch (event_type) {
    case "transaction.completed":
      return handleTransactionCompleted(data);
    case "subscription.created":
      return handleSubscriptionCreated(data);
    case "subscription.updated":
      return handleSubscriptionUpdated(data);
    case "subscription.canceled":
      return handleSubscriptionCanceled(data);
    default:
      return { handled: false, reason: `evento_no_manejado: ${event_type}` };
  }
}

async function handleTransactionCompleted(
  data: Record<string, unknown>
): Promise<{ handled: boolean; reason?: string }> {
  const customData = data["custom_data"] as Record<string, string> | undefined;
  const companyId = customData?.["companyId"]
    ? Number(customData["companyId"])
    : null;

  if (!companyId) {
    return { handled: false, reason: "sin_company_id_en_custom_data" };
  }

  // Registrar la transacción completada en BD
  try {
    await callSpOut("usp_sys_BillingEvent_Insert", {
      CompanyId: companyId,
      EventType: "transaction.completed",
      PaddleEventId: data["id"] as string,
      Payload: JSON.stringify(data),
    });
  } catch (err) {
    console.error("[billing] Error guardando transaction.completed:", err);
  }

  return { handled: true };
}

async function handleSubscriptionCreated(
  data: Record<string, unknown>
): Promise<{ handled: boolean; reason?: string }> {
  const subscriptionId = data["id"] as string;
  const customerId = (data["customer_id"] as string) ?? null;
  const status = data["status"] as string;
  const customData = data["custom_data"] as Record<string, string> | undefined;
  let companyId = customData?.["companyId"]
    ? Number(customData["companyId"])
    : null;

  const items = data["items"] as Array<Record<string, unknown>> | undefined;
  const priceId = (items?.[0]?.["price"] as Record<string, unknown>)?.["id"] as
    | string
    | undefined;
  const plan = PLANS.find((p) => p.priceId === priceId);

  const currentPeriod = data["current_billing_period"] as
    | Record<string, string>
    | undefined;

  // ── Provisionar tenant si es nueva suscripción (checkout con subdomain/companyName) ──
  const chosenSubdomain = customData?.["subdomain"]?.toLowerCase().replace(/[^a-z0-9-]/g, "").slice(0, 30) || "";
  const chosenCompanyName = customData?.["companyName"] || "";

  if (!companyId && (chosenSubdomain || chosenCompanyName)) {
    console.log("[billing] Nueva suscripción detectada — provisionando tenant...");

    // Obtener email del customer via Paddle API
    let customerEmail = "";
    if (customerId) {
      try {
        const customer = await paddleApi.get<{ email: string }>(`/customers/${customerId}`);
        customerEmail = customer.email;
      } catch (err) {
        console.error("[billing] Error obteniendo customer de Paddle:", err);
      }
    }

    if (!customerEmail) {
      console.error("[billing] No se pudo obtener email del customer — provisioning abortado");
      return { handled: false, reason: "no_customer_email" };
    }

    // Determinar plan por priceId
    const resolvedPlan: "FREE" | "STARTER" | "PRO" | "ENTERPRISE" =
      plan?.id === "profesional" ? "PRO"
      : plan?.id === "basico" ? "STARTER"
      : "STARTER";

    // Generar códigos
    const companyCode = chosenSubdomain
      ? chosenSubdomain.toUpperCase().replace(/-/g, "").slice(0, 20)
      : (() => {
          const slug = customerEmail.split("@")[0].replace(/[^a-z0-9]/gi, "").toUpperCase().slice(0, 12);
          return `${slug}${randomBytes(3).toString("hex").toUpperCase()}`;
        })();
    const adminUserCode = customerEmail.toUpperCase().replace(/[^A-Z0-9]/g, "").slice(0, 40);
    const tempPassword = randomBytes(8).toString("hex");

    try {
      const result = await provisionTenant({
        companyCode,
        legalName: chosenCompanyName || customerEmail,
        ownerEmail: customerEmail,
        countryCode: "VE",
        baseCurrency: "USD",
        adminUserCode,
        adminPassword: tempPassword,
        plan: resolvedPlan,
        paddleSubscriptionId: subscriptionId,
      });

      if (result.ok) {
        companyId = result.companyId;
        console.log(`[billing] Tenant provisionado: CompanyId=${companyId}`);

        // Actualizar subdomain si fue personalizado
        if (chosenSubdomain) {
          await callSp("usp_Cfg_Tenant_SetSubdomain", {
            CompanyId: companyId,
            Subdomain: chosenSubdomain,
          }).catch(() => {});
        }

        // Email de bienvenida
        const tenantUrl = chosenSubdomain ? `https://${chosenSubdomain}.zentto.net` : "https://app.zentto.net";
        sendWelcomeEmail(customerEmail, chosenCompanyName || customerEmail, tempPassword, companyId, tenantUrl).catch(() => {});
      } else {
        console.error(`[billing] Provisioning falló: ${result.mensaje}`);
      }
    } catch (err) {
      console.error("[billing] Error provisionando tenant:", err);
    }
  }

  // ── Registrar/actualizar suscripción en BD ──
  try {
    await callSpOut("usp_sys_Subscription_Upsert", {
      CompanyId: companyId,
      PaddleSubscriptionId: subscriptionId,
      PaddleCustomerId: customerId,
      PriceId: priceId ?? null,
      PlanName: plan?.name ?? "Desconocido",
      Status: status,
      CurrentPeriodStart: currentPeriod?.["starts_at"] ?? null,
      CurrentPeriodEnd: currentPeriod?.["ends_at"] ?? null,
    });
    if (companyId) invalidateSubscriptionCache(companyId);
  } catch (err) {
    console.error("[billing] Error guardando subscription.created:", err);
  }

  return { handled: true };
}

async function handleSubscriptionUpdated(
  data: Record<string, unknown>
): Promise<{ handled: boolean; reason?: string }> {
  const subscriptionId = data["id"] as string;
  const status = data["status"] as string;

  const items = data["items"] as Array<Record<string, unknown>> | undefined;
  const priceId = (items?.[0]?.["price"] as Record<string, unknown>)?.["id"] as
    | string
    | undefined;
  const plan = PLANS.find((p) => p.priceId === priceId);

  const currentPeriod = data["current_billing_period"] as
    | Record<string, string>
    | undefined;

  try {
    await callSpOut("usp_sys_Subscription_Upsert", {
      PaddleSubscriptionId: subscriptionId,
      PriceId: priceId ?? null,
      PlanName: plan?.name ?? "Desconocido",
      Status: status,
      CurrentPeriodStart: currentPeriod?.["starts_at"] ?? null,
      CurrentPeriodEnd: currentPeriod?.["ends_at"] ?? null,
    });
    // Invalidar cache de la empresa asociada
    await invalidateByPaddleSubId(subscriptionId);

    // Sync plan modules when plan changes
    if (plan?.name) {
      await syncPlanModules(subscriptionId, plan.name).catch((err) => {
        console.error("[billing] Error syncing plan modules:", err);
      });
    }
  } catch (err) {
    console.error("[billing] Error guardando subscription.updated:", err);
  }

  return { handled: true };
}

/** Busca companyId por PaddleSubscriptionId e invalida su cache */
async function invalidateByPaddleSubId(paddleSubId: string) {
  try {
    const rows = await callSp<{ CompanyId: number }>(
      "usp_sys_Subscription_GetByPaddleId",
      { PaddleSubscriptionId: paddleSubId }
    );
    if (rows[0]?.CompanyId) invalidateSubscriptionCache(rows[0].CompanyId);
  } catch { /* ignore */ }
}

async function handleSubscriptionCanceled(
  data: Record<string, unknown>
): Promise<{ handled: boolean; reason?: string }> {
  const subscriptionId = data["id"] as string;
  const canceledAt = data["canceled_at"] as string | null;

  try {
    await callSpOut("usp_sys_Subscription_Upsert", {
      PaddleSubscriptionId: subscriptionId,
      Status: "canceled",
      CancelledAt: canceledAt,
    });
    await invalidateByPaddleSubId(subscriptionId);
  } catch (err) {
    console.error("[billing] Error guardando subscription.canceled:", err);
  }

  return { handled: true };
}

// ── Consulta de suscripción ──────────────────────────────────────────────────

export async function getSubscription(companyId: number) {
  const rows = await callSp<Record<string, unknown>>(
    "usp_sys_Subscription_GetByCompany",
    { CompanyId: companyId }
  );
  return rows[0] ?? null;
}

// ── Portal de cliente Paddle ─────────────────────────────────────────────────

interface PaddlePortalSession {
  id: string;
  urls: { general: { overview: string } };
}

export async function getPortalUrl(customerId: string) {
  const session = await paddleApi.post<PaddlePortalSession>(
    `/customers/${customerId}/portal-sessions`,
    {}
  );
  return session.urls.general.overview;
}

// ── Cancelación ──────────────────────────────────────────────────────────────

interface PaddleSubscription {
  id: string;
  status: string;
}

export async function cancelSubscription(subscriptionId: string) {
  const result = await paddleApi.post<PaddleSubscription>(
    `/subscriptions/${subscriptionId}/cancel`,
    { effective_from: "next_billing_period" }
  );
  return {
    subscriptionId: result.id,
    status: result.status,
  };
}
