import { NextRequest, NextResponse } from "next/server";

const SHELL_URL = process.env.NEXTAUTH_URL || "http://localhost:3000";

async function proxyToShell(req: NextRequest) {
  const url = new URL(req.url);
  const target = `${SHELL_URL}${url.pathname}${url.search}`;
  try {
    const headers = new Headers();
    for (const [k, v] of req.headers.entries()) {
      if (["cookie", "content-type", "authorization", "accept"].includes(k)) headers.set(k, v);
    }
    const opts: RequestInit = { method: req.method, headers, redirect: "manual" };
    if (req.method !== "GET" && req.method !== "HEAD") opts.body = await req.text();
    const res = await fetch(target, opts);
    const rh = new Headers();
    for (const [k, v] of res.headers.entries()) rh.append(k, v);
    return new NextResponse(await res.arrayBuffer(), { status: res.status, headers: rh });
  } catch {
    return NextResponse.json({ error: "Auth proxy unavailable" }, { status: 502 });
  }
}

export const GET = proxyToShell;
export const POST = proxyToShell;
