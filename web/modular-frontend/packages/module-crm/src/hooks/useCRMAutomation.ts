"use client";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost, apiPut, apiDelete } from "@zentto/shared-api";

const BASE = "/api/v1/crm";
const QK_RULES = "crm-automation-rules";
const QK_STALE = "crm-stale-leads";
const QK_LOGS = "crm-automation-logs";

/* ─── Types ────────────────────────────────────────────────── */

export interface AutomationRule {
  RuleId: number;
  RuleName: string;
  TriggerEvent: string; // LEAD_STALE, STAGE_CHANGE, NO_ACTIVITY, SCORE_BELOW, LEAD_CREATED
  ConditionJson: Record<string, any>;
  ActionType: string; // NOTIFY, ASSIGN, MOVE_STAGE, CREATE_ACTIVITY, SEND_EMAIL
  ActionConfig: Record<string, any>;
  IsActive: boolean;
  SortOrder: number;
  CreatedAt: string;
}

export interface StaleLead {
  LeadId: number;
  LeadCode: string;
  ContactName: string;
  CompanyName: string;
  StageName: string;
  EstimatedValue: number;
  DaysSinceLastActivity: number;
  AssignedToName: string;
}

export interface AutomationLog {
  LogId: number;
  RuleId: number;
  RuleName: string;
  LeadId: number;
  LeadCode: string;
  ActionTaken: string;
  ActionResult: string;
  ExecutedAt: string;
}

/* ─── Hooks ────────────────────────────────────────────────── */

/** Lista todas las reglas de automatizacion */
export function useAutomationRules() {
  return useQuery<AutomationRule[]>({
    queryKey: [QK_RULES],
    queryFn: () => apiGet(`${BASE}/automations`),
  });
}

/** Crear o actualizar una regla */
export function useUpsertRule() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (rule: Partial<AutomationRule> & { RuleName: string }) => {
      if (rule.RuleId) {
        return apiPut(`${BASE}/automations/${rule.RuleId}`, rule);
      }
      return apiPost(`${BASE}/automations`, rule);
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [QK_RULES] });
    },
  });
}

/** Eliminar una regla */
export function useDeleteRule() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (ruleId: number) => apiDelete(`${BASE}/automations/${ruleId}`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [QK_RULES] });
    },
  });
}

/** Ejecutar evaluacion de reglas sobre leads activos */
export function useEvaluateRules() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: () => apiPost(`${BASE}/automations/evaluate`, {}),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [QK_STALE] });
      qc.invalidateQueries({ queryKey: [QK_LOGS] });
    },
  });
}

/** Leads estancados */
export function useStaleLeads(days?: number, pipelineId?: number) {
  const params = new URLSearchParams();
  if (days) params.set("days", String(days));
  if (pipelineId) params.set("pipelineId", String(pipelineId));
  const qs = params.toString();

  return useQuery<StaleLead[]>({
    queryKey: [QK_STALE, days, pipelineId],
    queryFn: () => apiGet(`${BASE}/leads/stale${qs ? `?${qs}` : ""}`),
  });
}

/** Logs de automatizacion */
export function useAutomationLogs(ruleId?: number, leadId?: number) {
  const params = new URLSearchParams();
  if (ruleId) params.set("ruleId", String(ruleId));
  if (leadId) params.set("leadId", String(leadId));
  const qs = params.toString();

  return useQuery<AutomationLog[]>({
    queryKey: [QK_LOGS, ruleId, leadId],
    queryFn: () => apiGet(`${BASE}/automations/logs${qs ? `?${qs}` : ""}`),
  });
}
