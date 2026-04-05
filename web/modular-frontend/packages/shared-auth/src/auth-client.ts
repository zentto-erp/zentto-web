'use client';

const APP_BASE_SEGMENTS = new Set([
  'contabilidad',
  'pos',
  'nomina',
  'bancos',
  'inventario',
  'ventas',
  'compras',
  'restaurante',
  'ecommerce',
  'auditoria',
]);

export function resolveAppBasePath(): string {
  if (typeof window === 'undefined') return '';
  const [firstSegment] = window.location.pathname.split('/').filter(Boolean);
  if (!firstSegment) return '';
  return APP_BASE_SEGMENTS.has(firstSegment) ? `/${firstSegment}` : '';
}

// La auth siempre la gestiona el shell en /api/auth.
// Las sub-apps con nginx propio proxean /appname/api/auth/* al shell.
// Las apps embebidas en el shell (compras, bancos, etc.) no tienen ruta
// /appname/api/auth en el shell → siempre usar /api/auth directamente.
export function resolveAuthBasePath(): string {
  return '/api/auth';
}

// La página de login siempre está en el shell en /authentication/login.
// Las sub-apps sin página propia de login redirigen allí.
export function buildLoginCallbackUrl(): string {
  if (typeof window === 'undefined') return '/authentication/login';
  return `${window.location.origin}/authentication/login`;
}

type AppAwareSignOutOptions = {
  redirect?: boolean;
  callbackUrl?: string;
};

export async function appAwareSignOut(options: AppAwareSignOutOptions = {}) {
  if (typeof window === 'undefined') {
    return { url: options.callbackUrl ?? '/authentication/login' };
  }

  const callbackUrl = options.callbackUrl ?? buildLoginCallbackUrl();
  const authBasePath = resolveAuthBasePath();

  const csrfResponse = await fetch(`${window.location.origin}${authBasePath}/csrf`, {
    credentials: 'include',
    headers: { Accept: 'application/json' },
    cache: 'no-store',
  });

  if (!csrfResponse.ok) {
    throw new Error('Failed to load CSRF token');
  }

  const csrfPayload = await csrfResponse.json().catch(() => ({} as { csrfToken?: string }));
  const csrfToken = typeof csrfPayload?.csrfToken === 'string' ? csrfPayload.csrfToken : '';
  if (!csrfToken) {
    throw new Error('Missing CSRF token');
  }

  const body = new URLSearchParams({
    csrfToken,
    callbackUrl,
    json: 'true',
  });

  // Limpiar cookie HttpOnly zentto_token antes de cerrar sesión
  await fetch(`${window.location.origin}/api/auth/set-token`, {
    method: 'DELETE',
    credentials: 'include',
  }).catch(() => {});

  const signOutResponse = await fetch(`${window.location.origin}${authBasePath}/signout`, {
    method: 'POST',
    credentials: 'include',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      Accept: 'application/json',
    },
    body: body.toString(),
  });

  if (!signOutResponse.ok) {
    throw new Error('Failed to sign out');
  }

  const payload = await signOutResponse.json().catch(() => ({ url: callbackUrl }));
  const targetUrl = typeof payload?.url === 'string' && payload.url ? payload.url : callbackUrl;

  if (options.redirect !== false) {
    window.location.href = targetUrl;
  }

  return { url: targetUrl };
}