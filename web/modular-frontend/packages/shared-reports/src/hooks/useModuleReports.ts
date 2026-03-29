'use client';

import { useMemo } from 'react';
import { getTemplateById, REPORT_TEMPLATES } from '@zentto/report-core';
import type { ReportLayout, DataSet } from '@zentto/report-core';
import { getModuleSlots, getModuleSlotsByCountry, getModuleReports } from '../config/module-reports';
import type { ModuleReportSlot, ModuleReportConfig } from '../config/module-reports';

export interface ResolvedReport {
  slot: ModuleReportSlot;
  layout: ReportLayout;
  sampleData: DataSet;
  /** true si el template fue encontrado en la galería */
  available: boolean;
}

export interface UseModuleReportsReturn {
  /** Configuración del módulo */
  config: ModuleReportConfig | undefined;
  /** Todos los slots del módulo */
  slots: ModuleReportSlot[];
  /** Reportes resueltos (con layout + sampleData) */
  reports: ResolvedReport[];
  /** Obtener un reporte resuelto por slotId */
  getReport: (slotId: string) => ResolvedReport | undefined;
  /** Obtener layout por slotId (con override custom si existe) */
  getLayout: (slotId: string, customTemplates?: Record<string, ReportLayout>) => ReportLayout | null;
  /** Total de reportes disponibles */
  count: number;
}

/**
 * Hook para acceder a los reportes de un módulo.
 *
 * @param moduleId - ID del módulo (e.g., 'ventas', 'nomina', 'inventario')
 * @param country  - País del tenant para filtrar (opcional)
 *
 * @example
 * ```tsx
 * const { reports, getLayout } = useModuleReports('ventas', 'VE');
 * // reports = [{ slot, layout, sampleData, available }]
 * ```
 */
export function useModuleReports(moduleId: string, country?: string): UseModuleReportsReturn {
  const config = useMemo(() => getModuleReports(moduleId), [moduleId]);

  const slots = useMemo(() => {
    return country
      ? getModuleSlotsByCountry(moduleId, country)
      : getModuleSlots(moduleId);
  }, [moduleId, country]);

  const reports = useMemo(() => {
    return slots.map<ResolvedReport>((slot) => {
      const template = getTemplateById(slot.defaultTemplateId);
      return {
        slot,
        layout: template?.layout ?? ({} as ReportLayout),
        sampleData: template?.sampleData ?? {},
        available: !!template,
      };
    });
  }, [slots]);

  const getReport = useMemo(() => {
    return (slotId: string) => reports.find(r => r.slot.slotId === slotId);
  }, [reports]);

  const getLayout = useMemo(() => {
    return (slotId: string, customTemplates?: Record<string, ReportLayout>) => {
      if (customTemplates && slotId in customTemplates) return customTemplates[slotId];
      const report = reports.find(r => r.slot.slotId === slotId);
      return report?.layout ?? null;
    };
  }, [reports]);

  return {
    config,
    slots,
    reports,
    getReport,
    getLayout,
    count: reports.filter(r => r.available).length,
  };
}
