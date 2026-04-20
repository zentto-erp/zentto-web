import type { ActiveCompany } from "../types";

/**
 * localStorage helpers para la empresa activa.
 *
 * Clave: `zentto-active-company:{userId}` — MISMA key que packages/shared-auth
 * para que el ERP y las apps verticales se sincronicen cross-app cuando
 * comparten dominio (`.zentto.net`).
 */
const KEY = (userId: string) => `zentto-active-company:${userId}`;

function hasWindow(): boolean {
  return typeof window !== "undefined";
}

export function getActiveCompany(userId: string): ActiveCompany | null {
  if (!hasWindow()) return null;
  try {
    const raw = window.localStorage.getItem(KEY(userId));
    if (!raw) return null;
    const parsed = JSON.parse(raw) as ActiveCompany;
    if (parsed && typeof parsed.companyId === "number" && parsed.companyId > 0) {
      return parsed;
    }
  } catch {
    /* ignore parse error */
  }
  return null;
}

export function setActiveCompany(userId: string, company: ActiveCompany): void {
  if (!hasWindow()) return;
  const serialized = JSON.stringify(company);
  const key = KEY(userId);
  window.localStorage.setItem(key, serialized);
  // Dispatch StorageEvent manualmente para pestañas dentro del mismo window.
  // Los storage events nativos solo se disparan en OTRAS pestañas.
  try {
    window.dispatchEvent(
      new StorageEvent("storage", {
        key,
        newValue: serialized,
        storageArea: window.localStorage,
      }),
    );
  } catch {
    /* StorageEvent constructor may not exist in older browsers */
  }
}

export function clearActiveCompany(userId: string): void {
  if (!hasWindow()) return;
  const key = KEY(userId);
  window.localStorage.removeItem(key);
  try {
    window.dispatchEvent(
      new StorageEvent("storage", {
        key,
        newValue: null,
        storageArea: window.localStorage,
      }),
    );
  } catch {
    /* ignore */
  }
}

export function subscribeActiveCompany(
  userId: string,
  cb: (company: ActiveCompany | null) => void,
): () => void {
  if (!hasWindow()) return () => undefined;
  const key = KEY(userId);
  const handler = (event: StorageEvent) => {
    if (event.key !== key) return;
    if (!event.newValue) {
      cb(null);
      return;
    }
    try {
      const parsed = JSON.parse(event.newValue) as ActiveCompany;
      cb(parsed);
    } catch {
      /* ignore */
    }
  };
  window.addEventListener("storage", handler);
  return () => window.removeEventListener("storage", handler);
}
