/**
 * Auth proxy route for sub-apps that don't have their own NextAuth.
 * In development, proxies /api/auth/* requests to the shell app (port 3000).
 * In production, this is not needed because Nginx routes everything.
 *
 * Usage in sub-app: Create app/api/auth/[...nextauth]/route.ts with:
 *   export { GET, POST } from '@zentto/shared-auth/auth-proxy-route';
 */
import { NextRequest, NextResponse } from 'next/server';

const SHELL_URL = process.env.NEXTAUTH_URL || 'http://localhost:3000';

async function proxyToShell(req: NextRequest) {
  const url = new URL(req.url);
  const targetUrl = `${SHELL_URL}${url.pathname}${url.search}`;

  try {
    const headers = new Headers();
    // Forward relevant headers
    for (const [key, value] of req.headers.entries()) {
      if (['cookie', 'content-type', 'authorization', 'user-agent', 'accept'].includes(key.toLowerCase())) {
        headers.set(key, value);
      }
    }

    const fetchOpts: RequestInit = {
      method: req.method,
      headers,
      redirect: 'manual',
    };

    if (req.method !== 'GET' && req.method !== 'HEAD') {
      fetchOpts.body = await req.text();
    }

    const res = await fetch(targetUrl, fetchOpts);

    // Forward response with all headers (especially Set-Cookie)
    const responseHeaders = new Headers();
    for (const [key, value] of res.headers.entries()) {
      responseHeaders.append(key, value);
    }

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
