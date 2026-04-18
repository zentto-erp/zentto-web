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

  // SameSite=None + Secure permite que la cookie viaje en fetch cross-origin
  // entre pos.zentto.net → api.zentto.net (Electron desktop). SameSite=Lax
  // bloquea cross-site fetch aunque el dominio sea compartido. Localhost/dev
  // sin HTTPS usa lax (SameSite=None requiere Secure=true).
  response.cookies.set("zentto_token", token, {
    httpOnly: true,
    secure: isSecure,
    sameSite: isSecure ? "none" : "lax",
    domain: cookieDomain,
    path: "/",
    maxAge: 12 * 60 * 60, // 12 horas (en segundos)
  });

  return response;
}

/**
 * DELETE /api/auth/set-token
 * Limpia la cookie zentto_token (logout) Y revoca el refresh token en DB
 * llamando server-to-server a zentto-auth /auth/logout.
 *
 * Sin esta llamada server-side, el refresh token sobrevive en la BD de
 * zentto-auth hasta 30 días — un atacante con la cookie podría seguir
 * obteniendo access tokens nuevos vía /auth/refresh.
 *
 * Cierra Hallazgo del plan de seguridad auth (Sprint 0 #4).
 */
export async function DELETE(req: NextRequest) {
  const host = req.headers.get("host") ?? "";
  const isZenttoNet = host.endsWith(".zentto.net") || host === "zentto.net";
  const cookieDomain = isZenttoNet ? ".zentto.net" : undefined;
  const response = NextResponse.json({ ok: true });

  // 1) Llamar a zentto-auth /auth/logout para revocar el refresh token en DB.
  //    Reenviamos la cookie del browser para que zentto-auth sepa qué sesión cerrar.
  //    Best-effort: si falla, igual limpiamos las cookies del browser.
  const authServiceUrl = process.env.AUTH_SERVICE_URL;
  if (authServiceUrl) {
    const cookieHeader = req.headers.get("cookie") ?? "";
    if (cookieHeader) {
      try {
        await fetch(`${authServiceUrl}/auth/logout`, {
          method: "POST",
          headers: {
            cookie: cookieHeader,
            "content-type": "application/json",
          },
          // Importante: no seguir redirects ni propagar Set-Cookie del response;
          // la limpieza de cookies en el browser la hacemos abajo de forma explícita.
        });
      } catch (err) {
        console.warn(
          "[/api/auth/set-token DELETE] zentto-auth /auth/logout failed:",
          (err as Error).message
        );
      }
    }
  }

  // 2) Limpiar cookies HttpOnly en el browser. Cubrimos los 3 nombres en transición:
  //    - __Secure-zentto_token (escritura nueva, prefijo seguro)
  //    - zentto_token (escritura actual del shell)
  //    - zentto_access (escritura legacy de zentto-auth)
  for (const name of ["__Secure-zentto_token", "zentto_token", "zentto_access"]) {
    response.cookies.set(name, "", {
      httpOnly: true,
      secure: isZenttoNet,
      sameSite: "none",
      domain: cookieDomain,
      path: "/",
      maxAge: 0,
    });
  }

  return response;
}
