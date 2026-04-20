"use client";

import { useCompanyContext } from "./CompanyProvider";
import type { ActiveCompany, CompanyAccess } from "../types";

export interface UseActiveCompanyResult {
  activeCompany: ActiveCompany | null;
  companyAccesses: CompanyAccess[];
  isLoading: boolean;
  switchCompany: (companyId: number, branchId?: number | null) => void;
}

/**
 * Hook para consumir la empresa activa y la lista de accesos.
 * Debe estar envuelto en `<CompanyProvider>`.
 */
export function useActiveCompany(): UseActiveCompanyResult {
  const { activeCompany, companyAccesses, isLoading, switchCompany } =
    useCompanyContext();
  return { activeCompany, companyAccesses, isLoading, switchCompany };
}
