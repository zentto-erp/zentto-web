import { createTransport, type Transporter } from "nodemailer";

type AuthMailPayload = {
  to: string;
  subject: string;
  text: string;
  html: string;
  from?: string;
};

type AuthMailResult = {
  sent: boolean;
  channel: "smtp" | "webhook" | "console";
  messageId?: string;
};

// â”€â”€â”€ Config â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

function isDevelopment() {
  const nodeEnv = String(process.env.NODE_ENV || "development").toLowerCase();
  return nodeEnv !== "production";
}

export function getAuthPublicBaseUrl() {
  const raw =
    process.env.AUTH_PUBLIC_URL ||
    process.env.FRONTEND_URL ||
    process.env.NEXT_PUBLIC_APP_URL ||
    process.env.NEXT_PUBLIC_FRONTEND_URL ||
    "http://localhost:3000";
  return String(raw).replace(/\/+$/, "");
}

const MAIL_FROM = process.env.MAIL_FROM || "Zentto <no-reply@zentto.net>";

// â”€â”€â”€ SMTP Transport (envÃ­o directo desde el servidor) â”€â”€

let _transporter: Transporter | null = null;

function getTransporter(): Transporter | null {
  if (_transporter) return _transporter;

  const smtpHost = process.env.SMTP_HOST || "";
  const smtpPort = Number(process.env.SMTP_PORT || 587);
  const smtpUser = process.env.SMTP_USER || "";
  const smtpPass = process.env.SMTP_PASS || "";

  if (smtpHost) {
    // SMTP relay configurado (ej: tu propio servidor SMTP, o futuro CRM)
    _transporter = createTransport({
      host: smtpHost,
      port: smtpPort,
      secure: smtpPort === 465,
      auth: smtpUser ? { user: smtpUser, pass: smtpPass } : undefined,
      // Security: rejectUnauthorized=false for internal SMTP relays without public CA certs
      tls: { rejectUnauthorized: false }, // nosemgrep: bypass-tls-verification
    });
  } else {
    // EnvÃ­o directo: el servidor actÃºa como su propio MTA
    // Resuelve MX del destinatario y entrega directo
    _transporter = createTransport({
      direct: true,
      name: "zentto.net",
    } as any);
  }

  return _transporter;
}

async function sendBySmtp(payload: AuthMailPayload): Promise<{ sent: boolean; messageId?: string }> {
  const transporter = getTransporter();
  if (!transporter) return { sent: false };

  try {
    const info = await transporter.sendMail({
      from: payload.from || MAIL_FROM,
      to: payload.to,
      subject: payload.subject,
      text: payload.text,
      html: payload.html,
    });

    console.info(`[MAIL] Sent to ${payload.to} â€” messageId: ${info.messageId}`);
    return { sent: true, messageId: info.messageId };
  } catch (err: any) {
    console.error(`[MAIL] Failed to send to ${payload.to}:`, err.message);
    return { sent: false };
  }
}

// â”€â”€â”€ Webhook fallback (compatibilidad con sistema anterior) â”€â”€

async function sendByWebhook(payload: AuthMailPayload): Promise<boolean> {
  const url = String(process.env.AUTH_MAIL_WEBHOOK_URL || "").trim();
  if (!url) return false;

  const token = String(process.env.AUTH_MAIL_WEBHOOK_TOKEN || "").trim();
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
    headers["X-API-Key"] = token; // zentto-notify compatibility
  }

  const response = await fetch(url, {
    method: "POST",
    headers,
    body: JSON.stringify({
      ...payload,
      from: payload.from || MAIL_FROM,
      track: true,
    }),
  });

  return response.ok;
}

// â”€â”€â”€ EnvÃ­o principal â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

export async function sendAuthMail(payload: AuthMailPayload): Promise<AuthMailResult> {
  // 1. Intentar SMTP (directo o relay)
  try {
    const smtp = await sendBySmtp(payload);
    if (smtp.sent) return { sent: true, channel: "smtp", messageId: smtp.messageId };
  } catch {
    // fallback
  }

  // 2. Intentar webhook (compatibilidad)
  try {
    const sent = await sendByWebhook(payload);
    if (sent) return { sent: true, channel: "webhook" };
  } catch {
    // fallback
  }

  // 3. Console (desarrollo)
  if (isDevelopment()) {
    console.info("[AUTH_MAIL_FALLBACK]", {
      to: payload.to,
      subject: payload.subject,
      text: payload.text.substring(0, 200),
    });
  } else {
    console.warn(`[MAIL] Could not deliver email to ${payload.to}: ${payload.subject}`);
  }

  return { sent: false, channel: "console" };
}
