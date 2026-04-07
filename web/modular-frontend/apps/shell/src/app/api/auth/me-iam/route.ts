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
 * Internamente usa @zentto/auth-client (server-side) para llamar a
 * GET /auth/me de zentto-auth, reenviando la cookie httponly del
 * usuario al microservicio.
 */

import { NextRequest, NextResponse } from 'next/server';
import { getAuthClient } from '@/lib/auth-client';
import { AuthClientError } from '@zentto/auth-client';

export async function GET(req: NextRequest) {
  const appId = req.nextUrl.searchParams.get('appId') ?? 'zentto-erp';
  const cookie = req.headers.get('cookie') ?? undefined;

  try {
    const data = await getAuthClient().me({ appId, cookie });
    return NextResponse.json(data);
  } catch (err) {
    if (err instanceof AuthClientError) {
      return NextResponse.json(
        { error: err.message, detail: err.body },
        { status: err.status },
      );
    }
    return NextResponse.json(
      { error: 'upstream_unreachable', detail: String(err) },
      { status: 502 },
    );
  }
}
