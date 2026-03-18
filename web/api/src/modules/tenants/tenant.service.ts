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
  if (!notifyKey) return; // Si no hay key, saltear silenciosamente

  try {
    await fetch(`${notifyUrl}/api/email/send`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-API-Key": notifyKey,
      },
      body: JSON.stringify({
        to: ownerEmail,
        subject: "¡Bienvenido a Zentto ERP!",
        html: `
          <div style="font-family:sans-serif;max-width:600px;margin:0 auto">
            <h2 style="color:#6C63FF">¡Bienvenido a Zentto, ${legalName}!</h2>
            <p>Tu cuenta ha sido creada exitosamente. Aquí están tus credenciales de acceso:</p>
            <table style="background:#f5f5f5;padding:16px;border-radius:8px;width:100%">
              <tr><td><strong>Email:</strong></td><td>${ownerEmail}</td></tr>
              <tr><td><strong>Contraseña temporal:</strong></td><td style="font-family:monospace">${tempPassword}</td></tr>
              <tr><td><strong>ID de empresa:</strong></td><td>${companyId}</td></tr>
            </table>
            <p style="color:#e74c3c;margin-top:16px"><strong>Por seguridad, cambia tu contrasena en el primer inicio de sesion.</strong></p>
            <p>Accede en: <a href="${tenantUrl || "https://app.zentto.net"}">${tenantUrl || "app.zentto.net"}</a></p>
            <p style="color:#999;font-size:12px">— El equipo de Zentto</p>
          </div>
        `,
        from: "Zentto <no-reply@zentto.net>",
      }),
    });
  } catch {
    // No falla el provisioning si el email no se puede enviar
  }
}
