/**
 * license.types.ts — Tipos y constantes del módulo de licencias
 *
 * Fuente de verdad de entitlements: `cfg."PricingPlan"."ModuleCodes"` en BD
 * (ver migraciones `00082_pricing_plans_and_partners.sql` y
 * `00153_seed_matrix_comercial_v1_plans.sql`). El helper `getPlanModules`
 * de este archivo es **fallback de emergencia** cuando la BD no responde o
 * el plan legacy no tiene `ModuleCodes` poblados.
 *
 * Ver decisión D-006 en docs/lanzamiento/DECISIONES.md.
 */

export type PlanCode = 'FREE' | 'STARTER' | 'PRO' | 'ENTERPRISE';
export type LicenseType = 'SUBSCRIPTION' | 'LIFETIME' | 'CORPORATE' | 'INTERNAL' | 'TRIAL';
export type LicenseStatus = 'ACTIVE' | 'EXPIRED' | 'SUSPENDED' | 'CANCELLED';

export interface LicenseValidationResult {
  ok: boolean;
  reason?: string;
  plan?: PlanCode;
  modules?: string[];
  expiresAt?: Date | null;  // null = nunca expira
  daysRemaining?: number | null;
  companyName?: string;
  licenseType?: LicenseType;
}

/**
 * @deprecated Fuente canónica de `ModuleCodes` es `cfg."PricingPlan"."ModuleCodes"` en BD.
 * Este mapa existe solo como fallback de emergencia cuando la BD no responde.
 * No añadir planes nuevos aquí — crear el plan en BD con `usp_cfg_plan_upsert`
 * y poblar `ModuleCodes` explícitamente. Ver `docs/lanzamiento/MATRIZ_COMERCIAL_V1.md`.
 */
export const PLAN_MODULE_DEFAULTS: Record<PlanCode, string[]> = {
  FREE: ['dashboard', 'facturas', 'clientes', 'inventario', 'articulos', 'reportes'],
  STARTER: [
    'dashboard', 'facturas', 'abonos', 'cxc', 'clientes', 'compras', 'cxp',
    'cuentas-por-pagar', 'proveedores', 'inventario', 'articulos', 'pagos',
    'bancos', 'reportes', 'configuracion', 'usuarios',
  ],
  PRO: [
    'dashboard', 'facturas', 'abonos', 'cxc', 'clientes', 'compras', 'cxp',
    'cuentas-por-pagar', 'proveedores', 'inventario', 'articulos', 'pagos',
    'bancos', 'reportes', 'configuracion', 'usuarios', 'contabilidad', 'nomina',
    'pos', 'restaurante', 'ecommerce', 'auditoria', 'logistica', 'crm', 'shipping',
  ],
  ENTERPRISE: [
    'dashboard', 'facturas', 'abonos', 'cxc', 'clientes', 'compras', 'cxp',
    'cuentas-por-pagar', 'proveedores', 'inventario', 'articulos', 'pagos',
    'bancos', 'reportes', 'configuracion', 'usuarios', 'contabilidad', 'nomina',
    'pos', 'restaurante', 'ecommerce', 'auditoria', 'logistica', 'crm', 'shipping',
    'manufactura', 'flota',
  ],
};

/**
 * @deprecated Preferir `cfg."PricingPlan"."ModuleCodes"` via `usp_cfg_plan_get_by_slug`.
 * Esta función queda disponible para paths donde la BD no es alcanzable.
 */
export function getPlanModules(plan: string | undefined | null): string[] {
  const p = (plan?.toUpperCase() ?? 'FREE') as PlanCode;
  return PLAN_MODULE_DEFAULTS[p] ?? PLAN_MODULE_DEFAULTS.FREE;
}
