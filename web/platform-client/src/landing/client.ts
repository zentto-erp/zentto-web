/**
 * LandingClient — cliente tipado para el endpoint público de leads del
 * ERP Zentto (POST https://api.zentto.net/api/landing/register).
 *
 * Útil para sitios externos de tenants clientes (acme.com) que quieren
 * integrar su formulario de contacto sin reescribir fetch a mano. Resuelve
 * el tenant destino vía `X-Tenant-Key` emitido desde el CRM del cliente.
 *
 * Para el landing propio de Zentto (zentto.net), la Pages Function ya
 * llama al ERP directamente — no necesita este cliente.
 */
import { defaultHttpConfig, httpRequest, type HttpConfig, type HttpResult } from "../internal/http.js";

export interface LandingConfig {
  baseUrl?: string;
  /** Header `X-Tenant-Key` — PublicApiKey emitida desde el CRM del tenant. */
  tenantKey?: string;
  timeoutMs?: number;
  retries?: number;
  onError?: HttpConfig["onError"];
}

export interface RegisterLeadParams {
  email: string;
  name: string;
  company?: string;
  country?: string;
  phone?: string;
  source?: string;
  topic?: string;
  message?: string;
}

export interface RegisterLeadResponse {
  ok: boolean;
  mensaje?: string;
  targetCompanyId?: number | null;
  zentto_registered?: boolean;
  paddle_customer_id?: string | null;
}

export class LandingClient {
  private readonly cfg: HttpConfig;
  private readonly tenantKey?: string;

  constructor(opts: LandingConfig) {
    this.cfg = defaultHttpConfig({
      baseUrl: opts.baseUrl ?? "https://api.zentto.net",
      timeoutMs: opts.timeoutMs,
      retries: opts.retries,
      onError: opts.onError,
    });
    this.tenantKey = opts.tenantKey;
  }

  async registerLead(params: RegisterLeadParams): Promise<HttpResult<RegisterLeadResponse>> {
    return httpRequest<RegisterLeadResponse>(this.cfg, {
      method: "POST",
      path: "/api/landing/register",
      body: params,
      headers: this.tenantKey ? { "X-Tenant-Key": this.tenantKey } : undefined,
    });
  }
}

/**
 * Factory desde env vars:
 *   ZENTTO_API_URL — default https://api.zentto.net
 *   ZENTTO_TENANT_KEY — PublicApiKey del tenant (si el caller es externo)
 */
export function landingFromEnv(overrides?: Partial<LandingConfig>): LandingClient {
  return new LandingClient({
    baseUrl: process.env.ZENTTO_API_URL,
    tenantKey: process.env.ZENTTO_TENANT_KEY,
    ...overrides,
  });
}
