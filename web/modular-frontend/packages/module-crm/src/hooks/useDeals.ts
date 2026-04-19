"use client";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { apiDelete, apiGet, apiPost, apiPut } from "@zentto/shared-api";
import type { Priority } from "../types";

const BASE = "/api/v1/crm";
const QK = "crm-deals";

/* ─── Types ────────────────────────────────────────────────── */

export type DealStatus = "OPEN" | "WON" | "LOST" | "ABANDONED";

export interface Deal {
  DealId: number;
  DealCode: string;
  Name: string;
  PipelineId: number;
  PipelineName?: string;
  StageId: number;
  StageName?: string;
  StageColor?: string | null;
  Status: DealStatus;
  ContactId: number | null;
  ContactName?: string | null;
  CrmCompanyId: number | null;
  CompanyName?: string | null;
  OwnerAgentId: number | null;
  OwnerAgentName?: string | null;
  Value: number;
  Currency: string;
  Probability: number;
  ExpectedClose: string | null;
  Priority: Priority;
  Source: string | null;
  Notes: string | null;
  Tags: string | null;
  CreatedAt: string;
  UpdatedAt?: string;
  ClosedAt?: string | null;
  LostReason?: string | null;
}

export interface DealFilter {
  pipelineId?: number;
  stageId?: number;
  status?: DealStatus;
  ownerAgentId?: number;
  contactId?: number;
  crmCompanyId?: number;
  search?: string;
  page?: number;
  limit?: number;
}

export interface DealInput {
  name: string;
  pipelineId: number;
  stageId: number;
  contactId?: number;
  crmCompanyId?: number;
  ownerAgentId?: number;
  value?: number;
  currency?: string;
  probability?: number;
  expectedClose?: string;
  priority?: Priority;
  source?: string;
  notes?: string;
  tags?: string;
}

export interface DealUpdateInput {
  name?: string;
  stageId?: number;
  value?: number;
  currency?: string;
  probability?: number;
  expectedClose?: string;
  priority?: Priority;
  source?: string;
  notes?: string;
  tags?: string;
}

export interface DealTimelineEvent {
  EventType: string;
  EventDate: string;
  Title: string;
  Description?: string | null;
  Actor?: string | null;
  Meta?: unknown;
}

/* ─── Queries ──────────────────────────────────────────────── */

export function useDealsList(filter?: DealFilter) {
  return useQuery({
    queryKey: [QK, "list", filter],
    queryFn: () => apiGet(`${BASE}/deals`, filter as Record<string, unknown>),
  });
}

export function useDeal(id?: number | null) {
  return useQuery({
    queryKey: [QK, "detail", id],
    queryFn: () => apiGet(`${BASE}/deals/${id}`),
    enabled: !!id,
  });
}

export function useDealTimeline(id?: number | null, limit = 100) {
  return useQuery({
    queryKey: [QK, "timeline", id, limit],
    queryFn: () => apiGet(`${BASE}/deals/${id}/timeline`, { limit }),
    enabled: !!id,
  });
}

export function useSearchDeals(q: string, limit = 10) {
  return useQuery({
    queryKey: [QK, "search", q, limit],
    queryFn: () => apiGet(`${BASE}/deals/search`, { q, limit }),
    enabled: q.trim().length > 0,
  });
}

/* ─── Mutations ────────────────────────────────────────────── */

export function useUpsertDeal() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: { id?: number } & (DealInput | DealUpdateInput)) => {
      if (d.id) {
        const { id, ...rest } = d as { id: number } & DealUpdateInput;
        return apiPut(`${BASE}/deals/${id}`, rest);
      }
      return apiPost(`${BASE}/deals`, d as DealInput);
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK] }),
  });
}

export function useDeleteDeal() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => apiDelete(`${BASE}/deals/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK] }),
  });
}

export function useMoveDealStage() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: { dealId: number; newStageId: number; notes?: string }) =>
      apiPost(`${BASE}/deals/${d.dealId}/move-stage`, {
        newStageId: d.newStageId,
        notes: d.notes,
      }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK] }),
  });
}

export function useCloseWonDeal() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: { id: number; reason?: string }) =>
      apiPost(`${BASE}/deals/${d.id}/close-won`, { reason: d.reason }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK] }),
  });
}

export function useCloseLostDeal() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: { id: number; reason?: string }) =>
      apiPost(`${BASE}/deals/${d.id}/close-lost`, { reason: d.reason }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK] }),
  });
}
