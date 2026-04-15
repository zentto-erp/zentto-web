/**
 * AuthClient — cliente tipado para zentto-auth (sso.zentto.net / auth.zentto.net).
 *
 * Expone dos modos:
 *   - Cliente user-facing (frontend): cookies httpOnly + Bearer JWT.
 *     Métodos: login, refresh, logout, me.
 *   - Cliente service-to-service (backend): header `x-service-key`.
 *     Métodos: admin.provisionOwner, admin.createMagicLink.
 *
 * setPassword es público (magic-link consumo), no requiere auth.
 */
import { defaultHttpConfig, httpRequest, type HttpConfig, type HttpConfigInput, type HttpResult } from "../internal/http.js";
import { TtlCache, memoAsync } from "../internal/cache.js";

export interface AuthConfig {
  baseUrl?: string;
  /** Bearer JWT para llamadas user-facing. Opcional — algunos métodos no requieren. */
  accessToken?: string;
  /** Service key (`x-service-key`) para llamadas admin/provisioning. */
  serviceKey?: string;
  timeoutMs?: number;
  retries?: number;
  onError?: HttpConfig["onError"];
  /** TTL del cache de `me()`. Default 15s. Pasar 0 para desactivar. */
  meCacheTtlMs?: number;
  /** Rate limit client-side (opcional). */
  rateLimit?: HttpConfigInput["rateLimit"];
}

// ── User shapes ─────────────────────────────────────────────────────────────
export interface AuthUser {
  userId?: number;
  username?: string;
  email?: string;
  displayName?: string;
  isAdmin?: boolean;
  mfaEnabled?: boolean;
  [k: string]: unknown;
}

export interface LoginResponse {
  user: AuthUser;
  accessToken: string;
  refreshToken?: string;
  mfaChallengeToken?: string;
}

export interface MeResponse {
  user: AuthUser;
  modulos?: unknown[];
  permisos?: unknown[];
  companyAccesses?: unknown[];
  defaultCompany?: unknown;
}

export interface ProvisionOwnerParams {
  email: string;
  fullName: string;
  companyId: number;
  companyCode: string;
  tenantSubdomain?: string;
  role?: string;
  sendMagicLink?: boolean;
  locale?: string;
}

export interface ProvisionOwnerResponse {
  userId: number;
  email: string;
  magicLinkUrl?: string;
  alreadyExisted?: boolean;
}

export interface MagicLinkParams {
  email: string;
  companyId: number;
  purpose: "set_password" | "reset_password";
  tenantSubdomain?: string;
  ttlMinutes?: number;
}

export interface MagicLinkResponse {
  url: string;
  expiresAt: string;
}

// ── Client ──────────────────────────────────────────────────────────────────
export class AuthClient {
  private readonly cfg: HttpConfig;
  private readonly serviceKey?: string;
  private accessToken?: string;
  private refreshInFlight?: Promise<string | undefined>;
  private readonly meCache: TtlCache<HttpResult<MeResponse>> | null;

  constructor(opts: AuthConfig) {
    this.cfg = defaultHttpConfig({
      baseUrl: opts.baseUrl ?? "https://auth.zentto.net",
      timeoutMs: opts.timeoutMs,
      retries: opts.retries,
      onError: opts.onError,
      rateLimit: opts.rateLimit,
      // Intercepta 401 → intenta refresh + reintenta UNA vez con el nuevo Bearer.
      // Evita que cada caller tenga que saber manejar expiración de tokens.
      beforeRetry: async (err, ctx) => {
        if (err.name !== "AuthError") return { retry: false };
        if (ctx.path === "/auth/refresh") return { retry: false }; // no refresh durante refresh
        const newToken = await this.tryRefresh();
        if (!newToken) return { retry: false };
        // Invalidate me cache on token change (identity may have changed).
        this.meCache?.clear();
        return { retry: true, headers: { Authorization: `Bearer ${newToken}` } };
      },
    });
    this.accessToken = opts.accessToken;
    this.serviceKey = opts.serviceKey;
    const ttl = opts.meCacheTtlMs ?? 15_000;
    this.meCache = ttl > 0 ? new TtlCache<HttpResult<MeResponse>>({ ttlMs: ttl, maxEntries: 16 }) : null;
  }

  setAccessToken(token: string | undefined): void {
    this.accessToken = token;
  }

  private bearer(): Record<string, string> {
    return this.accessToken ? { Authorization: `Bearer ${this.accessToken}` } : {};
  }

  /**
   * Refresh coalescido: si varios requests 401 caen a la vez, solo uno
   * llama a /auth/refresh y los demás esperan el mismo resultado.
   */
  private async tryRefresh(): Promise<string | undefined> {
    if (!this.refreshInFlight) {
      this.refreshInFlight = (async () => {
        const res = await this.refresh();
        const newToken = res.ok ? res.data?.accessToken : undefined;
        if (newToken) this.accessToken = newToken;
        return newToken;
      })().finally(() => {
        // Limpiar tras la resolución (con un tick de margen).
        setTimeout(() => { this.refreshInFlight = undefined; }, 0);
      });
    }
    return this.refreshInFlight;
  }

  private service(): Record<string, string> {
    if (!this.serviceKey) throw new Error("AuthClient: serviceKey no configurada para este método");
    return { "x-service-key": this.serviceKey };
  }

  // ── Health ───────────────────────────────────────────────────────────────
  async health(): Promise<HttpResult<{ ok: boolean; checks?: Record<string, unknown> }>> {
    return httpRequest(this.cfg, { method: "GET", path: "/health" });
  }

  // ── User-facing ──────────────────────────────────────────────────────────
  async login(params: { username: string; password: string; appId?: string }): Promise<HttpResult<LoginResponse>> {
    return httpRequest<LoginResponse>(this.cfg, {
      method: "POST",
      path: "/auth/login",
      body: params,
      credentials: "include",
    });
  }

  async loginMfa(params: { mfaChallengeToken: string; mfaToken: string }): Promise<HttpResult<LoginResponse>> {
    return httpRequest<LoginResponse>(this.cfg, {
      method: "POST",
      path: "/auth/login/mfa",
      body: params,
      credentials: "include",
    });
  }

  async refresh(): Promise<HttpResult<{ ok: boolean; accessToken: string }>> {
    return httpRequest(this.cfg, {
      method: "POST",
      path: "/auth/refresh",
      credentials: "include",
    });
  }

  async logout(): Promise<HttpResult<{ ok: boolean }>> {
    return httpRequest(this.cfg, {
      method: "POST",
      path: "/auth/logout",
      credentials: "include",
      headers: this.bearer(),
    });
  }

  async me(appId?: string): Promise<HttpResult<MeResponse>> {
    const fn = () => httpRequest<MeResponse>(this.cfg, {
      method: "GET",
      path: "/auth/me",
      query: { appId },
      headers: this.bearer(),
      credentials: "include",
    });
    if (!this.meCache) return fn();
    // key = token + appId — cambios de cualquiera invalidan la entrada.
    const key = `${this.accessToken ?? "anon"}:${appId ?? ""}`;
    return memoAsync(this.meCache, key, fn);
  }

  /** Purga manualmente el cache de `me()`. Útil tras cambios de permisos. */
  invalidateMeCache(): void {
    this.meCache?.clear();
  }

  async registerForApp(params: {
    email: string;
    password: string;
    displayName?: string;
    appId: string;
    role: string;
    metadata?: Record<string, unknown>;
  }): Promise<HttpResult<LoginResponse>> {
    return httpRequest<LoginResponse>(this.cfg, {
      method: "POST",
      path: "/auth/register-for-app",
      body: params,
    });
  }

  /** Consumo de magic-link (público). */
  async setPassword(params: { token: string; newPassword: string }): Promise<HttpResult<{ ok: boolean; email: string }>> {
    return httpRequest(this.cfg, {
      method: "POST",
      path: "/auth/set-password",
      body: params,
    });
  }

  // ── Service-to-service ───────────────────────────────────────────────────
  readonly admin = {
    provisionOwner: (params: ProvisionOwnerParams): Promise<HttpResult<ProvisionOwnerResponse>> =>
      httpRequest<ProvisionOwnerResponse>(this.cfg, {
        method: "POST",
        path: "/admin/users/provision-owner",
        body: params,
        headers: this.service(),
      }),

    createMagicLink: (params: MagicLinkParams): Promise<HttpResult<MagicLinkResponse>> =>
      httpRequest<MagicLinkResponse>(this.cfg, {
        method: "POST",
        path: "/admin/users/magic-link",
        body: params,
        headers: this.service(),
      }),
  };
}

/**
 * Factory desde env vars estándar:
 *   AUTH_SERVICE_URL / AUTH_URL — default https://auth.zentto.net
 *   AUTH_SERVICE_KEY — para llamadas admin (backend)
 *
 * Para user-facing, construí manualmente con `new AuthClient({ accessToken })`.
 */
export function authFromEnv(overrides?: Partial<AuthConfig>): AuthClient {
  return new AuthClient({
    baseUrl: process.env.AUTH_SERVICE_URL ?? process.env.AUTH_URL,
    serviceKey: process.env.AUTH_SERVICE_KEY,
    ...overrides,
  });
}
