import NextAuth from 'next-auth';
import Credentials from 'next-auth/providers/credentials';
import Google from 'next-auth/providers/google';
import type { Provider } from 'next-auth/providers';
import { AuthError, CredentialsSignin } from 'next-auth';

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
        const BACKEND_URL =
          process.env.BACKEND_URL ||
          process.env.NEXT_PUBLIC_API_BASE ||
          process.env.NEXT_PUBLIC_API_BASE_URL ||
          process.env.NEXT_PUBLIC_API_URL ||
          process.env.NEXT_PUBLIC_BACKEND_URL ||
          process.env.API_URL ||
          'http://localhost:4000';

        // zentto-auth microservice URL (centralizado para todas las apps)
        const AUTH_SERVICE_URL =
          process.env.AUTH_SERVICE_URL ||
          process.env.NEXT_PUBLIC_AUTH_URL ||
          '';

        const incoming = credentials as
          | Partial<Record<'username' | 'password' | 'companyId' | 'branchId' | 'captchaToken', unknown>>
          | undefined;
        const username = typeof incoming?.username === 'string' ? incoming.username : undefined;
        const password = typeof incoming?.password === 'string' ? incoming.password : undefined;
        const captchaToken =
          typeof incoming?.captchaToken === 'string' ? incoming.captchaToken : undefined;

        if (!username) {
          throw new CustomAuthError('invalid_credentials', 'Usuario es requerido');
        }

        const companyId =
          typeof incoming?.companyId === 'string' ? Number(incoming.companyId) : undefined;
        const branchId =
          typeof incoming?.branchId === 'string' ? Number(incoming.branchId) : undefined;

        // ── Estrategia primaria: zentto-auth con JWT enriquecido ─────
        // zentto-auth ahora devuelve modulos, permisos y companyAccesses
        // directamente en el token + en el response body. No necesitamos
        // el round-trip a /v1/auth/profile del ERP — todo viene del IAM
        // central.
        if (AUTH_SERVICE_URL) {
          const authRes = await fetch(`${AUTH_SERVICE_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              username: username.trim().toUpperCase(),
              password: password || '',
              appId: 'zentto-erp',
            }),
          });

          if (!authRes.ok) throw new CredentialsSignin();

          const authData = await authRes.json();
          if (!authData.user || !authData.accessToken) throw new CredentialsSignin();

          // Mapear directamente al shape que NextAuth + AuthContext esperan
          const u = authData.user;
          return {
            id: u.userId,
            name: u.displayName || u.username,
            email: u.email || null,
            token: authData.accessToken,
            isAdmin: u.isAdmin || false,
            tipo: u.userType || null,
            permisos: u.permisos || null,
            modulos: u.modulos || [],
            company: u.defaultCompany || null,
            defaultCompany: u.defaultCompany || null,
            companyAccesses: u.companyAccesses || [],
          };
        } else {
          // ── Modo legacy: autenticar directo contra ERP API ──
          const userData = {
            usuario: username.trim().toUpperCase(),
            clave: password || '',
            companyId: Number.isFinite(companyId) && Number(companyId) > 0 ? Number(companyId) : undefined,
            branchId: Number.isFinite(branchId) && Number(branchId) > 0 ? Number(branchId) : undefined,
            captchaToken,
          };

          const response = await fetch(`${BACKEND_URL}/v1/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(userData),
          });

          if (!response.ok) throw new CredentialsSignin();
          const data = await response.json();
          if (!data?.token) throw new CredentialsSignin();

          return {
            id: data.userId || data.usuario?.codUsuario || 'unknown',
            name: data.userName || data.usuario?.nombre || 'Usuario',
            email: data.email || null,
            token: data.token,
            isAdmin: data.isAdmin || data.usuario?.isAdmin || false,
            tipo: data.usuario?.tipo || null,
            permisos: data.permisos || null,
            modulos: data.modulos || [],
            company: data.defaultCompany || data.company || null,
            defaultCompany: data.defaultCompany || data.company || null,
            companyAccesses: data.companyAccesses || [],
          };
        }

        // No deberiamos llegar aqui — los dos branches anteriores
        // (zentto-auth o ERP fallback) ya retornan. Si caemos aqui,
        // algo esta mal en el flujo.
        throw new CredentialsSignin();
      } catch (error: unknown) {
        if (error instanceof CredentialsSignin) throw error;
        throw new CredentialsSignin();
      }
    },
  }),
];

export const { handlers, auth, signIn, signOut } = NextAuth({
  providers,
  secret: process.env.AUTH_SECRET,
  pages: {
    signIn: '/authentication/login',
    error: '/authentication/login',
  },
  callbacks: {
    async jwt({ token, user, account, trigger, session: updateData }) {
      // Switch company: actualizar token con nuevos datos de empresa
      if (trigger === 'update' && updateData?.accessToken) {
        token.accessToken = updateData.accessToken;
        token.accessTokenExpires = getJwtExpMs(updateData.accessToken);
        if (updateData.company) token.company = updateData.company;
        if (updateData.companyAccesses) token.companyAccesses = updateData.companyAccesses;
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
            if (data.token) {
              token.accessToken = data.token;
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
        // @ts-ignore
        token.accessToken = user.token;
        // @ts-ignore
        token.accessTokenExpires = getJwtExpMs(user.token as string);
        // @ts-ignore
        token.isAdmin = user.isAdmin;
        // @ts-ignore
        token.tipo = user.tipo;
        // @ts-ignore
        token.permisos = user.permisos;
        // @ts-ignore
        token.modulos = user.modulos;
        // @ts-ignore
        token.company = user.company;
        // @ts-ignore
        token.defaultCompany = user.defaultCompany;
        // @ts-ignore
        token.companyAccesses = user.companyAccesses;
      }

      // @ts-ignore
      const accessTokenExpires = token.accessTokenExpires as number | undefined;
      if (accessTokenExpires && Date.now() >= accessTokenExpires) {
        // @ts-ignore
        token.accessToken = null;
      }

      return token;
    },
    async session({ session, token }) {
      // accessToken viaja en cookie HttpOnly zentto_token (via /api/auth/set-token).
      // Se expone SOLO para que el cookie proxy pueda leerlo server-side.
      // El browser NO lo usa en Authorization headers — 100% cookies.
      // @ts-ignore
      session.accessToken = token.accessToken;
      // @ts-ignore
      session.isAdmin = token.isAdmin;
      // @ts-ignore
      session.tipo = token.tipo;
      // @ts-ignore
      session.permisos = token.permisos;
      // @ts-ignore
      session.modulos = token.modulos;
      // @ts-ignore
      session.company = token.company;
      // @ts-ignore
      session.defaultCompany = token.defaultCompany;
      // @ts-ignore
      session.companyAccesses = token.companyAccesses;
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
