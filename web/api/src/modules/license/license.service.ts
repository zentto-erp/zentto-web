/**
 * license.service.ts — Servicio de licencias Zentto
 *
 * Todas las operaciones ejecutan en la BD MASTER (getMasterPool).
 * Usa callSp() del helper estándar ya que las funciones de licencia
 * viven en la misma BD que el contexto master.
 */
import { callSp } from "../../db/query.js";
import { obs } from "../integrations/observability.js";
import type {
  LicenseValidationResult,
  LicenseType,
  PlanCode,
  LicenseStatus,
} from "./license.types.js";
import { getPlanModules } from "./license.types.js";

// ── Tipos de retorno internos ─────────────────────────────────────────────────

interface LicenseValidateRow {
  ok: boolean;
  reason?: string;
  plan?: string;
  modules_json?: string;
  expires_at?: string | null;
  days_remaining?: number | null;
  company_name?: string;
  license_type?: string;
}

interface LicenseCreateRow {
  ok: boolean;
  mensaje?: string;
  LicenseId?: number;
  LicenseKey?: string;
}

interface LicenseWriteRow {
  ok: boolean;
  mensaje?: string;
}

interface LicenseRecord {
  LicenseId: number;
  CompanyId: number;
  LicenseKey: string;
  LicenseType: LicenseType;
  Plan: PlanCode;
  Status: LicenseStatus;
  ExpiresAt: string | null;
  PaddleSubId: string | null;
  ContractRef: string | null;
  MaxUsers: number | null;
  Notes: string | null;
  CreatedAt: string;
  UpdatedAt: string;
}

interface ApplyPlanModulesRow {
  ok: boolean;
  mensaje?: string;
  modules_applied?: number;
}

// ── validateLicense ───────────────────────────────────────────────────────────

/**
 * Valida la licencia de un tenant por companyCode + licenseKey.
 * Usado principalmente por servidores BYOC para verificar su licencia al arrancar.
 */
export async function validateLicense(
  companyCode: string,
  licenseKey: string
): Promise<LicenseValidationResult> {
  try {
    const rows = await callSp<LicenseValidateRow>(
      "usp_Sys_License_Validate",
      { CompanyCode: companyCode, LicenseKey: licenseKey }
    );

    const row = rows[0];
    if (!row || !row.ok) {
      return {
        ok: false,
        reason: row?.reason ?? 'license_not_found',
      };
    }

    // Parsear módulos del JSON si viene como string
    let modules: string[] | undefined;
    if (row.modules_json) {
      try {
        const parsed = JSON.parse(row.modules_json) as unknown;
        if (Array.isArray(parsed)) {
          modules = parsed.filter((m): m is string => typeof m === 'string');
        }
      } catch {
        // Si no parsea, usar fallback por plan
        modules = getPlanModules(row.plan);
      }
    } else {
      modules = getPlanModules(row.plan);
    }

    const expiresAt = row.expires_at ? new Date(row.expires_at) : null;

    return {
      ok: true,
      plan: (row.plan?.toUpperCase() as PlanCode) ?? 'FREE',
      modules,
      expiresAt,
      daysRemaining: row.days_remaining ?? null,
      companyName: row.company_name,
      licenseType: row.license_type as LicenseType | undefined,
    };
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'internal_error';
    obs.error(`license.validate.failed: ${msg}`, { module: 'license', companyCode });
    return { ok: false, reason: 'internal_error' };
  }
}

// ── createLicense ─────────────────────────────────────────────────────────────

/**
 * Crea una nueva licencia para un tenant.
 * Retorna el ID y clave generada.
 */
export async function createLicense(params: {
  companyId: number;
  licenseType: LicenseType;
  plan: PlanCode;
  expiresAt?: Date | null;
  paddleSubId?: string | null;
  contractRef?: string | null;
  maxUsers?: number | null;
  notes?: string | null;
}): Promise<{ licenseId: number; licenseKey: string }> {
  const rows = await callSp<LicenseCreateRow>(
    "usp_Sys_License_Create",
    {
      CompanyId:   params.companyId,
      LicenseType: params.licenseType,
      Plan:        params.plan,
      ExpiresAt:   params.expiresAt ?? null,
      PaddleSubId: params.paddleSubId ?? null,
      ContractRef: params.contractRef ?? null,
      MaxUsers:    params.maxUsers ?? null,
      Notes:       params.notes ?? null,
    }
  );

  const row = rows[0];
  if (!row || !row.ok || !row.LicenseId || !row.LicenseKey) {
    throw new Error(row?.mensaje ?? 'license_create_failed');
  }

  obs.audit('license.created', {
    companyId: params.companyId,
    plan: params.plan,
    licenseType: params.licenseType,
    licenseId: row.LicenseId,
  });

  return { licenseId: row.LicenseId, licenseKey: row.LicenseKey };
}

// ── revokeLicense ─────────────────────────────────────────────────────────────

/**
 * Revoca (cancela) una licencia activa por su ID.
 */
export async function revokeLicense(
  licenseId: number,
  reason: string
): Promise<void> {
  const rows = await callSp<LicenseWriteRow>(
    "usp_Sys_License_Revoke",
    { LicenseId: licenseId, Reason: reason }
  );

  const row = rows[0];
  if (!row || !row.ok) {
    throw new Error(row?.mensaje ?? 'license_revoke_failed');
  }

  obs.audit('license.revoked', { licenseId, reason });
}

// ── renewLicense ──────────────────────────────────────────────────────────────

/**
 * Renueva una licencia actualizando su fecha de expiración.
 * Si newExpiresAt es null, la convierte a sin expiración (licencia permanente).
 */
export async function renewLicense(
  licenseId: number,
  newExpiresAt: Date | null
): Promise<void> {
  const rows = await callSp<LicenseWriteRow>(
    "usp_Sys_License_Renew",
    { LicenseId: licenseId, NewExpiresAt: newExpiresAt }
  );

  const row = rows[0];
  if (!row || !row.ok) {
    throw new Error(row?.mensaje ?? 'license_renew_failed');
  }
}

// ── applyPlanModules ──────────────────────────────────────────────────────────

/**
 * Aplica los módulos correspondientes al plan del tenant en la tabla sec.UserModuleAccess.
 * Normalmente se llama justo después de provisionTenant().
 */
export async function applyPlanModules(
  companyId: number,
  plan: string
): Promise<{ ok: boolean; modulesApplied: number }> {
  const rows = await callSp<ApplyPlanModulesRow>(
    "usp_Cfg_Plan_ApplyModules",
    { CompanyId: companyId, Plan: plan.toUpperCase() }
  );

  const row = rows[0];
  if (!row || !row.ok) {
    throw new Error(row?.mensaje ?? 'apply_plan_modules_failed');
  }

  return { ok: true, modulesApplied: row.modules_applied ?? 0 };
}

// ── getLicenseByCompany ───────────────────────────────────────────────────────

/**
 * Obtiene la licencia activa de un tenant por companyId.
 */
export async function getLicenseByCompany(
  companyId: number
): Promise<LicenseRecord | null> {
  const rows = await callSp<LicenseRecord>(
    "usp_Sys_License_GetByCompany",
    { CompanyId: companyId }
  );
  return rows[0] ?? null;
}
