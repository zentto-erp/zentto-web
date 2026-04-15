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
import { defaultHttpConfig, httpRequest, type HttpConfig, type HttpResult } from "../internal/http.js";

export interface AuthConfig {
  baseUrl?: string;
  /** Bearer JWT para llamadas user-facing. Opcional — algunos métodos no requieren. */
  accessToken?: string;
  /** Service key (`x-service-key`) para llamadas admin/provisioning. */
  serviceKey?: string;
  timeoutMs?: number;
  retries?: number;
  onError?: HttpConfig["onError"];
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

  constructor(opts: AuthConfig) {
    this.cfg = defaultHttpConfig({
      baseUrl: opts.baseUrl ?? "https://auth.zentto.net",
      timeoutMs: opts.timeoutMs,
      retries: opts.retries,
      onError: opts.onError,
    });
    this.accessToken = opts.accessToken;
    this.serviceKey = opts.serviceKey;
  }

  setAccessToken(token: string | undefined): void {
    this.accessToken = token;
  }

  private bearer(): Record<string, string> {
    return this.accessToken ? { Authorization: `Bearer ${this.accessToken}` } : {};
  }

  private service(): Record<string, string> {
    if (!this.serviceKey) throw new Error("AuthClient: serviceKey no configurada para este método");
    return { "x-service-key": this.serviceKey };
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
    return httpRequest<MeResponse>(this.cfg, {
      method: "GET",
      path: "/auth/me",
      query: { appId },
      headers: this.bearer(),
      credentials: "include",
    });
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
