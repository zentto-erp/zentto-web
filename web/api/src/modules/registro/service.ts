/**
 * registro/service.ts — Alta unificada de tenants (trial o paid).
 *
 * Flujos:
 *   • trial: provisiona tenant inmediato sin cobro (cfg.TrialUsage anti-abuso)
 *   • checkout: crea transacción Paddle con custom_data → webhook provisiona
 *
 * Siempre crea/actualiza un lead en public.Lead antes de continuar, para
 * tener trazabilidad del embudo landing → registro → conversión.
 */

import { callSp } from "../../db/query.js";
import { getPlanBySlug } from "../catalog/service.js";
import { provisionTenant, sendWelcomeEmail, resolveTenantByEmail } from "../tenants/tenant.service.js";
import { paddleApi } from "../billing/paddle.client.js";
import { authCreateOwner } from "../_shared/zentto-auth.client.js";
import crypto from "node:crypto";

export interface RegistroBase {
  email: string;
  fullName: string;
  companyName: string;
  countryCode: string;
  subdomain: string;
  planSlug: string;
  addonSlugs?: string[];
  utm?: { source?: string; medium?: string; campaign?: string };
  vertical?: string;
}

export interface TrialResult {
  ok: boolean;
  mensaje: string;
  companyId?: number;
  subdomain?: string;
  expiresAt?: string;
  magicLinkSent?: boolean;
}

export interface CheckoutResult {
  ok: boolean;
  mensaje: string;
  transactionId?: string;
  checkoutUrl?: string;
}

function genTempPassword(): string {
  return crypto.randomBytes(12).toString("base64url");
}

function sanitizeCode(s: string, max = 20): string {
  return s
    .toUpperCase()
    .replace(/[^A-Z0-9]/g, "")
    .slice(0, max) || `T${Date.now().toString().slice(-6)}`;
}

async function upsertLead(input: RegistroBase & { source: string; intent: string }) {
  await callSp("usp_public_lead_upsert", {
    Email: input.email.toLowerCase(),
    FullName: input.fullName,
    Company: input.companyName,
    Country: input.countryCode,
    Source: input.source,
    VerticalInterest: input.vertical ?? "",
    PlanSlug: input.planSlug,
    AddonSlugs: JSON.stringify(input.addonSlugs ?? []),
    IntendedSubdomain: input.subdomain,
    UtmSource: input.utm?.source ?? "",
    UtmMedium: input.utm?.medium ?? "",
    UtmCampaign: input.utm?.campaign ?? "",
  }).catch((err) => {
    console.warn("[registro] Lead upsert falló (no bloquea):", err.message);
  });
}

/**
 * Reenvía el magic-link a un owner que ya tiene tenant pero no recibió el email.
 * Usado como fallback cuando EMAIL_ALREADY_EXISTS o trial_already_used.
 */
async function resendMagicLinkToExisting(
  email: string,
  companyName: string,
): Promise<{ ok: boolean; magicLinkSent: boolean; companyId: number; subdomain: string; expiresAt?: string }> {
  const tenant = await resolveTenantByEmail(email);
  if (!tenant) {
    return { ok: false, magicLinkSent: false, companyId: 0, subdomain: "" };
  }

  let magicLinkSent = false;
  const subdomain = tenant.TenantSubdomain || "";
  const tenantUrl = subdomain ? `https://${subdomain}.zentto.net` : undefined;

  try {
    const authResult = await authCreateOwner({
      email,
      fullName: email,
      companyId: tenant.CompanyId,
      companyCode: tenant.CompanyCode,
      tenantSubdomain: subdomain,
      role: "owner",
      sendMagicLink: true,
    });
    magicLinkSent = Boolean(authResult.magicLinkUrl);
    if (magicLinkSent) {
      await sendWelcomeEmail(email, companyName || tenant.LegalName, "", tenant.CompanyId, tenantUrl, "ADMIN", authResult.magicLinkUrl).catch(() => {});
    }
  } catch {
    await sendWelcomeEmail(email, companyName || tenant.LegalName, "", tenant.CompanyId, tenantUrl, "ADMIN").catch(() => {});
  }

  return { ok: true, magicLinkSent, companyId: tenant.CompanyId, subdomain };
}

/**
 * Inicia un trial: provisiona tenant sin cobro, registra TrialUsage y
 * crea al owner en zentto-auth con magic-link.
 */
export async function startTrial(input: RegistroBase): Promise<TrialResult> {
  const plan = await getPlanBySlug(input.planSlug);
  if (!plan) return { ok: false, mensaje: "plan_not_found" };
  if (!plan.IsTrialOnly) return { ok: false, mensaje: "plan_not_trial" };
  if (!plan.IsActive) return { ok: false, mensaje: "plan_inactive" };

  await upsertLead({ ...input, source: "registro-trial", intent: "trial" });

  // Anti-abuso: ¿ya usó trial de este producto?
  const trialCheck = await callSp<{ available: boolean; mensaje: string }>(
    "usp_cfg_trial_check",
    { Email: input.email, ProductCode: plan.ProductCode }
  );
  if (!trialCheck[0]?.available) {
    // El email ya tiene un trial → intentar reenviar magic-link al tenant existente
    const resend = await resendMagicLinkToExisting(input.email, input.companyName);
    if (resend.ok) {
      return {
        ok: true,
        mensaje: "account_exists_link_resent",
        companyId: resend.companyId,
        subdomain: resend.subdomain,
        magicLinkSent: resend.magicLinkSent,
      };
    }
    return { ok: false, mensaje: "trial_already_used" };
  }

  // Provisiona tenant con un password temporal (se reemplaza por magic-link)
  const tempPassword = genTempPassword();
  const companyCode = sanitizeCode(input.subdomain || input.companyName);

  const provision = await provisionTenant({
    companyCode,
    legalName: input.companyName,
    ownerEmail: input.email.toLowerCase(),
    countryCode: input.countryCode || "VE",
    baseCurrency: "USD",
    adminUserCode: "ADMIN",
    adminPassword: tempPassword,
    plan: (plan.ProductCode.toUpperCase() as "FREE" | "STARTER" | "PRO" | "ENTERPRISE"),
    skipCompanyLimit: true,
  });

  if (!provision.ok) {
    // Email ya existe en otro tenant → reenviar magic-link
    if (provision.mensaje === "EMAIL_ALREADY_EXISTS") {
      const resend = await resendMagicLinkToExisting(input.email, input.companyName);
      if (resend.ok) {
        return {
          ok: true,
          mensaje: "account_exists_link_resent",
          companyId: resend.companyId,
          subdomain: resend.subdomain,
          magicLinkSent: resend.magicLinkSent,
        };
      }
    }
    return { ok: false, mensaje: provision.mensaje };
  }

  // Fijar subdomain explícito (si el usuario lo eligió)
  if (input.subdomain) {
    await callSp("usp_Cfg_Tenant_SetSubdomain", {
      CompanyId: provision.companyId,
      Subdomain: input.subdomain.toLowerCase(),
    }).catch((err) => console.warn("[registro] SetSubdomain falló:", err.message));
  }

  // Registrar uso de trial (unique email+product)
  const trialStart = await callSp<{ ok: boolean; ExpiresAt: string }>(
    "usp_cfg_trial_start",
    {
      Email: input.email,
      ProductCode: plan.ProductCode,
      PricingPlanId: plan.PricingPlanId,
      CompanyId: provision.companyId,
      TrialDays: plan.TrialDays,
    }
  );

  // Crear suscripción source='trial' + item del plan
  const subRows = await callSp<{ ok: boolean; SubscriptionId: number }>(
    "usp_sys_subscription_create",
    {
      CompanyId: provision.companyId,
      Source: "trial",
      PaddleSubscriptionId: "",
      PaddleCustomerId: "",
      Status: "trialing",
      CurrentPeriodStart: new Date(),
      CurrentPeriodEnd: trialStart[0]?.ExpiresAt ?? null,
      TrialEndsAt: trialStart[0]?.ExpiresAt ?? null,
      TenantSubdomain: input.subdomain.toLowerCase(),
    }
  );
  const subscriptionId = subRows[0]?.SubscriptionId ?? 0;

  if (subscriptionId) {
    await callSp("usp_sys_subscription_item_add", {
      SubscriptionId: subscriptionId,
      CompanyId: provision.companyId,
      PricingPlanId: plan.PricingPlanId,
      Quantity: 1,
      PaddleSubscriptionItemId: "",
      PaddlePriceId: "",
      UnitPrice: 0,
      BillingCycle: "monthly",
    });
  }

  // Marcar lead como convertido
  await callSp("usp_public_lead_mark_converted", {
    Email: input.email,
    CompanyId: provision.companyId,
  }).catch(() => {});

  // Crear identidad en zentto-auth + enviar email de bienvenida con magic-link
  const tenantUrl = input.subdomain ? `https://${input.subdomain.toLowerCase()}.zentto.net` : undefined;
  let magicLinkSent = false;
  try {
    const authResult = await authCreateOwner({
      email: input.email,
      fullName: input.fullName,
      companyId: provision.companyId,
      companyCode,
      tenantSubdomain: input.subdomain.toLowerCase(),
      role: "owner",
      sendMagicLink: true,
    });
    // authCreateOwner devuelve magicLinkUrl — usarlo para el email de bienvenida
    await sendWelcomeEmail(
      input.email,
      input.companyName,
      tempPassword,
      provision.companyId,
      tenantUrl,
      "ADMIN",
      authResult.magicLinkUrl,
    ).catch((err: any) => console.warn("[registro] sendWelcomeEmail (magic-link) falló:", err.message));
    magicLinkSent = Boolean(authResult.magicLinkUrl);
  } catch (err: any) {
    console.warn("[registro] authCreateOwner falló, fallback a welcome clásico:", err.message);
    await sendWelcomeEmail(
      input.email,
      input.companyName,
      tempPassword,
      provision.companyId,
      tenantUrl,
      "ADMIN"
    ).catch(() => {});
  }

  return {
    ok: true,
    mensaje: "trial_started",
    companyId: provision.companyId,
    subdomain: input.subdomain.toLowerCase(),
    expiresAt: trialStart[0]?.ExpiresAt,
    magicLinkSent,
  };
}

/**
 * API pública para reenviar magic-link a usuarios que ya tienen cuenta.
 * Usado por el flujo de recuperación desde el registro.
 */
export async function resendMagicLink(email: string): Promise<{ ok: boolean; mensaje: string; magicLinkSent?: boolean }> {
  const tenant = await resolveTenantByEmail(email.toLowerCase());
  if (!tenant) return { ok: false, mensaje: "email_not_found" };

  const subdomain = tenant.TenantSubdomain || "";
  const tenantUrl = subdomain ? `https://${subdomain}.zentto.net` : undefined;

  try {
    const authResult = await authCreateOwner({
      email: email.toLowerCase(),
      fullName: email,
      companyId: tenant.CompanyId,
      companyCode: tenant.CompanyCode,
      tenantSubdomain: subdomain,
      role: "owner",
      sendMagicLink: true,
    });
    const magicLinkSent = Boolean(authResult.magicLinkUrl);
    await sendWelcomeEmail(email, tenant.LegalName, "", tenant.CompanyId, tenantUrl, "ADMIN", authResult.magicLinkUrl ?? undefined).catch(() => {});
    return { ok: true, mensaje: "magic_link_sent", magicLinkSent };
  } catch {
    await sendWelcomeEmail(email, tenant.LegalName, "", tenant.CompanyId, tenantUrl, "ADMIN").catch(() => {});
    return { ok: true, mensaje: "welcome_email_sent", magicLinkSent: false };
  }
}

/**
 * Crea una transacción Paddle para cobrar el plan base + addons.
 * El webhook de Paddle subscription.created dispara el provisioning.
 */
export async function startCheckout(input: RegistroBase & { billingCycle: "monthly" | "annual" }): Promise<CheckoutResult> {
  const plan = await getPlanBySlug(input.planSlug);
  if (!plan || !plan.IsActive) return { ok: false, mensaje: "plan_not_found" };
  if (plan.IsTrialOnly) return { ok: false, mensaje: "use_trial_endpoint" };

  const priceId = input.billingCycle === "annual" ? plan.PaddlePriceIdAnnual : plan.PaddlePriceIdMonthly;
  if (!priceId) return { ok: false, mensaje: "plan_not_synced_with_paddle" };

  // Addons opcionales
  const addonItems: { price_id: string; quantity: number }[] = [];
  for (const addonSlug of input.addonSlugs ?? []) {
    const addon = await getPlanBySlug(addonSlug);
    if (!addon || !addon.IsActive) continue;
    const addonPriceId = input.billingCycle === "annual" ? addon.PaddlePriceIdAnnual : addon.PaddlePriceIdMonthly;
    if (addonPriceId) addonItems.push({ price_id: addonPriceId, quantity: 1 });
  }

  await upsertLead({ ...input, source: "registro-paid", intent: "checkout" });

  // custom_data viaja al webhook para identificar al comprador
  const transaction = await paddleApi.post<{ id: string; checkout?: { url: string } }>("/transactions", {
    items: [{ price_id: priceId, quantity: 1 }, ...addonItems],
    customer: { email: input.email.toLowerCase() },
    custom_data: {
      email: input.email.toLowerCase(),
      fullName: input.fullName,
      companyName: input.companyName,
      countryCode: input.countryCode,
      subdomain: input.subdomain.toLowerCase(),
      planSlug: input.planSlug,
      addonSlugs: input.addonSlugs ?? [],
      billingCycle: input.billingCycle,
      utm: input.utm ?? {},
    },
    collection_mode: "automatic",
  });

  return {
    ok: true,
    mensaje: "checkout_created",
    transactionId: transaction.id,
    checkoutUrl: transaction.checkout?.url,
  };
}
