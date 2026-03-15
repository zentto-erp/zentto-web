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

// ─── Pages ────────────────────────────────────────
export { default as AuditoriaHome } from "./pages/AuditoriaHome";
