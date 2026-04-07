/**
 * Cliente Zentto Auth para el shell del modular-frontend del ERP.
 *
 * Singleton del SDK @zentto/auth-client configurado server-side. La URL
 * del microservicio se lee de AUTH_SERVICE_URL (server-side env var).
 *
 * Centraliza las llamadas a auth.zentto.net que antes estaban duplicadas
 * en `apps/shell/auth.ts`, `apps/shell/src/app/api/auth/me-iam/route.ts`
 * y otros lugares con `process.env.AUTH_SERVICE_URL`.
 *
 *   import { authClient } from '@/lib/auth-client';
 *   await authClient.login({ username, password });
 *   await authClient.me({ accessToken: bearer, appId: 'zentto-erp' });
 *
 * Importante: en el shell `withCredentials` debe ser `false` porque las
 * llamadas son server-side (Node fetch) y no hay cookies del navegador
 * para enviar. Cuando el shell hace de proxy, reenvia explicitamente la
 * cookie del request original via `me({ cookie })`.
 */
import { createAuthClient, type AuthClient } from '@zentto/auth-client';

const baseUrl =
  process.env.AUTH_SERVICE_URL ||
  process.env.NEXT_PUBLIC_AUTH_URL ||
  'https://authdev.zentto.net';

let _client: AuthClient | null = null;

/**
 * Devuelve el singleton del cliente. Lazy para que `process.env` esté
 * inicializado cuando se construya (evita issues con Next.js bundling).
 */
export function getAuthClient(): AuthClient {
  if (!_client) {
    _client = createAuthClient({
      baseUrl,
      appId: 'zentto-erp',
      withCredentials: false, // server-side: no hay cookies del browser
    });
  }
  return _client;
}

/** Atajo: la URL configurada (debug). */
export const authBaseUrl = baseUrl;
