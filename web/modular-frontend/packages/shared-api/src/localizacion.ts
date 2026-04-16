'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiGet, apiPost, apiPublicGet } from './api';
import type { LocalizacionConfig } from './usePosStore';

// ─── CountryRecord (mirrors cfg.Country table) ─────────────────────────────

export interface CountryRecord {
  CountryCode: string;
  CountryName: string;
  Iso3?: string;
  CurrencyCode: string;
  CurrencySymbol: string;
  ReferenceCurrency: string;
  ReferenceCurrencySymbol: string;
  DefaultExchangeRate: number;
  PricesIncludeTax: boolean;
  SpecialTaxRate: number;
  SpecialTaxEnabled: boolean;
  TaxAuthorityCode: string | null;
  FiscalIdName: string | null;
  TimeZoneIana: string | null;
  PhonePrefix: string | null;
  FlagEmoji?: string;
  SortOrder: number;
  IsActive: boolean;
}

// ─── Country Presets ────────────────────────────────────────────────────────
// DEPRECATED: La fuente de verdad es cfg.Country en BD.
// Mantener vacío para retrocompatibilidad con código legacy que lo importa.

export interface CountryPreset {
  code: string;
  name: string;
  defaults: Omit<LocalizacionConfig, 'pais'>;
}

/** @deprecated Usar useCountries() — la verdad viene de cfg.Country en BD. */
export const PREDEFINED_COUNTRIES: CountryPreset[] = [];

// ─── Hooks ──────────────────────────────────────────────────────────────────

/** Fetch active countries from cfg.Country via API. Público (sin auth). */
export function useCountries() {
  return useQuery<CountryRecord[]>({
    queryKey: ['config', 'countries'],
    queryFn: () => apiPublicGet('/v1/config/countries'),
    staleTime: 5 * 60 * 1000, // 5 min
  });
}

/** Mutation to create or update a country record. */
export function useSaveCountry() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (body: Partial<CountryRecord>) => apiPost('/v1/config/countries', body),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['config', 'countries'] });
    },
  });
}

// ─── States (cfg.State) ─────────────────────────────────────────────────────

export interface StateRecord {
  StateId: number;
  CountryCode: string;
  StateCode: string;
  StateName: string;
  SortOrder: number;
}

/** Fetch states/provinces for a given country code. */
export function useStates(countryCode: string | undefined) {
  return useQuery<StateRecord[]>({
    queryKey: ['config', 'states', countryCode],
    queryFn: () => apiGet(`/v1/config/states/${countryCode}`),
    enabled: !!countryCode,
    staleTime: 10 * 60 * 1000, // 10 min — reference data
  });
}

// ─── Lookups (cfg.Lookup) ───────────────────────────────────────────────────

export interface LookupRecord {
  LookupId: number;
  Code: string;
  Label: string;
  LabelEn: string | null;
  SortOrder: number;
  Extra: string | null;
}

/** Fetch lookup values by type code (e.g. 'PAYROLL_FREQUENCY'). */
export function useLookup(typeCode: string) {
  return useQuery<LookupRecord[]>({
    queryKey: ['config', 'lookups', typeCode],
    queryFn: () => apiGet(`/v1/config/lookups/${typeCode}`),
    staleTime: 10 * 60 * 1000,
  });
}

// ─── Helpers ────────────────────────────────────────────────────────────────

/**
 * Given a list of CountryRecord and a country code, return the localization
 * defaults for that country mapped to LocalizacionConfig shape.
 */
export function getCountryDefaults(
  countries: CountryRecord[],
  code: string,
): LocalizacionConfig | null {
  const c = countries.find((r) => r.CountryCode === code.toUpperCase());
  if (!c) return null;
  return {
    pais: c.CountryCode,
    preciosIncluyenIva: c.PricesIncludeTax,
    tasaCambio: c.DefaultExchangeRate,
    monedaPrincipal: c.CurrencySymbol,
    monedaReferencia: c.ReferenceCurrencySymbol,
    tasaIgtf: c.SpecialTaxRate,
    aplicarIgtf: c.SpecialTaxEnabled,
  };
}

// ─── BCV Rates ──────────────────────────────────────────────────────────────

export interface BcvRates {
  success?: boolean;
  USD?: number;
  EUR?: number;
  fechaInformativa?: string;
}

/** Fetch BCV exchange rates from the API (auth handled by apiGet). */
export async function fetchBcvRates(): Promise<BcvRates> {
  return apiGet('/v1/config/tasas');
}

// ─── Settings <-> LocalizacionConfig mappers ────────────────────────────────

/**
 * Map flat DB settings keys to the runtime LocalizacionConfig shape.
 * Los valores vienen 100% desde cfg.AppSetting (seedeado desde cfg.Country
 * al provisionar tenant). Sin hardcode de país/moneda/tasa.
 */
export function settingsToLocalizacion(
  settings: Record<string, unknown>,
): LocalizacionConfig {
  return {
    pais: String(settings['localizacion.pais'] ?? ''),
    preciosIncluyenIva: Boolean(settings['localizacion.preciosIncluyenIva'] ?? false),
    tasaCambio: Number(settings['localizacion.tasaCambio'] ?? 1),
    monedaPrincipal: String(settings['localizacion.monedaPrincipal'] ?? ''),
    monedaReferencia: String(settings['localizacion.monedaReferencia'] ?? ''),
    tasaIgtf: Number(settings['localizacion.tasaIgtf'] ?? 0),
    aplicarIgtf: Boolean(settings['localizacion.aplicarIgtf'] ?? false),
  };
}

/** Map runtime LocalizacionConfig back to flat DB settings keys. */
export function localizacionToSettings(
  loc: LocalizacionConfig,
): Record<string, unknown> {
  return {
    'localizacion.pais': loc.pais,
    'localizacion.preciosIncluyenIva': loc.preciosIncluyenIva,
    'localizacion.tasaCambio': loc.tasaCambio,
    'localizacion.monedaPrincipal': loc.monedaPrincipal,
    'localizacion.monedaReferencia': loc.monedaReferencia,
    'localizacion.tasaIgtf': loc.tasaIgtf,
    'localizacion.aplicarIgtf': loc.aplicarIgtf,
  };
}
