import NextAuth from 'next-auth';
import Credentials from 'next-auth/providers/credentials';
import type { Provider } from 'next-auth/providers';
import { AuthError } from 'next-auth';

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
  '/api/register',
  '/api/auth-test',
];

const providers: Provider[] = [
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

        const userData = {
          usuario: username.includes('@') ? username.split('@')[0] : username,
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

        if (!response.ok) {
          let backendErrorCode = response.status.toString();
          let backendErrorMessage = 'Error de autenticacion';

          try {
            const payload = (await response.json()) as { error?: string; message?: string };
            backendErrorCode = String(payload?.error || backendErrorCode);
            backendErrorMessage = String(payload?.message || backendErrorMessage);
          } catch {
            const errorText = await response.text();
            backendErrorMessage = errorText || backendErrorMessage;
          }

          throw new CustomAuthError(
            backendErrorCode,
            `Error de autenticacion: ${backendErrorMessage}`
          );
        }

        const data = await response.json();

        if (!data || !data.token) {
          throw new CustomAuthError('no_token', 'No se recibio un token valido');
        }

        return {
          id: data.userId || data.usuario?.codUsuario || 'unknown',
          name: data.userName || data.usuario?.nombre || 'Usuario',
          email: data.email || null,
          token: data.token,
          isAdmin: data.isAdmin || data.usuario?.isAdmin || false,
          tipo: data.usuario?.tipo || null,
          permisos: data.permisos || null,
          modulos: data.modulos || [],
          company: data.company || null,
          companyAccesses: data.companyAccesses || [],
        };
      } catch (error: unknown) {
        if (error instanceof CustomAuthError) throw error;
        throw new CustomAuthError('unknown_error', 'Error en la autenticacion');
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
    async jwt({ token, user }) {
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
      // @ts-ignore
      session.accessToken = token.accessToken;
      // @ts-ignore
      session.accessTokenExpires = token.accessTokenExpires;
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
