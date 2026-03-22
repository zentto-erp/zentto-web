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

// ─── Types ───────────────────────────────────────────────────
export type {
  Pipeline,
  PipelineStage,
  Lead,
  LeadFilter,
  Activity,
  ActivityFilter,
} from "./hooks/useCRM";

// ─── Components ──────────────────────────────────────────────
export { default as PipelineKanban } from "./components/PipelineKanban";
export { default as LeadsPage } from "./components/LeadsPage";
export { default as ActividadesPage } from "./components/ActividadesPage";

// ─── Pages ───────────────────────────────────────────────────
export { default as CRMHome } from "./pages/CRMHome";
