import { callSp } from "../../db/query.js";
import { hashPassword } from "../../auth/password.js";
import { validateCompanyLimit } from "../iam/enforcement/company-limit.guard.js";
import type { TenantProvisionInput, TenantProvisionResult, TenantInfo } from "./tenant.types.js";

export async function provisionTenant(
  input: TenantProvisionInput
): Promise<TenantProvisionResult> {
  // Validate company limit before provisioning (solo para empresas hijas,
  // NO para nuevos tenants independientes — registro público pasa skipCompanyLimit)
  if (!input.skipCompanyLimit) {
    const limitCheck = await validateCompanyLimit();
    if (!limitCheck.allowed) {
      return { ok: false, mensaje: limitCheck.reason ?? "company_limit_exceeded", companyId: 0, userId: 0 };
    }
  }

  const passwordHash = await hashPassword(input.adminPassword);

  const rows = await callSp<{
    ok: boolean;
    mensaje: string;
    CompanyId?: number;
    UserId?: number;
    NewCompanyId?: number;
    NewUserId?: number;
  }>("usp_Cfg_Tenant_Provision", {
    CompanyCode:           input.companyCode,
    LegalName:             input.legalName,
    OwnerEmail:            input.ownerEmail,
    CountryCode:           input.countryCode,
    BaseCurrency:          input.baseCurrency,
    AdminUserCode:         input.adminUserCode,
    AdminPasswordHash:     passwordHash,
    Plan:                  input.plan,
    PaddleSubscriptionId:  input.paddleSubscriptionId ?? null,
  });

  const row = rows[0];
  const result: TenantProvisionResult = {
    ok:        Boolean(row?.ok ?? false),
    mensaje:   String(row?.mensaje ?? "UNKNOWN_ERROR"),
    companyId: Number(row?.NewCompanyId ?? row?.CompanyId ?? 0),
    userId:    Number(row?.NewUserId ?? row?.UserId ?? 0),
  };

  // Aplicar módulos del plan al tenant recién creado
  if (result.ok && result.companyId) {
    const { applyPlanModules } = await import("../license/license.service.js");
    await applyPlanModules(result.companyId, input.plan).catch((err: unknown) => {
      const msg = err instanceof Error ? err.message : String(err);
      console.warn("[provision] No se pudieron aplicar módulos del plan:", msg);
    });
  }

  return result;
}

export async function getTenantInfo(companyId: number): Promise<TenantInfo | null> {
  const rows = await callSp<TenantInfo>("usp_Cfg_Tenant_GetInfo", {
    CompanyId: companyId,
  });
  return rows[0] ?? null;
}

export async function resolveTenantByEmail(email: string) {
  const rows = await callSp<{
    CompanyId: number;
    CompanyCode: string;
    LegalName: string;
    OwnerEmail: string;
    Plan: string;
    TenantStatus: string;
    TenantSubdomain: string;
    IsActive: boolean;
  }>("usp_Cfg_Tenant_ResolveByEmail", { Email: email });
  return rows[0] ?? null;
}

export async function resolveTenantBySubdomain(subdomain: string) {
  const rows = await callSp<{
    CompanyId: number;
    CompanyCode: string;
    LegalName: string;
    Plan: string;
    TenantStatus: string;
    TenantSubdomain: string;
    IsActive: boolean;
  }>("usp_Cfg_Tenant_ResolveSubdomain", { Subdomain: subdomain });
  return rows[0] ?? null;
}

/**
 * Envía welcome email al owner del tenant.
 *
 * Modo preferido (B3): si se pasa `magicLinkUrl`, se manda como link de
 * uso único para fijar password (sin password plaintext en el correo).
 * Modo legacy: si no, manda tempPassword (compatibilidad con flujos viejos).
 *
 * Reintentos (F4): hasta 3 intentos con backoff exponencial al fallar el
 * envío via Notify (errores transitorios de red o 5xx).
 */
export async function sendWelcomeEmail(
  ownerEmail: string,
  legalName: string,
  tempPassword: string,
  companyId: number,
  tenantUrl?: string,
  adminUserCode: string = "ADMIN",
  magicLinkUrl?: string
): Promise<void> {
  const notifyUrl = process.env.NOTIFY_BASE_URL ?? "https://notify.zentto.net";
  // Acepta NOTIFY_API_KEY (directo) o AUTH_MAIL_WEBHOOK_TOKEN (inyectado por deploy)
  const notifyKey = process.env.NOTIFY_API_KEY || process.env.AUTH_MAIL_WEBHOOK_TOKEN;
  const loginUrl = `${tenantUrl || "https://app.zentto.net"}/authentication/login`;
  const useMagicLink = Boolean(magicLinkUrl);

  if (!notifyKey) {
    console.warn("[welcome-email] NOTIFY_API_KEY / AUTH_MAIL_WEBHOOK_TOKEN no configurada — email NO enviado a", ownerEmail);
    return;
  }

  const html = `
  <div style="font-family:'Segoe UI',Arial,sans-serif;max-width:620px;margin:0 auto;background:#f8f9fa;padding:0">

    <!-- Header -->
    <div style="background:#1a1a2e;padding:32px 40px;text-align:center">
      <div style="background:#ff9900;color:#fff;font-weight:900;font-size:22px;display:inline-block;padding:12px 22px;border-radius:10px;letter-spacing:2px">DB</div>
      <div style="color:#fff;font-size:28px;font-weight:700;margin:10px 0 4px;letter-spacing:3px">ZENTTO</div>
      <div style="color:#aaa;font-size:13px">Sistema de Administracion Empresarial</div>
    </div>

    <!-- Body -->
    <div style="background:#fff;padding:40px">
      <h2 style="color:#1a1a2e;margin:0 0 8px">Bienvenido a Zentto, <span style="color:#ff9900">${legalName}</span>!</h2>
      <p style="color:#555;margin:0 0 28px;line-height:1.6">
        Tu cuenta ha sido creada y tu entorno esta listo. A continuacion encontraras todo lo que necesitas para comenzar.
      </p>

      <!-- Credenciales / Magic-link -->
      <div style="background:#1a1a2e;border-radius:10px;padding:24px;margin-bottom:28px">
        <div style="color:#ff9900;font-weight:700;font-size:12px;letter-spacing:2px;margin-bottom:16px;text-transform:uppercase">${useMagicLink ? "Configura tu contraseña" : "Tus credenciales de acceso"}</div>
        <table style="width:100%;border-collapse:collapse">
          <tr>
            <td style="color:#aaa;font-size:13px;padding:6px 0;width:40%">Tu URL exclusiva</td>
            <td style="padding:6px 0"><a href="${tenantUrl || "https://app.zentto.net"}" style="color:#ff9900;font-weight:600;text-decoration:none">${tenantUrl || "app.zentto.net"}</a></td>
          </tr>
          <tr>
            <td style="color:#aaa;font-size:13px;padding:6px 0">Usuario</td>
            <td style="color:#fff;font-weight:700;font-family:monospace;font-size:16px;letter-spacing:2px;padding:6px 0">${adminUserCode}</td>
          </tr>
          ${useMagicLink ? `
          <tr>
            <td style="color:#aaa;font-size:13px;padding:6px 0">Acción</td>
            <td style="color:#ff9900;font-weight:700;font-size:14px;padding:6px 0">Click el botón abajo para fijar tu contraseña (válido 24h)</td>
          </tr>
          ` : `
          <tr>
            <td style="color:#aaa;font-size:13px;padding:6px 0">Contraseña temporal</td>
            <td style="color:#ff9900;font-weight:700;font-family:monospace;font-size:16px;letter-spacing:2px;padding:6px 0">${tempPassword}</td>
          </tr>
          `}
        </table>
      </div>

      <!-- Botón -->
      <div style="text-align:center;margin-bottom:36px">
        <a href="${useMagicLink ? magicLinkUrl : loginUrl}" style="background:#ff9900;color:#fff;padding:16px 40px;border-radius:8px;text-decoration:none;font-weight:700;font-size:16px;display:inline-block;letter-spacing:1px">
          ${useMagicLink ? "Fijar mi contraseña &rarr;" : "Iniciar sesión ahora &rarr;"}
        </a>
      </div>

      <!-- Pasos -->
      <div style="border-top:1px solid #eee;padding-top:28px">
        <div style="color:#1a1a2e;font-weight:700;margin-bottom:16px">Primeros pasos recomendados</div>
        <div style="display:flex;align-items:flex-start;margin-bottom:14px">
          <div style="background:#ff9900;color:#fff;border-radius:50%;width:24px;height:24px;text-align:center;line-height:24px;font-size:12px;font-weight:700;flex-shrink:0;margin-right:12px">1</div>
          <div>
            <div style="color:#333;font-weight:600">Entra a tu URL exclusiva</div>
            <div style="color:#777;font-size:13px">Guarda en tus favoritos <a href="${tenantUrl || "https://app.zentto.net"}" style="color:#ff9900">${tenantUrl || "app.zentto.net"}</a> — esta es la direccion unica de tu empresa.</div>
          </div>
        </div>
        <div style="display:flex;align-items:flex-start;margin-bottom:14px">
          <div style="background:#ff9900;color:#fff;border-radius:50%;width:24px;height:24px;text-align:center;line-height:24px;font-size:12px;font-weight:700;flex-shrink:0;margin-right:12px">2</div>
          <div>
            <div style="color:#333;font-weight:600">Inicia sesion con el usuario <span style="font-family:monospace;background:#f5f5f5;padding:2px 6px;border-radius:3px">${adminUserCode}</span></div>
            <div style="color:#777;font-size:13px">Usa la contrasena temporal que aparece arriba.</div>
          </div>
        </div>
        <div style="display:flex;align-items:flex-start;margin-bottom:14px">
          <div style="background:#ff9900;color:#fff;border-radius:50%;width:24px;height:24px;text-align:center;line-height:24px;font-size:12px;font-weight:700;flex-shrink:0;margin-right:12px">3</div>
          <div>
            <div style="color:#333;font-weight:600">Cambia tu contrasena</div>
            <div style="color:#777;font-size:13px">Ve a Configuracion > Seguridad y establece una contrasena segura para tu cuenta.</div>
          </div>
        </div>
        <div style="display:flex;align-items:flex-start">
          <div style="background:#ff9900;color:#fff;border-radius:50%;width:24px;height:24px;text-align:center;line-height:24px;font-size:12px;font-weight:700;flex-shrink:0;margin-right:12px">4</div>
          <div>
            <div style="color:#333;font-weight:600">Configura tu empresa</div>
            <div style="color:#777;font-size:13px">Completa los datos fiscales, moneda base, y agrega a tu equipo desde el panel de administracion.</div>
          </div>
        </div>
      </div>

      <!-- Soporte -->
      <div style="background:#fff8e1;border-left:4px solid #ff9900;padding:14px 18px;margin-top:28px;border-radius:0 6px 6px 0">
        <strong style="color:#333">¿Necesitas ayuda?</strong>
        <div style="color:#666;font-size:13px;margin-top:4px">Escribe a <a href="mailto:soporte@zentto.net" style="color:#ff9900">soporte@zentto.net</a> o visita nuestra documentacion en <a href="https://zentto.net" style="color:#ff9900">zentto.net</a>.</div>
      </div>
    </div>

    <!-- Footer -->
    <div style="padding:20px 40px;text-align:center;background:#f8f9fa">
      <p style="color:#999;font-size:12px;margin:0">© ${new Date().getFullYear()} Zentto. Todos los derechos reservados.</p>
      <p style="color:#bbb;font-size:11px;margin:6px 0 0">Este correo fue generado automaticamente. No respondas a este mensaje.</p>
    </div>
  </div>`;

  // Reintentos: 3 intentos con backoff exponencial. Solo reintenta errores
  // transitorios (red, 5xx). 4xx (auth/payload inválido) NO se reintenta.
  const { withRetry, isHttp4xx } = await import("../_shared/retry.js");
  try {
    await withRetry(async () => {
      const res = await fetch(`${notifyUrl}/api/email/send`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-API-Key": notifyKey,
        },
        body: JSON.stringify({
          to: ownerEmail,
          subject: `Bienvenido a Zentto — Tu cuenta ${legalName} está lista`,
          html,
          from: "Zentto <no-reply@zentto.net>",
        }),
      });
      if (!res.ok) {
        const body = await res.text().catch(() => "");
        throw new Error(`notify_${res.status}: ${body.slice(0, 200)}`);
      }
    }, {
      attempts: 3,
      isPermanent: isHttp4xx,
      onAttemptFailed: (err, attempt) =>
        console.warn(`[welcome-email] intento ${attempt} falló:`, err instanceof Error ? err.message : err),
    });
    console.log(`[welcome-email] Email enviado exitosamente a ${ownerEmail}`);
  } catch (err) {
    console.error("[welcome-email] FALLÓ tras reintentos para", ownerEmail, err);
    throw err; // que el caller decida si encolar reintento async vía sys.ProvisioningJob
  }
}
