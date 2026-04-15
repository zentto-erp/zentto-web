/**
 * Envelope estándar para eventos del bus Zentto.
 * Ver docs/wiki/15-event-bus.md en zentto-web.
 */

export interface EventEnvelope<T = unknown> {
  eventId: string;
  eventType: string;       // "crm.lead.created" — convención "<domain>.<entity>.<action>"
  tenantCode: string;      // "ZENTTO", "ACME", etc.
  tenantId?: number;
  timestamp: string;       // ISO 8601
  source: string;          // "zentto-web-api", "zentto-hotel", ...
  correlationId?: string;
  data: T;
  version: number;         // bump si el shape de data cambia
}

function uuid(): string {
  // RFC 4122 v4 — sin dependencias
  const bytes = new Uint8Array(16);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const g: any = globalThis as any;
  if (g.crypto?.getRandomValues) {
    g.crypto.getRandomValues(bytes);
  } else {
    for (let i = 0; i < 16; i++) bytes[i] = Math.floor(Math.random() * 256);
  }
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  const hex = Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

export function buildEnvelope<T>(params: {
  eventType: string;
  tenantCode: string;
  tenantId?: number;
  source: string;
  data: T;
  version?: number;
  correlationId?: string;
  eventId?: string;
  timestamp?: string;
}): EventEnvelope<T> {
  return {
    eventId: params.eventId ?? `evt_${uuid()}`,
    eventType: params.eventType,
    tenantCode: params.tenantCode.toUpperCase(),
    tenantId: params.tenantId,
    timestamp: params.timestamp ?? new Date().toISOString(),
    source: params.source,
    correlationId: params.correlationId,
    data: params.data,
    version: params.version ?? 1,
  };
}

export function topicName(tenantCode: string, eventType: string): string {
  return `zentto.${tenantCode.toLowerCase()}.${eventType}`;
}
