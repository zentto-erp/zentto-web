"use client";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost } from "@zentto/shared-api";

const BASE = "/api/v1/crm";
const QK_LEADS = "crm-leads";
const QK_SCORING = "crm-scoring";

/* ─── Types ────────────────────────────────────────────────── */

export interface LeadDetailData {
  LeadId: number;
  LeadCode: string;
  PipelineId: number;
  PipelineName: string;
  StageId: number;
  StageName: string;
  StageColor: string;
  ContactName: string;
  CompanyName: string;
  Email: string;
  Phone: string;
  EstimatedValue: number;
  Priority: string;
  Status: string;
  Source: string;
  AssignedTo: number;
  AssignedToName: string;
  Notes: string;
  ExpectedCloseDate: string;
  CreatedAt: string;
  WonAt: string | null;
  LostAt: string | null;
  LostReason: string | null;
  Probability: number;
  DaysInStage: number;
}

export interface TimelineLead {
  LeadId: number;
  LeadCode: string;
  ContactName: string;
  CompanyName: string;
  StageName: string;
  StageColor: string;
  Status: string;
  EstimatedValue: number;
  Score: number;
  CreatedAt: string;
  ExpectedCloseDate: string;
  WonAt: string | null;
  LostAt: string | null;
}

export interface LeadScoreData {
  LeadId: number;
  Score: number;
  Factors: ScoreFactor[];
  CalculatedAt: string;
}

export interface ScoreFactor {
  Factor: string;
  Points: number;
  MaxPoints: number;
  Description: string;
}

export interface HistoryEntry {
  HistoryId: number;
  LeadId: number;
  ChangeType: string;
  FromStage: string | null;
  ToStage: string | null;
  FromStageColor: string | null;
  ToStageColor: string | null;
  Description: string;
  CreatedBy: string;
  CreatedAt: string;
}

/* ─── Hooks ────────────────────────────────────────────────── */

export function useLeadDetailFull(id?: number) {
  return useQuery<LeadDetailData>({
    queryKey: [QK_LEADS, "detail-full", id],
    queryFn: () => apiGet(`${BASE}/leads/${id}/detail`),
    enabled: !!id,
  });
}

export function useLeadTimeline(pipelineId?: number, status?: string) {
  return useQuery<TimelineLead[]>({
    queryKey: [QK_SCORING, "timeline", pipelineId, status],
    queryFn: () =>
      apiGet(`${BASE}/leads/timeline`, {
        ...(pipelineId ? { pipelineId } : {}),
        ...(status ? { status } : {}),
      }),
  });
}

export function useLeadScore(leadId?: number) {
  return useQuery<LeadScoreData>({
    queryKey: [QK_SCORING, "score", leadId],
    queryFn: () => apiGet(`${BASE}/leads/${leadId}/score`),
    enabled: !!leadId,
  });
}

export function useLeadHistoryFull(leadId?: number) {
  return useQuery<HistoryEntry[]>({
    queryKey: [QK_LEADS, "history-full", leadId],
    queryFn: () => apiGet(`${BASE}/leads/${leadId}/history`),
    enabled: !!leadId,
  });
}

export function useCalculateScore() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (leadId: number) =>
      apiPost(`${BASE}/leads/${leadId}/score`, {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_LEADS] }),
  });
}

export function useBulkCalculateScores() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (leadIds: number[]) =>
      apiPost(`${BASE}/leads/score/bulk`, { leadIds }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_LEADS] }),
  });
}
