/**
 * Proxy de IAM admin endpoints a zentto-auth.
 *
 * El microservicio zentto-auth (puerto interno 4600) NO esta expuesto
 * publicamente. El browser no puede llamarlo directamente. Este route
 * handler corre server-side dentro del shell del ERP y reenvia las
 * requests al microservicio usando el mismo cookie httponly del usuario.
 *
 * Mapping:
 *   /api/iam/users          → ${AUTH_SERVICE_URL}/admin/users
 *   /api/iam/users/abc      → ${AUTH_SERVICE_URL}/admin/users/abc
 *   /api/iam/companies      → ${AUTH_SERVICE_URL}/admin/companies
 *   /api/iam/apps           → ${AUTH_SERVICE_URL}/admin/apps
 *   etc.
 *
 * Auth: el browser envia la cookie httponly __Secure-zentto_token al shell;
 * el shell la reenvia a zentto-auth en el header Cookie. zentto-auth la
 * descifra con su JWT_SECRET (sincronizado con el del ERP) y aplica
 * requireAuth + requireAdmin.
 */

import { NextRequest, NextResponse } from 'next/server';

const AUTH_SERVICE_URL =
  process.env.AUTH_SERVICE_URL ||
  process.env.NEXT_PUBLIC_AUTH_URL ||
  '';

async function proxy(req: NextRequest, params: { path: string[] }) {
  if (!AUTH_SERVICE_URL) {
    return NextResponse.json(
      { error: 'auth_service_not_configured' },
      { status: 503 },
    );
  }

  const subPath = params.path.join('/');
  const search = req.nextUrl.search;
  const url = `${AUTH_SERVICE_URL}/admin/${subPath}${search}`;

  const headers: Record<string, string> = {};
  const cookie = req.headers.get('cookie');
  if (cookie) headers['cookie'] = cookie;
  const ct = req.headers.get('content-type');
  if (ct) headers['content-type'] = ct;

  // Body solo en metodos que no son GET/HEAD
  const init: RequestInit = {
    method: req.method,
    headers,
  };
  if (req.method !== 'GET' && req.method !== 'HEAD') {
    init.body = await req.text();
  }

  let upstream: Response;
  try {
    upstream = await fetch(url, init);
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
  // Preservar Content-Type del upstream
  const upstreamCt = upstream.headers.get('content-type');
  if (upstreamCt) response.headers.set('content-type', upstreamCt);
  return response;
}

export async function GET(req: NextRequest, ctx: { params: Promise<{ path: string[] }> }) {
  return proxy(req, await ctx.params);
}
export async function POST(req: NextRequest, ctx: { params: Promise<{ path: string[] }> }) {
  return proxy(req, await ctx.params);
}
export async function PUT(req: NextRequest, ctx: { params: Promise<{ path: string[] }> }) {
  return proxy(req, await ctx.params);
}
export async function PATCH(req: NextRequest, ctx: { params: Promise<{ path: string[] }> }) {
  return proxy(req, await ctx.params);
}
export async function DELETE(req: NextRequest, ctx: { params: Promise<{ path: string[] }> }) {
  return proxy(req, await ctx.params);
}
