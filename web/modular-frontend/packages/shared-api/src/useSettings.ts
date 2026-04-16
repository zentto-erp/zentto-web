'use client';

import { useEffect } from 'react';
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
  | 'pagos'
  | 'branding'
  | 'flota'
  | 'manufactura'
  | 'logistica';

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
const SETTINGS_CHANNEL = 'zentto-settings-sync';

// ─── Cross-tab sync via BroadcastChannel ─────────────────────────
// Cuando un tab guarda settings, notifica a los demás tabs del mismo
// dominio para que invaliden su cache de React Query y re-hidraten.

function broadcastSettingsChange(mod: string, companyId: number) {
  if (typeof window === 'undefined') return;
  try {
    const bc = new BroadcastChannel(SETTINGS_CHANNEL);
    bc.postMessage({ mod, companyId, ts: Date.now() });
    bc.close();
  } catch {
    // BroadcastChannel no soportado — silenciar
  }
}

/**
 * Hook que escucha cambios de settings desde otros tabs y los aplica
 * invalidando el cache de React Query. Llamar una vez en el layout
 * de cada app (ya integrado en useModuleSettings automáticamente).
 */
export function useSettingsSync() {
  const qc = useQueryClient();
  useEffect(() => {
    if (typeof window === 'undefined') return;
    try {
      const bc = new BroadcastChannel(SETTINGS_CHANNEL);
      bc.onmessage = (ev: MessageEvent) => {
        const { mod: changedMod, companyId: cid } = ev.data ?? {};
        if (changedMod) {
          qc.invalidateQueries({ queryKey: [QK, changedMod, cid] });
        }
        qc.invalidateQueries({ queryKey: [QK, 'all', cid] });
      };
      return () => bc.close();
    } catch {
      // BroadcastChannel no soportado
    }
  }, [qc]);
}

// ─── Hooks ────────────────────────────────────────────────────────

/**
 * Get ALL settings for the company, grouped by module.
 * Returns: { general: { pais, ... }, contabilidad: { ... }, ... }
 */
export function useAllSettings(companyId = 1) {
  useSettingsSync();
  return useQuery<AllSettings>({
    queryKey: [QK, 'all', companyId],
    queryFn: () => apiGet(`${BASE}?companyId=${companyId}`),
    staleTime: 60_000,
  });
}

/**
 * Get settings for a single module.
 */
export function useModuleSettings(mod: SettingsModule, companyId = 1, enabled = true) {
  useSettingsSync();
  return useQuery<Record<string, unknown>>({
    queryKey: [QK, mod, companyId],
    queryFn: () => apiGet(`${BASE}/${mod}?companyId=${companyId}`),
    staleTime: 60_000,
    enabled,
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
 * Notifica a otros tabs via BroadcastChannel para sincronización.
 */
export function useSaveModuleSettings(mod: SettingsModule, companyId = 1) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (settings: Record<string, unknown>) =>
      apiPut(`${BASE}/${mod}?companyId=${companyId}`, settings),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [QK, mod, companyId] });
      qc.invalidateQueries({ queryKey: [QK, 'all', companyId] });
      broadcastSettingsChange(mod, companyId);
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
