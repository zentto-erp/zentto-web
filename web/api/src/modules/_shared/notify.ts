/**
 * Zentto Notify — Cliente integrado para notificaciones multi-canal.
 * Usa la API REST de notify.zentto.net directamente (sin SDK externo).
 * Configuración via .env: NOTIFY_API_URL + NOTIFY_API_KEY
 *
 * Todas las funciones son best-effort: nunca lanzan excepciones,
 * solo logean errores y retornan { ok: false }.
 */

const NOTIFY_URL = process.env.NOTIFY_API_URL || "https://notify.zentto.net";
const NOTIFY_KEY = process.env.NOTIFY_API_KEY || process.env.API_MASTER_KEY || "";

interface NotifyResult {
  ok: boolean;
  messageId?: string;
  error?: string;
}

async function notifyPost(path: string, body: Record<string, any>): Promise<NotifyResult> {
  if (!NOTIFY_KEY) return { ok: false, error: "NOTIFY_API_KEY not configured" };
  try {
    const res = await fetch(`${NOTIFY_URL}${path}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-API-Key": NOTIFY_KEY,
      },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(10000),
    });
    const data = await res.json().catch(() => ({}));
    if (res.ok) return { ok: true, messageId: data.messageId ?? data.id };
    return { ok: false, error: data.error ?? `HTTP ${res.status}` };
  } catch (err) {
    console.error("[notify] Error:", err);
    return { ok: false, error: String(err) };
  }
}

// ─── Email ────────────────────────────────────────────────────

export async function notifyEmail(
  to: string | string[],
  subject: string,
  html: string,
  options?: { from?: string; track?: boolean; templateId?: string; variables?: Record<string, string> }
): Promise<NotifyResult> {
  return notifyPost("/api/email/send", {
    to,
    subject,
    html,
    from: options?.from,
    track: options?.track ?? true,
    templateId: options?.templateId,
    variables: options?.variables,
  });
}

export async function notifyEmailQueued(
  to: string | string[],
  subject: string,
  html: string,
  scheduledAt?: string
): Promise<NotifyResult> {
  return notifyPost("/api/email/send-queued", { to, subject, html, scheduledAt });
}

// ─── WhatsApp ─────────────────────────────────────────────────

export async function notifyWhatsApp(
  instanceId: string,
  to: string,
  message: string,
  options?: { media?: { url: string; caption?: string } }
): Promise<NotifyResult> {
  const payload: Record<string, any> = { to, message };
  if (options?.media) payload.media = options.media;
  return notifyPost(`/api/whatsapp/instances/${instanceId}/send`, payload);
}

// ─── Push ─────────────────────────────────────────────────────

export async function notifyPush(
  subscription: { endpoint: string; keys: { p256dh: string; auth: string } },
  title: string,
  body: string,
  options?: { icon?: string; url?: string; data?: Record<string, any> }
): Promise<NotifyResult> {
  return notifyPost("/api/push/send", {
    subscription,
    title,
    body,
    icon: options?.icon,
    url: options?.url,
    data: options?.data,
  });
}

// ─── SMS ──────────────────────────────────────────────────────

export async function notifySMS(
  to: string,
  carrier: string,
  message: string
): Promise<NotifyResult> {
  return notifyPost("/api/sms/send", { to, carrier, message });
}

// ─── OTP ──────────────────────────────────────────────────────

export async function notifyOTP(
  channel: "email" | "sms",
  destination: string,
  options?: { carrier?: string; brandName?: string }
): Promise<NotifyResult> {
  return notifyPost("/api/otp/send", {
    channel,
    destination,
    carrier: options?.carrier,
    brandName: options?.brandName ?? "Zentto",
  });
}

export async function verifyOTP(
  channel: "email" | "sms",
  destination: string,
  code: string
): Promise<NotifyResult> {
  return notifyPost("/api/otp/verify", { channel, destination, code });
}

// ─── Contactos (sincronizar con Notify) ───────────────────────

export async function syncContact(contact: {
  email: string;
  name?: string;
  phone?: string;
  company?: string;
  country?: string;
  tags?: string[];
  metadata?: Record<string, string>;
}): Promise<NotifyResult> {
  return notifyPost("/api/contacts", contact);
}

// ─── Evento genérico de negocio → Notificación ───────────────

export type BusinessEvent =
  | "INVOICE_CREATED"
  | "PAYMENT_RECEIVED"
  | "PAYMENT_SENT"
  | "LEAD_WON"
  | "LEAD_ASSIGNED"
  | "ACTIVITY_OVERDUE"
  | "GOODS_RECEIVED"
  | "DELIVERY_DISPATCHED"
  | "DELIVERY_CONFIRMED"
  | "LOW_STOCK_ALERT"
  | "LOT_EXPIRY_ALERT"
  | "PAYROLL_PROCESSED"
  | "WITHHOLDING_GENERATED";

interface BusinessNotification {
  event: BusinessEvent;
  to: string;
  subject: string;
  data: Record<string, string>;
  channels?: ("email" | "push" | "whatsapp")[];
}

/**
 * Envía notificación de evento de negocio.
 * Usa template basado en el evento si existe, sino usa HTML genérico.
 * Best-effort: nunca bloquea la operación de negocio.
 */
export async function emitBusinessNotification(
  notification: BusinessNotification
): Promise<void> {
  const { event, to, subject, data, channels = ["email"] } = notification;

  const templateId = `zentto_${event.toLowerCase()}`;
  const html = buildEventHtml(event, subject, data);

  for (const channel of channels) {
    try {
      if (channel === "email") {
        await notifyEmail(to, subject, html, {
          track: true,
          templateId,
          variables: data,
        });
      }
      // Push y WhatsApp se pueden agregar cuando estén configurados
    } catch {
      // Best-effort: nunca bloquear
    }
  }
}

function buildEventHtml(
  event: string,
  subject: string,
  data: Record<string, string>
): string {
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
