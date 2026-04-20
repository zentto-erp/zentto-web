"use client";

import React, {
  createContext,
  useContext,
  useCallback,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { useSession } from "next-auth/react";
import type { ActiveCompany, CompanyAccess } from "../types";
import {
  getActiveCompany,
  setActiveCompany as persistActiveCompany,
  subscribeActiveCompany,
} from "./activeCompany";

export interface CompanyContextValue {
  userId: string | null;
  companyAccesses: CompanyAccess[];
  activeCompany: ActiveCompany | null;
  isLoading: boolean;
  switchCompany: (companyId: number, branchId?: number | null) => void;
}

const CompanyContext = createContext<CompanyContextValue | undefined>(undefined);

interface CompanyProviderProps {
  children: ReactNode;
  /** Recarga la página cuando cambia la empresa. Default: true (invalida caches). */
  reloadOnSwitch?: boolean;
}

function resolveDefault(
  accesses: CompanyAccess[],
): ActiveCompany | null {
  if (!accesses || accesses.length === 0) return null;
  const preferred = accesses.find((a) => a.isDefault) ?? accesses[0];
  return toActive(preferred);
}

function toActive(access: CompanyAccess): ActiveCompany {
  return {
    companyId: access.companyId,
    branchId: access.branchId,
    companyCode: access.companyCode,
    branchCode: access.branchCode ?? undefined,
    countryCode: access.countryCode,
    timeZone: access.timeZone,
  };
}

export function CompanyProvider({
  children,
  reloadOnSwitch = true,
}: CompanyProviderProps) {
  const { data: session, status } = useSession();
  const isLoading = status === "loading";

  const sessionUnknown = session as unknown as {
    user?: { id?: string };
    companyAccesses?: CompanyAccess[];
    defaultCompany?: ActiveCompany | null;
  } | null;

  const userId = sessionUnknown?.user?.id ?? null;
  const companyAccesses = useMemo<CompanyAccess[]>(
    () =>
      Array.isArray(sessionUnknown?.companyAccesses)
        ? (sessionUnknown!.companyAccesses as CompanyAccess[])
        : [],
    [sessionUnknown],
  );

  const [activeCompany, setActive] = useState<ActiveCompany | null>(null);

  // Inicializar desde localStorage → defaultCompany → primer access
  useEffect(() => {
    if (!userId || companyAccesses.length === 0) return;

    const stored = getActiveCompany(userId);
    if (stored) {
      const match = companyAccesses.find(
        (a) =>
          a.companyId === stored.companyId &&
          (a.branchId ?? null) === (stored.branchId ?? null),
      );
      if (match) {
        setActive(toActive(match));
        return;
      }
    }

    const fallback =
      sessionUnknown?.defaultCompany ?? resolveDefault(companyAccesses);
    if (fallback) setActive(fallback);
  }, [userId, companyAccesses, sessionUnknown?.defaultCompany]);

  // Sync entre pestañas via storage event
  useEffect(() => {
    if (!userId) return;
    return subscribeActiveCompany(userId, (next) => {
      if (!next) {
        setActive(null);
        return;
      }
      const match = companyAccesses.find(
        (a) =>
          a.companyId === next.companyId &&
          (a.branchId ?? null) === (next.branchId ?? null),
      );
      setActive(match ? toActive(match) : next);
    });
  }, [userId, companyAccesses]);

  const switchCompany = useCallback(
    (companyId: number, branchId: number | null = null) => {
      if (!userId) return;
      if (
        activeCompany?.companyId === companyId &&
        (activeCompany?.branchId ?? null) === (branchId ?? null)
      ) {
        return;
      }
      const match = companyAccesses.find(
        (a) =>
          a.companyId === companyId &&
          (a.branchId ?? null) === (branchId ?? null),
      );
      if (!match) return;
      const next = toActive(match);
      persistActiveCompany(userId, next);
      setActive(next);
      if (reloadOnSwitch && typeof window !== "undefined") {
        window.location.reload();
      }
    },
    [userId, companyAccesses, activeCompany, reloadOnSwitch],
  );

  const value = useMemo<CompanyContextValue>(
    () => ({
      userId,
      companyAccesses,
      activeCompany,
      isLoading,
      switchCompany,
    }),
    [userId, companyAccesses, activeCompany, isLoading, switchCompany],
  );

  return (
    <CompanyContext.Provider value={value}>{children}</CompanyContext.Provider>
  );
}

export function useCompanyContext(): CompanyContextValue {
  const ctx = useContext(CompanyContext);
  if (!ctx) {
    throw new Error("useCompanyContext must be used within CompanyProvider");
  }
  return ctx;
}

export function useCompanyContextOptional(): CompanyContextValue | null {
  return useContext(CompanyContext) ?? null;
}
