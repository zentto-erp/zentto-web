import { NextRequest, NextResponse } from "next/server";
import { auth } from "../../../../../auth";
import { getStoredAccessToken } from "../../../../../auth";

/**
 * POST /api/auth/set-token
 *
 * Cookie proxy: setea el JWT del ERP como cookie HttpOnly zentto_token
 * en el browser del usuario. Llamado por el frontend después del login.
 *
 * El token se obtiene del accessTokenStore server-side (nunca del body
 * del request ni de la session serializada — el cliente NUNCA ve el token).
 *
 * Flujo:
 * 1. NextAuth login → backend retorna JWT → se guarda en accessTokenStore
 * 2. Frontend llama POST /api/auth/set-token → este route lee del store
 * 3. Este route setea Set-Cookie: zentto_token=<jwt> (HttpOnly, Secure, SameSite=Lax)
 * 4. El browser tiene la cookie → todas las requests API van con credentials: include
 * 5. shared-api NO envía Authorization: Bearer — solo la cookie viaja
 */
export async function POST(req: NextRequest) {
  const session = await auth();

  if (!session?.user?.id) {
    return NextResponse.json({ ok: false, error: "no_session" }, { status: 401 });
  }

  const token = getStoredAccessToken(session.user.id);
  if (!token) {
    return NextResponse.json({ ok: false, error: "token_not_available" }, { status: 401 });
  }

  // Determinar dominio de la cookie según el host del request.
  // En prod Y en dev (appdev.zentto.net), la cookie debe tener domain=.zentto.net
  // para que viaje también a apidev.zentto.net (mismo dominio raíz, subdomain distinto).
  // Sin domain explícito, el browser solo la envía al subdominio exacto → 401 en API.
  const host = req.headers.get("host") ?? "";
  const isZenttoNet = host.endsWith(".zentto.net") || host === "zentto.net";
  const cookieDomain = isZenttoNet ? ".zentto.net" : undefined;
  const isSecure = host.endsWith(".zentto.net") || host === "zentto.net";

  const response = NextResponse.json({ ok: true });

  response.cookies.set("zentto_token", token, {
    httpOnly: true,
    secure: isSecure,
    sameSite: "lax",
    domain: cookieDomain,
    path: "/",
    maxAge: 12 * 60 * 60, // 12 horas (en segundos)
  });

  return response;
}

/**
 * DELETE /api/auth/set-token
 * Limpia la cookie zentto_token (logout).
 */
export async function DELETE(req: NextRequest) {
  const host = req.headers.get("host") ?? "";
  const isZenttoNet = host.endsWith(".zentto.net") || host === "zentto.net";
  const response = NextResponse.json({ ok: true });

  response.cookies.set("zentto_token", "", {
    httpOnly: true,
    secure: isZenttoNet,
    sameSite: "lax",
    domain: isZenttoNet ? ".zentto.net" : undefined,
    path: "/",
    maxAge: 0,
  });

  return response;
}
