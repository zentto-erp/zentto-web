import crypto from "node:crypto";
import { randomBytes } from "node:crypto";
import { provisionTenant, sendWelcomeEmail } from "../tenants/tenant.service.js";
import { handleWebhookEvent } from "../billing/billing.service.js";
import { provisionTenantDatabase } from "../../db/provision-tenant-db.js";
import { createSubdomainDns } from "../../lib/cloudflare.client.js";
import { obs } from "../integrations/observability.js";

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
    const { callSp } = await import("../../db/query.js");
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
