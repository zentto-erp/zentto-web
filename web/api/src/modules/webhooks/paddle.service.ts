import crypto from "node:crypto";
import { randomBytes } from "node:crypto";
import { provisionTenant, sendWelcomeEmail } from "../tenants/tenant.service.js";
import { handleWebhookEvent } from "../billing/billing.service.js";
import { provisionTenantDatabase } from "../../db/provision-tenant-db.js";
import { createSubdomainDns } from "../../lib/cloudflare.client.js";
import { obs } from "../integrations/observability.js";
import { callSp } from "../../db/query.js";

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
  if (event["event_type"] !== "subscription.created") {
    return { handled: false, reason: "event_not_handled" };
  }

  const data = event["data"] as Record<string, unknown>;
  const customer = data["customer"] as Record<string, unknown> | undefined;
  const customerEmail = customer?.["email"] as string | undefined;

  if (!customerEmail) return { handled: false, reason: "no_customer_email" };

  const items = data["items"] as Array<Record<string, unknown>> | undefined;
  const priceName = (items?.[0]?.["price"] as Record<string, unknown>)?.["name"] as string | undefined;
  const subscriptionId = data["id"] as string | undefined;

  // custom_data del checkout (subdomain + companyName elegidos por el usuario)
  const customData = data["custom_data"] as Record<string, string> | undefined;
  const chosenSubdomain = customData?.["subdomain"]?.toLowerCase().replace(/[^a-z0-9-]/g, "").slice(0, 30) || "";
  const chosenCompanyName = customData?.["companyName"] || customerEmail;

  // Determinar plan desde nombre del precio de Paddle
  const planMap: Record<string, "FREE" | "STARTER" | "PRO" | "ENTERPRISE"> = {
    free: "FREE", starter: "STARTER", pro: "PRO", enterprise: "ENTERPRISE",
  };
  const planKey = (priceName ?? "starter").toLowerCase();
  const plan = planMap[planKey] ?? "STARTER";

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

  // Actualizar subdomain si el usuario eligió uno personalizado
  if (chosenSubdomain) {
    await callSp("usp_Cfg_Tenant_SetSubdomain", {
      CompanyId: result.companyId,
      Subdomain: chosenSubdomain,
    }).catch(() => {});
  }

  // Registrar suscripcion en tabla sys.Subscription (no bloquea provision)
  handleWebhookEvent({
    event_type: "subscription.created",
    event_id: (event["event_id"] as string) ?? "",
    occurred_at: (event["occurred_at"] as string) ?? new Date().toISOString(),
    data: { ...data, custom_data: { companyId: String(result.companyId) } },
  }).catch((err) => console.error("[paddle] Error registrando subscription:", err));

  const tenantUrl = chosenSubdomain ? `https://${chosenSubdomain}.zentto.net` : "https://app.zentto.net";

  // Crear DNS en Cloudflare (no bloquea — si falla se puede crear manualmente)
  if (chosenSubdomain) {
    createSubdomainDns(chosenSubdomain)
      .then((dns) => {
        if (dns.ok) {
          obs.audit("tenant.dns.created", {
            module: "webhooks",
            companyId: result.companyId,
            subdomain: chosenSubdomain,
            url: tenantUrl,
          });
        } else {
          obs.error(`tenant.dns.failed: ${dns.error}`, {
            module: "webhooks",
            companyId: result.companyId,
            subdomain: chosenSubdomain,
          });
        }
      })
      .catch((err) => console.error("[paddle] Error DNS Cloudflare:", err));
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
        const notifyUrl = process.env.NOTIFY_BASE_URL ?? "https://notify.zentto.net";
        const notifyKey = process.env.NOTIFY_API_KEY;
        if (notifyKey) {
          fetch(`${notifyUrl}/api/email/send`, {
            method: "POST",
            headers: { "Content-Type": "application/json", "X-API-Key": notifyKey },
            body: JSON.stringify({
              to: customerEmail,
              subject: `Zentto BYOC — Configura tu servidor para ${chosenCompanyName}`,
              html: byocHtml,
              from: "Zentto <no-reply@zentto.net>",
            }),
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

  // Provisionar BD del tenant (no bloquea — proceso largo ~2 min)
  provisionTenantDatabase(result.companyId, companyCode)
    .then((db) => {
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
      }
    })
    .catch((err) => console.error("[paddle] Error provision BD:", err));

  // Enviar email de bienvenida
  console.log(`[paddle] Tenant provisionado OK — companyId=${result.companyId}, email=${customerEmail}, subdomain=${chosenSubdomain || "(ninguno)"}`);
  sendWelcomeEmail(customerEmail, chosenCompanyName, tempPassword, result.companyId, tenantUrl, adminUserCode)
    .then(() => {
      obs.audit("tenant.welcome_email.sent", {
        module: "webhooks",
        companyId: result.companyId,
        ownerEmail: customerEmail,
      });
    })
    .catch((err) => {
      console.error("[paddle] Error enviando welcome email:", err);
      obs.error(`tenant.welcome_email.failed: ${err.message}`, {
        module: "webhooks",
        companyId: result.companyId,
        ownerEmail: customerEmail,
      });
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
