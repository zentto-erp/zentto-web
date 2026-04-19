"use client";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost, apiPut, apiDelete } from "@zentto/shared-api";
import type { Priority } from "../types";

const BASE = "/api/v1/crm";
const QK_PIPELINES = "crm-pipelines";
const QK_LEADS = "crm-leads";
const QK_ACTIVITIES = "crm-activities";

/* ─── Types ────────────────────────────────────────────────── */

export interface Pipeline {
  PipelineId: number;
  Name: string;
  Description: string;
  IsDefault: boolean;
  IsActive: boolean;
}

export interface PipelineStage {
  StageId: number;
  PipelineId: number;
  Name: string;
  SortOrder: number;
  Color: string;
  IsClosed: boolean;
  Probability: number;
}

export interface Lead {
  LeadId: number;
  LeadCode: string;
  PipelineId: number;
  StageId: number;
  StageName: string;
  StageColor: string;
  ContactName: string;
  CompanyName: string;
  Email: string;
  Phone: string;
  EstimatedValue: number;
  Priority: Priority;
  Status: string;
  Source: string;
  AssignedTo: number;
  AssignedToName: string;
  Notes: string;
  ExpectedCloseDate: string;
  CreatedAt: string;
}

export interface LeadFilter {
  pipelineId?: number;
  stageId?: number;
  status?: string;
  priority?: Priority;
  assignedTo?: number;
  search?: string;
  page?: number;
  limit?: number;
}

export interface Activity {
  ActivityId: number;
  LeadId: number;
  LeadCode: string;
  ActivityType: string;
  Subject: string;
  Description: string;
  DueDate: string;
  IsCompleted: boolean;
  CompletedAt: string | null;
  AssignedTo: number;
  AssignedToName: string;
  CreatedAt: string;
}

export interface ActivityFilter {
  leadId?: number;
  type?: string;
  isCompleted?: boolean;
  page?: number;
  limit?: number;
}

/* ─── Pipelines ────────────────────────────────────────────── */

export function usePipelinesList() {
  return useQuery({
    queryKey: [QK_PIPELINES],
    queryFn: () => apiGet(`${BASE}/pipelines`),
  });
}

export function usePipelineStages(pipelineId?: number) {
  return useQuery({
    queryKey: [QK_PIPELINES, "stages", pipelineId],
    queryFn: () => apiGet(`${BASE}/pipelines/${pipelineId}/stages`),
    enabled: !!pipelineId,
  });
}

export function useCreatePipeline() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: any) => apiPost(`${BASE}/pipelines`, d),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_PIPELINES] }),
  });
}

export function useCreateStage() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: any) => apiPost(`${BASE}/pipelines/${d.pipelineId}/stages`, d),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_PIPELINES] }),
  });
}

/* ─── Leads ────────────────────────────────────────────────── */

export function useLeadsList(filter?: LeadFilter) {
  return useQuery({
    queryKey: [QK_LEADS, filter],
    queryFn: () => apiGet(`${BASE}/leads`, filter as any),
  });
}

export function useLeadDetail(id?: number) {
  return useQuery({
    queryKey: [QK_LEADS, "detail", id],
    queryFn: () => apiGet(`${BASE}/leads/${id}`),
    enabled: !!id,
  });
}

export function useLeadHistory(id?: number) {
  return useQuery({
    queryKey: [QK_LEADS, "history", id],
    queryFn: () => apiGet(`${BASE}/leads/${id}/historial`),
    enabled: !!id,
  });
}

export function useCreateLead() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: any) => apiPost(`${BASE}/leads`, d),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_LEADS] }),
  });
}

export function useUpdateLead() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: any) => apiPut(`${BASE}/leads/${d.id}`, d),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_LEADS] }),
  });
}

export function useMoveLeadStage() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: { leadId: number; newStageId: number; notes?: string }) =>
      apiPost(`${BASE}/leads/${d.leadId}/cambiar-etapa`, {
        newStageId: d.newStageId,
        notes: d.notes,
      }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_LEADS] }),
  });
}

export function useWinLead() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: { id: number; customerId?: number }) =>
      apiPost(`${BASE}/leads/${d.id}/cerrar`, {
        isWon: true,
        customerId: d.customerId,
      }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_LEADS] }),
  });
}

export function useLoseLead() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: { id: number; reason: string }) =>
      apiPost(`${BASE}/leads/${d.id}/cerrar`, {
        isWon: false,
        lostReason: d.reason,
      }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_LEADS] }),
  });
}

export function useCRMDashboard(pipelineId?: number) {
  return useQuery({
    queryKey: [QK_LEADS, "dashboard", pipelineId],
    queryFn: () => apiGet(`${BASE}/dashboard`, pipelineId ? { pipeline: pipelineId } : {}),
  });
}

/* ─── Activities ───────────────────────────────────────────── */

export function useActivitiesList(filter?: ActivityFilter) {
  return useQuery({
    queryKey: [QK_ACTIVITIES, filter],
    queryFn: () => apiGet(`${BASE}/actividades`, filter as any),
  });
}

export function useCreateActivity() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: any) => apiPost(`${BASE}/actividades`, d),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_ACTIVITIES] }),
  });
}

export function useCompleteActivity() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => apiPost(`${BASE}/actividades/${id}/completar`, {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_ACTIVITIES] }),
  });
}
