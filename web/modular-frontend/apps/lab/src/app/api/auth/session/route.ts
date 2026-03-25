// Fake /api/auth/session endpoint for lab sandbox.
// Auto-login: calls the real API to get a JWT, then returns it
// in the same format that NextAuth would.

import { NextResponse } from "next/server";

const API_URL =
  process.env.LAB_API_TARGET ||
  process.env.NEXT_PUBLIC_API_URL ||
  "http://localhost:4000";

// Default credentials — override via env LAB_USER / LAB_PASSWORD
const LAB_USER = process.env.LAB_USER || "SUP";
const LAB_PASSWORD = process.env.LAB_PASSWORD || "1234";

// Cache the session so we don't login on every request
let cachedSession: Record<string, unknown> | null = null;
let cachedAt = 0;
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes

async function doLogin(): Promise<Record<string, unknown>> {
  const res = await fetch(`${API_URL}/v1/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ usuario: LAB_USER, clave: LAB_PASSWORD }),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Login failed (${res.status}): ${text}`);
  }

  const data = await res.json();

  // Build session object matching NextAuth shape expected by shared-api
  return {
    user: {
      name: data.userName || data.usuario?.nombre || LAB_USER,
      email: data.email || null,
    },
    accessToken: data.token,
    accessTokenExpires: Date.now() + 60 * 60 * 1000, // 1h
    userId: data.userId || data.usuario?.codUsuario,
    userName: data.userName || data.usuario?.nombre,
    tipo: data.usuario?.tipo || "ADMIN",
    isAdmin: data.isAdmin ?? true,
    permisos: data.permisos || {},
    modulos: data.modulos || [],
    company: data.company || null,
    companyAccesses: data.companyAccesses || [],
  };
}

export async function GET() {
  try {
    const now = Date.now();
    if (!cachedSession || now - cachedAt > CACHE_TTL) {
      cachedSession = await doLogin();
      cachedAt = now;
    }
    return NextResponse.json(cachedSession);
  } catch (err: any) {
    console.error("[lab] auto-login error:", err.message);
    return NextResponse.json(
      { error: err.message },
      { status: 500 }
    );
  }
}
