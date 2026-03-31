/**
 * IAM Module — Shared types for Identity & Access Management.
 *
 * Consolidates types for roles, permissions, license enforcement,
 * and audit across the Zentto ERP platform.
 */

export interface LimitCheckResult {
  allowed: boolean;
  current: number;
  max: number | null;
  plan: string;
}

export interface CompanyLimitResult extends LimitCheckResult {
  multiCompanyEnabled: boolean;
}

export interface LicenseLimits {
  maxUsers: number | null;
  currentUsers: number;
  maxCompanies: number | null;
  currentCompanies: number;
  maxBranches: number | null;
  currentBranches: number;
  multiCompanyEnabled: boolean;
  plan: string;
}

export interface IamChangeLogEntry {
  changeType: "ROLE_CREATED" | "ROLE_DELETED" | "PERMISSION_CHANGED" | "ROLE_ASSIGNED" | "PLAN_SYNCED" | "LIMIT_ADJUSTED";
  entityType: "ROLE" | "PERMISSION" | "USER_ROLE" | "LICENSE" | "PLAN";
  entityId: number | string;
  oldValue: string | null;
  newValue: string | null;
  userId: number;
}
