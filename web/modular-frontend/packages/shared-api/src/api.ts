'use client';

import { getSession } from 'next-auth/react';
import { signOut } from 'next-auth/react';
import { createAuthClient } from '@zentto/auth-client';

const RAW_API_BASE = process.env.NEXT_PUBLIC_API_URL || process.env.NEXT_PUBLIC_API_BASE || "http://localhost:4000";
export const API_BASE = RAW_API_BASE.replace(/\/+$/, '');

// Sprint 1 #2 — fetchWithRefresh wireado.
//
// Cliente del SDK @zentto/auth-client@^0.3.0. Usado por todas las funciones
// apiGet/apiPost/apiPut/apiPatch/apiDelete: cuando una request responde 401,
// llama automáticamente a /auth/refresh (de-duplicado entre requests
// concurrentes) y reintenta UNA vez.
//
// Si el refresh falla, dispara onRefreshFailed → forzamos signOut.
// Si el refresh sucede, dispara onRefreshed → re-seteamos zentto_token cookie
// vía /api/auth/set-token (igual que el flujo post-login del shell).
const AUTH_BASE_URL =
  process.env.NEXT_PUBLIC_AUTH_URL ||
  process.env.NEXT_PUBLIC_AUTH_SERVICE_URL ||
  'https://auth.zentto.net';

const authClient = createAuthClient({
  baseUrl: AUTH_BASE_URL,
  appId: 'zentto-erp',
});

async function reSetTokenCookie(): Promise<void> {
  // El shell expone POST /api/auth/set-token que lee el accessToken de su
  // store server-side (renovado por el refresh) y lo setea como cookie
  // zentto_token HttpOnly. Sin esta llamada, el refresh deja /auth/refresh
  // con cookies actualizadas pero nuestra cookie zentto_token sigue stale.
  if (typeof window === 'undefined') return;
  try {
    await fetch(`${window.location.origin}/api/auth/set-token`, {
      method: 'POST',
      credentials: 'include',
      cache: 'no-store',
    });
  } catch {
    // best-effort
  }
}

// Rutas públicas donde NO se debe forzar signOut al fallar un refresh de token.
// En estas rutas el usuario no tiene sesión — disparar signOut causaría un
// redirect al login que impide completar el flujo (ej. registro de nuevas cuentas).
const PUBLIC_CLIENT_ROUTES = ['/registro', '/authentication/', '/pricing'];

async function forceSignOut(): Promise<void> {
  if (typeof window === 'undefined') return;
  const path = window.location.pathname;
  if (PUBLIC_CLIENT_ROUTES.some((r) => path.startsWith(r))) return;
  try {
    const loginUrl = `${window.location.origin}/authentication/login`;
    await signOut({ callbackUrl: loginUrl });
  } catch {
    // noop
  }
}

function fetchWithRefresh(input: string | URL | Request, init?: RequestInit): Promise<Response> {
  return authClient.fetchWithRefresh(input, init, {
    onRefreshed: reSetTokenCookie,
    onRefreshFailed: forceSignOut,
  });
}

// Active company override — set by AuthContext, used by authHeader()
let _activeCompanyOverride: {
  companyId?: number;
  branchId?: number;
  timeZone?: string;
  countryCode?: string;
} | null = null;

export function setActiveCompanyForApi(company: {
  companyId?: number;
  branchId?: number;
  timeZone?: string;
  countryCode?: string;
} | null) {
  _activeCompanyOverride = company;
}

// La auth siempre la gestiona el shell en /api/auth.
// No usar prefijo de app: compras/bancos van al shell (puerto 3000) vía nginx,
// el shell no tiene /compras/api/auth. Sub-apps con nginx propio proxean al shell.
async function fetchSessionFromCurrentApp() {
  if (typeof window === 'undefined') {
    return getSession();
  }
  // Siempre llamar al shell directamente en /api/auth/session
  const response = await fetch(`${window.location.origin}/api/auth/session`, {
    credentials: 'include',
    headers: { Accept: 'application/json' },
    cache: 'no-store',
  });
  if (!response.ok) return null;
  return response.json();
}

export function resolveAssetUrl(url?: unknown): string | undefined {
  if (typeof url !== 'string') return undefined;
  const value = url.trim();
  if (!value) return undefined;
  if (value.startsWith('data:')) return value;
  if (/^https?:\/\//i.test(value)) return value;
  if (value.startsWith('//')) return `https:${value}`;
  if (value.startsWith('/')) return `${API_BASE}${value}`;
  return `${API_BASE}/${value.replace(/^\.?\//, '')}`;
}

async function getAuthToken(): Promise<string | null> {
  try {
    const session = await fetchSessionFromCurrentApp();
    // @ts-ignore
    return session?.accessToken || null;
  } catch { return null; }
}

async function authHeader(): Promise<Record<string, string>> {
  try {
    const session = await fetchSessionFromCurrentApp();
    const headers: Record<string, string> = {};
    // JWT viaja en cookie HttpOnly zentto_token (credentials: 'include').
    // Cookie seteada por /api/auth/set-token después del login.
    // NO enviar Authorization: Bearer — 100% cookies.

    // Prioridad: override de AuthContext > localStorage > session.company > primer acceso
    // @ts-ignore
    const sessionCompany = session?.company as { companyId?: number; branchId?: number; timeZone?: string; countryCode?: string } | undefined;
    // @ts-ignore
    const accesses = (session?.companyAccesses as Array<{ companyId?: number; branchId?: number; timeZone?: string; countryCode?: string }> | undefined) ?? [];

    let activeCompany = _activeCompanyOverride ?? null;
    if (!activeCompany && typeof window !== 'undefined') {
      try {
        const userId = session?.user?.id ?? (session as any)?.userId;
        const stored = localStorage.getItem(`zentto-active-company:${userId ?? 'anon'}`);
        if (stored) {
          const { companyId: storedCid, branchId: storedBid } = JSON.parse(stored);
          const match = accesses.find((a) => a.companyId === storedCid && a.branchId === storedBid);
          if (match) activeCompany = match;
        }
      } catch { /* ignore */ }
    }
    if (!activeCompany) activeCompany = sessionCompany ?? null;

    const companyId = Number(activeCompany?.companyId ?? accesses[0]?.companyId);
    const branchId = Number(activeCompany?.branchId ?? accesses[0]?.branchId);

    if (Number.isFinite(companyId) && companyId > 0) {
      headers['x-company-id'] = String(companyId);
    }
    if (Number.isFinite(branchId) && branchId > 0) {
      headers['x-branch-id'] = String(branchId);
    }

    const timezone = activeCompany?.timeZone as string | undefined;
    const countryCode = activeCompany?.countryCode as string | undefined;
    if (timezone) {
      headers['x-timezone'] = timezone;
    }
    if (countryCode) {
      headers['x-country-code'] = countryCode;
    }

    // Multi-tenant: si estamos en un subdomain de tenant, forzar su CompanyId
    if (typeof window !== 'undefined') {
      const tenantData = localStorage.getItem('zentto-tenant');
      if (tenantData) {
        try {
          const { companyId } = JSON.parse(tenantData);
          if (companyId) headers['x-company-id'] = String(companyId);
        } catch { /* ignore parse errors */ }
      } else {
        // Demo mode header: solo si NO estamos en un subdomain de tenant
        const dbMode = localStorage.getItem('zentto-db-mode');
        if (dbMode === 'demo') {
          headers['x-db-mode'] = 'demo';
        }
      }
    }

    return headers;
  } catch {
    // Cookie HttpOnly viaja automáticamente via credentials: 'include'.
    return {};
  }
}

async function handleUnauthorized(res: Response) {
  if (res.status === 401) {
    if (typeof window !== 'undefined') {
      const path = window.location.pathname;
      if (PUBLIC_CLIENT_ROUTES.some((r) => path.startsWith(r))) return;
    }
    try {
      const loginUrl = typeof window !== 'undefined'
        ? `${window.location.origin}/authentication/login`
        : '/authentication/login';
      await signOut({ callbackUrl: loginUrl });
    } catch {
      // noop
    }
    return;
  }
  // Suscripción vencida → redirigir a página de renovación
  if (res.status === 403) {
    try {
      const data = await res.clone().json();
      if (data?.error === 'subscription_required') {
        if (typeof window !== 'undefined' && !window.location.pathname.includes('subscription-expired')) {
          window.location.href = '/subscription-expired';
        }
      }
    } catch {
      // noop
    }
  }
}

// ─── Public API helpers (sin auth, sin fetchWithRefresh) ────────────────────
// Para endpoints públicos como /v1/catalog/* y /v1/registro/* que NO requieren
// sesión. Usan fetch nativo — nunca disparan forceSignOut.

export async function apiPublicGet(path: string, params?: Record<string, unknown>) {
  let fullUrl = `${API_BASE}${path}`;
  if (params) {
    const query = Object.entries(params)
      .filter(([, v]) => v !== undefined && v !== null && v !== '')
      .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(String(v))}`)
      .join('&');
    if (query) fullUrl += `?${query}`;
  }
  const res = await fetch(fullUrl);
  const responseData = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(responseData?.message || responseData?.error || res.statusText);
  return responseData;
}

export async function apiPublicPost(path: string, body: unknown) {
  const fullUrl = `${API_BASE}${path}`;
  const res = await fetch(fullUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const responseData = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(responseData?.message || responseData?.error || res.statusText);
  return responseData;
}

export async function apiGet(path: string, params?: Record<string, unknown>) {
  let fullUrl = `${API_BASE}${path}`;
  if (params) {
    const query = Object.entries(params)
      .filter(([, v]) => v !== undefined && v !== null && v !== '')
      .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(String(v))}`)
      .join('&');
    if (query) fullUrl += `?${query}`;
  }
  const res = await fetchWithRefresh(fullUrl, { headers: await authHeader(), credentials: 'include' });
  await handleUnauthorized(res);
  const responseData = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(responseData?.message || responseData?.error || res.statusText);
  return responseData;
}

export async function apiPost(path: string, body: unknown) {
  const fullUrl = `${API_BASE}${path}`;
  const res = await fetchWithRefresh(fullUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json", ...(await authHeader()) },
    credentials: 'include',
    body: JSON.stringify(body),
  });
  await handleUnauthorized(res);
  const responseData = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(responseData?.message || responseData?.error || res.statusText);
  return responseData;
}

export async function apiPut(path: string, body: unknown) {
  const fullUrl = `${API_BASE}${path}`;
  const res = await fetchWithRefresh(fullUrl, {
    method: "PUT",
    headers: { "Content-Type": "application/json", ...(await authHeader()) },
    credentials: 'include',
    body: JSON.stringify(body),
  });
  await handleUnauthorized(res);
  const responseData = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(responseData?.message || responseData?.error || res.statusText);
  return responseData;
}

export async function apiPatch(path: string, body: unknown) {
  const fullUrl = `${API_BASE}${path}`;
  const res = await fetchWithRefresh(fullUrl, {
    method: "PATCH",
    headers: { "Content-Type": "application/json", ...(await authHeader()) },
    credentials: 'include',
    body: JSON.stringify(body),
  });
  await handleUnauthorized(res);
  const responseData = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(responseData?.message || responseData?.error || res.statusText);
  return responseData;
}

export async function apiDelete(path: string) {
  const fullUrl = `${API_BASE}${path}`;
  const res = await fetchWithRefresh(fullUrl, { method: "DELETE", headers: await authHeader(), credentials: 'include' });
  await handleUnauthorized(res);
  const responseData = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(responseData?.message || responseData?.error || res.statusText);
  return responseData;
}

// ═══════════════════════════════════════════════════════════════
// IAM (Identity & Access Management) — proxy a zentto-auth /admin
// ═══════════════════════════════════════════════════════════════
//
// Estos wrappers apuntan al proxy local /api/iam/* del shell, que
// reenvia las requests al microservicio zentto-auth (puerto interno
// 4600, NO expuesto publicamente). El path en zentto-auth es
// /admin/<path>, asi que iamGet('users') → /api/iam/users → zentto-auth /admin/users.
//
// La cookie httponly del usuario viaja al shell automaticamente
// (mismo dominio) y el route handler la reenvia a zentto-auth.

function iamUrl(path: string): string {
  // Quitar / inicial si lo trae para que el join sea limpio
  const clean = path.replace(/^\/+/, '');
  return `/api/iam/${clean}`;
}

export async function iamGet(path: string, params?: Record<string, unknown>) {
  let fullUrl = iamUrl(path);
  if (params) {
    const query = Object.entries(params)
      .filter(([, v]) => v !== undefined && v !== null && v !== '')
      .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(String(v))}`)
      .join('&');
    if (query) fullUrl += `?${query}`;
  }
  const res = await fetch(fullUrl, { credentials: 'include' });
  await handleUnauthorized(res);
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data?.error || data?.message || res.statusText);
  return data;
}

export async function iamPost(path: string, body: unknown) {
  const res = await fetch(iamUrl(path), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    credentials: 'include',
    body: JSON.stringify(body),
  });
  await handleUnauthorized(res);
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data?.error || data?.message || res.statusText);
  return data;
}

export async function iamPut(path: string, body: unknown) {
  const res = await fetch(iamUrl(path), {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    credentials: 'include',
    body: JSON.stringify(body),
  });
  await handleUnauthorized(res);
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data?.error || data?.message || res.statusText);
  return data;
}

export async function iamDelete(path: string) {
  const res = await fetch(iamUrl(path), {
    method: 'DELETE',
    credentials: 'include',
  });
  await handleUnauthorized(res);
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data?.error || data?.message || res.statusText);
  return data;
}
