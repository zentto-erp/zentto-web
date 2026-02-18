import NextAuth from 'next-auth';
import Credentials from 'next-auth/providers/credentials';
import type { Provider } from 'next-auth/providers';
import { AuthError } from 'next-auth';

export class CustomAuthError extends AuthError {
  code: string;

  constructor(code: string, msg: string) {
    super();
    this.code = code;
    this.message = msg;
    this.stack = undefined;
  }
}

// Lista de rutas públicas que no requieren autenticación
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
    authorize: async (credentials: Record<"username" | "password", string | undefined> | undefined) => {
      try {
        const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:4000';

        if (!credentials?.username) {
          throw new CustomAuthError('invalid_credentials', 'Usuario es requerido');
        }

        const userData = {
          usuario: credentials.username.includes('@') ? 
            credentials.username.split('@')[0] : 
            credentials.username,
          clave: credentials?.password || '',
        };

        console.log('Intentando autenticación:', { 
          usuario: userData.usuario,
          backendUrl: BACKEND_URL 
        });

        const response = await fetch(`${BACKEND_URL}/v1/auth/login`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(userData),
        });

        if (!response.ok) {
          const errorText = await response.text();
          console.error('Error en autenticación:', {
            status: response.status,
            error: errorText
          });
          throw new CustomAuthError(
            response.status.toString(),
            `Error de autenticación: ${errorText}`
          );
        }

        const data = await response.json();
        
        console.log('Respuesta de autenticación:', {
          userId: data.userId,
          userName: data.userName,
          hasToken: !!data.token,
          isAdmin: data.isAdmin,
        });

        if (!data || !data.token) {
          throw new CustomAuthError('no_token', 'No se recibió un token válido');
        }

        const authUser = {
          id: data.userId || data.usuario?.codUsuario || 'unknown',
          name: data.userName || data.usuario?.nombre || 'Usuario',
          email: data.email || null,
          token: data.token,
          isAdmin: data.isAdmin || data.usuario?.isAdmin || false
        };

        console.log('Usuario autenticado:', {
          id: authUser.id,
          name: authUser.name,
          hasEmail: !!authUser.email,
          isAdmin: authUser.isAdmin
        });

        return authUser;
      } catch (error: any) {
        if (error instanceof CustomAuthError) {
          throw error;
        }
        console.error('Error inesperado:', error);
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
        // @ts-ignore
        token.accessToken = user.token;
        // @ts-ignore
        token.isAdmin = user.isAdmin;
      }
      return token;
    },
    async session({ session, token }) {
      // @ts-ignore
      session.accessToken = token.accessToken;
      // @ts-ignore
      session.isAdmin = token.isAdmin;
      return session;
    },
    authorized({ auth: session, request: { nextUrl } }) {
      const isLoggedIn = !!session?.user;
      
      // Verificar si es una ruta pública o un recurso estático
      const isPublicRoute = PUBLIC_ROUTES.some(route => nextUrl.pathname.startsWith(route));
      const isStaticAsset = nextUrl.pathname.startsWith('/_next') || 
                           nextUrl.pathname.includes('/images/') ||
                           nextUrl.pathname.includes('.png') ||
                           nextUrl.pathname.includes('.svg');
      
      if (isPublicRoute || isStaticAsset) {
        return true;
      }

      return isLoggedIn;
    },
  },
});
