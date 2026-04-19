'use client';

import { useCallback, useEffect, useState } from 'react';
import { usePathname, useRouter, useSearchParams } from 'next/navigation';

/**
 * Hook para manejar drawers con deep-link en query string.
 *
 * Patrón "list → detail drawer" del design system (ver DESIGN.md §5.1).
 * La URL es la fuente de verdad: `?<key>=<id>` abre el drawer, `&tab=<name>`
 * selecciona tab. Reload, compartir URL, back/forward browser → todo funciona.
 *
 * @example
 * const { id, open, tab, openDrawer, closeDrawer, setTab } = useDrawerQueryParam('lead');
 * // URL: /leads?lead=42&tab=activity
 * // id === '42', open === true, tab === 'activity'
 */
export interface UseDrawerQueryParamOptions {
  /** Nombre del param opcional para tab activa. Default: 'tab'. */
  tabParamKey?: string;
}

export interface UseDrawerQueryParamResult {
  /** ID actual (string) si el drawer está abierto; null si no. */
  id: string | null;
  /** true si el drawer debe estar abierto. */
  open: boolean;
  /** Tab activa leída de la URL (`?tab=...`), o null. */
  tab: string | null;
  /** Abre drawer para `nextId`. Mantiene otros params. */
  openDrawer: (nextId: string | number, nextTab?: string) => void;
  /** Cierra drawer — remueve el key y `tab` de la URL. */
  closeDrawer: () => void;
  /** Cambia tab activa (sin cerrar drawer). */
  setTab: (nextTab: string | null) => void;
}

export function useDrawerQueryParam(
  key: string = 'id',
  options: UseDrawerQueryParamOptions = {},
): UseDrawerQueryParamResult {
  const { tabParamKey = 'tab' } = options;
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();

  // Estado interno espejo de la URL (útil para transiciones animadas).
  const urlId = searchParams?.get(key) ?? null;
  const urlTab = searchParams?.get(tabParamKey) ?? null;
  const [id, setId] = useState<string | null>(urlId);
  const [tab, setTabState] = useState<string | null>(urlTab);

  // Sync estado ← URL (back/forward, reload, cambio externo).
  useEffect(() => {
    setId(urlId);
    setTabState(urlTab);
  }, [urlId, urlTab]);

  const buildUrl = useCallback(
    (nextId: string | null, nextTab: string | null) => {
      const params = new URLSearchParams(searchParams?.toString() ?? '');
      if (nextId == null) {
        params.delete(key);
      } else {
        params.set(key, nextId);
      }
      if (nextTab == null) {
        params.delete(tabParamKey);
      } else {
        params.set(tabParamKey, nextTab);
      }
      const qs = params.toString();
      return qs ? `${pathname}?${qs}` : pathname;
    },
    [key, tabParamKey, pathname, searchParams],
  );

  const openDrawer = useCallback(
    (nextId: string | number, nextTab?: string) => {
      const idStr = String(nextId);
      setId(idStr);
      if (nextTab !== undefined) setTabState(nextTab);
      router.push(buildUrl(idStr, nextTab ?? tab), { scroll: false });
    },
    [buildUrl, router, tab],
  );

  const closeDrawer = useCallback(() => {
    setId(null);
    setTabState(null);
    router.push(buildUrl(null, null), { scroll: false });
  }, [buildUrl, router]);

  const setTab = useCallback(
    (nextTab: string | null) => {
      setTabState(nextTab);
      if (id != null) {
        router.push(buildUrl(id, nextTab), { scroll: false });
      }
    },
    [buildUrl, router, id],
  );

  return {
    id,
    open: id != null,
    tab,
    openDrawer,
    closeDrawer,
    setTab,
  };
}

export default useDrawerQueryParam;
