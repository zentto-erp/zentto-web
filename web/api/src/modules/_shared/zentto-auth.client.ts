/**
 * zentto-auth.client.ts — Cliente HTTP para el microservicio zentto-auth.
 *
 * Usado durante provisioning de tenants para:
 *   • crear la identidad del owner en zentto-auth (fuente de verdad de users)
 *   • generar magic-link para que el owner fije su password
 *   • asociar un user existente a un nuevo company (multi-tenant user)
 *
 * Env vars:
 *   AUTH_SERVICE_URL   (default: https://auth.zentto.net)
 *   AUTH_SERVICE_KEY   master key para llamadas server-to-server
 */

const AUTH_BASE_URL = process.env.AUTH_SERVICE_URL || "https://auth.zentto.net";

function getServiceKey(): string {
  const key = process.env.AUTH_SERVICE_KEY || process.env.AUTH_MASTER_KEY || "";
  if (!key) {
    console.warn("[zentto-auth] AUTH_SERVICE_KEY no configurado, calls S2S fallarán");
  }
  return key;
}

async function request<T>(
  method: "GET" | "POST" | "PATCH" | "DELETE",
  path: string,
  body?: Record<string, unknown>
): Promise<T> {
  const url = `${AUTH_BASE_URL}${path}`;
  const res = await fetch(url, {
    method,
    headers: {
      "Content-Type": "application/json",
      "x-service-key": getServiceKey(),
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  let json: any = null;
  try {
    json = await res.json();
  } catch {
    /* sin body */
  }

  if (!res.ok) {
    const detail = json?.error || json?.message || res.statusText;
    throw new Error(`zentto-auth ${method} ${path} falló (${res.status}): ${detail}`);
  }
  return json as T;
}

export interface AuthUserCreateInput {
  email: string;
  fullName: string;
  companyId: number;
  companyCode: string;
  tenantSubdomain: string;
  role?: "owner" | "admin" | "user";
  sendMagicLink?: boolean;
  locale?: string;
}

export interface AuthUserCreateResult {
  userId: string;
  email: string;
  magicLinkUrl?: string;
  alreadyExisted?: boolean;
}

/**
 * Crea el owner del tenant en zentto-auth. Si el email ya existe, asocia el
 * company nuevo al user existente (multi-tenant login).
 */
export async function authCreateOwner(input: AuthUserCreateInput): Promise<AuthUserCreateResult> {
  return request<AuthUserCreateResult>("POST", "/admin/users/provision-owner", {
    email: input.email.toLowerCase(),
    fullName: input.fullName,
    companyId: input.companyId,
    companyCode: input.companyCode,
    tenantSubdomain: input.tenantSubdomain,
    role: input.role ?? "owner",
    sendMagicLink: input.sendMagicLink ?? true,
    locale: input.locale ?? "es",
  });
}

/**
 * Genera un magic-link de set-password para un user existente.
 * Retorna la URL absoluta que el caller embebe en el email.
 */
export async function authGenerateMagicLink(email: string, companyId: number): Promise<string> {
  const result = await request<{ url: string }>("POST", "/admin/users/magic-link", {
    email: email.toLowerCase(),
    companyId,
    purpose: "set-password",
    ttlMinutes: 60 * 24, // 24 horas
  });
  return result.url;
}
