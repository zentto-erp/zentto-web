'use client';

import { useState, useCallback } from 'react';
import type { ReportLayout, DataSet } from '@zentto/report-core';
import { renderToFullHtml } from '@zentto/report-core';
import { ReportViewer } from './ReportViewer';
import { ReportDesigner } from './ReportDesigner';
import { ReportSlotPicker } from './ReportSlotPicker';
import type { ModuleReportSlot } from '../config/module-reports';

type ViewState =
  | { mode: 'picker' }
  | { mode: 'viewer'; slot: ModuleReportSlot; layout: ReportLayout; data: DataSet }
  | { mode: 'designer'; slot: ModuleReportSlot; layout: ReportLayout };

export interface ModuleReportsPageProps {
  /** ID del módulo (debe coincidir con MODULE_REPORT_MAP) */
  moduleId: string;
  /** Nombre del módulo para el título */
  moduleName: string;
  /** País del tenant */
  country?: string;
  /** Si el usuario actual es admin (puede editar templates) */
  isAdmin?: boolean;
  /** Templates personalizados por el admin (slotId → layout) */
  customTemplates?: Record<string, ReportLayout>;
  /** Callback para guardar un template personalizado */
  onSaveCustomTemplate?: (slotId: string, layout: ReportLayout) => Promise<void>;
  /** Función para obtener datos reales del reporte dado un slot */
  fetchReportData?: (slot: ModuleReportSlot) => Promise<DataSet>;
}

/**
 * Página completa de reportes para un módulo.
 *
 * Incluye:
 * - Lista de reportes disponibles (slots) filtrada por país
 * - Visor de reporte (ReportViewer) con toolbar
 * - Editor de diseño (ReportDesigner) para administradores
 * - Navegación picker → viewer ↔ designer
 */
export function ModuleReportsPage({
  moduleId,
  moduleName,
  country,
  isAdmin = false,
  customTemplates = {},
  onSaveCustomTemplate,
  fetchReportData,
}: ModuleReportsPageProps) {
  const [view, setView] = useState<ViewState>({ mode: 'picker' });
  const [saving, setSaving] = useState(false);

  const handleSelect = useCallback(async (slot: ModuleReportSlot, layout: ReportLayout, sampleData: DataSet) => {
    // Si hay fetchReportData, intentar datos reales, sino usar sampleData
    let data = sampleData;
    if (fetchReportData) {
      try {
        data = await fetchReportData(slot);
      } catch {
        // Fallback a sample data si falla
        console.warn(`[ModuleReportsPage] Error fetching data for ${slot.slotId}, using sample`);
      }
    }
    setView({ mode: 'viewer', slot, layout, data });
  }, [fetchReportData]);

  const handleCustomize = useCallback((slot: ModuleReportSlot) => {
    const existing = customTemplates[slot.slotId];
    // Si hay custom, usar ese; sino cargar el default
    const { getTemplateById } = require('@zentto/report-core');
    const template = getTemplateById(slot.defaultTemplateId);
    const layout = existing ?? template?.layout;
    if (layout) {
      setView({ mode: 'designer', slot, layout });
    }
  }, [customTemplates]);

  const handleSaveDesign = useCallback(async (layout: ReportLayout) => {
    if (view.mode !== 'designer' || !onSaveCustomTemplate) return;
    setSaving(true);
    try {
      await onSaveCustomTemplate(view.slot.slotId, layout);
    } finally {
      setSaving(false);
    }
  }, [view, onSaveCustomTemplate]);

  const handlePrint = useCallback(() => {
    if (view.mode !== 'viewer') return;
    const html = renderToFullHtml(view.layout, view.data);
    const win = window.open('', '_blank', 'width=900,height=700');
    if (!win) return;
    win.document.write(html);
    win.document.close();
    win.onload = () => { win.focus(); win.print(); };
  }, [view]);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', gap: 16, padding: 24 }}>
      {/* Header con navegación */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, flexWrap: 'wrap' }}>
        <h2 style={{ margin: 0, fontSize: 20, fontWeight: 600 }}>
          📄 Reportes — {moduleName}
        </h2>
        <div style={{ flex: 1 }} />

        {view.mode !== 'picker' && (
          <button
            onClick={() => setView({ mode: 'picker' })}
            style={{
              padding: '8px 16px', borderRadius: 6, border: '1px solid #ddd',
              background: '#fff', cursor: 'pointer', fontSize: 13,
            }}
          >
            ← Volver a lista
          </button>
        )}

        {view.mode === 'viewer' && (
          <>
            <button
              onClick={handlePrint}
              style={{
                padding: '8px 16px', borderRadius: 6, border: 'none',
                background: '#1a1a2e', color: '#fff', cursor: 'pointer', fontSize: 13,
              }}
            >
              🖨️ Imprimir
            </button>
            {isAdmin && (
              <button
                onClick={() => setView({ mode: 'designer', slot: view.slot, layout: view.layout })}
                style={{
                  padding: '8px 16px', borderRadius: 6, border: '1px solid #7b1fa2',
                  background: '#f3e5f5', color: '#7b1fa2', cursor: 'pointer', fontSize: 13,
                }}
              >
                ✏️ Editar diseño
              </button>
            )}
          </>
        )}

        {view.mode === 'designer' && onSaveCustomTemplate && (
          <button
            onClick={() => {
              // Obtener layout actual del designer
              const el = document.querySelector('zentto-report-designer') as HTMLElement & { getLayout?: () => ReportLayout };
              if (el?.getLayout) handleSaveDesign(el.getLayout());
            }}
            disabled={saving}
            style={{
              padding: '8px 16px', borderRadius: 6, border: 'none',
              background: saving ? '#ccc' : '#7b1fa2', color: '#fff',
              cursor: saving ? 'default' : 'pointer', fontSize: 13,
            }}
          >
            {saving ? '⏳ Guardando...' : '💾 Guardar template'}
          </button>
        )}
      </div>

      {/* Subtítulo del reporte seleccionado */}
      {view.mode !== 'picker' && (
        <div style={{ fontSize: 14, color: '#666' }}>
          {view.slot.icon} {view.slot.label} — {view.slot.description}
        </div>
      )}

      {/* Contenido */}
      <div style={{ flex: 1, minHeight: 0 }}>
        {view.mode === 'picker' && (
          <ReportSlotPicker
            moduleId={moduleId}
            country={country}
            onSelect={handleSelect}
            isAdmin={isAdmin}
            onCustomize={isAdmin ? handleCustomize : undefined}
            customTemplates={customTemplates}
          />
        )}

        {view.mode === 'viewer' && (
          <ReportViewer
            layout={view.layout}
            data={view.data}
            showToolbar
            style={{ height: '100%' }}
          />
        )}

        {view.mode === 'designer' && (
          <ReportDesigner
            layout={view.layout}
            showPreview
            onLayoutChange={(layout) => {
              // Mantener referencia al layout actualizado
              setView(prev => prev.mode === 'designer' ? { ...prev, layout } : prev);
            }}
            style={{ height: '100%' }}
          />
        )}
      </div>
    </div>
  );
}
