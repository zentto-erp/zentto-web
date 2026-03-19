import { callSp } from "../../db/query.js";
import { hashPassword } from "../../auth/password.js";
import type { TenantProvisionInput, TenantProvisionResult, TenantInfo } from "./tenant.types.js";

export async function provisionTenant(
  input: TenantProvisionInput
): Promise<TenantProvisionResult> {
  const passwordHash = await hashPassword(input.adminPassword);

  const rows = await callSp<{
    ok: boolean;
    mensaje: string;
    CompanyId: number;
    UserId: number;
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
  return {
    ok:        Boolean(row?.ok ?? false),
    mensaje:   String(row?.mensaje ?? "UNKNOWN_ERROR"),
    companyId: Number(row?.CompanyId ?? 0),
    userId:    Number(row?.UserId ?? 0),
  };
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

export async function sendWelcomeEmail(
  ownerEmail: string,
  legalName: string,
  tempPassword: string,
  companyId: number,
  tenantUrl?: string
): Promise<void> {
  const notifyUrl = process.env.NOTIFY_BASE_URL ?? "https://notify.zentto.net";
  const notifyKey = process.env.NOTIFY_API_KEY;
  if (!notifyKey) {
    console.warn("[welcome-email] NOTIFY_API_KEY no configurada — email NO enviado a", ownerEmail);
    return;
  }

  try {
    const res = await fetch(`${notifyUrl}/api/email/send`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-API-Key": notifyKey,
      },
      body: JSON.stringify({
        to: ownerEmail,
        subject: "Bienvenido a Zentto — Tus credenciales de acceso",
        html: `
          <div style="font-family:sans-serif;max-width:600px;margin:0 auto;padding:20px">
            <div style="text-align:center;margin-bottom:24px">
              <div style="background:#ff9900;color:#fff;font-weight:bold;font-size:18px;display:inline-block;padding:12px 20px;border-radius:8px">DB</div>
              <h1 style="color:#131921;margin:8px 0 0">ZENTTO</h1>
              <p style="color:#666;margin:4px 0">Sistema de Administracion</p>
            </div>
            <h2 style="color:#6C63FF">Bienvenido, ${legalName}!</h2>
            <p>Tu cuenta ha sido creada exitosamente. Aqui estan tus credenciales de acceso:</p>
            <table style="background:#f5f5f5;padding:16px;border-radius:8px;width:100%;border-collapse:collapse">
              <tr><td style="padding:8px"><strong>Email / Usuario:</strong></td><td style="padding:8px">${ownerEmail}</td></tr>
              <tr><td style="padding:8px"><strong>Contrasena temporal:</strong></td><td style="padding:8px;font-family:monospace;font-size:16px;letter-spacing:1px;color:#6C63FF">${tempPassword}</td></tr>
              <tr><td style="padding:8px"><strong>ID de empresa:</strong></td><td style="padding:8px">${companyId}</td></tr>
              <tr><td style="padding:8px"><strong>Tu URL:</strong></td><td style="padding:8px"><a href="${tenantUrl || "https://app.zentto.net"}" style="color:#6C63FF">${tenantUrl || "app.zentto.net"}</a></td></tr>
            </table>
            <div style="background:#fff3e0;border-left:4px solid #ff9900;padding:12px 16px;margin:20px 0;border-radius:4px">
              <strong>Importante:</strong> Por seguridad, cambia tu contrasena en el primer inicio de sesion.
            </div>
            <div style="text-align:center;margin:24px 0">
              <a href="${tenantUrl || "https://app.zentto.net"}/authentication/login" style="background:#6C63FF;color:#fff;padding:14px 32px;border-radius:8px;text-decoration:none;font-weight:bold;font-size:16px;display:inline-block">Iniciar sesion</a>
            </div>
            <p style="color:#999;font-size:12px;text-align:center;margin-top:32px">— El equipo de Zentto</p>
          </div>
        `,
        from: "Zentto <no-reply@zentto.net>",
      }),
    });

    if (!res.ok) {
      const body = await res.text().catch(() => "");
      console.error(`[welcome-email] Notify respondio ${res.status} para ${ownerEmail}:`, body);
    } else {
      console.log(`[welcome-email] Email enviado exitosamente a ${ownerEmail}`);
    }
  } catch (err) {
    console.error("[welcome-email] Error enviando email a", ownerEmail, err);
  }
}
