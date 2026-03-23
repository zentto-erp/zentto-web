'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiGet, apiPost } from './api';
import type { LocalizacionConfig } from './usePosStore';

// ─── CountryRecord (mirrors cfg.Country table) ─────────────────────────────

export interface CountryRecord {
  CountryCode: string;
  CountryName: string;
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
  SortOrder: number;
  IsActive: boolean;
}

// ─── Country Presets ────────────────────────────────────────────────────────

export interface CountryPreset {
  code: string;
  name: string;
  defaults: Omit<LocalizacionConfig, 'pais'>;
}

/**
 * @deprecated Use useCountries() hook instead. Kept as offline/fallback only.
 */
export const PREDEFINED_COUNTRIES: CountryPreset[] = [
  { code: 'VE', name: 'Venezuela', defaults: { preciosIncluyenIva: true, tasaCambio: 45.0, monedaPrincipal: 'Bs', monedaReferencia: '$', tasaIgtf: 3, aplicarIgtf: true } },
  { code: 'CO', name: 'Colombia', defaults: { preciosIncluyenIva: false, tasaCambio: 4000, monedaPrincipal: '$', monedaReferencia: 'USD', tasaIgtf: 0, aplicarIgtf: false } },
  { code: 'MX', name: 'Mexico', defaults: { preciosIncluyenIva: false, tasaCambio: 18.0, monedaPrincipal: '$', monedaReferencia: 'USD', tasaIgtf: 0, aplicarIgtf: false } },
  { code: 'ES', name: 'Espana', defaults: { preciosIncluyenIva: true, tasaCambio: 1.0, monedaPrincipal: '\u20ac', monedaReferencia: '$', tasaIgtf: 0, aplicarIgtf: false } },
  { code: 'US', name: 'Estados Unidos', defaults: { preciosIncluyenIva: false, tasaCambio: 1.0, monedaPrincipal: '$', monedaReferencia: 'EUR', tasaIgtf: 0, aplicarIgtf: false } },
];

// ─── Hooks ──────────────────────────────────────────────────────────────────

/** Fetch active countries from cfg.Country via API. */
export function useCountries() {
  return useQuery<CountryRecord[]>({
    queryKey: ['config', 'countries'],
    queryFn: () => apiGet('/v1/config/countries'),
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

/** Map flat DB settings keys to the runtime LocalizacionConfig shape. */
export function settingsToLocalizacion(
  settings: Record<string, unknown>,
): LocalizacionConfig {
  return {
    pais: String(settings['localizacion.pais'] ?? 'VE'),
    preciosIncluyenIva: Boolean(settings['localizacion.preciosIncluyenIva'] ?? true),
    tasaCambio: Number(settings['localizacion.tasaCambio'] ?? 1),
    monedaPrincipal: String(settings['localizacion.monedaPrincipal'] ?? 'Bs'),
    monedaReferencia: String(settings['localizacion.monedaReferencia'] ?? '$'),
    tasaIgtf: Number(settings['localizacion.tasaIgtf'] ?? 3),
    aplicarIgtf: Boolean(settings['localizacion.aplicarIgtf'] ?? true),
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
