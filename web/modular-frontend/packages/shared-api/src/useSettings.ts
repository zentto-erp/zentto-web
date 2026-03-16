'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiGet, apiPut } from './api';

// ─── Types ────────────────────────────────────────────────────────

export type SettingsModule =
  | 'general'
  | 'contabilidad'
  | 'nomina'
  | 'bancos'
  | 'inventario'
  | 'pos'
  | 'restaurante'
  | 'facturacion'
  | 'pagos';

/** All settings grouped by module */
export type AllSettings = Record<string, Record<string, unknown>>;

/** Full metadata entry returned when ?meta=true */
export interface SettingMeta {
  settingId: number;
  companyId: number;
  module: string;
  settingKey: string;
  settingValue: string;
  valueType: 'string' | 'number' | 'boolean' | 'json';
  description: string | null;
  isReadOnly: boolean;
  updatedAt: string;
}

const QK = 'app-settings';
const BASE = '/v1/settings';

// ─── Hooks ────────────────────────────────────────────────────────

/**
 * Get ALL settings for the company, grouped by module.
 * Returns: { general: { pais, ... }, contabilidad: { ... }, ... }
 */
export function useAllSettings(companyId = 1) {
  return useQuery<AllSettings>({
    queryKey: [QK, 'all', companyId],
    queryFn: () => apiGet(`${BASE}?companyId=${companyId}`),
    staleTime: 60_000,
  });
}

/**
 * Get settings for a single module.
 */
export function useModuleSettings(mod: SettingsModule, companyId = 1) {
  return useQuery<Record<string, unknown>>({
    queryKey: [QK, mod, companyId],
    queryFn: () => apiGet(`${BASE}/${mod}?companyId=${companyId}`),
    staleTime: 60_000,
  });
}

/**
 * Get settings with full metadata (for admin/debug panels).
 */
export function useModuleSettingsMeta(mod: SettingsModule, companyId = 1) {
  return useQuery<SettingMeta[]>({
    queryKey: [QK, mod, 'meta', companyId],
    queryFn: () => apiGet(`${BASE}/${mod}?companyId=${companyId}&meta=true`),
    staleTime: 60_000,
  });
}

/**
 * Save (UPSERT) settings for a module.
 * Accepts a flat object: { key1: value1, key2: value2, ... }
 */
export function useSaveModuleSettings(mod: SettingsModule, companyId = 1) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (settings: Record<string, unknown>) =>
      apiPut(`${BASE}/${mod}?companyId=${companyId}`, settings),
    onSuccess: () => {
      // Invalidate both the module-specific and the all-settings queries
      qc.invalidateQueries({ queryKey: [QK, mod, companyId] });
      qc.invalidateQueries({ queryKey: [QK, 'all', companyId] });
    },
  });
}

/**
 * List of module names that have settings.
 */
export function useSettingModules(companyId = 1) {
  return useQuery<string[]>({
    queryKey: [QK, 'modules', companyId],
    queryFn: () => apiGet(`${BASE}/modules?companyId=${companyId}`),
    staleTime: 300_000,
  });
}
