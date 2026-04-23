"use client";

/**
 * useAdminLogin — Autenticación de administradores del ecommerce.
 *
 * Delega al microservicio zentto-auth (NEXT_PUBLIC_AUTH_URL, default auth.zentto.net).
 * El accessToken resultante es un JWT firmado con el mismo JWT_SECRET que usa
 * el API de DatqBoxWeb, por lo que `requireJwt` lo acepta directamente.
 *
 * El response de zentto-auth incluye `companyAccesses` (lista de empresas/sucursales
 * a las que tiene acceso el admin) y `defaultCompany`. Se persisten en
 * useAdminAuthStore para que el selector de empresa del panel pueda usarlos.
 *
 * Los clientes del store usan un flujo distinto (/store/auth/login).
 */

import { useMutation } from "@tanstack/react-query";
import { useAdminAuthStore, type CompanyAccess } from "../store/useAdminAuthStore";

const AUTH_BASE =
  typeof window !== "undefined"
    ? process.env.NEXT_PUBLIC_AUTH_URL || "https://auth.zentto.net"
    : "https://auth.zentto.net";

export function useAdminLogin() {
  const setAuth = useAdminAuthStore((s) => s.setAuth);

  return useMutation({
    mutationFn: async (payload: { username: string; password: string }) => {
      const res = await fetch(`${AUTH_BASE}/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({
          username: payload.username,
          password: payload.password,
          appId: "zentto-web",
        }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(data?.message || data?.error || "login_failed");
      return data;
    },
    onSuccess: (data: any) => {
      if (!data?.accessToken) throw new Error("no_token");
      if (!data?.user?.isAdmin) throw new Error("not_admin");

      // El backend de zentto-auth expone companyAccesses y defaultCompany
      // DENTRO de data.user (shape: { user: { companyAccesses: [...], defaultCompany: {} } }).
      // Fallback al top-level por si cambia en el futuro.
      const rawAccesses =
        data.user?.companyAccesses ??
        data.companyAccesses ??
        [];
      const companyAccesses: CompanyAccess[] = Array.isArray(rawAccesses) ? rawAccesses : [];

      const defaultCompany: CompanyAccess | null =
        data.user?.defaultCompany ??
        data.defaultCompany ??
        companyAccesses.find((c) => c.isDefault) ??
        companyAccesses[0] ??
        null;

      setAuth(
        data.accessToken,
        {
          sub: data.user.sub ?? data.user.userId ?? "",
          name: data.user.displayName ?? data.user.username ?? "",
          email: data.user.email ?? "",
          isAdmin: true,
        },
        companyAccesses,
        defaultCompany?.companyId ?? null,
        defaultCompany?.branchId ?? null
      );
    },
  });
}

export function useAdminLogout() {
  const clearAuth = useAdminAuthStore((s) => s.clearAuth);
  return clearAuth;
}
