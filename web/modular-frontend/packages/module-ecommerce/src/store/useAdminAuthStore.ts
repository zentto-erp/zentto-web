"use client";

import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";

export interface CompanyAccess {
  companyId: number;
  companyCode: string;
  companyName: string;
  branchId: number | null;
  branchCode: string | null;
  branchName: string | null;
  countryCode: string;
  isDefault: boolean;
}

export interface AdminUser {
  sub: string;
  name: string;
  email: string;
  isAdmin: boolean;
}

interface AdminAuthState {
  token: string | null;
  user: AdminUser | null;
  companyAccesses: CompanyAccess[];
  activeCompanyId: number | null;
  activeBranchId: number | null;
  setAuth: (
    token: string,
    user: AdminUser,
    companyAccesses: CompanyAccess[],
    defaultCompanyId: number | null,
    defaultBranchId: number | null
  ) => void;
  setActiveCompany: (companyId: number, branchId: number | null) => void;
  clearAuth: () => void;
}

export const useAdminAuthStore = create<AdminAuthState>()(
  persist(
    (set) => ({
      token: null,
      user: null,
      companyAccesses: [],
      activeCompanyId: null,
      activeBranchId: null,
      setAuth: (token, user, companyAccesses, defaultCompanyId, defaultBranchId) =>
        set({ token, user, companyAccesses, activeCompanyId: defaultCompanyId, activeBranchId: defaultBranchId }),
      setActiveCompany: (companyId, branchId) =>
        set({ activeCompanyId: companyId, activeBranchId: branchId }),
      clearAuth: () =>
        set({ token: null, user: null, companyAccesses: [], activeCompanyId: null, activeBranchId: null }),
    }),
    {
      name: "zentto_admin_auth",
      storage: createJSONStorage(() =>
        typeof window !== "undefined" ? window.localStorage : ({} as Storage)
      ),
    }
  )
);
