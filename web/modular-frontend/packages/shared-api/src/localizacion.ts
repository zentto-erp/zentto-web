'use client';

import { apiGet } from './api';
import type { LocalizacionConfig } from './usePosStore';

// ─── Country Presets ────────────────────────────────────────────────────────

export interface CountryPreset {
  code: string;
  name: string;
  defaults: Omit<LocalizacionConfig, 'pais'>;
}

export const PREDEFINED_COUNTRIES: CountryPreset[] = [
  { code: 'VE', name: 'Venezuela', defaults: { preciosIncluyenIva: true, tasaCambio: 45.0, monedaPrincipal: 'Bs', monedaReferencia: '$', tasaIgtf: 3, aplicarIgtf: true } },
  { code: 'CO', name: 'Colombia', defaults: { preciosIncluyenIva: false, tasaCambio: 4000, monedaPrincipal: '$', monedaReferencia: 'USD', tasaIgtf: 0, aplicarIgtf: false } },
  { code: 'MX', name: 'México', defaults: { preciosIncluyenIva: false, tasaCambio: 18.0, monedaPrincipal: '$', monedaReferencia: 'USD', tasaIgtf: 0, aplicarIgtf: false } },
  { code: 'ES', name: 'España', defaults: { preciosIncluyenIva: true, tasaCambio: 1.0, monedaPrincipal: '€', monedaReferencia: '$', tasaIgtf: 0, aplicarIgtf: false } },
  { code: 'US', name: 'Estados Unidos', defaults: { preciosIncluyenIva: false, tasaCambio: 1.0, monedaPrincipal: '$', monedaReferencia: 'EUR', tasaIgtf: 0, aplicarIgtf: false } },
];

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
