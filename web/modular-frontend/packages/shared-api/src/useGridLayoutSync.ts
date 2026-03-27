'use client';

import { useEffect, useRef, useState } from 'react';

const STORAGE_PREFIX = 'zentto-grid-layout:';
const DEFAULT_SYNC_INTERVAL_MS = 1500;
const DEFAULT_DEBOUNCE_MS = 2000;
const MAX_LAYOUT_SIZE_BYTES = 50 * 1024;
const DEFAULT_CACHE_URL = 'https://cache.zentto.net';

export interface GridLayoutSnapshot {
  updatedAt?: string;
  [key: string]: unknown;
}

interface GridLayoutIdentity {
  companyId: string;
  email?: string;
  userId?: string;
}

interface GridLayoutResponse {
  layout?: GridLayoutSnapshot | null;
  ok?: boolean;
}

interface UseGridLayoutSyncOptions {
  debounceMs?: number;
  enabled?: boolean;
  syncIntervalMs?: number;
}

export interface UseGridLayoutSyncResult {
  ready: boolean;
  remoteEnabled: boolean;
}

function normalizeBaseUrl(value?: string | null): string {
  return (value || '').trim().replace(/\/+$/, '');
}

function buildStorageKey(gridId: string): string {
  return `${STORAGE_PREFIX}${gridId}`;
}

function readLocalLayout(gridId: string): GridLayoutSnapshot | null {
  if (typeof window === 'undefined') return null;

  try {
    const raw = window.localStorage.getItem(buildStorageKey(gridId));
    if (!raw) return null;
    return JSON.parse(raw) as GridLayoutSnapshot;
  } catch {
    return null;
  }
}

function writeLocalLayout(gridId: string, layout: GridLayoutSnapshot | null): void {
  if (typeof window === 'undefined') return;

  try {
    const storageKey = buildStorageKey(gridId);
    if (!layout) {
      window.localStorage.removeItem(storageKey);
      return;
    }

    window.localStorage.setItem(storageKey, JSON.stringify(layout));
  } catch {
    // noop
  }
}

function serializeLayout(layout: GridLayoutSnapshot | null): string {
  if (!layout) return '';

  try {
    return JSON.stringify(layout);
  } catch {
    return '';
  }
}

async function fetchSessionIdentity(): Promise<GridLayoutIdentity | null> {
  if (typeof window === 'undefined') return null;

  try {
    const response = await fetch(`${window.location.origin}/api/auth/session`, {
      cache: 'no-store',
      credentials: 'include',
      headers: { Accept: 'application/json' },
    });

    if (!response.ok) return null;

    const session = await response.json();
    const activeCompany = session?.company;
    const companyAccesses = Array.isArray(session?.companyAccesses) ? session.companyAccesses : [];
    const companyId = activeCompany?.companyId ?? companyAccesses[0]?.companyId;
    const userId = session?.userId ? String(session.userId) : undefined;
    const email = typeof session?.user?.email === 'string' ? session.user.email : undefined;

    if (!companyId || (!userId && !email)) return null;

    return {
      companyId: String(companyId),
      email,
      userId,
    };
  } catch {
    return null;
  }
}

function buildRemoteHeaders(): HeadersInit {
  const appKey = (process.env.NEXT_PUBLIC_CACHE_APP_KEY || '').trim();
  return appKey ? { 'x-app-key': appKey } : {};
}

async function fetchRemoteLayout(
  baseUrl: string,
  gridId: string,
  identity: GridLayoutIdentity,
): Promise<GridLayoutSnapshot | null> {
  const query = new URLSearchParams({ companyId: identity.companyId });
  if (identity.userId) query.set('userId', identity.userId);
  if (identity.email) query.set('email', identity.email);

  const response = await fetch(`${baseUrl}/v1/grid-layouts/${encodeURIComponent(gridId)}?${query.toString()}`, {
    cache: 'no-store',
    headers: {
      Accept: 'application/json',
      ...buildRemoteHeaders(),
    },
  });

  if (response.status === 404) return null;
  if (!response.ok) throw new Error(`Cache GET failed: ${response.status}`);

  const payload = (await response.json()) as GridLayoutResponse;
  return payload.layout ?? null;
}

async function pushRemoteLayout(
  baseUrl: string,
  gridId: string,
  identity: GridLayoutIdentity,
  layout: GridLayoutSnapshot | null,
): Promise<void> {
  if (!layout) return;

  const raw = serializeLayout(layout);
  if (!raw || raw.length > MAX_LAYOUT_SIZE_BYTES) return;

  const stampedLayout: GridLayoutSnapshot = layout.updatedAt
    ? layout
    : { ...layout, updatedAt: new Date().toISOString() };

  const response = await fetch(`${baseUrl}/v1/grid-layouts/${encodeURIComponent(gridId)}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      ...buildRemoteHeaders(),
    },
    body: JSON.stringify({
      companyId: identity.companyId,
      email: identity.email,
      gridId,
      layout: stampedLayout,
      userId: identity.userId,
    }),
  });

  if (!response.ok) {
    throw new Error(`Cache PUT failed: ${response.status}`);
  }

  if (!layout.updatedAt) {
    writeLocalLayout(gridId, stampedLayout);
  }
}

export function useGridLayoutSync(gridId: string, options: UseGridLayoutSyncOptions = {}): UseGridLayoutSyncResult {
  const baseUrl = normalizeBaseUrl(process.env.NEXT_PUBLIC_CACHE_URL || DEFAULT_CACHE_URL);
  const remoteEnabled = options.enabled ?? Boolean(baseUrl);
  const debounceMs = options.debounceMs ?? DEFAULT_DEBOUNCE_MS;
  const syncIntervalMs = options.syncIntervalMs ?? DEFAULT_SYNC_INTERVAL_MS;

  const [ready, setReady] = useState(!remoteEnabled);
  const identityRef = useRef<GridLayoutIdentity | null>(null);
  const lastSerializedRef = useRef('');
  const saveTimerRef = useRef<ReturnType<typeof window.setTimeout> | null>(null);

  useEffect(() => {
    if (!remoteEnabled || typeof window === 'undefined') {
      setReady(true);
      return;
    }

    let cancelled = false;
    let pollTimer: ReturnType<typeof window.setInterval> | null = null;

    const schedulePush = (layout: GridLayoutSnapshot | null) => {
      if (!identityRef.current || !layout) return;

      if (saveTimerRef.current !== null) {
        window.clearTimeout(saveTimerRef.current);
      }

      saveTimerRef.current = window.setTimeout(() => {
        pushRemoteLayout(baseUrl, gridId, identityRef.current!, layout).catch(() => {
          // Redis is a plus feature; the grid still works with defaults if sync fails.
        });
      }, debounceMs);
    };

    const syncFromLocalStorage = () => {
      const currentLayout = readLocalLayout(gridId);
      const serialized = serializeLayout(currentLayout);
      if (!serialized || serialized === lastSerializedRef.current) return;

      lastSerializedRef.current = serialized;
      schedulePush(currentLayout);
    };

    const boot = async () => {
      identityRef.current = await fetchSessionIdentity();

      let remoteLayout: GridLayoutSnapshot | null = null;
      if (identityRef.current) {
        try {
          remoteLayout = await fetchRemoteLayout(baseUrl, gridId, identityRef.current);
        } catch {
          remoteLayout = null;
        }
      }

      if (cancelled) return;

      if (remoteLayout) {
        writeLocalLayout(gridId, remoteLayout);
        lastSerializedRef.current = serializeLayout(remoteLayout);
      } else {
        writeLocalLayout(gridId, null);
        lastSerializedRef.current = '';
      }

      setReady(true);

      pollTimer = window.setInterval(syncFromLocalStorage, syncIntervalMs);
      window.addEventListener('visibilitychange', syncFromLocalStorage);
      window.addEventListener('beforeunload', syncFromLocalStorage);
    };

    boot().catch(() => {
      if (!cancelled) setReady(true);
    });

    return () => {
      cancelled = true;
      if (pollTimer !== null) {
        window.clearInterval(pollTimer);
      }
      if (saveTimerRef.current !== null) {
        window.clearTimeout(saveTimerRef.current);
        saveTimerRef.current = null;
      }
      window.removeEventListener('visibilitychange', syncFromLocalStorage);
      window.removeEventListener('beforeunload', syncFromLocalStorage);
    };
  }, [baseUrl, debounceMs, gridId, remoteEnabled, syncIntervalMs]);

  return { ready, remoteEnabled };
}
