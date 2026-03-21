'use client';

import { getSession } from 'next-auth/react';
import { signOut } from 'next-auth/react';

const RAW_API_BASE = process.env.NEXT_PUBLIC_API_URL || process.env.NEXT_PUBLIC_API_BASE || "http://localhost:4000";
export const API_BASE = RAW_API_BASE.replace(/\/+$/, '');

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
    // @ts-ignore
    const token = session?.accessToken as string | undefined;
    if (token) {
      headers.Authorization = `Bearer ${token}`;
    }

    // @ts-ignore
    const activeCompany = session?.company as { companyId?: number; branchId?: number } | undefined;
    // @ts-ignore
    const accesses = (session?.companyAccesses as Array<{ companyId?: number; branchId?: number }> | undefined) ?? [];

    const companyId = Number(activeCompany?.companyId ?? accesses[0]?.companyId);
    const branchId = Number(activeCompany?.branchId ?? accesses[0]?.branchId);

    if (Number.isFinite(companyId) && companyId > 0) {
      headers['x-company-id'] = String(companyId);
    }
    if (Number.isFinite(branchId) && branchId > 0) {
      headers['x-branch-id'] = String(branchId);
    }

    // @ts-ignore
    const timezone = activeCompany?.timeZone as string | undefined;
    // @ts-ignore
    const countryCode = activeCompany?.countryCode as string | undefined;
    if (timezone) {
      headers['x-timezone'] = timezone;
    }
    if (countryCode) {
      headers['x-country-code'] = countryCode;
    }

    return headers;
  } catch {
    const token = await getAuthToken();
    return token ? { Authorization: `Bearer ${token}` } : {};
  }
}

async function handleUnauthorized(res: Response) {
  if (res.status === 401) {
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

export async function apiGet(path: string, params?: Record<string, unknown>) {
  let fullUrl = `${API_BASE}${path}`;
  if (params) {
    const query = Object.entries(params)
      .filter(([, v]) => v !== undefined && v !== null && v !== '')
      .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(String(v))}`)
      .join('&');
    if (query) fullUrl += `?${query}`;
  }
  const res = await fetch(fullUrl, { headers: await authHeader(), credentials: 'include' });
  await handleUnauthorized(res);
  const responseData = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(responseData?.message || responseData?.error || res.statusText);
  return responseData;
}

export async function apiPost(path: string, body: unknown) {
  const fullUrl = `${API_BASE}${path}`;
  const res = await fetch(fullUrl, {
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
  const res = await fetch(fullUrl, {
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
  const res = await fetch(fullUrl, {
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
  const res = await fetch(fullUrl, { method: "DELETE", headers: await authHeader(), credentials: 'include' });
  await handleUnauthorized(res);
  const responseData = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(responseData?.message || responseData?.error || res.statusText);
  return responseData;
}
