"use client";

export { AuthProvider, useAuth } from './AuthContext';
export type { AuthContextType } from './AuthContext';
export {
  ROLES, isAdminRole, getRoleName, canAccessDebug,
  SYSTEM_MODULES, hasModuleAccess, getEffectiveModules, getDefaultPermisos,
} from './roles';
export type { Role, UserPermisos, SystemModule } from './roles';
export { AUTH_ROUTES, PUBLIC_ROUTES, isPublicRoute, getRedirectRoute } from './config';
export { default as AuthLogin } from './auth/AuthLogin';
