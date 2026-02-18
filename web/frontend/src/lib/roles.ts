// Utilidades para manejo de roles y permisos

export const ROLES = {
  ADMIN: 'ADMIN',
  SUP: 'SUP',      // Superusuario
  USER: 'USER',
} as const;

export type Role = typeof ROLES[keyof typeof ROLES];

/**
 * Verifica si un tipo de usuario es administrador
 */
export function isAdminRole(tipo: string | null | undefined): boolean {
  if (!tipo) return false;
  const upperTipo = tipo.toUpperCase();
  return upperTipo === ROLES.ADMIN || upperTipo === ROLES.SUP;
}

/**
 * Obtiene el nombre legible del rol
 */
export function getRoleName(tipo: string | null | undefined): string {
  if (!tipo) return 'Usuario';
  const upperTipo = tipo.toUpperCase();
  if (upperTipo === ROLES.ADMIN || upperTipo === ROLES.SUP) return 'Administrador';
  return 'Usuario';
}

/**
 * Verifica si el usuario tiene permiso para acceder al debug
 */
export function canAccessDebug(isAdmin: boolean): boolean {
  return isAdmin === true;
}
