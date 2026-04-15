/**
 * NotifyClient — único cliente tipado para https://notify.zentto.net.
 *
 * Diseño:
 * - Factory (no singleton global) → permite tests y múltiples instancias
 *   (p.ej. enviar como tenant X vs tenant master master-key).
 * - Best-effort por default en los métodos de negocio (nunca lanzan). Los
 *   métodos bajos (`request`) sí propagan errores para que el caller decida.
 * - Timeouts + 1 retry exponencial en errores de red (no en 4xx).
 * - Sin dependencias externas: usa fetch nativo de Node 20+.
 */

export interface NotifyConfig {
  baseUrl?: string;
  apiKey: string;
  /** Timeout por request en ms. Default 10000. */
  timeoutMs?: number;
  /** Cantidad de reintentos ante fallos de red o 5xx. Default 1. */
  retries?: number;
  /** Hook para logs/observability. Default no-op. */
  onError?: (err: Error, context: { path: string; attempt: number }) => void;
}

export interface NotifyResult<T = unknown> {
  ok: boolean;
  messageId?: string;
  via?: string;
  data?: T;
  error?: string;
}

export interface SendEmailParams {
  to: string | string[];
  subject?: string;
  html?: string;
  text?: string;
  from?: string;
  replyTo?: string;
  /** Si se pasa, sobreescribe subject/html con el template de notify. */
  templateId?: string;
  variables?: Record<string, string>;
  track?: boolean;
  attachments?: Array<{
    filename: string;
    content?: string;
    path?: string;
    contentType?: string;
    encoding?: string;
  }>;
}

export interface UpsertContactParams {
  email: string;
  name?: string;
  phone?: string;
  company?: string;
  country?: string;
  tags?: string[];
  metadata?: Record<string, string | number | null>;
  subscribed?: boolean;
}

export interface SendOtpParams {
  channel: "email" | "sms";
  destination: string;
  carrier?: string;
  brandName?: string;
}

export interface VerifyOtpParams {
  channel: "email" | "sms";
  destination: string;
  code: string;
}

export interface SendWebPushParams {
  subscription: { endpoint: string; keys: { p256dh: string; auth: string } };
  title: string;
  body: string;
  icon?: string;
  url?: string;
  data?: Record<string, unknown>;
}

export class NotifyClient {
  private readonly baseUrl: string;
  private readonly apiKey: string;
  private readonly timeoutMs: number;
  private readonly retries: number;
  private readonly onError: NonNullable<NotifyConfig["onError"]>;

  constructor(cfg: NotifyConfig) {
    this.baseUrl = (cfg.baseUrl || "https://notify.zentto.net").replace(/\/$/, "");
    this.apiKey = cfg.apiKey;
    this.timeoutMs = cfg.timeoutMs ?? 10_000;
    this.retries = Math.max(0, cfg.retries ?? 1);
    this.onError = cfg.onError ?? (() => {});
  }

  // ── Low-level ────────────────────────────────────────────────────────────
  async request<T = unknown>(
    method: "POST" | "GET" | "DELETE" | "PUT",
    path: string,
    body?: object,
  ): Promise<NotifyResult<T>> {
    if (!this.apiKey) return { ok: false, error: "apiKey not configured" };
    let lastErr: Error | undefined;
    for (let attempt = 0; attempt <= this.retries; attempt++) {
      try {
        const res = await fetch(`${this.baseUrl}${path}`, {
          method,
          headers: {
            "Content-Type": "application/json",
            "X-API-Key": this.apiKey,
          },
          body: body ? JSON.stringify(body) : undefined,
          signal: AbortSignal.timeout(this.timeoutMs),
        });
        const json = (await res.json().catch(() => ({}))) as Record<string, unknown>;
        if (res.ok) {
          return {
            ok: true,
            messageId: (json.messageId as string) ?? (json.id as string),
            via: json.via as string | undefined,
            data: json as T,
          };
        }
        // 4xx: no retry — es error del caller o auth
        if (res.status >= 400 && res.status < 500) {
          return { ok: false, error: (json.error as string) ?? `HTTP ${res.status}` };
        }
        lastErr = new Error(`HTTP ${res.status}`);
      } catch (err) {
        lastErr = err as Error;
      }
      if (attempt < this.retries) {
        this.onError(lastErr, { path, attempt });
        await new Promise((r) => setTimeout(r, 250 * Math.pow(2, attempt)));
      }
    }
    const err = lastErr ?? new Error("unknown error");
    this.onError(err, { path, attempt: this.retries });
    return { ok: false, error: err.message };
  }

  // ── Health ───────────────────────────────────────────────────────────────
  async health(): Promise<{ ok: boolean; latencyMs?: number; error?: string }> {
    const t0 = Date.now();
    try {
      const res = await fetch(`${this.baseUrl}/health`, { signal: AbortSignal.timeout(this.timeoutMs) });
      if (!res.ok) return { ok: false, latencyMs: Date.now() - t0, error: `HTTP ${res.status}` };
      return { ok: true, latencyMs: Date.now() - t0 };
    } catch (err) {
      return { ok: false, latencyMs: Date.now() - t0, error: (err as Error).message };
    }
  }

  // ── Email ────────────────────────────────────────────────────────────────
  email = {
    send: (params: SendEmailParams): Promise<NotifyResult> =>
      this.request("POST", "/api/email/send", {
        ...params,
        track: params.track ?? true,
      }),

    sendQueued: (params: SendEmailParams & { scheduledAt?: string }): Promise<NotifyResult> =>
      this.request("POST", "/api/email/send-queued", params),

    /** Atajo: `email.sendTemplate('lead-confirmacion', { to, variables })` */
    sendTemplate: (
      templateId: string,
      opts: { to: string | string[]; variables: Record<string, string>; replyTo?: string; from?: string; track?: boolean },
    ): Promise<NotifyResult> =>
      this.request("POST", "/api/email/send", {
        templateId,
        to: opts.to,
        variables: opts.variables,
        replyTo: opts.replyTo,
        from: opts.from,
        track: opts.track ?? true,
      }),
  };

  // ── Contacts (CRM notify) ────────────────────────────────────────────────
  contacts = {
    upsert: (c: UpsertContactParams): Promise<NotifyResult> =>
      this.request("POST", "/api/contacts", {
        ...c,
        subscribed: c.subscribed ?? true,
      }),
  };

  // ── OTP ──────────────────────────────────────────────────────────────────
  otp = {
    send: (p: SendOtpParams): Promise<NotifyResult> =>
      this.request("POST", "/api/otp/send", {
        ...p,
        brandName: p.brandName ?? "Zentto",
      }),
    verify: (p: VerifyOtpParams): Promise<NotifyResult> =>
      this.request("POST", "/api/otp/verify", p),
  };

  // ── Push web ─────────────────────────────────────────────────────────────
  push = {
    send: (p: SendWebPushParams): Promise<NotifyResult> =>
      this.request("POST", "/api/push/send", p),
  };

  // ── SMS (carrier-based) ──────────────────────────────────────────────────
  sms = {
    send: (p: { to: string; carrier: string; message: string }): Promise<NotifyResult> =>
      this.request("POST", "/api/sms/send", p),
  };

  // ── WhatsApp (multi-instance) ────────────────────────────────────────────
  whatsapp = {
    send: (instanceId: string, p: { to: string; message: string; media?: { url: string; caption?: string } }): Promise<NotifyResult> =>
      this.request("POST", `/api/whatsapp/instances/${instanceId}/send`, p),
  };
}

// ── Factory convenience ─────────────────────────────────────────────────────
/**
 * Devuelve un NotifyClient configurado desde env vars estándar. Las variables
 * son:
 *
 *   NOTIFY_API_URL  (default https://notify.zentto.net)
 *   NOTIFY_API_KEY  (preferida)
 *   API_MASTER_KEY  (fallback)
 *
 * Si ninguna key está seteada, el cliente igual se construye pero los métodos
 * retornan `{ ok: false, error: "apiKey not configured" }` — mantiene la
 * propiedad "best-effort, nunca tumba el flujo de negocio".
 */
export function notifyFromEnv(overrides?: Partial<NotifyConfig>): NotifyClient {
  return new NotifyClient({
    baseUrl: process.env.NOTIFY_API_URL,
    apiKey: process.env.NOTIFY_API_KEY || process.env.API_MASTER_KEY || "",
    ...overrides,
  });
}
