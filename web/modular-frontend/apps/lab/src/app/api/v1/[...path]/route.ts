// API proxy — forwards all /api/v1/* requests to the real API server-side.
// This avoids CORS issues since the browser only talks to localhost:3016.

import { NextRequest, NextResponse } from "next/server";

const API_URL = (
  process.env.LAB_API_TARGET ||
  process.env.NEXT_PUBLIC_API_URL ||
  "http://localhost:4000"
).replace(/\/+$/, "");

async function proxy(req: NextRequest, { params }: { params: Promise<{ path: string[] }> }) {
  const { path } = await params;
  const target = `${API_URL}/v1/${path.join("/")}`;
  const url = new URL(target);

  // Forward query params
  req.nextUrl.searchParams.forEach((v, k) => url.searchParams.set(k, v));

  // Forward headers (auth, company, etc.)
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
  };
  const fwd = [
    "authorization",
    "x-company-id",
    "x-branch-id",
    "x-timezone",
    "x-country-code",
    "x-db-mode",
  ];
  for (const h of fwd) {
    const val = req.headers.get(h);
    if (val) headers[h] = val;
  }

  // Also get token from our session if no Authorization header present
  if (!headers["authorization"]) {
    try {
      const sessionRes = await fetch(`${req.nextUrl.origin}/api/auth/session`);
      if (sessionRes.ok) {
        const session = await sessionRes.json();
        if (session?.accessToken) {
          headers["authorization"] = `Bearer ${session.accessToken}`;
        }
        if (session?.company?.companyId && !headers["x-company-id"]) {
          headers["x-company-id"] = String(session.company.companyId);
        }
        if (session?.company?.branchId && !headers["x-branch-id"]) {
          headers["x-branch-id"] = String(session.company.branchId);
        }
        if (session?.company?.timeZone && !headers["x-timezone"]) {
          headers["x-timezone"] = session.company.timeZone;
        }
        if (session?.company?.countryCode && !headers["x-country-code"]) {
          headers["x-country-code"] = session.company.countryCode;
        }
      }
    } catch {
      // noop
    }
  }

  const fetchOpts: RequestInit = {
    method: req.method,
    headers,
  };

  if (req.method !== "GET" && req.method !== "HEAD") {
    try {
      fetchOpts.body = await req.text();
    } catch {
      // no body
    }
  }

  try {
    const res = await fetch(url.toString(), fetchOpts);
    const body = await res.text();

    return new NextResponse(body, {
      status: res.status,
      headers: {
        "Content-Type": res.headers.get("Content-Type") || "application/json",
      },
    });
  } catch (err: any) {
    return NextResponse.json(
      { error: `Proxy error: ${err.message}` },
      { status: 502 }
    );
  }
}

export const GET = proxy;
export const POST = proxy;
export const PUT = proxy;
export const PATCH = proxy;
export const DELETE = proxy;
