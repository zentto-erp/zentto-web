/**
 * SubscriptionsClient — cliente tipado self-service para la suscripcion del
 * tenant autenticado (https://api.zentto.net/v1/subscriptions/*).
 *
 * Todos los endpoints requieren sesion JWT (cookie httpOnly desde
 * zentto-auth). Este cliente envia `credentials: "include"` por defecto
 * para que el navegador incluya la cookie.
 *
 * Operaciones admin de suscripciones (ver/editar/cancelar en otros tenants)
 * requieren master-key y no se exponen aqui.
 *
 * Consumo principal: apps verticales (hotel, medical, tickets, education,
 * rental, inmobiliario, pos, restaurante) que necesitan verificar
 * entitlements antes de habilitar features gated por plan/addon.
 */
import { defaultHttpConfig, httpRequest, type HttpConfig, type HttpConfigInput, type HttpResult } from "../internal/http.js";

export interface SubscriptionsConfig {
  baseUrl?: string;
  /** Override del CompanyId del JWT — util cuando el usuario opera multi-tenant. */
  companyId?: number;
  timeoutMs?: number;
  retries?: number;
  onError?: HttpConfig["onError"];
  rateLimit?: HttpConfigInput["rateLimit"];
  /**
   * Modo de transmision de la cookie. En browser la cookie viaja via
   * `credentials: "include"`. En Node (SSR / apps hermanas) puede pasarse
   * manualmente el header Cookie — en ese caso poner `credentials: "omit"`
   * y pasar `cookieHeader`.
   */
  credentials?: "include" | "omit";
  /** Header `Cookie` manual para llamadas server-side (Node). */
  cookieHeader?: string;
}

export type BillingCycle = "monthly" | "annual";

export type SubscriptionSource = "paddle" | "trial" | "manual";

export type SubscriptionStatus =
  | "trialing"
  | "active"
  | "past_due"
  | "paused"
  | "cancelled"
  | "expired";

export interface Subscription {
  SubscriptionId: number;
  CompanyId: number;
  Source: SubscriptionSource;
  Plan: string;
  BillingCycle: BillingCycle;
  MonthlyRecurringRevenue: number;
  Status: SubscriptionStatus;
  PaddleSubscriptionId: string | null;
  PaddleCustomerId: string | null;
  TrialEndsAt: string | null;
  PaidUntilAt: string | null;
  CreatedAt: string;
}

export interface SubscriptionEntitlements {
  CompanyId: number;
  ModuleCodes: string[];
  Plans: string[];
  ExpiresAt: string | null;
  IsActive: boolean;
}

export interface GetMeResponse {
  ok: boolean;
  subscription: Subscription | null;
}

export interface GetEntitlementsResponse {
  ok: boolean;
  entitlements: SubscriptionEntitlements;
}

export interface AddItemParams {
  addonSlug: string;
  billingCycle?: BillingCycle;
}

export interface AddItemResponse {
  ok: boolean;
  mode: "paddle_checkout" | "direct_add";
  transactionId?: string | null;
  checkoutUrl?: string | null;
  mensaje?: string | null;
}

export interface RemoveItemResponse {
  ok: boolean;
  mensaje?: string;
}

export class SubscriptionsClient {
  private readonly cfg: HttpConfig;
  private readonly companyId?: number;
  private readonly credentials: "include" | "omit";
  private readonly cookieHeader?: string;

  constructor(opts: SubscriptionsConfig = {}) {
    this.cfg = defaultHttpConfig({
      baseUrl: opts.baseUrl ?? "https://api.zentto.net",
      timeoutMs: opts.timeoutMs,
      retries: opts.retries,
      onError: opts.onError,
      rateLimit: opts.rateLimit,
    });
    this.companyId = opts.companyId;
    this.credentials = opts.credentials ?? "include";
    this.cookieHeader = opts.cookieHeader;
  }

  private buildHeaders(extra?: Record<string, string>): Record<string, string> {
    const headers: Record<string, string> = { ...extra };
    if (this.companyId !== undefined) headers["X-Company-Id"] = String(this.companyId);
    if (this.cookieHeader) headers["Cookie"] = this.cookieHeader;
    return headers;
  }

  /** Estado actual de la suscripcion del tenant autenticado. */
  getMe(): Promise<HttpResult<GetMeResponse>> {
    return httpRequest<GetMeResponse>(this.cfg, {
      method: "GET",
      path: "/v1/subscriptions/me",
      headers: this.buildHeaders(),
      credentials: this.credentials,
    });
  }

  /** Modulos y limites activos (union de plan core + addons vigentes). */
  getEntitlements(): Promise<HttpResult<GetEntitlementsResponse>> {
    return httpRequest<GetEntitlementsResponse>(this.cfg, {
      method: "GET",
      path: "/v1/subscriptions/entitlements",
      headers: this.buildHeaders(),
      credentials: this.credentials,
    });
  }

  /** Agrega un addon — genera checkout Paddle o aplicacion directa (trial/manual). */
  addItem(params: AddItemParams): Promise<HttpResult<AddItemResponse>> {
    return httpRequest<AddItemResponse>(this.cfg, {
      method: "POST",
      path: "/v1/subscriptions/items",
      body: {
        addonSlug: params.addonSlug,
        billingCycle: params.billingCycle ?? "monthly",
      },
      headers: this.buildHeaders(),
      credentials: this.credentials,
    });
  }

  /** Remueve un addon activo por id de item. */
  removeItem(itemId: number): Promise<HttpResult<RemoveItemResponse>> {
    return httpRequest<RemoveItemResponse>(this.cfg, {
      method: "DELETE",
      path: `/v1/subscriptions/items/${encodeURIComponent(String(itemId))}`,
      headers: this.buildHeaders(),
      credentials: this.credentials,
    });
  }
}

/**
 * Factory desde env vars:
 *   ZENTTO_API_URL — default https://api.zentto.net
 *   ZENTTO_COMPANY_ID — override opcional del CompanyId del JWT
 */
export function subscriptionsFromEnv(overrides?: Partial<SubscriptionsConfig>): SubscriptionsClient {
  const envCompany = process.env.ZENTTO_COMPANY_ID ? Number(process.env.ZENTTO_COMPANY_ID) : undefined;
  return new SubscriptionsClient({
    baseUrl: process.env.ZENTTO_API_URL,
    companyId: Number.isFinite(envCompany) ? envCompany : undefined,
    ...overrides,
  });
}
