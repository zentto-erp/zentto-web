'use client';

import { apiGet, apiPost, apiPut, apiDelete } from './api';

/* ── Types ────────────────────────────────────────────────────── */

export interface StudioAddon {
  id: string;
  title: string;
  description: string;
  icon: string;
  modules: string[];
  config: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
}

export interface SaveAddonInput {
  title: string;
  description?: string;
  icon?: string;
  modules: string[];
  config: Record<string, unknown>;
}

export type FrontendAddon = { id: string; name: string; entry: string };

/* ── LocalStorage fallback key ────────────────────────────────── */
const LS_KEY = 'zentto-studio-apps';

function lsRead(): StudioAddon[] {
  try { return JSON.parse(localStorage.getItem(LS_KEY) || '[]'); } catch { return []; }
}

function lsWrite(apps: StudioAddon[]) {
  localStorage.setItem(LS_KEY, JSON.stringify(apps));
}

/* ── Normalize API response → StudioAddon ─────────────────────── */
function normalize(row: Record<string, unknown>): StudioAddon {
  return {
    id: String(row.AddonId ?? row.addonId ?? row.id ?? ''),
    title: String(row.Title ?? row.title ?? ''),
    description: String(row.Description ?? row.description ?? ''),
    icon: String(row.Icon ?? row.icon ?? '📦'),
    modules: (row.modules as string[]) ?? [],
    config: (row.config ?? row.Config ?? {}) as Record<string, unknown>,
    createdAt: String(row.CreatedAt ?? row.createdAt ?? ''),
    updatedAt: String(row.UpdatedAt ?? row.updatedAt ?? ''),
  };
}

/* ── API with localStorage fallback ───────────────────────────── */

/** List all addons (optionally filtered by moduleId) */
export async function listAddons(moduleId?: string): Promise<StudioAddon[]> {
  try {
    const path = moduleId
      ? `/v1/studio/addons/module/${moduleId}`
      : '/v1/studio/addons';
    const res = await apiGet(path);
    const data = (res.data ?? []) as Record<string, unknown>[];
    const addons = data.map(normalize);
    // Sync to localStorage for offline fallback
    if (!moduleId) lsWrite(addons);
    return addons;
  } catch {
    // Fallback: localStorage
    const all = lsRead();
    if (moduleId) return all.filter((a) => a.modules.includes(moduleId) || a.modules.includes('global'));
    return all;
  }
}

/** Get a single addon by ID */
export async function getAddon(addonId: string): Promise<StudioAddon | null> {
  try {
    const res = await apiGet(`/v1/studio/addons/${addonId}`);
    if (!res.data) return null;
    return normalize(res.data);
  } catch {
    // Fallback: localStorage
    return lsRead().find((a) => a.id === addonId) ?? null;
  }
}

/** Create a new addon */
export async function createAddon(input: SaveAddonInput): Promise<StudioAddon> {
  try {
    const res = await apiPost('/v1/studio/addons', input);
    const addon: StudioAddon = {
      id: res.data?.addonId ?? `addon-${Date.now()}`,
      title: input.title,
      description: input.description ?? '',
      icon: input.icon ?? '📦',
      modules: input.modules,
      config: input.config,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    // Sync to localStorage
    const all = lsRead();
    all.push(addon);
    lsWrite(all);
    return addon;
  } catch {
    // Fallback: save only to localStorage
    const addon: StudioAddon = {
      id: `addon-${Date.now()}`,
      title: input.title,
      description: input.description ?? '',
      icon: input.icon ?? '📦',
      modules: input.modules,
      config: input.config,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    const all = lsRead();
    all.push(addon);
    lsWrite(all);
    return addon;
  }
}

/** Update an existing addon */
export async function updateAddon(addonId: string, input: SaveAddonInput): Promise<void> {
  try {
    await apiPut(`/v1/studio/addons/${addonId}`, input);
  } catch { /* fallback below */ }
  // Always update localStorage
  const all = lsRead();
  const idx = all.findIndex((a) => a.id === addonId);
  if (idx >= 0) {
    all[idx] = { ...all[idx], ...input, updatedAt: new Date().toISOString() };
    lsWrite(all);
  }
}

/** Delete an addon */
export async function deleteAddon(addonId: string): Promise<void> {
  try {
    await apiDelete(`/v1/studio/addons/${addonId}`);
  } catch { /* fallback below */ }
  // Always remove from localStorage
  lsWrite(lsRead().filter((a) => a.id !== addonId));
}

/** Legacy loader */
export async function loadFrontendAddons() {
  const response = await fetch('/addons/registry.json');
  if (!response.ok) return [] as FrontendAddon[];
  return (await response.json()) as FrontendAddon[];
}
