import { NextRequest, NextResponse } from "next/server";

/**
 * Middleware de resolución de tenant por subdomain.
 *
 * Flujo:
 *   empresa1.zentto.net → extrae "empresa1" del host
 *   → inyecta header x-tenant-subdomain para que el frontend lo lea
 *   → la página de login auto-selecciona la empresa del tenant
 *
 * Subdominios reservados (no son tenants):
 *   app, www, api, notify, notify-dash, broker, vault
 */

const RESERVED_SUBDOMAINS = new Set([
  "app", "www", "api", "notify", "notify-dash",
  "broker", "vault", "mail", "smtp", "admin",
]);

const BASE_DOMAIN = process.env.BASE_DOMAIN || "zentto.net";

export function middleware(request: NextRequest) {
  const host = request.headers.get("host") || "";
  const hostname = host.split(":")[0]; // quitar puerto si lo tiene

  // Solo procesar si es subdomain de zentto.net
  if (!hostname.endsWith(`.${BASE_DOMAIN}`)) {
    return NextResponse.next();
  }

  // Extraer subdomain: "empresa1.zentto.net" → "empresa1"
  const subdomain = hostname.replace(`.${BASE_DOMAIN}`, "").toLowerCase();

  // No procesar subdominios reservados
  if (!subdomain || RESERVED_SUBDOMAINS.has(subdomain)) {
    return NextResponse.next();
  }

  // Inyectar el subdomain como header para que las páginas lo lean
  const response = NextResponse.next();
  response.headers.set("x-tenant-subdomain", subdomain);

  // También setear cookie para que client-side lo pueda leer
  response.cookies.set("tenant_subdomain", subdomain, {
    path: "/",
    sameSite: "lax",
    maxAge: 60 * 60 * 24, // 24h
  });

  return response;
}

export const config = {
  // Aplicar a todas las rutas excepto assets estáticos
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp|ico)$).*)",
  ],
};
