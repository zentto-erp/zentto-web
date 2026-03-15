'use client';

import { useEffect, useRef } from 'react';
import { useModuleSettings } from './useSettings';
import { usePosStore } from './usePosStore';
import { settingsToLocalizacion } from './localizacion';
import type { SettingsModule } from './useSettings';

/**
 * Hydrates `usePosStore.localizacion` from DB settings on mount.
 * Call this once in the root layout of POS / Restaurante apps.
 *
 * @param mod  Settings module whose keys contain `localizacion.*`
 * @param companyId  Company id (defaults to 1)
 */
export function useHydrateLocalizacion(mod: SettingsModule, companyId = 1) {
  const { data, isLoading, error } = useModuleSettings(mod, companyId);
  const setLocalizacion = usePosStore((s) => s.setLocalizacion);
  const hydrated = useRef(false);

  useEffect(() => {
    if (!data || isLoading || error || hydrated.current) return;

    // Only hydrate if the DB actually has localizacion data
    const pais = data['localizacion.pais'];
    if (pais !== undefined && pais !== null) {
      setLocalizacion(settingsToLocalizacion(data));
      hydrated.current = true;
    }
  }, [data, isLoading, error, setLocalizacion]);

  // Reset hydrated flag when company changes
  useEffect(() => {
    hydrated.current = false;
  }, [companyId]);

  return { isLoading, error, hydrated: hydrated.current };
}
