/**
 * Zentto Notify — wrapper de compatibilidad alrededor de NotifyClient.
 *
 * ⚠️ Para código nuevo, importá directamente `notifyFromEnv()` desde
 * `src/lib/platform-client/notify` y usá `client.email.send(...)`. Este
 * archivo existe solo para no romper los ~10 callers legacy (OTP auth,
 * CRM notifications, invoice events, etc.) durante la migración.
 */
import { notifyFromEnv, type NotifyResult as PlatformNotifyResult } from "@zentto/platform-client/notify";

const client = notifyFromEnv({
  onError: (err, ctx) => {
    console.error(`[notify] ${ctx.path} attempt=${ctx.attempt}:`, err.message);
  },
});

// Mantenemos el shape previo ({ ok, messageId, error }) para no romper callers.
export interface NotifyResult {
  ok: boolean;
  messageId?: string;
  error?: string;
}

function toLegacy(r: PlatformNotifyResult): NotifyResult {
  return { ok: r.ok, messageId: r.messageId, error: r.error };
}

// ─── Email ────────────────────────────────────────────────────

export async function notifyEmail(
  to: string | string[],
  subject: string,
  html: string,
  options?: { from?: string; track?: boolean; templateId?: string; variables?: Record<string, string> },
): Promise<NotifyResult> {
  return toLegacy(
    await client.email.send({
      to, subject, html,
      from: options?.from,
      track: options?.track ?? true,
      templateId: options?.templateId,
      variables: options?.variables,
    }),
  );
}

export async function notifyEmailQueued(
  to: string | string[],
  subject: string,
  html: string,
  scheduledAt?: string,
): Promise<NotifyResult> {
  return toLegacy(await client.email.sendQueued({ to, subject, html, scheduledAt }));
}

// ─── WhatsApp ─────────────────────────────────────────────────

export async function notifyWhatsApp(
  instanceId: string,
  to: string,
  message: string,
  options?: { media?: { url: string; caption?: string } },
): Promise<NotifyResult> {
  return toLegacy(await client.whatsapp.send(instanceId, { to, message, media: options?.media }));
}

// ─── Push web (navegador) ─────────────────────────────────────

export async function notifyPush(
  subscription: { endpoint: string; keys: { p256dh: string; auth: string } },
  title: string,
  body: string,
  options?: { icon?: string; url?: string; data?: Record<string, any> },
): Promise<NotifyResult> {
  return toLegacy(
    await client.push.send({
      subscription, title, body,
      icon: options?.icon, url: options?.url, data: options?.data,
    }),
  );
}

// ─── SMS ──────────────────────────────────────────────────────

export async function notifySMS(to: string, carrier: string, message: string): Promise<NotifyResult> {
  return toLegacy(await client.sms.send({ to, carrier, message }));
}

// ─── OTP ──────────────────────────────────────────────────────

export async function notifyOTP(
  channel: "email" | "sms",
  destination: string,
  options?: { carrier?: string; brandName?: string },
): Promise<NotifyResult> {
  return toLegacy(await client.otp.send({ channel, destination, ...options }));
}

export async function verifyOTP(
  channel: "email" | "sms",
  destination: string,
  code: string,
): Promise<NotifyResult> {
  return toLegacy(await client.otp.verify({ channel, destination, code }));
}

// ─── Mobile Push (Expo Push API — externo a notify) ───────────

const EXPO_PUSH_URL = "https://exp.host/--/api/v2/push/send";

export async function notifyMobilePush(
  pushTokens: string[],
  title: string,
  body: string,
  data?: Record<string, any>,
): Promise<NotifyResult> {
  if (!pushTokens.length) return { ok: false, error: "No push tokens" };
  try {
    const messages = pushTokens.map((token) => ({
      to: token, sound: "default" as const, title, body, data: data || {},
    }));
    const res = await fetch(EXPO_PUSH_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json", Accept: "application/json" },
      body: JSON.stringify(messages),
      signal: AbortSignal.timeout(10000),
    });
    const result = await res.json().catch(() => ({}));
    return { ok: res.ok, messageId: result?.data?.[0]?.id };
  } catch (err) {
    console.error("[notify] Expo push error:", err);
    return { ok: false, error: String(err) };
  }
}

// ─── Contactos ────────────────────────────────────────────────

export async function syncContact(contact: {
  email: string;
  name?: string;
  phone?: string;
  company?: string;
  country?: string;
  tags?: string[];
  metadata?: Record<string, string>;
}): Promise<NotifyResult> {
  return toLegacy(await client.contacts.upsert(contact));
}

// ─── Evento de negocio → email con template ──────────────────

export type BusinessEvent =
  | "INVOICE_CREATED" | "PAYMENT_RECEIVED" | "PAYMENT_SENT" | "LEAD_WON"
  | "LEAD_ASSIGNED" | "ACTIVITY_OVERDUE" | "GOODS_RECEIVED"
  | "DELIVERY_DISPATCHED" | "DELIVERY_CONFIRMED" | "LOW_STOCK_ALERT"
  | "LOT_EXPIRY_ALERT" | "PAYROLL_PROCESSED" | "WITHHOLDING_GENERATED"
  | "ORDER_CREATED" | "CUSTOMER_REGISTERED" | "RESTAURANT_ORDER_CLOSED"
  | "PURCHASE_ORDER_CREATED" | "BANK_MOVEMENT_RECORDED" | "VACATION_APPROVED"
  | "VACATION_REJECTED" | "PAYROLL_EMPLOYEE_PROCESSED"
  | "LIQUIDATION_CALCULATED" | "BATCH_PAYROLL_PROCESSED";

interface BusinessNotification {
  event: BusinessEvent;
  to: string;
  subject: string;
  data: Record<string, string>;
  channels?: ("email" | "push" | "whatsapp")[];
  mobilePushTokens?: string[];
}

export async function emitBusinessNotification(
  notification: BusinessNotification,
): Promise<void> {
  const { event, to, subject, data, channels = ["email"] } = notification;
  const templateId = `zentto_${event.toLowerCase()}`;
  const html = buildEventHtml(event, subject, data);

  for (const channel of channels) {
    try {
      if (channel === "email") {
        await notifyEmail(to, subject, html, { track: true, templateId, variables: data });
      }
      if (channel === "push" && notification.mobilePushTokens?.length) {
        await notifyMobilePush(
          notification.mobilePushTokens, subject,
          Object.values(data).join(" · "), { event, ...data },
        );
      }
    } catch {
      // Best-effort: nunca bloquear flujo de negocio.
    }
  }
}

function buildEventHtml(event: string, subject: string, data: Record<string, string>): string {
  const rows = Object.entries(data)
    .map(([k, v]) => `<tr><td style="padding:4px 12px;font-weight:600;color:#555">${k}</td><td style="padding:4px 12px">${v}</td></tr>`)
    .join("");
  return `
    <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto">
      <div style="background:#1a1a2e;color:#fff;padding:20px;text-align:center;border-radius:8px 8px 0 0">
        <h2 style="margin:0">${subject}</h2>
      </div>
      <div style="padding:20px;background:#fff;border:1px solid #eee">
        <table style="width:100%;border-collapse:collapse">${rows}</table>
      </div>
      <div style="padding:12px;text-align:center;color:#999;font-size:12px">
        Enviado por Zentto ERP
      </div>
    </div>
  `;
}
