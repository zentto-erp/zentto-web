'use client';

import { useEffect, useRef } from 'react';
import { useModuleSettings } from './useSettings';
import { usePosStore } from './usePosStore';
import { settingsToLocalizacion } from './localizacion';
import type { SettingsModule } from './useSettings';

/**
 * Pre-fetches 'general' settings AND module-specific settings into
 * the React Query cache on app boot. Also hydrates `usePosStore.localizacion`
 * from the general settings so that currency/tax helpers work everywhere.
 *
 * Call once in the root layout of each module app.
 *
 * @param mod       Module-specific settings key (e.g. 'nomina', 'contabilidad').
 *                  Pass `null` to only prefetch 'general'.
 * @param companyId Company id (defaults to 1)
 */
export function useHydrateModuleSettings(
  mod: SettingsModule | null,
  companyId = 1,
) {
  const general = useModuleSettings('general', companyId);
  const modResult = useModuleSettings(
    (mod ?? 'general') as SettingsModule,
    companyId,
  );

  const setLocalizacion = usePosStore((s) => s.setLocalizacion);
  const hydrated = useRef(false);

  // Hydrate localizacion from general settings (pais, moneda, tasa, etc.)
  useEffect(() => {
    if (!general.data || general.isLoading || general.error || hydrated.current) return;

    const pais = general.data['localizacion.pais'];
    if (pais !== undefined && pais !== null) {
      setLocalizacion(settingsToLocalizacion(general.data));
      hydrated.current = true;
    }
  }, [general.data, general.isLoading, general.error, setLocalizacion]);

  // Reset hydrated flag when company changes
  useEffect(() => {
    hydrated.current = false;
  }, [companyId]);

  return {
    isLoading: general.isLoading || modResult.isLoading,
    error: general.error || modResult.error,
    generalSettings: general.data,
    moduleSettings: modResult.data,
  };
}
