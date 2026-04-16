'use client';

import { useEffect, useRef } from 'react';
import { useModuleSettings } from './useSettings';
import { usePosStore } from './usePosStore';
import { settingsToLocalizacion } from './localizacion';
import { apiGet } from './api';
import type { SettingsModule } from './useSettings';

/**
 * Hydrates `usePosStore.localizacion` from DB settings on mount,
 * then auto-fetches the latest BCV exchange rate and updates tasaCambio.
 *
 * Re-hidrata automáticamente cuando los settings cambian (por ejemplo,
 * si otro tab guarda configuración y el BroadcastChannel invalida el cache).
 *
 * @param mod  Settings module whose keys contain `localizacion.*`
 * @param companyId  Company id (defaults to 1)
 */
export function useHydrateLocalizacion(mod: SettingsModule, companyId = 1) {
  const { data, isLoading, error } = useModuleSettings(mod, companyId);
  const setLocalizacion = usePosStore((s) => s.setLocalizacion);
  const bcvFetched = useRef(false);
  const lastDataRef = useRef<string>('');

  // 1. Hydrate from DB settings — siempre que los datos cambien.
  // No requiere localizacion.pais para hidratar — si hay cualquier key
  // de localizacion (tasaCambio, moneda, etc.), la aplicamos.
  useEffect(() => {
    if (!data || isLoading || error) return;

    // Verificar que hay al menos una key de localizacion
    const hasLocKeys = Object.keys(data).some((k) => k.startsWith('localizacion.'));
    if (!hasLocKeys) return;

    // Solo actualizar si los datos realmente cambiaron (evita loops)
    const dataHash = JSON.stringify(data);
    if (dataHash === lastDataRef.current) return;
    lastDataRef.current = dataHash;

    setLocalizacion(settingsToLocalizacion(data));
  }, [data, isLoading, error, setLocalizacion]);

  // 2. Auto-fetch BCV rate una vez al boot (no en cada cambio de settings)
  const hasLocData = Boolean(
    data && !isLoading && !error &&
    Object.keys(data).some((k) => k.startsWith('localizacion.'))
  );
  useEffect(() => {
    if (!hasLocData || bcvFetched.current) return;
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
  }, [hasLocData, setLocalizacion]);

  // Reset BCV flag when company changes
  useEffect(() => {
    bcvFetched.current = false;
    lastDataRef.current = '';
  }, [companyId]);

  return { isLoading, error, hydrated: hasLocData };
}
