// Auth — Token en cookie HttpOnly (NO en localStorage, NO en JavaScript)
// El browser envia la cookie automaticamente con credentials: 'include'

const USER_KEY = 'zentto-panel-user';
const API_BASE = process.env.NEXT_PUBLIC_SITES_API || 'https://sitesdev.zentto.net';

export function getUser(): any | null {
  if (typeof window === 'undefined') return null;
  try { return JSON.parse(sessionStorage.getItem(USER_KEY) || 'null'); } catch { return null; }
}

export function setUser(user: any): void {
  if (typeof window !== 'undefined') {
    sessionStorage.setItem(USER_KEY, JSON.stringify(user));
  }
}

export async function logout(): Promise<void> {
  try {
    await fetch(`${API_BASE}/auth/logout`, { method: 'POST', credentials: 'include' });
  } catch { /* ignore */ }
  if (typeof window !== 'undefined') {
    sessionStorage.removeItem(USER_KEY);
    window.location.href = '/login';
  }
}

export async function checkAuth(): Promise<boolean> {
  try {
    const res = await fetch(`${API_BASE}/auth/me`, { credentials: 'include' });
    if (res.ok) {
      const data = await res.json();
      if (data.ok && data.data) {
        setUser(data.data);
        return true;
      }
    }
    return false;
  } catch {
    return false;
  }
}

export function isAuthenticated(): boolean {
  return !!getUser();
}
