/**
 * billing.service.ts — Lógica de negocio para facturación SaaS via Paddle
 */

import { paddleApi } from "./paddle.client.js";
import { PLANS, type WebhookEvent } from "./billing.types.js";
import { callSp, callSpOut } from "../../db/query.js";

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
  const companyId = customData?.["companyId"]
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
  } catch (err) {
    console.error("[billing] Error guardando subscription.updated:", err);
  }

  return { handled: true };
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
