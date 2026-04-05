"use client";

import React, { createContext, useContext, ReactNode, useMemo, useEffect, useState, useCallback } from "react";
import { useSession, signIn, signOut } from "next-auth/react";
import type { UserPermisos } from "./roles";
import { getDefaultPermisos, hasModuleAccess, getEffectiveModules } from "./roles";
import type { SystemModule } from "./roles";
import { appAwareSignOut, buildLoginCallbackUrl } from "./auth-client";
import { setActiveCompanyForApi } from "@zentto/shared-api";

export type AuthContextType = {
  isAdmin: boolean;
  isLoading: boolean;
  isAuthenticated: boolean;
  userName: string | null;
  userEmail: string | null;
  userId: string | null;
  accessToken: string | null;
  tipo: string | null;
  permisos: UserPermisos;
  modulos: string[];
  company: {
    companyId: number;
    companyCode: string;
    companyName: string;
    branchId: number;
    branchCode: string;
    branchName: string;
    countryCode: string;
    timeZone: string;
  } | null;
  companyAccesses: Array<{
    companyId: number;
    companyCode: string;
    companyName: string;
    branchId: number;
    branchCode: string;
    branchName: string;
    countryCode: string;
    timeZone: string;
    isDefault?: boolean;
  }>;
  /** Switch active company without re-login */
  setActiveCompany: (companyId: number, branchId: number) => void;
  /** Check if user can access a specific module */
  hasModule: (modulo: SystemModule) => boolean;
  signIn: typeof signIn;
  signOut: typeof signOut;
};

const AuthContext = createContext<AuthContextType | undefined>(undefined);

function getStorageKey(userId: string | null) {
  return `zentto-active-company:${userId ?? "anon"}`;
}

function loadActiveCompanyFromStorage(userId: string | null): { companyId: number; branchId: number } | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = localStorage.getItem(getStorageKey(userId));
    if (!raw) return null;
    const parsed = JSON.parse(raw);
    if (parsed?.companyId && parsed?.branchId) return parsed;
  } catch { /* ignore */ }
  return null;
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const { data: session, status } = useSession();
  const isLoading = status === "loading";
  const isAuthenticated = status === "authenticated";

  // @ts-ignore
  const companyAccesses = Array.isArray(session?.companyAccesses) ? session.companyAccesses : [];
  const userId = session?.user?.id || null;
  // @ts-ignore
  const defaultCompany = session?.defaultCompany || session?.company || null;

  const [activeCompanyState, setActiveCompanyState] = useState<{
    companyId: number;
    branchId: number;
  } | null>(null);

  // Setear cookie HttpOnly zentto_token en el browser después del login
  useEffect(() => {
    if (!isAuthenticated) return;
    // Llama al cookie proxy para que el browser tenga zentto_token
    fetch("/api/auth/set-token", { method: "POST", credentials: "include" }).catch(() => {});
  }, [isAuthenticated]);

  // Inicializar activeCompany desde localStorage → defaultCompany → primer acceso
  useEffect(() => {
    if (!isAuthenticated || companyAccesses.length === 0) return;
    const stored = loadActiveCompanyFromStorage(userId);
    if (stored) {
      const valid = companyAccesses.find(
        (a: any) => a.companyId === stored.companyId && a.branchId === stored.branchId
      );
      if (valid) {
        setActiveCompanyState(stored);
        return;
      }
    }
    if (defaultCompany) {
      setActiveCompanyState({ companyId: defaultCompany.companyId, branchId: defaultCompany.branchId });
    } else {
      setActiveCompanyState({ companyId: companyAccesses[0].companyId, branchId: companyAccesses[0].branchId });
    }
  }, [isAuthenticated, userId, companyAccesses.length]);

  // Resolver la empresa activa completa desde companyAccesses
  const activeCompany = useMemo(() => {
    if (!activeCompanyState || companyAccesses.length === 0) return defaultCompany;
    return companyAccesses.find(
      (a: any) => a.companyId === activeCompanyState.companyId && a.branchId === activeCompanyState.branchId
    ) ?? defaultCompany;
  }, [activeCompanyState, companyAccesses, defaultCompany]);

  // Sincronizar con API client
  useEffect(() => {
    if (activeCompany) {
      setActiveCompanyForApi(activeCompany);
    }
  }, [activeCompany]);

  // Sync entre tabs via storage event
  useEffect(() => {
    if (typeof window === "undefined") return;
    const key = getStorageKey(userId);
    const handler = (e: StorageEvent) => {
      if (e.key !== key || !e.newValue) return;
      try {
        const parsed = JSON.parse(e.newValue);
        if (parsed?.companyId && parsed?.branchId) {
          setActiveCompanyState(parsed);
        }
      } catch { /* ignore */ }
    };
    window.addEventListener("storage", handler);
    return () => window.removeEventListener("storage", handler);
  }, [userId]);

  const setActiveCompany = useCallback((companyId: number, branchId: number) => {
    if (activeCompany?.companyId === companyId && activeCompany?.branchId === branchId) return;
    const valid = companyAccesses.find(
      (a: any) => a.companyId === companyId && a.branchId === branchId
    );
    if (!valid) return;
    if (typeof window !== "undefined") {
      localStorage.setItem(getStorageKey(userId), JSON.stringify({ companyId, branchId }));
      window.location.reload();
    }
  }, [companyAccesses, userId, activeCompany]);

  // Token expiration auto-logout
  useEffect(() => {
    if (!session) return;
    // @ts-ignore
    const expiresAt = session?.accessTokenExpires as number | undefined;
    if (!expiresAt) return;

    const msRemaining = expiresAt - Date.now();
    if (msRemaining <= 0) {
      void appAwareSignOut({ callbackUrl: buildLoginCallbackUrl() });
      return;
    }

    const timeout = window.setTimeout(() => {
      void appAwareSignOut({ callbackUrl: buildLoginCallbackUrl() });
    }, msRemaining);

    return () => window.clearTimeout(timeout);
  }, [session]);

  const value = useMemo<AuthContextType>(() => {
    // @ts-ignore – extended session properties from auth.ts callbacks
    const isAdmin = session?.isAdmin === true;
    // @ts-ignore
    const tipo = session?.tipo || null;
    // @ts-ignore
    const permisos: UserPermisos = session?.permisos || getDefaultPermisos();
    // @ts-ignore
    const rawModulos: string[] | null = session?.modulos;
    const modulos = getEffectiveModules(rawModulos, isAdmin);

    return {
      isAdmin,
      isLoading,
      isAuthenticated,
      userName: session?.user?.name || null,
      userEmail: session?.user?.email || null,
      userId,
      // accessToken NO se usa en el browser — cookie HttpOnly zentto_token viaja automáticamente
      accessToken: null,
      tipo,
      permisos,
      modulos,
      company: activeCompany,
      companyAccesses,
      setActiveCompany,
      hasModule: (modulo: SystemModule) => hasModuleAccess(rawModulos, modulo, isAdmin),
      signIn,
      signOut,
    };
  }, [session, status, isLoading, isAuthenticated, activeCompany, companyAccesses, setActiveCompany, userId]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}

/** Like useAuth but returns null instead of throwing when outside AuthProvider */
export function useAuthOptional(): AuthContextType | null {
  return useContext(AuthContext) ?? null;
}

export default AuthContext;
