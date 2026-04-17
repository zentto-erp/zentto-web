import NextAuth from 'next-auth';
import Credentials from 'next-auth/providers/credentials';
import Google from 'next-auth/providers/google';
import type { Provider } from 'next-auth/providers';
import { AuthError, CredentialsSignin } from 'next-auth';
import { getAuthClient } from '@/lib/auth-client';
import { AuthClientError } from '@zentto/auth-client';

// ─── Server-side access token store ───────────────────────────────────────────
// El accessToken de zentto-auth (~3KB) NO va en el JWT de NextAuth porque
// inflaría la cookie por encima del límite de nginx. Se guarda aquí en memoria
// del proceso y se recupera por userId en session() y en /api/auth/set-token.
//
// Trade-off aceptable: proceso restart limpia el store → zentto_token no puede
// renovarse hasta que el usuario haga login de nuevo. La cookie zentto_token
// existente (maxAge 12h) sigue siendo válida para las llamadas a la API.
type AccessTokenEntry = { token: string; expiresAt: number };
const accessTokenStore = new Map<string, AccessTokenEntry>();

export function getStoredAccessToken(userId: string): string | null {
  const entry = accessTokenStore.get(userId);
  if (!entry) return null;
  if (Date.now() >= entry.expiresAt) {
    accessTokenStore.delete(userId);
    return null;
  }
  return entry.token;
}

function storeAccessToken(userId: string, token: string, expiresAt: number | null): void {
  if (!userId || !token) return;
  accessTokenStore.set(userId, {
    token,
    expiresAt: expiresAt ?? Date.now() + 12 * 60 * 60 * 1000,
  });
}

// ─── Cache server-side de claims IAM por usuario ─────────────────────────────
// Los claims pesados (modulos, permisos, companyAccesses) NO van en
// el JWT/cookie de NextAuth porque inflarian el header mas alla del
// limite de Cloudflare. Los cargamos en cada session() callback con
// cache en memoria del proceso (TTL 60s) para no martillar zentto-auth.
type IamClaimsCache = {
  modulos: string[];
  permisos: Record<string, Record<string, boolean>>;
  companyAccesses: Array<Record<string, unknown>>;
  defaultCompany: Record<string, unknown> | null;
  loadedAt: number;
};
const iamCache = new Map<string, IamClaimsCache>();
const IAM_CACHE_TTL_MS = 60 * 1000;

async function loadIamClaimsForSession(
  userId: string,
  accessToken: string | null,
): Promise<IamClaimsCache | null> {
  const cached = iamCache.get(userId);
  if (cached && Date.now() - cached.loadedAt < IAM_CACHE_TTL_MS) {
    return cached;
  }

  if (!accessToken) return cached ?? null;

  try {
    // Server-to-server via @zentto/auth-client: pasamos el accessToken slim
    // como Bearer. zentto-auth acepta Bearer porque la request NO viene de
    // un browser (es el server del shell hablando con el microservicio).
    // El SDK timeoutea internamente; aqui ademas envolvemos en try/catch.
    const data = (await getAuthClient().me({
      appId: 'zentto-erp',
      accessToken,
    })) as unknown as {
      modulos?: IamClaimsCache['modulos'];
      permisos?: IamClaimsCache['permisos'];
      companyAccesses?: IamClaimsCache['companyAccesses'];
      defaultCompany?: IamClaimsCache['defaultCompany'];
    };

    const fresh: IamClaimsCache = {
      modulos: data.modulos ?? [],
      permisos: data.permisos ?? {},
      companyAccesses: data.companyAccesses ?? [],
      defaultCompany: data.defaultCompany ?? null,
      loadedAt: Date.now(),
    };
    iamCache.set(userId, fresh);
    return fresh;
  } catch {
    // Fallback al cache anterior si zentto-auth no respondio o devolvio error
    return cached ?? null;
  }
}

function getJwtExpMs(jwtToken: string | null | undefined): number | null {
  if (!jwtToken) return null;
  try {
    const parts = jwtToken.split('.');
    if (parts.length < 2) return null;
    const base64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
    const padded = base64 + '='.repeat((4 - (base64.length % 4)) % 4);
    const payload = JSON.parse(Buffer.from(padded, 'base64').toString('utf8')) as { exp?: number };
    if (!payload?.exp) return null;
    return payload.exp * 1000;
  } catch {
    return null;
  }
}

export class CustomAuthError extends AuthError {
  code: string;

  constructor(code: string, msg: string) {
    super();
    this.code = code;
    this.message = msg;
    this.stack = undefined;
  }
}

const PUBLIC_ROUTES = [
  '/authentication/login',
  '/authentication/register',
  '/authentication/forgot-password',
  '/authentication/reset-password',
  '/authentication/verify-email',
  '/api/auth',
  '/api/register',
  '/api/auth-test',
  '/registro',
];

const providers: Provider[] = [
  Google({
    clientId: process.env.AUTH_GOOGLE_ID,
    clientSecret: process.env.AUTH_GOOGLE_SECRET,
    authorization: {
      params: {
        prompt: 'consent',
        access_type: 'offline',
      },
    },
  }),
  Credentials({
    credentials: {
      username: { label: 'Usuario', type: 'text' },
      password: { label: 'Contrasena', type: 'password' },
      companyId: { label: 'Empresa', type: 'text' },
      branchId: { label: 'Sucursal', type: 'text' },
      captchaToken: { label: 'Captcha', type: 'text' },
    },
    authorize: async (credentials) => {
      try {
        // zentto-auth es OBLIGATORIO. Toda la auth pasa por @zentto/auth-client
        // (apps/shell/src/lib/auth-client.ts singleton).
        // Los claims los carga loadIamClaimsForSession() server-side sin
        // tocar la cookie de NextAuth.
        const incoming = credentials as
          | Partial<Record<'username' | 'password' | 'companyId' | 'branchId' | 'captchaToken', unknown>>
          | undefined;
        const username = typeof incoming?.username === 'string' ? incoming.username : undefined;
        const password = typeof incoming?.password === 'string' ? incoming.password : undefined;

        if (!username) {
          throw new CustomAuthError('invalid_credentials', 'Usuario es requerido');
        }

        type AuthLoginData = {
          user?: {
            userId?: string | number;
            username?: string;
            displayName?: string;
            email?: string | null;
            isAdmin?: boolean;
            userType?: string | null;
          };
          accessToken?: string;
        };

        let authData: AuthLoginData;
        try {
          authData = (await getAuthClient().login({
            username: username.trim().toUpperCase(),
            password: password || '',
          })) as unknown as AuthLoginData;
        } catch (err) {
          // El SDK lanza AuthClientError con status. 401/403/etc => credenciales invalidas.
          if (err instanceof AuthClientError) {
            throw new CredentialsSignin();
          }
          throw new CustomAuthError('upstream_error', 'No se pudo contactar al servicio de autenticacion');
        }

        if (!authData?.user || !authData?.accessToken || authData.user.userId == null) throw new CredentialsSignin();

        // JWT slim: solo id, name, email, token.
        // permisos/modulos/companyAccesses NO van aquí — los carga
        // loadIamClaimsForSession() en session() callback (server-side).
        const u = authData.user;

        // Almacenar el token en el store SERVER-SIDE ahora mismo.
        // En NextAuth v5 beta, los campos custom del return de authorize()
        // pueden no pasarse al jwt() callback (solo llegan id/name/email/image).
        // Guardarlo aquí garantiza que set-token lo encuentre sin importar eso.
        const expMs = getJwtExpMs(authData.accessToken);
        // String() garantiza clave string en el Map — u.userId llega como number
        // desde PG (integer) y token.sub en NextAuth es siempre string.
        // Sin este cast: Map.get("1") !== Map.get(1) → token_not_available → loop.
        storeAccessToken(String(u.userId), authData.accessToken, expMs);

        return {
          id: String(u.userId),
          name: u.displayName || u.username || null,
          email: u.email || null,
          token: authData.accessToken,
          isAdmin: u.isAdmin || false,
          tipo: u.userType || null,
        };
      } catch (error: unknown) {
        if (error instanceof CredentialsSignin) throw error;
        throw new CredentialsSignin();
      }
    },
  }),
];

// Cookie domain para que la sesión sea accesible desde sub-apps en *.zentto.net
// (por ejemplo posdev.zentto.net usa auth-proxy-route que necesita la cookie).
// En local/CI el NEXTAUTH_COOKIE_DOMAIN no está → sin domain (solo localhost).
const COOKIE_DOMAIN = process.env.NEXTAUTH_COOKIE_DOMAIN || undefined;

export const { handlers, auth, signIn, signOut } = NextAuth({
  providers,
  secret: process.env.AUTH_SECRET,
  pages: {
    signIn: '/authentication/login',
    error: '/authentication/login',
  },
  ...(COOKIE_DOMAIN && {
    cookies: {
      sessionToken: {
        name: '__Secure-next-auth.session-token',
        options: {
          httpOnly: true,
          sameSite: 'lax' as const,
          path: '/',
          secure: true,
          domain: COOKIE_DOMAIN,
        },
      },
    },
  }),
  callbacks: {
    async jwt({ token, user, account, trigger, session: updateData }) {
      // Switch company: actualizar store con nuevo accessToken
      if (trigger === 'update' && updateData?.accessToken) {
        const userId = token.sub;
        if (userId) {
          storeAccessToken(userId, updateData.accessToken, getJwtExpMs(updateData.accessToken));
        }
        token.accessTokenExpires = getJwtExpMs(updateData.accessToken);
        if (updateData.company) token.company = updateData.company;
        if (updateData.companyAccesses) token.companyAccesses = updateData.companyAccesses;
        // Limpiar accessToken del JWT si quedó de versión anterior
        // @ts-ignore
        delete token.accessToken;
        return token;
      }

      // Google OAuth: intercambiar token de Google por token del backend
      if (account?.provider === 'google' && account.id_token) {
        try {
          const BACKEND_URL =
            process.env.BACKEND_URL ||
            process.env.NEXT_PUBLIC_API_BASE_URL ||
            'http://localhost:4000';

          const res = await fetch(`${BACKEND_URL}/store/auth/google`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ idToken: account.id_token }),
          });

          if (res.ok) {
            const data = await res.json();
            if (data.token && token.sub) {
              storeAccessToken(token.sub, data.token, getJwtExpMs(data.token));
              token.accessTokenExpires = getJwtExpMs(data.token);
              token.isAdmin = false;
              token.modulos = ['ecommerce'];
              return token;
            }
          }
        } catch {
          // Si falla el backend, continuar con sesión básica de Google
        }
      }

      if (user) {
        // SLIM token: solo identidad básica. El accessToken (~3KB) va en
        // accessTokenStore (server-side) para no inflar la cookie de NextAuth.
        // @ts-ignore
        const at = user.token as string | undefined;
        const exp = at ? getJwtExpMs(at) : null;
        // Redundante con el storeAccessToken en authorize(), pero cubre el caso
        // donde authorize() guardó con clave numérica (antes del fix String()).
        if (token.sub && at) storeAccessToken(token.sub, at, exp);
        token.accessTokenExpires = exp;
        // @ts-ignore
        token.isAdmin = user.isAdmin;
        // @ts-ignore
        token.tipo = user.tipo;
        return token;
      }

      // Migración: JWT viejo puede tener token.accessToken — pasarlo al store y eliminarlo
      // para que la cookie se reduzca en el próximo ciclo.
      // @ts-ignore
      const legacyAt = token.accessToken as string | undefined;
      if (legacyAt && token.sub) {
        storeAccessToken(
          token.sub,
          legacyAt,
          // @ts-ignore
          (token.accessTokenExpires as number | undefined) ?? null,
        );
        // @ts-ignore
        delete token.accessToken;
      }

      return token;
    },

    async session({ session, token }) {
      // Garantizar que session.user.id esté siempre disponible.
      // NextAuth v5 beta puede no mapearlo automáticamente desde token.sub.
      if (token.sub) session.user.id = token.sub;

      // @ts-ignore
      session.accessTokenExpires = token.accessTokenExpires;
      // @ts-ignore
      session.isAdmin = token.isAdmin;
      // @ts-ignore
      session.tipo = token.tipo;

      // Cargar claims pesados desde zentto-auth /auth/me con el accessToken
      // slim como Bearer (server-to-server, sin browser). Cache 60s por user.
      // @ts-ignore
      const userId = (token.sub as string | undefined) ?? session?.user?.id;
      const accessToken = userId ? getStoredAccessToken(userId) : null;

      if (userId && accessToken) {
        const claims = await loadIamClaimsForSession(userId, accessToken);
        if (claims) {
          // @ts-ignore
          session.modulos = claims.modulos;
          // @ts-ignore
          session.permisos = claims.permisos;
          // @ts-ignore
          session.companyAccesses = claims.companyAccesses;
          // @ts-ignore
          session.company = claims.defaultCompany;
          // @ts-ignore
          session.defaultCompany = claims.defaultCompany;
        }
      }

      // NOTA: session.accessToken NO se expone aquí — el token viaja solo en
      // la cookie HttpOnly zentto_token (seteada por /api/auth/set-token que
      // lee directamente de getStoredAccessToken). Nunca llega al cliente.

      return session;
    },

    authorized({ auth: session, request: { nextUrl } }) {
      const isLoggedIn = !!session?.user;
      const isPublicRoute = PUBLIC_ROUTES.some((route) => nextUrl.pathname.startsWith(route));
      const isStaticAsset =
        nextUrl.pathname.startsWith('/_next') ||
        nextUrl.pathname.includes('/images/') ||
        nextUrl.pathname.includes('.png') ||
        nextUrl.pathname.includes('.svg');

      if (isPublicRoute || isStaticAsset) return true;
      return isLoggedIn;
    },
  },
});
