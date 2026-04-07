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

  const isProduction = process.env.NODE_ENV === "production";

  const response = NextResponse.json({ ok: true });

  response.cookies.set("zentto_token", token, {
    httpOnly: true,
    secure: isProduction,
    sameSite: "lax",
    domain: isProduction ? ".zentto.net" : undefined,
    path: "/",
    maxAge: 12 * 60 * 60, // 12 horas (en segundos)
  });

  return response;
}

/**
 * DELETE /api/auth/set-token
 * Limpia la cookie zentto_token (logout).
 */
export async function DELETE() {
  const isProduction = process.env.NODE_ENV === "production";
  const response = NextResponse.json({ ok: true });

  response.cookies.set("zentto_token", "", {
    httpOnly: true,
    secure: isProduction,
    sameSite: "lax",
    domain: isProduction ? ".zentto.net" : undefined,
    path: "/",
    maxAge: 0, // Expirar inmediatamente
  });

  return response;
}
