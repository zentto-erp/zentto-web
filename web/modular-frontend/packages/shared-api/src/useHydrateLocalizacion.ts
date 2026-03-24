'use client';

import { useEffect, useRef, useState } from 'react';
import { useModuleSettings } from './useSettings';
import { usePosStore } from './usePosStore';
import { settingsToLocalizacion } from './localizacion';
import { apiGet } from './api';
import type { SettingsModule } from './useSettings';

/**
 * Hydrates `usePosStore.localizacion` from DB settings on mount,
 * then auto-fetches the latest BCV exchange rate and updates tasaCambio.
 *
 * @param mod  Settings module whose keys contain `localizacion.*`
 * @param companyId  Company id (defaults to 1)
 */
export function useHydrateLocalizacion(mod: SettingsModule, companyId = 1) {
  const { data, isLoading, error } = useModuleSettings(mod, companyId);
  const setLocalizacion = usePosStore((s) => s.setLocalizacion);
  const [isHydrated, setIsHydrated] = useState(false);
  const bcvFetched = useRef(false);

  // 1. Hydrate from DB settings
  useEffect(() => {
    if (!data || isLoading || error || isHydrated) return;

    const pais = data['localizacion.pais'];
    if (pais !== undefined && pais !== null) {
      setLocalizacion(settingsToLocalizacion(data));
      setIsHydrated(true);
    }
  }, [data, isLoading, error, setLocalizacion, isHydrated]);

  // 2. Auto-fetch BCV rate after hydration (always, on every load)
  useEffect(() => {
    if (!isHydrated || bcvFetched.current) return;
    bcvFetched.current = true;

    (async () => {
      try {
        const tasas = await apiGet('/v1/config/tasas') as {
          success?: boolean;
          USD?: number;
          EUR?: number;
          origen?: string;
        };

        const loc = usePosStore.getState().localizacion;
        const ref = (loc.monedaReferencia || '').trim().toUpperCase();
        let rate = 0;

        if (ref === '$' || ref.includes('USD')) rate = Number(tasas?.USD ?? 0);
        else if (ref === '€' || ref.includes('EUR')) rate = Number(tasas?.EUR ?? 0);

        if (Number.isFinite(rate) && rate > 0) {
          setLocalizacion({ tasaCambio: rate });
          console.log(`[POS] Tasa BCV cargada: ${rate} (${tasas?.origen})`);
        }
      } catch (e) {
        console.warn('[POS] No se pudo obtener tasa BCV al iniciar:', e);
      }
    })();
  }, [isHydrated, setLocalizacion]);

  // Reset flags when company changes
  useEffect(() => {
    setIsHydrated(false);
    bcvFetched.current = false;
  }, [companyId]);

  return { isLoading, error, hydrated: isHydrated };
}
