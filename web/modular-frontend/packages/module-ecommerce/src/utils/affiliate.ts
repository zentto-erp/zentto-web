/**
 * Utilidades de tracking de afiliados — cliente.
 *
 * Al cargar la app:
 *   1. Si la URL trae `?ref=CODE` o `?referral=CODE` → guarda cookie `zentto_ref` (30 días)
 *      y llama `POST /store/affiliate/track-click` con un session_id estable.
 *   2. El flow de checkout luego envía automáticamente la cookie al backend
 *      (el backend lee también `zentto_ref` por Cookie header).
 */

const API_BASE =
  typeof window !== "undefined"
    ? process.env.NEXT_PUBLIC_API_URL || "http://localhost:4000"
    : "http://localhost:4000";

export const REFERRAL_COOKIE = "zentto_ref";
export const SESSION_COOKIE = "zentto_sid";
const THIRTY_DAYS_MS = 30 * 24 * 60 * 60 * 1000;

function setCookie(name: string, value: string, maxAgeMs: number): void {
  if (typeof document === "undefined") return;
  const expires = new Date(Date.now() + maxAgeMs).toUTCString();
  const secure = typeof location !== "undefined" && location.protocol === "https:" ? "; Secure" : "";
  document.cookie = `${name}=${encodeURIComponent(value)}; path=/; expires=${expires}; SameSite=Lax${secure}`;
}

export function getCookie(name: string): string | null {
  if (typeof document === "undefined") return null;
  const prefix = `${name}=`;
  for (const part of document.cookie.split(";")) {
    const t = part.trim();
    if (t.startsWith(prefix)) {
      try { return decodeURIComponent(t.slice(prefix.length)); } catch { return t.slice(prefix.length); }
    }
  }
  return null;
}

/** Genera/obtiene un session_id estable para este navegador. */
export function ensureSessionId(): string {
  const existing = getCookie(SESSION_COOKIE);
  if (existing) return existing;
  const sid = (globalThis.crypto?.randomUUID?.() ?? `sid-${Math.random().toString(36).slice(2)}-${Date.now()}`);
  setCookie(SESSION_COOKIE, sid, 180 * 24 * 60 * 60 * 1000); // 180 días
  return sid;
}

export function getReferralCode(): string | null {
  return getCookie(REFERRAL_COOKIE);
}

export function setReferralCode(code: string): void {
  const safe = code.trim().slice(0, 20);
  if (!safe) return;
  setCookie(REFERRAL_COOKIE, safe, THIRTY_DAYS_MS);
}

/**
 * Hook idempotente de tracking: lee `?ref=` en URL, guarda cookie y reporta click.
 * Llamar una sola vez al montar la app (StoreLayout).
 */
export async function processReferralFromUrl(): Promise<void> {
  if (typeof window === "undefined") return;
  try {
    const params = new URLSearchParams(window.location.search);
    const code = params.get("ref") || params.get("referral");
    if (!code) return;
    setReferralCode(code);

    const sessionId = ensureSessionId();
    // Fire-and-forget
    fetch(`${API_BASE}/store/affiliate/track-click`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        referralCode: code,
        sessionId,
        referer: document.referrer || undefined,
      }),
    }).catch(() => { /* ignore */ });

    // Limpia el parámetro de la URL sin recargar (UX)
    params.delete("ref");
    params.delete("referral");
    const query = params.toString();
    const newUrl = window.location.pathname + (query ? "?" + query : "") + window.location.hash;
    window.history.replaceState({}, "", newUrl);
  } catch {
    /* ignore */
  }
}

/** Construye URL del referral link para compartir (`https://store/?ref=CODE`). */
export function buildReferralUrl(code: string): string {
  const base = (typeof window !== "undefined" ? window.location.origin : "https://zentto.net");
  return `${base}/?ref=${encodeURIComponent(code)}`;
}
