'use client';

import { useState, useMemo } from 'react';
import { REPORT_TEMPLATES, getTemplateById } from '@zentto/report-core';
import type { ReportLayout, DataSet } from '@zentto/report-core';
import { getModuleSlots, getModuleSlotsByCountry } from '../config/module-reports';
import type { ModuleReportSlot } from '../config/module-reports';

export interface ReportSlotPickerProps {
  moduleId: string;
  /** País del tenant (ISO 2 letter) — filtra slots relevantes */
  country?: string;
  /** Callback cuando el usuario selecciona un slot para ver/imprimir */
  onSelect: (slot: ModuleReportSlot, layout: ReportLayout, sampleData: DataSet) => void;
  /** Si es admin, muestra opción de personalizar */
  isAdmin?: boolean;
  /** Callback cuando admin quiere editar el template de un slot */
  onCustomize?: (slot: ModuleReportSlot) => void;
  /** Overrides de template por slot (configurados por admin) */
  customTemplates?: Record<string, ReportLayout>;
}

/**
 * Selector de reportes disponibles para un módulo.
 *
 * Muestra una lista de "slots" (reportes asociados al módulo) con su template
 * por defecto o personalizado. Los administradores ven un botón extra para
 * editar/reemplazar el template.
 */
export function ReportSlotPicker({
  moduleId,
  country,
  onSelect,
  isAdmin = false,
  onCustomize,
  customTemplates = {},
}: ReportSlotPickerProps) {
  const [search, setSearch] = useState('');

  const slots = useMemo(() => {
    const raw = country
      ? getModuleSlotsByCountry(moduleId, country)
      : getModuleSlots(moduleId);
    if (!search) return raw;
    const q = search.toLowerCase();
    return raw.filter(s =>
      s.label.toLowerCase().includes(q) || s.description.toLowerCase().includes(q)
    );
  }, [moduleId, country, search]);

  if (slots.length === 0) {
    return (
      <div style={{ padding: 24, textAlign: 'center', color: '#888' }}>
        No hay reportes configurados para este módulo.
      </div>
    );
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
      {/* Buscador */}
      <input
        type="text"
        placeholder="Buscar reporte..."
        value={search}
        onChange={(e) => setSearch(e.target.value)}
        style={{
          padding: '10px 14px', borderRadius: 8, border: '1px solid #ddd',
          fontSize: 14, outline: 'none', width: '100%', boxSizing: 'border-box',
        }}
      />

      {/* Lista de slots */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: 12 }}>
        {slots.map((slot) => {
          const template = getTemplateById(slot.defaultTemplateId);
          const hasCustom = slot.slotId in customTemplates;

          return (
            <div
              key={slot.slotId}
              style={{
                border: '1px solid #e0e0e0', borderRadius: 10, padding: 16,
                cursor: 'pointer', transition: 'all 0.15s',
                background: hasCustom ? '#f3e5f5' : '#fff',
                position: 'relative',
              }}
              onClick={() => {
                const layout = customTemplates[slot.slotId] ?? template?.layout;
                const sampleData = template?.sampleData ?? {};
                if (layout) onSelect(slot, layout, sampleData);
              }}
              onMouseEnter={(e) => { (e.currentTarget as HTMLDivElement).style.borderColor = '#1a1a2e'; }}
              onMouseLeave={(e) => { (e.currentTarget as HTMLDivElement).style.borderColor = '#e0e0e0'; }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 6 }}>
                <span style={{ fontSize: 22 }}>{slot.icon}</span>
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: 600, fontSize: 14 }}>{slot.label}</div>
                  <div style={{ fontSize: 12, color: '#888' }}>{slot.description}</div>
                </div>
              </div>

              {hasCustom && (
                <span style={{
                  position: 'absolute', top: 8, right: 8,
                  fontSize: 10, background: '#7b1fa2', color: '#fff',
                  padding: '2px 6px', borderRadius: 4,
                }}>
                  Personalizado
                </span>
              )}

              {/* Botón admin para personalizar */}
              {isAdmin && onCustomize && (
                <button
                  onClick={(e) => { e.stopPropagation(); onCustomize(slot); }}
                  style={{
                    marginTop: 8, width: '100%', padding: '6px 0',
                    background: 'none', border: '1px dashed #999',
                    borderRadius: 6, cursor: 'pointer', fontSize: 12,
                    color: '#666',
                  }}
                >
                  ✏️ Personalizar template
                </button>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
