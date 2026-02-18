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
  '/api/register',
  '/api/auth-test',
];

const providers: Provider[] = [
  Credentials({
    credentials: {
      username: { label: 'Usuario', type: 'text' },
      password: { label: 'Contraseña', type: 'password' },
    },
    authorize: async (credentials) => {
      try {
        const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:3001';

        const username = credentials?.username as string | undefined;
        const password = credentials?.password as string | undefined;

        if (!username) {
          throw new CustomAuthError('invalid_credentials', 'Usuario es requerido');
        }

        const userData = {
          usuario: username.includes('@')
            ? username.split('@')[0]
            : username,
          clave: password || '',
        };

        const response = await fetch(`${BACKEND_URL}/v1/auth/login`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(userData),
        });

        if (!response.ok) {
          const errorText = await response.text();
          throw new CustomAuthError(
            response.status.toString(),
            `Error de autenticación: ${errorText}`
          );
        }

        const data = await response.json();

        if (!data || !data.token) {
          throw new CustomAuthError('no_token', 'No se recibió un token válido');
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
        };
      } catch (error: any) {
        if (error instanceof CustomAuthError) throw error;
        throw new CustomAuthError('unknown_error', 'Error en la autenticación');
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
        // @ts-ignore – extended user object from authorize
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
      }

      // Si ya está vencido, invalidar access token para forzar re-autenticación en cliente
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
      return session;
    },
    authorized({ auth: session, request: { nextUrl } }) {
      const isLoggedIn = !!session?.user;
      const isPublicRoute = PUBLIC_ROUTES.some((route) =>
        nextUrl.pathname.startsWith(route)
      );
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
