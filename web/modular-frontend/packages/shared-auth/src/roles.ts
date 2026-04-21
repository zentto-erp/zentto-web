export const ROLES = { ADMIN: 'ADMIN', SUP: 'SUP', USER: 'USER' } as const;
export type Role = typeof ROLES[keyof typeof ROLES];

/**
 * Field-level permission flags from the Usuarios table.
 */
export interface UserPermisos {
  canUpdate: boolean;
  canCreate: boolean;
  canDelete: boolean;
  canChangePrice: boolean;
  canGiveCredit: boolean;
  canChangePwd: boolean;
  isCreator: boolean;
}

/**
 * System modules matching API SYSTEM_MODULES constant.
 * Each module maps to an AccesoUsuarios.Modulo entry.
 */
export const SYSTEM_MODULES = [
  'dashboard', 'facturas', 'compras', 'clientes', 'proveedores',
  'inventario', 'articulos', 'pagos', 'abonos', 'cuentas-por-pagar',
  'cxc', 'cxp', 'bancos', 'contabilidad', 'nomina',
  'configuracion', 'reportes', 'usuarios',
  // Módulos avanzados (requieren licencia + acceso por usuario)
  'pos', 'restaurante', 'ecommerce', 'auditoria',
  'logistica', 'crm', 'manufactura', 'flota', 'shipping',
  'report-studio', 'addons',
  'cms',
] as const;

export type SystemModule = typeof SYSTEM_MODULES[number];

/** Default modules for users without specific assignments */
const DEFAULT_MODULES: SystemModule[] = [
  'dashboard', 'facturas', 'clientes', 'inventario', 'articulos',
];

export function isAdminRole(tipo: string | null | undefined): boolean {
  if (!tipo) return false;
  const u = tipo.toUpperCase();
  return u === ROLES.ADMIN || u === ROLES.SUP;
}

export function getRoleName(tipo: string | null | undefined): string {
  if (!tipo) return 'Usuario';
  const u = tipo.toUpperCase();
  if (u === ROLES.ADMIN || u === ROLES.SUP) return 'Administrador';
  return 'Usuario';
}

export function canAccessDebug(isAdmin: boolean): boolean {
  return isAdmin === true;
}

/**
 * Check if a user has access to a specific module.
 * Admins have access to everything.
 */
export function hasModuleAccess(
  modulos: string[] | null | undefined,
  modulo: SystemModule,
  isAdmin: boolean,
): boolean {
  if (isAdmin) return true;
  if (!modulos || modulos.length === 0) {
    return DEFAULT_MODULES.includes(modulo);
  }
  return modulos.includes(modulo);
}

/**
 * Get the effective module list for a user.
 * Admins get all modules, users get their assigned list or defaults.
 */
export function getEffectiveModules(
  modulos: string[] | null | undefined,
  isAdmin: boolean,
): string[] {
  if (isAdmin) return [...SYSTEM_MODULES];
  if (!modulos || modulos.length === 0) return [...DEFAULT_MODULES];
  return modulos;
}

/**
 * Get default permisos (all false for safety).
 */
export function getDefaultPermisos(): UserPermisos {
  return {
    canUpdate: false,
    canCreate: false,
    canDelete: false,
    canChangePrice: false,
    canGiveCredit: false,
    canChangePwd: false,
    isCreator: false,
  };
}
