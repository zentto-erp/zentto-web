"use client";

import React, { createContext, useContext, useEffect, useState, useMemo, type ReactNode } from "react";

// Minimal auth context that matches what shared-auth's useAuth() expects.
// Fetches the session from our fake /api/auth/session endpoint (auto-login).

type Company = {
  companyId: number;
  companyCode: string;
  companyName: string;
  branchId: number;
  branchCode: string;
  branchName: string;
  countryCode: string;
  timeZone: string;
};

type AuthContextType = {
  isAdmin: boolean;
  isLoading: boolean;
  isAuthenticated: boolean;
  userName: string | null;
  userEmail: string | null;
  userId: string | null;
  accessToken: string | null;
  tipo: string | null;
  permisos: Record<string, boolean>;
  modulos: string[];
  company: Company | null;
  companyAccesses: Company[];
  hasModule: (m: string) => boolean;
  signIn: (...args: any[]) => Promise<any>;
  signOut: (...args: any[]) => Promise<any>;
};

// We need to patch into the SAME context that shared-auth exports.
// Since shared-auth's AuthContext is the default export, we import it and provide to it.
// But that context requires SessionProvider... so instead we monkey-patch useAuth.

// Strategy: We provide context via the same React context object from shared-auth.
// shared-auth exports AuthContext as default.
import AuthContext from "@zentto/shared-auth/src/AuthContext";

export function LabAuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Record<string, any> | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch("/api/auth/session")
      .then((r) => (r.ok ? r.json() : null))
      .then((data) => {
        setSession(data);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, []);

  const value = useMemo<AuthContextType>(() => {
    if (!session) {
      return {
        isAdmin: false,
        isLoading: loading,
        isAuthenticated: false,
        userName: null,
        userEmail: null,
        userId: null,
        accessToken: null,
        tipo: null,
        permisos: {},
        modulos: [],
        company: null,
        companyAccesses: [],
        hasModule: () => true,
        signIn: async () => {},
        signOut: async () => {},
      };
    }

    return {
      isAdmin: session.isAdmin ?? true,
      isLoading: false,
      isAuthenticated: true,
      userName: session.userName || session.user?.name || null,
      userEmail: session.user?.email || null,
      userId: session.userId || null,
      accessToken: session.accessToken || null,
      tipo: session.tipo || "ADMIN",
      permisos: session.permisos || {},
      modulos: session.modulos || [],
      company: session.company || null,
      companyAccesses: session.companyAccesses || [],
      hasModule: () => true,
      signIn: async () => {},
      signOut: async () => {},
    };
  }, [session, loading]);

  return (
    <AuthContext.Provider value={value as any}>
      {children}
    </AuthContext.Provider>
  );
}
