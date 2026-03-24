/**
 * license.types.ts — Tipos y constantes del módulo de licencias
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

/** Mapa fallback en código (por si la BD está vacía) */
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

export function getPlanModules(plan: string | undefined | null): string[] {
  const p = (plan?.toUpperCase() ?? 'FREE') as PlanCode;
  return PLAN_MODULE_DEFAULTS[p] ?? PLAN_MODULE_DEFAULTS.FREE;
}
