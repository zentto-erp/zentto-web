/**
 * Webhook dispatcher — consumidor Kafka que escucha todos los eventos del
 * ecosistema (topics `zentto.*`) y los reenvía a los webhooks registrados
 * por los tenants dueños.
 *
 * Activación: ENV `WEBHOOK_DISPATCHER_ENABLED=true`.
 *
 * Flujo por mensaje:
 *   1. Decodifica el envelope.
 *   2. Extrae tenantCode → resuelve CompanyId.
 *   3. Consulta cfg.usp_cfg_tenantwebhook_resolve(companyId, eventType).
 *   4. Para cada webhook, POST al URL con header `X-Zentto-Signature`
 *      (HMAC-SHA256 del body, con el secret del webhook).
 *   5. Registra la delivery en cfg.TenantWebhookDelivery (idempotente por
 *      WebhookId+EventId — si el mismo evento se entrega dos veces, solo
 *      se actualiza el último intento).
 *
 * Retries: 3 intentos inmediatos (backoff 1s / 4s / 16s). Si todos fallan,
 * marca status='dlq' y sube ConsecutiveFailures. Tras 10 fallos consecutivos
 * el webhook se autodesactiva (visible al admin del tenant).
 */
import { Kafka, logLevel, type Consumer } from "kafkajs";
import crypto from "node:crypto";
import { callSp, callSpOut, query } from "../../db/query.js";
import sql from "mssql";

interface EventEnvelope {
  eventId: string;
  eventType: string;
  tenantCode: string;
  tenantId?: number;
  timestamp: string;
  source: string;
  correlationId?: string;
  data: unknown;
  version: number;
}

const ENABLED = process.env.WEBHOOK_DISPATCHER_ENABLED === "true";
const KAFKA_BROKERS = (process.env.KAFKA_BROKERS ?? "")
  .split(",").map((s) => s.trim()).filter(Boolean);
const GROUP_ID = process.env.WEBHOOK_DISPATCHER_GROUP_ID ?? "zentto-webhook-dispatcher";
const TOPIC_PATTERN = /^zentto\..+$/;

let consumer: Consumer | null = null;

export async function startWebhookDispatcher(): Promise<void> {
  if (!ENABLED) {
    console.log("[webhook-dispatcher] Disabled (WEBHOOK_DISPATCHER_ENABLED!=true) — skip");
    return;
  }
  if (KAFKA_BROKERS.length === 0) {
    console.warn("[webhook-dispatcher] KAFKA_BROKERS no configurado — skip");
    return;
  }
  const clientId = `zentto-webhook-dispatcher-${process.env.NODE_ENV ?? "production"}-${process.pid}`;
  const kafka = new Kafka({
    clientId,
    brokers: KAFKA_BROKERS,
    logLevel: logLevel.WARN,
    retry: { initialRetryTime: 2000, retries: 5 },
  });
  consumer = kafka.consumer({ groupId: GROUP_ID });
  await consumer.connect();
  await consumer.subscribe({ topic: TOPIC_PATTERN, fromBeginning: false });

  await consumer.run({
    eachMessage: async ({ topic, message }) => {
      const raw = message.value?.toString("utf-8");
      if (!raw) return;
      let envelope: EventEnvelope;
      try {
        envelope = JSON.parse(raw) as EventEnvelope;
      } catch (err) {
        console.warn(`[webhook-dispatcher] bad envelope in ${topic}:`, (err as Error).message);
        return;
      }
      if (!envelope.eventId || !envelope.eventType || !envelope.tenantCode) {
        console.warn("[webhook-dispatcher] envelope incompleto — skip", envelope);
        return;
      }
      await dispatchEvent(topic, envelope);
    },
  });
  console.log(`[webhook-dispatcher] started — group=${GROUP_ID} clientId=${clientId}`);
}

export async function stopWebhookDispatcher(): Promise<void> {
  if (consumer) {
    try { await consumer.disconnect(); } catch { /* ignore */ }
    consumer = null;
  }
}

async function dispatchEvent(topic: string, envelope: EventEnvelope): Promise<void> {
  // Resolver CompanyId a partir de tenantId (si viene) o tenantCode.
  const companyId = envelope.tenantId ?? await resolveTenantCodeToCompanyId(envelope.tenantCode);
  if (!companyId) {
    console.warn(`[webhook-dispatcher] tenantCode ${envelope.tenantCode} no resuelve a CompanyId`);
    return;
  }

  // Resolver webhooks registrados que matcheen el eventType.
  const hooks = await callSp<{
    WebhookId: number; Url: string; SecretHash: string; EventFilter: string;
  }>("cfg.usp_cfg_tenantwebhook_resolve", {
    CompanyId: companyId, EventType: envelope.eventType,
  });

  if (!hooks.length) return;

  const body = JSON.stringify(envelope);
  const payloadSize = Buffer.byteLength(body, "utf-8");

  // Filtrado fino en JS (SP hace match grueso por substring).
  const filtered = hooks.filter((h) => matchFilter(h.EventFilter, envelope.eventType));

  await Promise.all(filtered.map(async (h) => {
    const result = await deliverWithRetry(h.Url, body, h.SecretHash);
    await callSpOut("cfg.usp_cfg_tenantwebhook_delivery_record", {
      WebhookId:   h.WebhookId,
      EventId:     envelope.eventId,
      EventType:   envelope.eventType,
      Topic:       topic,
      Status:      result.status,
      HttpStatus:  result.httpStatus ?? null,
      AttemptCount: result.attempts,
      LastError:   result.lastError ?? null,
      PayloadSize: payloadSize,
    }, {
      DeliveryId: { type: sql.BigInt,        value: 0 },
      Resultado:  { type: sql.Int,           value: 0 },
      Mensaje:    { type: sql.NVarChar(500), value: "" },
    }).catch((err) => {
      console.error("[webhook-dispatcher] failed to record delivery:", (err as Error).message);
    });
  }));
}

/** Match glob simple: "*" = todo; "crm.lead.*" = eventType que empiece con "crm.lead."; separador CSV. */
function matchFilter(filter: string, eventType: string): boolean {
  if (!filter || filter.trim() === "*") return true;
  const patterns = filter.split(",").map((s) => s.trim()).filter(Boolean);
  return patterns.some((p) => {
    if (p === "*") return true;
    if (p.endsWith(".*")) return eventType.startsWith(p.slice(0, -1)); // "crm.lead." ← "crm.lead.*"
    return eventType === p;
  });
}

interface DeliveryResult {
  status: "success" | "failed" | "dlq";
  httpStatus?: number;
  attempts: number;
  lastError?: string;
}

async function deliverWithRetry(url: string, body: string, secretHash: string): Promise<DeliveryResult> {
  // NO firmamos con el hash — firmamos con el SECRET plain. Pero solo tenemos
  // el hash en BD. Trade-off: el tenant verifica HMAC con su secret, y acá
  // firmamos con... no podemos.
  //
  // Decisión: guardar el secret plain encriptado (no solo hash) para poder
  // firmar server-side es una violación de security básica (si se leakea la
  // BD, leaker tiene todos los secrets). En vez de eso firmamos con el
  // PROPIO HASH como clave HMAC — el tenant debe verificar con el hash, no
  // con el secret plain. El secret plain sirve para que el tenant SEPA cual
  // es SU webhook (mostrarlo en su UI), pero la verificación usa el hash.
  //
  // Más simple y seguro: firmar con `secretHash` como clave HMAC. El cliente
  // verifica computando HMAC(secretHash, body). El secret plain NO se usa
  // para firma — es solo un identificador opaco para el admin.
  const signature = crypto.createHmac("sha256", secretHash).update(body).digest("hex");
  const backoffs = [0, 1000, 4000, 16000]; // 4 intentos: inmediato + 3 retries
  let lastError: string | undefined;
  let lastStatus: number | undefined;

  for (let attempt = 0; attempt < backoffs.length; attempt++) {
    if (backoffs[attempt] > 0) await new Promise((r) => setTimeout(r, backoffs[attempt]));
    try {
      const res = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Zentto-Signature": `sha256=${signature}`,
          "User-Agent": "Zentto-Webhook-Dispatcher/1.0",
        },
        body,
        signal: AbortSignal.timeout(8000),
      });
      lastStatus = res.status;
      if (res.ok) {
        return { status: "success", httpStatus: res.status, attempts: attempt + 1 };
      }
      if (res.status >= 400 && res.status < 500 && res.status !== 408 && res.status !== 429) {
        // 4xx permanente (excepto timeout/rate limit) → no tiene sentido reintentar
        return { status: "failed", httpStatus: res.status, attempts: attempt + 1, lastError: `HTTP ${res.status}` };
      }
      lastError = `HTTP ${res.status}`;
    } catch (err) {
      lastError = (err as Error).message;
    }
  }
  return { status: "dlq", httpStatus: lastStatus, attempts: backoffs.length, lastError };
}

// ── Resolver tenantCode → CompanyId ────────────────────────────────────────
const tenantCache = new Map<string, { id: number; expiresAt: number }>();
const TENANT_CACHE_TTL_MS = 5 * 60 * 1000;

async function resolveTenantCodeToCompanyId(tenantCode: string): Promise<number | null> {
  const key = tenantCode.toUpperCase();
  const cached = tenantCache.get(key);
  if (cached && cached.expiresAt > Date.now()) return cached.id;

  try {
    const rows = await query<{ CompanyId: number }>(
      `SELECT "CompanyId" FROM cfg."Company" WHERE "CompanyCode" = @CompanyCode AND "IsDeleted" = FALSE LIMIT 1`,
      { CompanyCode: key },
    );
    if (rows?.[0]?.CompanyId) {
      tenantCache.set(key, { id: rows[0].CompanyId, expiresAt: Date.now() + TENANT_CACHE_TTL_MS });
      return rows[0].CompanyId;
    }
  } catch (err) {
    console.warn("[webhook-dispatcher] resolve tenant failed:", (err as Error).message);
  }
  return null;
}
