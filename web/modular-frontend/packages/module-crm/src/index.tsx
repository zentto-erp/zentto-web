"use client";

// ─── Module Metadata ─────────────────────────────────────────
export const MODULE_ID = "crm";
export const MODULE_TITLE = "CRM";

// ─── Shared types ───────────────────────────────────────────
export type { Priority, LeadStatus } from "./types";
export {
  PRIORITY_VALUES,
  PRIORITY_LABELS,
  PRIORITY_COLORS,
  LEAD_STATUS_LABELS,
  isPriority,
  toPriority,
} from "./types";

// ─── Hooks ───────────────────────────────────────────────────
export {
  usePipelinesList,
  usePipelineStages,
  useCreatePipeline,
  useCreateStage,
  useLeadsList,
  useLeadDetail,
  useLeadHistory,
  useCreateLead,
  useUpdateLead,
  useMoveLeadStage,
  useWinLead,
  useLoseLead,
  useActivitiesList,
  useCreateActivity,
  useCompleteActivity,
} from "./hooks/useCRM";

export {
  useLeadDetailFull,
  useLeadTimeline,
  useLeadScore,
  useLeadHistoryFull,
  useCalculateScore,
  useBulkCalculateScores,
} from "./hooks/useCRMScoring";

export {
  useCRMKPIs,
  useCRMForecast,
  useCRMFunnel,
  useCRMWinLossByPeriod,
  useCRMWinLossBySource,
  useCRMVelocity,
  useCRMActivityReport,
} from "./hooks/useCRMAnalytics";

export { useCRMDashboard } from "./hooks/useCRM";

// ─── Types ───────────────────────────────────────────────────
export type {
  Pipeline,
  PipelineStage,
  Lead,
  LeadFilter,
  Activity,
  ActivityFilter,
} from "./hooks/useCRM";

export type {
  LeadDetailData,
  TimelineLead,
  LeadScoreData,
  ScoreFactor,
  HistoryEntry,
} from "./hooks/useCRMScoring";

// ─── Components ──────────────────────────────────────────────
export { default as PipelineKanban } from "./components/PipelineKanban";
export { default as LeadsPage } from "./components/LeadsPage";
export { default as IntegrationsPage } from "./components/IntegrationsPage";
export {
  useWebhooksList, useCreateWebhook, useRevokeWebhook,
  usePublicKeysList, useCreatePublicKey, useRevokePublicKey,
} from "./hooks/useIntegrations";
export type { TenantWebhook, PublicApiKey } from "./hooks/useIntegrations";
export { default as ActividadesPage } from "./components/ActividadesPage";
export { default as LeadDetailPanel } from "./components/LeadDetailPanel";
export { LeadTimeline } from "./components/LeadTimeline";
export { LeadScoreBadge } from "./components/LeadScoreBadge";
export { LeadActivityTimeline } from "./components/LeadActivityTimeline";

// ─── Automation ─────────────────────────────────────────────
export {
  useAutomationRules,
  useUpsertRule,
  useDeleteRule,
  useEvaluateRules,
  useStaleLeads,
  useAutomationLogs,
} from "./hooks/useCRMAutomation";
export type {
  AutomationRule,
  StaleLead,
  AutomationLog,
} from "./hooks/useCRMAutomation";
export { default as AutomationRulesPage } from "./components/AutomationRulesPage";
export { StaleLeadsAlert } from "./components/StaleLeadsAlert";

// ─── Reports ────────────────────────────────────────────────
export {
  useSalesByPeriod,
  useLeadAging,
  useConversionBySource,
  useTopPerformers,
} from "./hooks/useCRMReports";
export type {
  SalesByPeriodRow,
  LeadAgingRow,
  ConversionBySourceRow,
  TopPerformerRow,
} from "./hooks/useCRMReports";
export { default as CRMReportsPage } from "./components/CRMReportsPage";
export { default as CRMSettingsPage } from "./components/CRMSettingsPage";

// ─── Pages ───────────────────────────────────────────────────
export { default as CRMHome } from "./pages/CRMHome";
