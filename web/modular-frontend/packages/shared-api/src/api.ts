'use client';

import { getSession } from 'next-auth/react';
import { signOut } from 'next-auth/react';

const API_BASE = process.env.NEXT_PUBLIC_API_URL || process.env.NEXT_PUBLIC_API_BASE || "http://localhost:4000";

async function getAuthToken(): Promise<string | null> {
  try {
    const session = await getSession();
    // @ts-ignore
    return session?.accessToken || null;
  } catch { return null; }
}

async function authHeader(): Promise<Record<string, string>> {
  const token = await getAuthToken();
  if (token) return { 'Authorization': `Bearer ${token}` };
  return {};
}

async function handleUnauthorized(res: Response) {
  if (res.status !== 401) return;
  try {
    await signOut({ callbackUrl: '/authentication/login' });
  } catch {
    // noop
  }
}

export async function apiGet(path: string, params?: Record<string, any>) {
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

export async function apiDelete(path: string) {
  const fullUrl = `${API_BASE}${path}`;
  const res = await fetch(fullUrl, { method: "DELETE", headers: await authHeader(), credentials: 'include' });
  await handleUnauthorized(res);
  const responseData = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(responseData?.message || responseData?.error || res.statusText);
  return responseData;
}
