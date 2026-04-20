import crypto from "node:crypto";
import { randomBytes } from "node:crypto";
import { notifyFromEnv } from "@zentto/platform-client/notify";
import { provisionTenant, sendWelcomeEmail } from "../tenants/tenant.service.js";
import { handleWebhookEvent } from "../billing/billing.service.js";
import { provisionTenantDatabase } from "../../db/provision-tenant-db.js";
import { createSubdomainDns } from "../../lib/cloudflare.client.js";
import { obs } from "../integrations/observability.js";
import { callSp } from "../../db/query.js";
import { dedupWebhookEvent, completeWebhookEvent } from "../_shared/webhook-dedup.js";
import { createPasswordResetToken, buildSetPasswordUrl } from "../_shared/password-reset.js";
import { authCreateOwner } from "../_shared/zentto-auth.client.js";
import { withRetry, isHttp4xx } from "../_shared/retry.js";

export function verifyPaddleSignature(rawBody: Buffer, signatureHeader: string): boolean {
  const secret = process.env.PADDLE_WEBHOOK_SECRET ?? "";
  if (!secret) return false;

  // Formato Paddle: "ts=<timestamp>;h1=<hex>"
  const parts: Record<string, string> = {};
  for (const part of signatureHeader.split(";")) {
    const [k, v] = part.split("=");
    if (k && v) parts[k] = v;
  }

  if (!parts["ts"] || !parts["h1"]) return false;

  const payload = `${parts["ts"]}:${rawBody.toString("utf8")}`;
  const expected = crypto
    .createHmac("sha256", secret)
    .update(payload)
    .digest("hex");

  try {
    return crypto.timingSafeEqual(Buffer.from(parts["h1"]), Buffer.from(expected));
  } catch {
    return false;
  }
}

export async function handlePaddleEvent(
  event: Record<string, unknown>
): Promise<{ handled: boolean; reason?: string; companyId?: number }> {
  const eventType = event["event_type"] as string | undefined;
  const eventId = (event["event_id"] as string | undefined) ?? "";

  // Router de eventos: created → provisiona, updated/cancelled → re-aplica
  if (eventType === "subscription.updated") return handleSubscriptionUpdated(event);
  if (eventType === "subscription.canceled" || eventType === "subscription.cancelled") {
    return handleSubscriptionCancelled(event);
  }
  if (eventType !== "subscription.created") {
    return { handled: false, reason: "event_not_handled" };
  }

  // ── B1: Idempotencia — dedup por event_id antes de procesar ───────────────
  // Si Paddle reenvía el webhook (timeout/retry), el dedup retorna isNew=false
  // y skip todo el provisioning para evitar duplicar Company, BD, DNS, email.
  if (eventId) {
    const dedup = await dedupWebhookEvent({
      eventId,
      eventType,
      source: "paddle",
    }).catch((err) => {
      console.warn("[paddle] dedup falló (continuando como nuevo):", err?.message);
      return { isNew: true, previousStatus: undefined as string | undefined };
    });
    if (!dedup.isNew) {
      obs.audit("paddle.webhook.duplicate_skipped", { module: "webhooks", eventId, previousStatus: dedup.previousStatus });
      return { handled: true, reason: "duplicate_skipped" };
    }
  }

  const data = event["data"] as Record<string, unknown>;
  const customer = data["customer"] as Record<string, unknown> | undefined;
  const customerEmail = customer?.["email"] as string | undefined;

  if (!customerEmail) {
    await completeWebhookEvent({ eventId, status: "skipped", errorMessage: "no_customer_email" });
    return { handled: false, reason: "no_customer_email" };
  }

  const items = (data["items"] as Array<Record<string, unknown>>) ?? [];
  const subscriptionId = data["id"] as string | undefined;
  const paddleCustomerId = (customer?.["id"] as string) ?? "";

  // custom_data del checkout (subdomain + companyName elegidos por el usuario)
  const customData = data["custom_data"] as Record<string, any> | undefined;
  const chosenSubdomain = (customData?.["subdomain"] as string | undefined)?.toLowerCase().replace(/[^a-z0-9-]/g, "").slice(0, 30) || "";
  const chosenCompanyName = (customData?.["companyName"] as string | undefined) || customerEmail;
  const chosenCountryCode = ((customData?.["countryCode"] as string | undefined) || "VE").toUpperCase();
  const chosenPlanSlug = (customData?.["planSlug"] as string | undefined) || "";

  // ── F1: Resolver plan base sin fallback silencioso ────────────────────────
  // Antes: si el lookup por PaddlePriceId fallaba, se usaba STARTER hardcoded.
  // Cliente podía pagar PRO y recibir STARTER. Ahora: si el price_id no resuelve
  // ni hay planSlug en custom_data → marcar webhook como error y NO provisionar.
  // Operador debe sincronizar el plan a Paddle desde backoffice antes de retry.
  let resolvedBase: { plan: string; planId: number; moduleCodes: string[] } | null = null;
  const primaryPriceId = (items[0]?.["price"] as Record<string, unknown> | undefined)?.["id"] as string | undefined;
  if (primaryPriceId) {
    try {
      const lookupRows = await callSp<{
        PricingPlanId: number; Slug: string; ProductCode: string; ModuleCodes: string[];
      }>("usp_cfg_plan_get_by_paddle_price_id", { PaddlePriceId: primaryPriceId });
      if (lookupRows[0]) {
        resolvedBase = {
          plan: lookupRows[0].ProductCode.toUpperCase(),
          planId: lookupRows[0].PricingPlanId,
          moduleCodes: Array.isArray(lookupRows[0].ModuleCodes) ? lookupRows[0].ModuleCodes : [],
        };
      }
    } catch (err: any) {
      console.warn("[paddle] plan lookup by price_id falló:", err.message);
    }
  }
  if (!resolvedBase && chosenPlanSlug) {
    try {
      const slugRows = await callSp<{
        PricingPlanId: number; Slug: string; ProductCode: string; ModuleCodes: string[];
      }>("usp_cfg_plan_get_by_slug", { Slug: chosenPlanSlug });
      if (slugRows[0]) {
        resolvedBase = {
          plan: slugRows[0].ProductCode.toUpperCase(),
          planId: slugRows[0].PricingPlanId,
          moduleCodes: Array.isArray(slugRows[0].ModuleCodes) ? slugRows[0].ModuleCodes : [],
        };
      }
    } catch { /* falla → manejada abajo */ }
  }
  if (!resolvedBase) {
    const err = `plan_not_resolved (priceId=${primaryPriceId ?? "n/a"}, slug=${chosenPlanSlug || "n/a"})`;
    obs.error(`paddle.webhook.${err}`, { module: "webhooks", eventId, ownerEmail: customerEmail });
    await completeWebhookEvent({ eventId, status: "error", errorMessage: err });
    return { handled: false, reason: err };
  }
  const plan = resolvedBase.plan as "FREE" | "STARTER" | "PRO" | "ENTERPRISE";

  // companyCode: usar subdomain elegido o generar uno
  const companyCode = chosenSubdomain
    ? chosenSubdomain.toUpperCase().replace(/-/g, "").slice(0, 20)
    : (() => {
        const slug = customerEmail.split("@")[0].replace(/[^a-z0-9]/gi, "").toUpperCase().slice(0, 12);
        return `${slug}${randomBytes(3).toString("hex").toUpperCase()}`;
      })();
  const adminUserCode = "ADMIN";
  const tempPassword = randomBytes(8).toString("hex");

  obs.audit("tenant.provision.start", {
    module: "webhooks",
    entity: "Company",
    companyCode,
    ownerEmail: customerEmail,
    plan,
    subdomain: chosenSubdomain || null,
    paddleSubscriptionId: subscriptionId,
  });

  const result = await provisionTenant({
    companyCode,
    legalName: chosenCompanyName,
    ownerEmail: customerEmail,
    countryCode: "VE",
    baseCurrency: "USD",
    adminUserCode,
    adminPassword: tempPassword,
    plan,
    paddleSubscriptionId: subscriptionId,
  });

  if (!result.ok) {
    obs.error(`tenant.provision.failed: ${result.mensaje}`, {
      module: "webhooks",
      companyCode,
      ownerEmail: customerEmail,
    });
    await completeWebhookEvent({ eventId, status: "error", errorMessage: `provision_failed: ${result.mensaje}` });
    return { handled: true, companyId: 0 };
  }

  obs.audit("tenant.provision.ok", {
    module: "webhooks",
    entity: "Company",
    entityId: result.companyId,
    companyCode,
    ownerEmail: customerEmail,
    plan,
  });

  // ── B2: SetSubdomain ruidoso (no .catch silencioso) ───────────────────────
  // Si falla (colisión de subdomain o constraint), Notificamos error explícito
  // y dejamos el webhook como error → operador puede investigar.
  if (chosenSubdomain) {
    try {
      await callSp("usp_Cfg_Tenant_SetSubdomain", {
        CompanyId: result.companyId,
        Subdomain: chosenSubdomain,
      });
      obs.audit("tenant.subdomain.set", { module: "webhooks", companyId: result.companyId, subdomain: chosenSubdomain });
    } catch (err: any) {
      obs.error(`tenant.subdomain.failed: ${err?.message}`, {
        module: "webhooks",
        companyId: result.companyId,
        companyCode,
        subdomain: chosenSubdomain,
      });
      await completeWebhookEvent({
        eventId,
        status: "error",
        companyId: result.companyId,
        errorMessage: `subdomain_failed: ${err?.message}`.slice(0, 500),
      });
      // Continuamos para al menos crear la BD y mandar email — pero el operador
      // sabe que el subdomain no se asignó (debe corregir manualmente).
    }
  }

  // ── F5: Orden secuencial — antes handleWebhookEvent y upsertSubscriptionItems
  // corrían concurrentemente y podían crear duplicados de sys.Subscription.
  // Ahora primero registramos la subscription (handler legacy) y solo después
  // insertamos los items, garantizando que sys.SubscriptionItem ya tiene un
  // SubscriptionId válido al que adjuntarse.
  try {
    await handleWebhookEvent({
      event_type: "subscription.created",
      event_id: eventId,
      occurred_at: (event["occurred_at"] as string) ?? new Date().toISOString(),
      data: { ...data, custom_data: { companyId: String(result.companyId) } },
    });
  } catch (err: any) {
    obs.error(`paddle.webhook.subscription_register_failed: ${err?.message}`, {
      module: "webhooks", companyId: result.companyId,
    });
  }
  try {
    await upsertSubscriptionItems({
      companyId: result.companyId,
      paddleSubscriptionId: subscriptionId ?? "",
      items,
    });
  } catch (err: any) {
    obs.error(`paddle.webhook.items_register_failed: ${err?.message}`, {
      module: "webhooks", companyId: result.companyId,
    });
  }

  const tenantUrl = chosenSubdomain ? `https://${chosenSubdomain}.zentto.net` : "https://app.zentto.net";

  // ── F2: Crear DNS en Cloudflare con retry exponencial ────────────────────
  // Antes: una sola llamada, si Cloudflare estaba lento o rate-limited el
  // tenant quedaba sin DNS y operador debía crearlo a mano.
  // Ahora: 3 intentos con backoff. Si tras 3 sigue fallando, se encola un job
  // en sys.ProvisioningJob para reintento por el sweeper.
  if (chosenSubdomain) {
    withRetry(() => createSubdomainDns(chosenSubdomain), {
      attempts: 3,
      isPermanent: isHttp4xx,
      onAttemptFailed: (err, attempt) =>
        console.warn(`[paddle] Cloudflare DNS intento ${attempt} falló:`, err instanceof Error ? err.message : err),
    })
      .then((dns) => {
        if (dns.ok) {
          obs.audit("tenant.dns.created", {
            module: "webhooks",
            companyId: result.companyId,
            subdomain: chosenSubdomain,
            url: tenantUrl,
          });
        } else {
          throw new Error(dns.error || "dns_unknown_error");
        }
      })
      .catch(async (err) => {
        obs.error(`tenant.dns.failed_after_retries: ${err?.message ?? err}`, {
          module: "webhooks",
          companyId: result.companyId,
          subdomain: chosenSubdomain,
        });
        await callSp("usp_sys_provisioning_job_enqueue", {
          CompanyId: result.companyId,
          CompanyCode: companyCode,
          Step: "cloudflare_dns",
          PayloadJson: JSON.stringify({ subdomain: chosenSubdomain }),
        }).catch(() => {});
      });
  }

  // Flujo BYOC: en lugar de provisionar BD, generar token de onboarding
  const isByoc = customData?.["deployType"] === "byoc";

  if (isByoc) {
    // Generar token de onboarding y enviar email con link de setup
    createOnboardingToken(result.companyId)
      .then((token) => {
        const onboardingUrl = `https://app.zentto.net/onboarding/${token}`;
        obs.audit("tenant.byoc.onboarding_token.created", {
          module: "webhooks",
          companyId: result.companyId,
          onboardingUrl,
        });

        // Email de bienvenida BYOC — incluye link de onboarding
        const byocHtml = buildByocWelcomeHtml(chosenCompanyName, onboardingUrl);
        const notifyKey = process.env.NOTIFY_API_KEY;
        if (notifyKey) {
          const notify = notifyFromEnv({
            baseUrl: process.env.NOTIFY_BASE_URL ?? process.env.NOTIFY_API_URL,
            apiKey: notifyKey,
          });
          notify.email.send({
            to: customerEmail,
            subject: `Zentto BYOC — Configura tu servidor para ${chosenCompanyName}`,
            html: byocHtml,
            from: "Zentto <no-reply@zentto.net>",
          }).then((r) => {
            if (!r.ok) console.error("[paddle] Error enviando email BYOC:", r.error);
          }).catch((err) => console.error("[paddle] Error enviando email BYOC:", err));
        }
      })
      .catch((err) => {
        obs.error(`tenant.byoc.onboarding_token.failed: ${err.message}`, {
          module: "webhooks",
          companyId: result.companyId,
        });
      });

    return { handled: true, companyId: result.companyId };
  }

  // ── F3: Provisionar BD del tenant — fallback a job queue si falla ─────────
  // Sigue siendo async (proceso largo ~2 min), pero si falla queda registrado
  // en sys.ProvisioningJob para que el sweeper retry sin intervención manual.
  provisionTenantDatabase(result.companyId, companyCode)
    .then(async (db) => {
      if (db.ok) {
        obs.audit("tenant.db.provisioned", {
          module: "webhooks",
          companyId: result.companyId,
          dbName: db.dbName,
        });
      } else {
        obs.error(`tenant.db.provision.failed: ${db.error}`, {
          module: "webhooks",
          companyId: result.companyId,
          companyCode,
        });
        await callSp("usp_sys_provisioning_job_enqueue", {
          CompanyId: result.companyId,
          CompanyCode: companyCode,
          Step: "provision_database",
          PayloadJson: JSON.stringify({ error: db.error }),
        }).catch(() => {});
      }
    })
    .catch(async (err) => {
      console.error("[paddle] Error provision BD:", err);
      await callSp("usp_sys_provisioning_job_enqueue", {
        CompanyId: result.companyId,
        CompanyCode: companyCode,
        Step: "provision_database",
        PayloadJson: JSON.stringify({ error: err?.message ?? String(err) }),
      }).catch(() => {});
    });

  // ── B3: Magic-link set-password (sin password plaintext en email) ─────────
  // Estrategia preferida: zentto-auth (microservicio centralizado) emite el
  // token y lo administra junto con la identidad del owner. Si zentto-auth
  // no está disponible o aún no tiene el endpoint, fallback al token local
  // (sec.PasswordResetToken en BD master). Esto garantiza que la primera
  // prueba funcione SIEMPRE.
  console.log(`[paddle] Tenant provisionado OK — companyId=${result.companyId}, email=${customerEmail}, subdomain=${chosenSubdomain || "(ninguno)"}`);
  let magicLinkUrl: string | undefined;

  // 1) Camino preferido: zentto-auth /admin/users/provision-owner
  try {
    const authRes = await authCreateOwner({
      email: customerEmail,
      fullName: chosenCompanyName,
      companyId: result.companyId,
      companyCode,
      tenantSubdomain: chosenSubdomain || "app",
      role: "owner",
      sendMagicLink: true,
    });
    if (authRes.magicLinkUrl) {
      magicLinkUrl = authRes.magicLinkUrl;
      obs.audit("tenant.auth.owner_provisioned", {
        module: "webhooks",
        companyId: result.companyId,
        userId: authRes.userId,
        alreadyExisted: authRes.alreadyExisted,
      });
    }
  } catch (err: any) {
    console.warn("[paddle] zentto-auth provision-owner falló, fallback local:", err?.message);
    obs.error(`tenant.auth.provision_failed: ${err?.message}`, { module: "webhooks", companyId: result.companyId });
  }

  // 2) Fallback local (sec.PasswordResetToken en master) si zentto-auth no respondió
  if (!magicLinkUrl) {
    try {
      const tokenInfo = await createPasswordResetToken({
        companyId: result.companyId,
        userCode: adminUserCode,
        email: customerEmail,
        ttlHours: 24,
        fromIp: "paddle-webhook",
      });
      magicLinkUrl = buildSetPasswordUrl({ subdomain: chosenSubdomain || undefined, token: tokenInfo.token });
      obs.audit("tenant.password_reset_token.created_local", {
        module: "webhooks", companyId: result.companyId, expiresAt: tokenInfo.expiresAt,
      });
    } catch (err: any) {
      console.warn("[paddle] Local password-reset token también falló, fallback a tempPassword:", err?.message);
      obs.error(`tenant.password_reset_token.failed: ${err?.message}`, { module: "webhooks", companyId: result.companyId });
    }
  }

  sendWelcomeEmail(customerEmail, chosenCompanyName, tempPassword, result.companyId, tenantUrl, adminUserCode, magicLinkUrl)
    .then(() => {
      obs.audit("tenant.welcome_email.sent", {
        module: "webhooks",
        companyId: result.companyId,
        ownerEmail: customerEmail,
        usedMagicLink: Boolean(magicLinkUrl),
      });
    })
    .catch(async (err) => {
      console.error("[paddle] Welcome email falló tras 3 reintentos:", err);
      obs.error(`tenant.welcome_email.failed: ${err.message}`, {
        module: "webhooks",
        companyId: result.companyId,
        ownerEmail: customerEmail,
      });
      // Encolar reintento async para que el sweeper lo intente de nuevo
      await callSp("usp_sys_provisioning_job_enqueue", {
        CompanyId: result.companyId,
        CompanyCode: companyCode,
        Step: "welcome_email",
        PayloadJson: JSON.stringify({ ownerEmail: customerEmail, magicLinkUrl, tenantUrl }),
      }).catch(() => {});
    });

  // Marcar webhook como done — todo el flujo principal completó OK
  await completeWebhookEvent({
    eventId,
    status: "done",
    companyId: result.companyId,
  });

  return { handled: true, companyId: result.companyId };
}

// ---------------------------------------------------------------------------
// Onboarding token para flujo BYOC
// ---------------------------------------------------------------------------

async function createOnboardingToken(companyId: number): Promise<string> {
  const token = randomBytes(32).toString("hex");
  const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 días

  await callSp("usp_Sys_OnboardingToken_Create", {
    CompanyId: companyId,
    Token: token,
    ExpiresAt: expiresAt.toISOString(),
  });

  return token;
}

// ---------------------------------------------------------------------------
// Multi-item: insertar cada Paddle item como sys.SubscriptionItem
// ---------------------------------------------------------------------------

async function upsertSubscriptionItems(params: {
  companyId: number;
  paddleSubscriptionId: string;
  items: Array<Record<string, unknown>>;
}): Promise<void> {
  // Busca la subscription recién creada por PaddleSubscriptionId
  const subRows = await callSp<{ SubscriptionId: number; CompanyId: number }>(
    "usp_sys_subscription_get_by_paddle_id",
    { PaddleSubscriptionId: params.paddleSubscriptionId }
  );
  const subscriptionId = subRows[0]?.SubscriptionId;
  if (!subscriptionId) {
    console.warn("[paddle] upsertSubscriptionItems: subscription no encontrada, saltando items");
    return;
  }

  for (const item of params.items) {
    const price = item["price"] as Record<string, unknown> | undefined;
    const priceId = (price?.["id"] as string) ?? "";
    const paddleItemId = (item["id"] as string) ?? "";
    const quantity = Number(item["quantity"] ?? 1);
    if (!priceId) continue;

    // Resolver plan interno por PaddlePriceId
    const planRows = await callSp<{
      PricingPlanId: number; Slug: string; BillingCycle: string;
      MonthlyPrice: string | number; AnnualPrice: string | number;
    }>("usp_cfg_plan_get_by_paddle_price_id", { PaddlePriceId: priceId });
    const plan = planRows[0];
    if (!plan) {
      console.warn(`[paddle] plan no encontrado para price_id=${priceId} (ignorado)`);
      continue;
    }

    const unitPrice = plan.BillingCycle === "annual" ? Number(plan.AnnualPrice) : Number(plan.MonthlyPrice);

    await callSp("usp_sys_subscription_item_add", {
      SubscriptionId: subscriptionId,
      CompanyId: params.companyId,
      PricingPlanId: plan.PricingPlanId,
      Quantity: quantity,
      PaddleSubscriptionItemId: paddleItemId,
      PaddlePriceId: priceId,
      UnitPrice: unitPrice,
      BillingCycle: plan.BillingCycle,
    }).catch((err: any) =>
      console.warn(`[paddle] item_add falló para plan=${plan.Slug}:`, err.message)
    );
  }
}

// ---------------------------------------------------------------------------
// subscription.updated — re-sincroniza items (añade nuevos, remueve eliminados)
// ---------------------------------------------------------------------------

async function handleSubscriptionUpdated(event: Record<string, unknown>) {
  const data = event["data"] as Record<string, unknown>;
  const paddleSubId = (data["id"] as string) ?? "";
  if (!paddleSubId) return { handled: false, reason: "no_subscription_id" };

  const subRows = await callSp<{ SubscriptionId: number; CompanyId: number; Status: string }>(
    "usp_sys_subscription_get_by_paddle_id",
    { PaddleSubscriptionId: paddleSubId }
  );
  const sub = subRows[0];
  if (!sub) return { handled: false, reason: "subscription_not_found" };

  const currentStart = data["current_billing_period"] as Record<string, string> | undefined;
  const newStatus = ((data["status"] as string) ?? sub.Status).toLowerCase();
  const mappedStatus = newStatus === "active" ? "active"
    : newStatus === "past_due" ? "past_due"
    : newStatus === "paused" ? "paused"
    : newStatus === "canceled" || newStatus === "cancelled" ? "cancelled"
    : sub.Status;

  await callSp("usp_sys_subscription_update_status", {
    SubscriptionId: sub.SubscriptionId,
    Status: mappedStatus,
    CurrentPeriodStart: currentStart?.["starts_at"] ? new Date(currentStart["starts_at"]) : null,
    CurrentPeriodEnd: currentStart?.["ends_at"] ? new Date(currentStart["ends_at"]) : null,
    CancelledAt: null,
  }).catch(() => {});

  // Re-sincroniza items de Paddle (añade nuevos; los que ya no están se marcan removed abajo)
  const paddleItems = (data["items"] as Array<Record<string, unknown>>) ?? [];
  await upsertSubscriptionItems({
    companyId: sub.CompanyId,
    paddleSubscriptionId: paddleSubId,
    items: paddleItems,
  }).catch(() => {});

  obs.audit("tenant.subscription.updated", {
    module: "webhooks",
    companyId: sub.CompanyId,
    status: mappedStatus,
    itemCount: paddleItems.length,
  });

  return { handled: true, companyId: sub.CompanyId };
}

// ---------------------------------------------------------------------------
// subscription.cancelled — marca subscription cancelada
// ---------------------------------------------------------------------------

async function handleSubscriptionCancelled(event: Record<string, unknown>) {
  const data = event["data"] as Record<string, unknown>;
  const paddleSubId = (data["id"] as string) ?? "";
  if (!paddleSubId) return { handled: false, reason: "no_subscription_id" };

  const subRows = await callSp<{ SubscriptionId: number; CompanyId: number }>(
    "usp_sys_subscription_get_by_paddle_id",
    { PaddleSubscriptionId: paddleSubId }
  );
  const sub = subRows[0];
  if (!sub) return { handled: false, reason: "subscription_not_found" };

  const cancelledAt = (data["canceled_at"] as string) ?? new Date().toISOString();

  await callSp("usp_sys_subscription_update_status", {
    SubscriptionId: sub.SubscriptionId,
    Status: "cancelled",
    CurrentPeriodStart: null,
    CurrentPeriodEnd: null,
    CancelledAt: new Date(cancelledAt),
  }).catch(() => {});

  obs.audit("tenant.subscription.cancelled", {
    module: "webhooks",
    companyId: sub.CompanyId,
    cancelledAt,
  });

  return { handled: true, companyId: sub.CompanyId };
}

function buildByocWelcomeHtml(legalName: string, onboardingUrl: string): string {
  return `
  <div style="font-family:'Segoe UI',Arial,sans-serif;max-width:620px;margin:0 auto;background:#f8f9fa;padding:0">
    <div style="background:#1a1a2e;padding:32px 40px;text-align:center">
      <div style="background:#ff9900;color:#fff;font-weight:900;font-size:22px;display:inline-block;padding:12px 22px;border-radius:10px;letter-spacing:2px">DB</div>
      <div style="color:#fff;font-size:28px;font-weight:700;margin:10px 0 4px;letter-spacing:3px">ZENTTO</div>
      <div style="color:#aaa;font-size:13px">BYOC — Bring Your Own Cloud</div>
    </div>
    <div style="background:#fff;padding:40px">
      <h2 style="color:#1a1a2e;margin:0 0 8px">Tu cuenta esta lista, <span style="color:#ff9900">${legalName}</span></h2>
      <p style="color:#555;margin:0 0 28px;line-height:1.6">
        Suscripcion activada correctamente. Ahora debes configurar tu servidor propio para desplegar Zentto.
      </p>
      <div style="text-align:center;margin-bottom:36px">
        <a href="${onboardingUrl}" style="background:#ff9900;color:#fff;padding:16px 40px;border-radius:8px;text-decoration:none;font-weight:700;font-size:16px;display:inline-block;letter-spacing:1px">
          Configurar mi servidor &rarr;
        </a>
      </div>
      <div style="background:#fff8e1;border-left:4px solid #ff9900;padding:14px 18px;border-radius:0 6px 6px 0">
        <strong style="color:#333">Este enlace expira en 7 dias.</strong>
        <div style="color:#666;font-size:13px;margin-top:4px">Si necesitas uno nuevo, contacta <a href="mailto:soporte@zentto.net" style="color:#ff9900">soporte@zentto.net</a>.</div>
      </div>
    </div>
    <div style="padding:20px 40px;text-align:center;background:#f8f9fa">
      <p style="color:#999;font-size:12px;margin:0">© ${new Date().getFullYear()} Zentto. Todos los derechos reservados.</p>
    </div>
  </div>`;
}
