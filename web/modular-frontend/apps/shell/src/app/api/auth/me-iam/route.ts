/**
 * GET /api/auth/me-iam
 *
 * Devuelve los claims IAM del usuario autenticado: modulos, permisos
 * y companyAccesses. Estos NO van en el JWT/cookie porque inflarian
 * el header mas alla del limite de 16KB de Cloudflare.
 *
 * El cliente llama a este endpoint despues del login (o cuando lo
 * necesite) y los cachea en React Query.
 *
 * Internamente proxea a GET /auth/me de zentto-auth con la cookie
 * httponly del usuario.
 */

import { NextRequest, NextResponse } from 'next/server';

const AUTH_SERVICE_URL =
  process.env.AUTH_SERVICE_URL ||
  process.env.NEXT_PUBLIC_AUTH_URL ||
  '';

export async function GET(req: NextRequest) {
  if (!AUTH_SERVICE_URL) {
    return NextResponse.json(
      { error: 'auth_service_not_configured' },
      { status: 503 },
    );
  }

  const appId = req.nextUrl.searchParams.get('appId') ?? 'zentto-erp';
  const url = `${AUTH_SERVICE_URL}/auth/me?appId=${encodeURIComponent(appId)}`;

  const headers: Record<string, string> = {};
  const cookie = req.headers.get('cookie');
  if (cookie) headers['cookie'] = cookie;

  let upstream: Response;
  try {
    upstream = await fetch(url, { headers });
  } catch (err) {
    return NextResponse.json(
      { error: 'upstream_unreachable', detail: String(err) },
      { status: 502 },
    );
  }

  const text = await upstream.text();
  const response = new NextResponse(text, {
    status: upstream.status,
    statusText: upstream.statusText,
  });
  const ct = upstream.headers.get('content-type');
  if (ct) response.headers.set('content-type', ct);
  return response;
}
