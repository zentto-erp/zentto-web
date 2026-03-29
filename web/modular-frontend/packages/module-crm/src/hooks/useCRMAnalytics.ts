"use client";
import { useQuery } from "@tanstack/react-query";
import { apiGet } from "@zentto/shared-api";

const BASE = "/api/v1/crm/analytics";
const QK = "crm-analytics";

/* ─── Types ────────────────────────────────────────────────── */

export interface CRMKPIs {
  OpenCount: number;
  OpenValue: number;
  WonCount: number;
  WonValue: number;
  LostCount: number;
  LostValue: number;
  ConversionRate: number;
  AvgDealSize: number;
  AvgDaysToClose: number;
  NewLeadsThisMonth: number;
  NewLeadsLastMonth: number;
  ActivitiesPending: number;
  ActivitiesOverdue: number;
}

export interface ForecastRow {
  Month: string;
  WeightedValue: number;
  TotalValue: number;
  LeadCount: number;
}

export interface FunnelRow {
  StageName: string;
  StageOrder: number;
  LeadCount: number;
  TotalValue: number;
  Color: string;
  ConversionToNext: number;
}

export interface WinLossPeriodRow {
  Period: string;
  WonCount: number;
  LostCount: number;
  WinRate: number;
}

export interface WinLossSourceRow {
  Source: string;
  WonCount: number;
  LostCount: number;
  WinRate: number;
}

export interface VelocityRow {
  StageName: string;
  AvgDaysInStage: number;
  MedianDaysInStage: number;
  Color: string;
}

export interface ActivityReportRow {
  AssignedToName: string;
  ActivityType: string;
  TotalCount: number;
  CompletedCount: number;
  PendingCount: number;
  OverdueCount: number;
}

/* ─── Hooks ────────────────────────────────────────────────── */

export function useCRMKPIs(pipelineId?: number) {
  return useQuery<CRMKPIs>({
    queryKey: [QK, "kpis", pipelineId],
    queryFn: () =>
      apiGet(`${BASE}/kpis`, pipelineId ? { pipelineId } : {}),
  });
}

export function useCRMForecast(pipelineId?: number, months?: number) {
  return useQuery<ForecastRow[]>({
    queryKey: [QK, "forecast", pipelineId, months],
    queryFn: () =>
      apiGet(`${BASE}/forecast`, {
        ...(pipelineId ? { pipelineId } : {}),
        ...(months ? { months } : {}),
      }),
  });
}

export function useCRMFunnel(pipelineId?: number) {
  return useQuery<FunnelRow[]>({
    queryKey: [QK, "funnel", pipelineId],
    queryFn: () =>
      apiGet(`${BASE}/funnel`, pipelineId ? { pipelineId } : {}),
  });
}

export function useCRMWinLossByPeriod(
  pipelineId?: number,
  dateFrom?: string,
  dateTo?: string,
) {
  return useQuery<WinLossPeriodRow[]>({
    queryKey: [QK, "win-loss-period", pipelineId, dateFrom, dateTo],
    queryFn: () =>
      apiGet(`${BASE}/win-loss/period`, {
        ...(pipelineId ? { pipelineId } : {}),
        ...(dateFrom ? { dateFrom } : {}),
        ...(dateTo ? { dateTo } : {}),
      }),
  });
}

export function useCRMWinLossBySource(pipelineId?: number) {
  return useQuery<WinLossSourceRow[]>({
    queryKey: [QK, "win-loss-source", pipelineId],
    queryFn: () =>
      apiGet(`${BASE}/win-loss/source`, pipelineId ? { pipelineId } : {}),
  });
}

export function useCRMVelocity(pipelineId?: number) {
  return useQuery<VelocityRow[]>({
    queryKey: [QK, "velocity", pipelineId],
    queryFn: () =>
      apiGet(`${BASE}/velocity`, pipelineId ? { pipelineId } : {}),
  });
}

export function useCRMActivityReport(pipelineId?: number) {
  return useQuery<ActivityReportRow[]>({
    queryKey: [QK, "activity-report", pipelineId],
    queryFn: () =>
      apiGet(`${BASE}/activity-report`, pipelineId ? { pipelineId } : {}),
  });
}
