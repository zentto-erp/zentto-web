type AuthMailPayload = {
  to: string;
  subject: string;
  text: string;
  html: string;
};

type AuthMailResult = {
  sent: boolean;
  channel: "webhook" | "console";
};

function isDevelopment() {
  const nodeEnv = String(process.env.NODE_ENV || "development").toLowerCase();
  return nodeEnv !== "production";
}

function getMailWebhookUrl() {
  return String(process.env.AUTH_MAIL_WEBHOOK_URL || "").trim();
}

function getMailWebhookToken() {
  return String(process.env.AUTH_MAIL_WEBHOOK_TOKEN || "").trim();
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

async function sendByWebhook(payload: AuthMailPayload): Promise<boolean> {
  const url = getMailWebhookUrl();
  if (!url) return false;

  const token = getMailWebhookToken();
  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify(payload),
  });

  return response.ok;
}

export async function sendAuthMail(payload: AuthMailPayload): Promise<AuthMailResult> {
  try {
    const sent = await sendByWebhook(payload);
    if (sent) return { sent: true, channel: "webhook" };
  } catch {
    // fallback to console below
  }

  if (isDevelopment()) {
    console.info("[AUTH_MAIL_FALLBACK]", {
      to: payload.to,
      subject: payload.subject,
      text: payload.text,
    });
  }
  return { sent: true, channel: "console" };
}
