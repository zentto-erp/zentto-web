'use client';

// ─── Components ──────────────────────────────────────────────────────

export { ReportViewer } from './components/ReportViewer';
export type { ReportViewerProps } from './components/ReportViewer';

export { ReportDesigner } from './components/ReportDesigner';
export type { ReportDesignerProps } from './components/ReportDesigner';

export { PrintButton } from './components/PrintButton';
export type { PrintButtonProps } from './components/PrintButton';

export { ReportSlotPicker } from './components/ReportSlotPicker';
export type { ReportSlotPickerProps } from './components/ReportSlotPicker';

export { ModuleReportsPage } from './components/ModuleReportsPage';
export type { ModuleReportsPageProps } from './components/ModuleReportsPage';

// ─── Hooks ───────────────────────────────────────────────────────────

export { useModuleReports } from './hooks/useModuleReports';
export type { ResolvedReport, UseModuleReportsReturn } from './hooks/useModuleReports';

export { usePrintReport } from './hooks/usePrintReport';
export type { UsePrintReportReturn, UsePrintReportOptions } from './hooks/usePrintReport';

// ─── Config ──────────────────────────────────────────────────────────

export {
  MODULE_REPORT_MAP,
  getModuleReports,
  getModuleSlots,
  getModuleSlotsByCountry,
  getSlot,
  getModulesWithReports,
} from './config/module-reports';

export type {
  ModuleReportSlot,
  ModuleReportConfig,
} from './config/module-reports';

// ─── Re-exports from report-core (convenience) ──────────────────────

export {
  REPORT_TEMPLATES,
  getTemplateById,
  getTemplatesByCategory,
  renderToFullHtml,
  createBlankLayout,
} from '@zentto/report-core';

export type {
  ReportLayout,
  DataSet,
  DataSourceDef,
} from '@zentto/report-core';
