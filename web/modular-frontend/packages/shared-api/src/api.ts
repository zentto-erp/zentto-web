'use client';

import { getSession } from 'next-auth/react';
import { signOut } from 'next-auth/react';

const RAW_API_BASE = process.env.NEXT_PUBLIC_API_URL || process.env.NEXT_PUBLIC_API_BASE || "http://localhost:4000";
export const API_BASE = RAW_API_BASE.replace(/\/+$/, '');

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
    const session = await getSession();
    // @ts-ignore
    return session?.accessToken || null;
  } catch { return null; }
}

async function authHeader(): Promise<Record<string, string>> {
  try {
    const session = await getSession();
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
  if (res.status !== 401) return;
  try {
    await signOut({ callbackUrl: '/authentication/login' });
  } catch {
    // noop
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
