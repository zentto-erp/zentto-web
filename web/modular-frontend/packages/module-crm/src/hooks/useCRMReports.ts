"use client";
import { useQuery } from "@tanstack/react-query";
import { apiGet } from "@zentto/shared-api";

const BASE = "/api/v1/crm/reports";
const QK = "crm-reports";

/* ─── Types ────────────────────────────────────────────────── */

export interface SalesByPeriodRow {
  Period: string;
  WonCount: number;
  WonValue: number;
  CumulativeValue: number;
  AvgDealSize: number;
}

export interface LeadAgingRow {
  Bucket: string;
  BucketOrder: number;
  LeadCount: number;
  Percentage: number;
  TotalValue: number;
}

export interface ConversionBySourceRow {
  Source: string;
  TotalLeads: number;
  WonCount: number;
  LostCount: number;
  OpenCount: number;
  ConversionRate: number;
  TotalValue: number;
  WonValue: number;
}

export interface TopPerformerRow {
  UserId: number;
  UserName: string;
  WonCount: number;
  TotalDeals: number;
  WinRate: number;
  Revenue: number;
  AvgDealSize: number;
}

/* ─── Hooks ────────────────────────────────────────────────── */

export function useSalesByPeriod(pipelineId?: number, groupBy?: string) {
  return useQuery<SalesByPeriodRow[]>({
    queryKey: [QK, "sales", pipelineId, groupBy],
    queryFn: () =>
      apiGet(`${BASE}/sales`, {
        ...(pipelineId ? { pipeline: pipelineId } : {}),
        ...(groupBy ? { groupBy } : {}),
      }),
  });
}

export function useLeadAging(pipelineId?: number) {
  return useQuery<LeadAgingRow[]>({
    queryKey: [QK, "aging", pipelineId],
    queryFn: () =>
      apiGet(`${BASE}/aging`, pipelineId ? { pipeline: pipelineId } : {}),
  });
}

export function useConversionBySource(pipelineId?: number) {
  return useQuery<ConversionBySourceRow[]>({
    queryKey: [QK, "conversion", pipelineId],
    queryFn: () =>
      apiGet(`${BASE}/conversion`, pipelineId ? { pipeline: pipelineId } : {}),
  });
}

export function useTopPerformers(pipelineId?: number, dateFrom?: string) {
  return useQuery<TopPerformerRow[]>({
    queryKey: [QK, "top-performers", pipelineId, dateFrom],
    queryFn: () =>
      apiGet(`${BASE}/top-performers`, {
        ...(pipelineId ? { pipeline: pipelineId } : {}),
        ...(dateFrom ? { from: dateFrom } : {}),
      }),
  });
}
