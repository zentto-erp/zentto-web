import type { NextAuthConfig } from "next-auth";
import CredentialsProvider from "next-auth/providers/credentials";
import type { AuthClient } from "@zentto/auth-client";
import type { ActiveCompany, CompanyAccess } from "../types";

export interface BuildNextAuthConfigOptions {
  /** Identificador de la app vertical (ej. "zentto-hotel", "zentto-tickets"). */
  appId: string;
  /** Cliente del microservicio zentto-auth creado con `createAuthClient`. */
  authClient: AuthClient;
  /**
   * URL opcional para enriquecer el perfil tras el login (ej. el ERP vertical
   * API que retorna `companyAccesses`, `defaultCompany`, `roles`, etc). Se
   * llama con `Authorization: Bearer <accessToken>`.
   */
  profileUrl?: string;
  /** Overrides de las páginas de NextAuth. */
  pages?: NextAuthConfig["pages"];
  /** Duración de la sesión JWT en segundos. Default: 12h. */
  sessionMaxAge?: number;
  /** Auth secret. Default: process.env.AUTH_SECRET. */
  secret?: string;
}

interface ProfilePayload {
  userId?: string | number;
  userName?: string;
  isAdmin?: boolean;
  roles?: string[];
  modulos?: string[];
  permisos?: unknown;
  companyAccesses?: CompanyAccess[];
  defaultCompany?: ActiveCompany | null;
}

/**
 * Factory que genera la config de NextAuth v5 para apps verticales.
 *
 * Importante: el provider usa `{ username, password }` (NO `email`). Cambiar
 * este contrato ha roto los logins de hotel y tickets en el pasado.
 */
export function buildNextAuthConfig(
  opts: BuildNextAuthConfigOptions,
): NextAuthConfig {
  const {
    authClient,
    profileUrl,
    pages,
    sessionMaxAge = 12 * 60 * 60,
    secret = process.env.AUTH_SECRET,
  } = opts;

  return {
    trustHost: true,
    secret,
    session: { strategy: "jwt", maxAge: sessionMaxAge },
    pages: { signIn: "/login", ...pages },
    providers: [
      CredentialsProvider({
        name: "Zentto",
        credentials: {
          username: { label: "Usuario", type: "text" },
          password: { label: "Contraseña", type: "password" },
        },
        async authorize(credentials) {
          const username = credentials?.username as string | undefined;
          const password = credentials?.password as string | undefined;
          if (!username || !password) return null;

          let loginData: {
            user?: {
              userId?: string | number;
              username?: string;
              displayName?: string;
              email?: string;
              isAdmin?: boolean;
              roles?: string[];
              companyAccesses?: CompanyAccess[];
            };
            accessToken?: string;
            refreshToken?: string;
          };

          try {
            const raw = await authClient.login({ username, password });
            // Si es un MfaChallenge, no lo manejamos aquí — el flujo TOTP es del app.
            if ((raw as { mfaRequired?: boolean }).mfaRequired) return null;
            loginData = raw as typeof loginData;
          } catch {
            return null;
          }

          if (!loginData.user) return null;

          const accessToken = loginData.accessToken ?? "";
          const refreshToken = loginData.refreshToken;
          const userId = String(
            loginData.user.userId ?? loginData.user.username ?? "",
          );
          const userName =
            loginData.user.displayName ?? loginData.user.username ?? "";

          let profile: ProfilePayload = {};
          if (profileUrl && accessToken) {
            try {
              const res = await fetch(profileUrl, {
                headers: { Authorization: `Bearer ${accessToken}` },
              });
              if (res.ok) {
                profile = (await res.json()) as ProfilePayload;
              }
            } catch {
              /* profile endpoint unavailable — continuar sin enriquecer */
            }
          }

          return {
            id: String(profile.userId ?? userId),
            name: profile.userName ?? userName,
            email: loginData.user.email,
            accessToken,
            refreshToken,
            isAdmin: profile.isAdmin ?? loginData.user.isAdmin ?? false,
            roles: profile.roles ?? loginData.user.roles ?? [],
            modulos: profile.modulos ?? [],
            permisos: profile.permisos ?? null,
            companyAccesses:
              profile.companyAccesses ?? loginData.user.companyAccesses ?? [],
            defaultCompany: profile.defaultCompany ?? null,
          } as unknown as Record<string, unknown>;
        },
      }),
    ],
    callbacks: {
      async jwt({ token, user }) {
        if (user) {
          const u = user as Record<string, unknown>;
          token.accessToken = u.accessToken;
          token.refreshToken = u.refreshToken;
          token.isAdmin = u.isAdmin;
          token.roles = u.roles;
          token.modulos = u.modulos;
          token.permisos = u.permisos;
          token.companyAccesses = u.companyAccesses;
          token.defaultCompany = u.defaultCompany;
        }

        // Auto-refresh si el accessToken expiró
        const accessToken = token.accessToken as string | undefined;
        if (accessToken) {
          try {
            const [, payloadB64] = accessToken.split(".");
            if (payloadB64) {
              const payload = JSON.parse(
                Buffer.from(payloadB64, "base64").toString(),
              ) as { exp?: number };
              if (payload.exp && payload.exp * 1000 < Date.now()) {
                try {
                  const refreshed = await authClient.refresh();
                  const rr = refreshed as unknown as {
                    accessToken?: string;
                    refreshToken?: string;
                  };
                  if (rr?.accessToken) {
                    token.accessToken = rr.accessToken;
                    token.refreshToken = rr.refreshToken ?? token.refreshToken;
                  } else {
                    token.error = "RefreshAccessTokenError";
                  }
                } catch {
                  token.error = "RefreshAccessTokenError";
                }
              }
            }
          } catch {
            /* token malformado — ignorar */
          }
        }

        return token;
      },
      async session({ session, token }) {
        const s = session as unknown as Record<string, unknown>;
        s.accessToken = token.accessToken;
        s.isAdmin = token.isAdmin;
        s.roles = token.roles;
        s.modulos = token.modulos;
        s.permisos = token.permisos;
        s.companyAccesses = token.companyAccesses;
        s.defaultCompany = token.defaultCompany;
        s.error = token.error;
        return session;
      },
    },
  };
}
