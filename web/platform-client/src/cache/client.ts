/**
 * CacheClient — cliente tipado para zentto-cache (cache.zentto.net).
 *
 * Estandariza el header `x-client-key`. Cada recurso (grid-layouts,
 * report-templates, studio-schemas, blog-posts) expone list/get/put/delete
 * con la misma forma.
 *
 * Identidad del dueño del dato: `companyId` + (`userId` | `email`).
 */
import { defaultHttpConfig, httpRequest, type HttpConfig, type HttpResult } from "../internal/http.js";

export interface CacheConfig {
  baseUrl?: string;
  /** Header `x-client-key` — identifica la app consumidora. */
  clientKey: string;
  timeoutMs?: number;
  retries?: number;
  onError?: HttpConfig["onError"];
}

export interface CacheIdentity {
  companyId: number;
  userId?: number | string;
  email?: string;
}

function identityQuery(id: CacheIdentity): Record<string, string | number | undefined> {
  return {
    companyId: id.companyId,
    userId: id.userId !== undefined ? String(id.userId) : undefined,
    email: id.email,
  };
}

type Resource = "grid-layouts" | "report-templates" | "studio-schemas" | "blog-posts";

export class CacheClient {
  private readonly cfg: HttpConfig;
  private readonly clientKey: string;

  constructor(opts: CacheConfig) {
    this.cfg = defaultHttpConfig({
      baseUrl: opts.baseUrl ?? "https://cache.zentto.net",
      timeoutMs: opts.timeoutMs,
      retries: opts.retries,
      onError: opts.onError,
    });
    this.clientKey = opts.clientKey;
  }

  private headers(): Record<string, string> {
    return { "x-client-key": this.clientKey };
  }

  async health(): Promise<HttpResult<{ ok: boolean }>> {
    return httpRequest(this.cfg, { method: "GET", path: "/health" });
  }

  private resource<TValue = unknown>(name: Resource) {
    return {
      list: (id: CacheIdentity): Promise<HttpResult<{ ok: boolean } & Record<string, string[]>>> =>
        httpRequest(this.cfg, {
          method: "GET",
          path: `/v1/${name}`,
          query: identityQuery(id),
          headers: this.headers(),
        }),

      get: (itemId: string, id: CacheIdentity): Promise<HttpResult<{ ok: boolean; layout?: TValue; template?: TValue; schema?: TValue; post?: TValue; updatedAt?: string }>> =>
        httpRequest(this.cfg, {
          method: "GET",
          path: `/v1/${name}/${encodeURIComponent(itemId)}`,
          query: identityQuery(id),
          headers: this.headers(),
        }),

      put: (itemId: string, value: TValue, id: CacheIdentity): Promise<HttpResult<{ ok: boolean }>> =>
        httpRequest(this.cfg, {
          method: "PUT",
          path: `/v1/${name}/${encodeURIComponent(itemId)}`,
          body: {
            companyId: id.companyId,
            userId: id.userId,
            email: id.email,
            // El campo varía según el recurso; mandamos todos los shapes vistos en el server.
            layout: value,
            template: value,
            schema: value,
            post: value,
          },
          headers: this.headers(),
        }),

      delete: (itemId: string, id: CacheIdentity): Promise<HttpResult<{ ok: boolean }>> =>
        httpRequest(this.cfg, {
          method: "DELETE",
          path: `/v1/${name}/${encodeURIComponent(itemId)}`,
          query: identityQuery(id),
          headers: this.headers(),
        }),
    };
  }

  readonly gridLayouts     = this.resource<unknown>("grid-layouts");
  readonly reportTemplates = this.resource<unknown>("report-templates");
  readonly studioSchemas   = this.resource<unknown>("studio-schemas");
  readonly blogPosts       = this.resource<unknown>("blog-posts");
}

/**
 * Factory desde env vars:
 *   CACHE_URL — default https://cache.zentto.net
 *   CACHE_APP_KEY — header x-client-key (obligatoria)
 */
export function cacheFromEnv(overrides?: Partial<CacheConfig>): CacheClient {
  return new CacheClient({
    baseUrl: process.env.CACHE_URL,
    clientKey: process.env.CACHE_APP_KEY ?? "",
    ...overrides,
  });
}
