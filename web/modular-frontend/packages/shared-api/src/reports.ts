'use client';

import { apiGet, apiPut, apiDelete } from './api';

/* ── Types ────────────────────────────────────────────────────── */

export interface SavedReport {
  id: string;
  name: string;
  description: string;
  icon: string;
  layout: Record<string, unknown>;
  sampleData: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
}

export interface SaveReportInput {
  name: string;
  description?: string;
  icon?: string;
  layout: Record<string, unknown>;
  sampleData?: Record<string, unknown>;
}

/* ── LocalStorage fallback ────────────────────────────────────── */
const LS_KEY = 'zentto-report-studio-saved';

function lsRead(): SavedReport[] {
  try { return JSON.parse(localStorage.getItem(LS_KEY) || '[]'); } catch { return []; }
}

function lsWrite(reports: SavedReport[]) {
  localStorage.setItem(LS_KEY, JSON.stringify(reports));
}

/* ── Normalize API response → SavedReport ─────────────────────── */
function normalize(row: Record<string, unknown>): SavedReport {
  const tpl = (row.template ?? {}) as Record<string, unknown>;
  return {
    id: String(row.id ?? row.reportId ?? ''),
    name: String(row.name ?? row.Name ?? tpl.name ?? ''),
    description: String(row.description ?? row.Description ?? ''),
    icon: String(row.icon ?? row.Icon ?? '📊'),
    layout: (tpl.layout ?? row.layout ?? {}) as Record<string, unknown>,
    sampleData: (tpl.sampleData ?? row.sampleData ?? {}) as Record<string, unknown>,
    createdAt: String(row.createdAt ?? row.CreatedAt ?? ''),
    updatedAt: String(row.updatedAt ?? row.UpdatedAt ?? ''),
  };
}

/* ── API with localStorage fallback ───────────────────────────── */

export async function listSavedReports(): Promise<SavedReport[]> {
  try {
    const res = await apiGet('/v1/reportes/saved');
    const data = (Array.isArray(res) ? res : res.data ?? res.rows ?? []) as Record<string, unknown>[];
    const reports = data.map(normalize);
    lsWrite(reports);
    return reports;
  } catch {
    return lsRead();
  }
}

export async function getSavedReport(id: string): Promise<SavedReport | null> {
  try {
    const res = await apiGet(`/v1/reportes/saved/${id}`);
    if (!res) return null;
    return normalize(res.data ?? res);
  } catch {
    return lsRead().find((r) => r.id === id) ?? null;
  }
}

export async function createSavedReport(input: SaveReportInput): Promise<SavedReport> {
  const id = `report-${Date.now()}`;
  const report: SavedReport = {
    id,
    name: input.name,
    description: input.description ?? '',
    icon: input.icon ?? '📊',
    layout: input.layout,
    sampleData: input.sampleData ?? {},
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
  try {
    await apiPut(`/v1/reportes/saved/${id}`, {
      name: input.name,
      template: { layout: input.layout, sampleData: input.sampleData ?? {} },
    });
  } catch { /* fallback below */ }
  const all = lsRead();
  all.push(report);
  lsWrite(all);
  return report;
}

export async function updateSavedReport(id: string, input: SaveReportInput): Promise<void> {
  try {
    await apiPut(`/v1/reportes/saved/${id}`, {
      name: input.name,
      template: { layout: input.layout, sampleData: input.sampleData ?? {} },
    });
  } catch { /* fallback below */ }
  const all = lsRead();
  const idx = all.findIndex((r) => r.id === id);
  if (idx >= 0) {
    all[idx] = { ...all[idx], ...input, updatedAt: new Date().toISOString() } as SavedReport;
    lsWrite(all);
  }
}

export async function deleteSavedReport(id: string): Promise<void> {
  try {
    await apiDelete(`/v1/reportes/saved/${id}`);
  } catch { /* fallback below */ }
  lsWrite(lsRead().filter((r) => r.id !== id));
}
