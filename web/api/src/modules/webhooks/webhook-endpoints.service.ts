/**
 * webhook-endpoints.service.ts — CRUD de endpoints de webhooks por tenant.
 */

import { callSp, callSpOut, sql } from "../../db/query.js";

// ── Interfaces ───────────────────────────────────────────────────────────────

export interface WebhookEndpoint {
  WebhookEndpointId: number;
  CompanyId: number;
  Url: string;
  Events: string[];
  Description: string | null;
  IsActive: boolean;
  CreatedAtUtc: string;
  UpdatedAtUtc: string;
}

export interface WebhookEndpointDetail extends WebhookEndpoint {
  Secret: string;
}

export interface CreateWebhookDto {
  url: string;
  secret: string;
  events: string[];
  description?: string;
}

export interface UpdateWebhookDto {
  url?: string;
  secret?: string;
  events?: string[];
  description?: string;
  isActive?: boolean;
}

// ── Event types válidos ──────────────────────────────────────────────────────

export const WEBHOOK_EVENT_TYPES = [
  "order.created",
  "order.completed",
  "payment.received",
  "invoice.created",
  "appointment.created",
  "appointment.completed",
  "inventory.low_stock",
  "*", // wildcard — recibe todos
] as const;

export type WebhookEventType = (typeof WEBHOOK_EVENT_TYPES)[number];

// ── Service functions ────────────────────────────────────────────────────────

export async function createWebhookEndpoint(
  companyId: number,
  dto: CreateWebhookDto
): Promise<{ ok: boolean; mensaje: string; webhookEndpointId: number | null }> {
  // Validar event types
  for (const ev of dto.events) {
    if (!WEBHOOK_EVENT_TYPES.includes(ev as WebhookEventType)) {
      return { ok: false, mensaje: `Evento inválido: ${ev}`, webhookEndpointId: null };
    }
  }

  const rows = await callSp<{ ok: boolean; mensaje: string; WebhookEndpointId: number }>(
    "usp_Platform_WebhookEndpoint_Create",
    {
      CompanyId: companyId,
      Url: dto.url,
      Secret: dto.secret,
      Events: dto.events,
      Description: dto.description ?? null,
    }
  );

  const row = rows[0];
  return {
    ok: row?.ok ?? false,
    mensaje: row?.mensaje ?? "Error desconocido",
    webhookEndpointId: row?.WebhookEndpointId ?? null,
  };
}

export async function listWebhookEndpoints(companyId: number): Promise<WebhookEndpoint[]> {
  return callSp<WebhookEndpoint>("usp_Platform_WebhookEndpoint_List", {
    CompanyId: companyId,
  });
}

export async function getWebhookEndpoint(
  companyId: number,
  endpointId: number
): Promise<WebhookEndpointDetail | null> {
  const rows = await callSp<WebhookEndpointDetail>(
    "usp_Platform_WebhookEndpoint_GetById",
    {
      CompanyId: companyId,
      WebhookEndpointId: endpointId,
    }
  );
  return rows[0] ?? null;
}

export async function updateWebhookEndpoint(
  companyId: number,
  endpointId: number,
  dto: UpdateWebhookDto
): Promise<{ ok: boolean; mensaje: string }> {
  // Validar event types si se pasan
  if (dto.events) {
    for (const ev of dto.events) {
      if (!WEBHOOK_EVENT_TYPES.includes(ev as WebhookEventType)) {
        return { ok: false, mensaje: `Evento inválido: ${ev}` };
      }
    }
  }

  const rows = await callSp<{ ok: boolean; mensaje: string }>(
    "usp_Platform_WebhookEndpoint_Update",
    {
      CompanyId: companyId,
      WebhookEndpointId: endpointId,
      Url: dto.url ?? null,
      Secret: dto.secret ?? null,
      Events: dto.events ?? null,
      Description: dto.description ?? null,
      IsActive: dto.isActive ?? null,
    }
  );

  return rows[0] ?? { ok: false, mensaje: "Error desconocido" };
}

export async function deleteWebhookEndpoint(
  companyId: number,
  endpointId: number
): Promise<{ ok: boolean; mensaje: string }> {
  const rows = await callSp<{ ok: boolean; mensaje: string }>(
    "usp_Platform_WebhookEndpoint_Delete",
    {
      CompanyId: companyId,
      WebhookEndpointId: endpointId,
    }
  );

  return rows[0] ?? { ok: false, mensaje: "Error desconocido" };
}

export async function listWebhookDeliveries(
  companyId: number,
  endpointId: number,
  page = 1,
  pageSize = 50
) {
  const rows = await callSp<{
    WebhookDeliveryId: number;
    WebhookEndpointId: number;
    EventType: string;
    Payload: object;
    Status: string;
    ResponseCode: number | null;
    Attempts: number;
    MaxAttempts: number;
    NextRetryAtUtc: string | null;
    CreatedAtUtc: string;
    CompletedAtUtc: string | null;
    TotalCount: number;
  }>("usp_Platform_WebhookDelivery_ListByEndpoint", {
    CompanyId: companyId,
    WebhookEndpointId: endpointId,
    PageNumber: page,
    PageSize: pageSize,
  });

  const totalCount = rows[0]?.TotalCount ?? 0;

  return {
    data: rows.map(({ TotalCount, ...r }) => r),
    pagination: {
      page,
      pageSize,
      totalCount,
      totalPages: Math.ceil(Number(totalCount) / pageSize),
    },
  };
}
