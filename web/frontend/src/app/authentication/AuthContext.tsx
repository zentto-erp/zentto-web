"use client";

import React, { createContext, useContext, ReactNode, useMemo } from "react";
import { useSession, signIn, signOut } from "next-auth/react";

type AuthContextType = {
  isAdmin: boolean;
  isLoading: boolean;
  isAuthenticated: boolean;
  userName: string | null;
  userEmail: string | null;
  userId: string | null;
  accessToken: string | null;
  signIn: typeof signIn;
  signOut: typeof signOut;
};

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const { data: session, status } = useSession();
  const isLoading = status === "loading";
  const isAuthenticated = status === "authenticated";

  const value = useMemo<AuthContextType>(() => ({
    // @ts-ignore - isAdmin es añadido por nosotros en el callback session
    isAdmin: session?.isAdmin === true,
    isLoading,
    isAuthenticated,
    userName: session?.user?.name || null,
    userEmail: session?.user?.email || null,
    userId: session?.user?.id || null,
    // @ts-ignore - accessToken es añadido por nosotros
    accessToken: session?.accessToken || null,
    signIn,
    signOut,
  }), [session, status, isLoading, isAuthenticated]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}

export default AuthContext;
