"use client";

import { createContext, useContext, useState, useCallback, type ReactNode } from "react";

const SESSION_KEY = "bo_session_token";

interface BackofficeContextType {
  token: string;
  isSet: boolean;
  save: (t: string) => void;
  clear: () => void;
}

const BackofficeContext = createContext<BackofficeContextType>({
  token: "",
  isSet: false,
  save: () => {},
  clear: () => {},
});

export function BackofficeProvider({ children }: { children: ReactNode }) {
  const [token, setToken] = useState<string>(() => {
    if (typeof window !== "undefined") {
      return sessionStorage.getItem(SESSION_KEY) ?? "";
    }
    return "";
  });

  const save = useCallback((t: string) => {
    sessionStorage.setItem(SESSION_KEY, t);
    setToken(t);
  }, []);

  const clear = useCallback(() => {
    sessionStorage.removeItem(SESSION_KEY);
    setToken("");
  }, []);

  return (
    <BackofficeContext.Provider value={{ token, isSet: !!token, save, clear }}>
      {children}
    </BackofficeContext.Provider>
  );
}

export function useBackoffice() {
  return useContext(BackofficeContext);
}

// ─── Fetcher con Session Token ────────────────────────────────────────────────

export async function apiFetch<T>(
  path: string,
  sessionToken: string,
  options: RequestInit = {}
): Promise<T> {
  const base = process.env.NEXT_PUBLIC_API_URL ?? "/api";
  const res = await fetch(`${base}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      "X-Backoffice-Token": sessionToken,
      ...(options.headers ?? {}),
    },
  });
  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(`${res.status}: ${text || res.statusText}`);
  }
  return res.json() as Promise<T>;
}

// ─── Tipos compartidos ──────────────────────────────────────────────────────

export interface DashboardData {
  TotalTenants: number;
  MRR: number;
  TotalDbMB: number;
  CleanupPending: number;
  TicketsOpen?: number;
  TicketsClosed?: number;
  TicketsUrgent?: number;
  TicketsAiPending?: number;
  TicketsAiResolved?: number;
}

export interface TenantRow {
  id: number;
  CompanyId: number;
  CompanyCode: string;
  LegalName: string;
  Plan: string;
  LicenseType: string;
  LicenseStatus: string;
  ExpiresAt: string | null;
  UserCount: number;
  LastLogin: string | null;
}

export interface ResourceRow {
  id: number;
  CompanyId: number;
  CompanyCode: string;
  LegalName: string;
  DbSizeMB: number;
  LastLoginAt: string | null;
  Status: string;
}

export interface CleanupRow {
  id: number;
  QueueId: number;
  CompanyCode: string;
  LegalName: string;
  Reason: string;
  Status: string;
  FlaggedAt: string;
  DeleteAfter: string;
  DaysUntilDelete: number;
}

export interface BackupRow {
  id: number;
  CompanyId: number;
  CompanyCode: string;
  LegalName: string;
  LastBackupAt: string | null;
  BackupSizeMB: number | null;
  BackupStatus: string;
}

export const PLAN_OPTIONS = ["FREE", "STARTER", "PRO", "ENTERPRISE"];

export const STATUS_COLORS: Record<
  string,
  "default" | "success" | "warning" | "error" | "info"
> = {
  ACTIVE: "success",
  INACTIVE: "default",
  SUSPENDED: "error",
  TRIAL: "warning",
  PENDING: "warning",
  NOTIFIED: "info",
  CONFIRMED: "error",
  CANCELLED: "default",
  OK: "success",
  FAILED: "error",
  RUNNING: "info",
};
