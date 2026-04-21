/**
 * LicenseClient — cliente tipado para la validacion publica de licencias
 * Zentto (https://api.zentto.net/v1/license/validate).
 *
 * Pensado para instalaciones BYOC / on-prem que necesitan validar su
 * licencia al iniciar la app o periodicamente (ej. cada 24h). El endpoint
 * tiene rate-limit de 20 req/min por IP; este cliente NO impone rate-limit
 * local por defecto, pero se puede activar via `rateLimit` en la config.
 *
 * Operaciones admin (crear/revocar/renovar licencias) requieren master-key
 * y NO estan en este cliente publico — se agregaran en un submodulo
 * `license-admin` en un lote posterior si hay necesidad de exponerlas.
 */
import { defaultHttpConfig, httpRequest, type HttpConfig, type HttpConfigInput, type HttpResult } from "../internal/http.js";

export interface LicenseConfig {
  baseUrl?: string;
  timeoutMs?: number;
  retries?: number;
  onError?: HttpConfig["onError"];
  /** Opcional: activa rate-limit client-side para evitar 429 del servidor. */
  rateLimit?: HttpConfigInput["rateLimit"];
}

export interface LicenseValidateParams {
  code: string;
  key: string;
}

export interface LicenseValidateResult {
  ok: boolean;
  reason?:
    | null
    | "invalid_key"
    | "expired"
    | "revoked"
    | "rate_limit_exceeded"
    | "internal_error"
    | string;
}

export class LicenseClient {
  private readonly cfg: HttpConfig;

  constructor(opts: LicenseConfig = {}) {
    this.cfg = defaultHttpConfig({
      baseUrl: opts.baseUrl ?? "https://api.zentto.net",
      timeoutMs: opts.timeoutMs,
      retries: opts.retries,
      onError: opts.onError,
      rateLimit: opts.rateLimit,
    });
  }

  /** Valida una licencia BYOC. Siempre retorna 200 salvo error de red/timeout. */
  validate(params: LicenseValidateParams): Promise<HttpResult<LicenseValidateResult>> {
    return httpRequest<LicenseValidateResult>(this.cfg, {
      method: "GET",
      path: "/v1/license/validate",
      query: { code: params.code, key: params.key },
    });
  }
}

/**
 * Factory desde env vars:
 *   ZENTTO_API_URL — default https://api.zentto.net
 */
export function licenseFromEnv(overrides?: Partial<LicenseConfig>): LicenseClient {
  return new LicenseClient({
    baseUrl: process.env.ZENTTO_API_URL,
    ...overrides,
  });
}
