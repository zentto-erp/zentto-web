"use client";

import React, { createContext, useContext, ReactNode, useMemo, useEffect } from "react";
import { useSession, signIn, signOut } from "next-auth/react";
import type { UserPermisos } from "./roles";
import { getDefaultPermisos, hasModuleAccess, getEffectiveModules } from "./roles";
import type { SystemModule } from "./roles";

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
  /** Check if user can access a specific module */
  hasModule: (modulo: SystemModule) => boolean;
  signIn: typeof signIn;
  signOut: typeof signOut;
};

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const { data: session, status } = useSession();
  const isLoading = status === "loading";
  const isAuthenticated = status === "authenticated";

  useEffect(() => {
    if (!session) return;
    // @ts-ignore
    const expiresAt = session?.accessTokenExpires as number | undefined;
    if (!expiresAt) return;

    const msRemaining = expiresAt - Date.now();
    if (msRemaining <= 0) {
      void signOut({ callbackUrl: "/authentication/login" });
      return;
    }

    const timeout = window.setTimeout(() => {
      void signOut({ callbackUrl: "/authentication/login" });
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
      userId: session?.user?.id || null,
      // @ts-ignore
      accessToken: session?.accessToken || null,
      tipo,
      permisos,
      modulos,
      hasModule: (modulo: SystemModule) => hasModuleAccess(rawModulos, modulo, isAdmin),
      signIn,
      signOut,
    };
  }, [session, status, isLoading, isAuthenticated]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}

export default AuthContext;
