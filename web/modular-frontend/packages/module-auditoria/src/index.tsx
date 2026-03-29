// ─── Hooks ────────────────────────────────────────
export {
  useAuditLogs,
  useAuditLogDetail,
  useAuditDashboard,
  useFiscalRecords,
  useFiscalConfig,
  useSaveFiscalConfig,
  useFiscalCountries,
  useFiscalCountryProfile,
  useFiscalTaxRates,
  useFiscalInvoiceTypes,
} from "./hooks/useAuditoria";

// ─── Types ────────────────────────────────────────
export type {
  AuditLogFilter,
  AuditLogEntry,
  AuditDashboard,
  FiscalRecordFilter,
} from "./hooks/useAuditoria";

// ─── Components ───────────────────────────────────
export { default as AuditLogPage } from "./components/AuditLogPage";
export { default as FiscalConfigPage } from "./components/FiscalConfigPage";
export { default as FiscalRecordsPage } from "./components/FiscalRecordsPage";
export { default as AuditoriaReportesPage } from "./components/AuditoriaReportesPage";
export { default as AnalyticsDashboardPage } from "./components/AnalyticsDashboardPage";

// ─── Analytics Hooks ─────────────────────────────
export {
  useAnalyticsDashboard,
  useAnalyticsBusiness,
  useAnalyticsPerformance,
  useAnalyticsActivity,
  useAnalyticsAudit,
} from "./hooks/useAnalytics";

export type {
  TimeRange,
  AnalyticsDashboard,
  BusinessEvents,
  PerformanceData,
  UserActivity,
  AuditData,
  AuditRecord,
} from "./hooks/useAnalytics";

// ─── Pages ────────────────────────────────────────
export { default as AuditoriaHome } from "./pages/AuditoriaHome";
