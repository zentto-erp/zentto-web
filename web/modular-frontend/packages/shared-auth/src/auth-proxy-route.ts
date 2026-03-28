/**
 * Auth proxy route for sub-apps that don't have their own NextAuth.
 * Proxies /api/auth/* requests to the shell app (port 3000).
 *
 * Usage in sub-app: Create app/api/auth/[...nextauth]/route.ts with:
 *   export { GET, POST } from '@zentto/shared-auth/auth-proxy-route';
 *
 * Set NEXT_BASE_PATH in the sub-app's env (e.g. '/restaurante') so the
 * proxy strips the basePath prefix before forwarding to the shell.
 */
import { NextRequest, NextResponse } from 'next/server';

const SHELL_URL = process.env.SHELL_URL || process.env.NEXTAUTH_URL || 'http://localhost:3000';
// basePath of this sub-app (e.g. '/restaurante'). Must be stripped before
// forwarding so the shell receives /api/auth/... not /restaurante/api/auth/...
const BASE_PATH = process.env.NEXT_BASE_PATH || '';

// Headers that fetch() may decode automatically — must NOT be re-forwarded
// or the browser will try to decode already-decoded content (ERR_CONTENT_DECODING_FAILED)
const STRIP_RESPONSE_HEADERS = new Set(['content-encoding', 'content-length', 'transfer-encoding']);

async function proxyToShell(req: NextRequest) {
  const url = new URL(req.url);

  // Strip basePath so shell receives /api/auth/* (not /restaurante/api/auth/*)
  const pathname = BASE_PATH && url.pathname.startsWith(BASE_PATH)
    ? url.pathname.slice(BASE_PATH.length) || '/'
    : url.pathname;

  const targetUrl = `${SHELL_URL}${pathname}${url.search}`;

  try {
    const headers = new Headers();
    req.headers.forEach((value, key) => {
      if (['cookie', 'content-type', 'authorization', 'user-agent', 'accept'].includes(key.toLowerCase())) {
        headers.set(key, value);
      }
    });

    const fetchOpts: RequestInit = {
      method: req.method,
      headers,
      redirect: 'manual',
    };

    if (req.method !== 'GET' && req.method !== 'HEAD') {
      fetchOpts.body = await req.text();
    }

    const res = await fetch(targetUrl, fetchOpts);

    // Forward response headers — skip encoding headers (fetch already decoded the body)
    const responseHeaders = new Headers();
    res.headers.forEach((value, key) => {
      if (!STRIP_RESPONSE_HEADERS.has(key.toLowerCase())) {
        responseHeaders.append(key, value);
      }
    });

    const body = await res.arrayBuffer();
    return new NextResponse(body, {
      status: res.status,
      headers: responseHeaders,
    });
  } catch (err) {
    return NextResponse.json(
      { error: 'Auth proxy unavailable' },
      { status: 502 }
    );
  }
}

export const GET = proxyToShell;
export const POST = proxyToShell;
