"use client";

// ─── Module Metadata ─────────────────────────────────────────
export const MODULE_ID = "crm";
export const MODULE_TITLE = "CRM";

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

// ─── Pages ───────────────────────────────────────────────────
export { default as CRMHome } from "./pages/CRMHome";
