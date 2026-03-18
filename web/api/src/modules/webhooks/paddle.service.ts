import crypto from "node:crypto";
import { randomBytes } from "node:crypto";
import { provisionTenant, sendWelcomeEmail } from "../tenants/tenant.service.js";

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

  // Determinar plan desde nombre del precio de Paddle
  const planMap: Record<string, "FREE" | "STARTER" | "PRO" | "ENTERPRISE"> = {
    free: "FREE", starter: "STARTER", pro: "PRO", enterprise: "ENTERPRISE",
  };
  const planKey = (priceName ?? "starter").toLowerCase();
  const plan = planMap[planKey] ?? "STARTER";

  // Generar companyCode único
  const slug = customerEmail.split("@")[0]
    .replace(/[^a-z0-9]/gi, "")
    .toUpperCase()
    .slice(0, 12);
  const suffix = randomBytes(3).toString("hex").toUpperCase();
  const companyCode = `${slug}${suffix}`;
  const adminUserCode = customerEmail.toUpperCase().replace(/[^A-Z0-9]/g, "").slice(0, 40);
  const tempPassword = randomBytes(8).toString("hex");

  const result = await provisionTenant({
    companyCode,
    legalName: customerEmail,
    ownerEmail: customerEmail,
    countryCode: "VE",
    baseCurrency: "USD",
    adminUserCode,
    adminPassword: tempPassword,
    plan,
    paddleSubscriptionId: subscriptionId,
  });

  if (result.ok) {
    sendWelcomeEmail(customerEmail, customerEmail, tempPassword, result.companyId).catch(() => {});
  }

  return { handled: true, companyId: result.companyId };
}
