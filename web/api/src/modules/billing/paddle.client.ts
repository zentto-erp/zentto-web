/**
 * paddle.client.ts — Cliente ligero para Paddle API v2
 *
 * Usa fetch nativo (Node 18+). No requiere dependencias externas.
 */

import crypto from "node:crypto";

const PADDLE_BASE_URL = "https://api.paddle.com";

function getApiKey(): string {
  const key = process.env.PADDLE_API_KEY;
  if (!key) throw new Error("PADDLE_API_KEY no está configurado");
  return key;
}

function getWebhookSecret(): string {
  const secret = process.env.PADDLE_WEBHOOK_SECRET;
  if (!secret) throw new Error("PADDLE_WEBHOOK_SECRET no está configurado");
  return secret;
}

// ── HTTP helpers ─────────────────────────────────────────────────────────────

async function request<T>(
  method: "GET" | "POST" | "PATCH",
  path: string,
  body?: Record<string, unknown>
): Promise<T> {
  const url = `${PADDLE_BASE_URL}${path}`;
  const headers: Record<string, string> = {
    Authorization: `Bearer ${getApiKey()}`,
    "Content-Type": "application/json",
  };

  const res = await fetch(url, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });

  const json = (await res.json()) as { data?: T; error?: { detail: string } };

  if (!res.ok) {
    const detail = json.error?.detail ?? res.statusText;
    throw new Error(`Paddle API ${method} ${path} falló (${res.status}): ${detail}`);
  }

  return json.data as T;
}

export const paddleApi = {
  get: <T>(path: string) => request<T>("GET", path),
  post: <T>(path: string, body: Record<string, unknown>) =>
    request<T>("POST", path, body),
  patch: <T>(path: string, body: Record<string, unknown>) =>
    request<T>("PATCH", path, body),
};

// ── Verificación de firma de webhook ─────────────────────────────────────────

/**
 * Verifica la firma HMAC-SHA256 de Paddle.
 * Formato del header: "ts=<timestamp>;h1=<hex>"
 */
export function verifyPaddleWebhookSignature(
  rawBody: Buffer,
  signatureHeader: string
): boolean {
  const secret = getWebhookSecret();

  const parts: Record<string, string> = {};
  for (const part of signatureHeader.split(";")) {
    const idx = part.indexOf("=");
    if (idx > 0) {
      parts[part.slice(0, idx)] = part.slice(idx + 1);
    }
  }

  const ts = parts["ts"];
  const h1 = parts["h1"];
  if (!ts || !h1) return false;

  const payload = `${ts}:${rawBody.toString("utf8")}`;
  const expected = crypto
    .createHmac("sha256", secret)
    .update(payload)
    .digest("hex");

  try {
    return crypto.timingSafeEqual(Buffer.from(h1), Buffer.from(expected));
  } catch {
    return false;
  }
}
