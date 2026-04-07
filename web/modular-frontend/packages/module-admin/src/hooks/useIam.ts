/**
 * Hooks IAM (Identity & Access Management).
 *
 * Consumen los endpoints /admin/* del microservicio zentto-auth via el
 * proxy local /api/iam/* del shell. Estos hooks son para la UI de
 * administracion central de identidad: usuarios, empresas, modulos,
 * permisos y accesos.
 *
 * IMPORTANTE: requieren cookie HttpOnly de un usuario con isAdmin=true.
 * El proxy del shell reenvia la cookie a zentto-auth.
 */

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { iamGet, iamPost, iamPut, iamDelete } from '@zentto/shared-api';

// ─────────────────────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────────────────────

export type IamUser = {
  UserId: string;
  Username: string;
  Email: string | null;
  DisplayName: string | null;
  IsActive: boolean;
  IsAdmin: boolean;
  EmailVerified: boolean;
  UserType: string;
  LastLoginAt: string | null;
  CreatedAt: string;
};

export type IamUserListResponse = {
  rows: IamUser[];
  total: number;
  limit: number;
  offset: number;
};

export type IamModule = {
  ModuleId: string;
  Code: string;
  Name: string;
  Description: string | null;
  Category: string | null;
  Icon: string | null;
  SortOrder: number;
  IsActive: boolean;
};

export type IamPermission = {
  PermissionId: string;
  Code: string;
  Name: string;
  Description: string | null;
  SortOrder: number;
};

export type IamApp = {
  AppId: string;
  Name: string;
  ClientId: string;
  IsActive: boolean;
};

export type IamCompany = {
  CompanyId: number;
  Code: string;
  Name: string;
  TaxId: string | null;
  CountryCode: string;
  TimeZone: string;
  Currency: string;
  Email: string | null;
  Phone: string | null;
  IsActive: boolean;
};

export type IamCompanyAccess = {
  companyId: number;
  companyCode: string;
  companyName: string;
  branchId: number | null;
  branchCode: string | null;
  branchName: string | null;
  isDefault: boolean;
};

// ─────────────────────────────────────────────────────────────
// Query keys
// ─────────────────────────────────────────────────────────────

const KEYS = {
  users: ['iam', 'users'] as const,
  user: (id: string) => ['iam', 'users', id] as const,
  userModules: (id: string, appId?: string) => ['iam', 'users', id, 'modules', appId] as const,
  userCompanies: (id: string) => ['iam', 'users', id, 'companies'] as const,
  companies: ['iam', 'companies'] as const,
  apps: ['iam', 'apps'] as const,
  appModules: (clientId: string) => ['iam', 'apps', clientId, 'modules'] as const,
  modulePermissions: (clientId: string, code: string) =>
    ['iam', 'apps', clientId, 'modules', code, 'permissions'] as const,
};

// ─────────────────────────────────────────────────────────────
// USERS
// ─────────────────────────────────────────────────────────────

export function useIamUsers(params?: { search?: string; limit?: number; offset?: number }) {
  return useQuery<IamUserListResponse>({
    queryKey: [...KEYS.users, params],
    queryFn: () => iamGet('users', params as Record<string, unknown> | undefined),
  });
}

export function useIamUser(userId: string | undefined) {
  return useQuery<IamUser>({
    queryKey: KEYS.user(userId ?? ''),
    queryFn: () => iamGet(`users/${userId}`),
    enabled: !!userId,
  });
}

export type CreateUserInput = {
  username: string;
  email?: string | null;
  password: string;
  displayName?: string | null;
  isAdmin?: boolean;
  userType?: 'staff' | 'customer';
};

export function useCreateIamUser() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: CreateUserInput) => iamPost('users', input),
    onSuccess: () => qc.invalidateQueries({ queryKey: KEYS.users }),
  });
}

export type UpdateUserInput = {
  email?: string | null;
  displayName?: string | null;
  isActive?: boolean;
  isAdmin?: boolean;
  userType?: 'staff' | 'customer';
};

export function useUpdateIamUser() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ userId, ...input }: UpdateUserInput & { userId: string }) =>
      iamPut(`users/${userId}`, input),
    onSuccess: (_data, vars) => {
      qc.invalidateQueries({ queryKey: KEYS.users });
      qc.invalidateQueries({ queryKey: KEYS.user(vars.userId) });
    },
  });
}

export function useDeleteIamUser() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (userId: string) => iamDelete(`users/${userId}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: KEYS.users }),
  });
}

// ─────────────────────────────────────────────────────────────
// USER MODULES (acceso a modulos por user)
// ─────────────────────────────────────────────────────────────

export type UserModuleRow = {
  ModuleId: string;
  Code: string;
  Name: string;
  Category: string | null;
  Icon: string | null;
  appClientId: string;
  appName: string;
};

export function useIamUserModules(userId: string | undefined, appId?: string) {
  return useQuery<{ rows: UserModuleRow[] }>({
    queryKey: KEYS.userModules(userId ?? '', appId),
    queryFn: () => iamGet(`users/${userId}/modules`, appId ? { appId } : undefined),
    enabled: !!userId,
  });
}

export function useSetIamUserModules() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({
      userId,
      appId,
      moduleCodes,
    }: {
      userId: string;
      appId: string;
      moduleCodes: string[];
    }) => iamPut(`users/${userId}/modules`, { appId, moduleCodes }),
    onSuccess: (_d, vars) => {
      qc.invalidateQueries({ queryKey: KEYS.userModules(vars.userId, vars.appId) });
      qc.invalidateQueries({ queryKey: KEYS.userModules(vars.userId, undefined) });
    },
  });
}

// ─────────────────────────────────────────────────────────────
// USER COMPANIES
// ─────────────────────────────────────────────────────────────

export function useIamUserCompanies(userId: string | undefined) {
  return useQuery<{ rows: IamCompanyAccess[] }>({
    queryKey: KEYS.userCompanies(userId ?? ''),
    queryFn: () => iamGet(`users/${userId}/companies`),
    enabled: !!userId,
  });
}

export function useSetIamUserCompanies() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({
      userId,
      accesses,
    }: {
      userId: string;
      accesses: Array<{
        companyId: number;
        branchId?: number | null;
        isDefault?: boolean;
      }>;
    }) => iamPut(`users/${userId}/companies`, { accesses }),
    onSuccess: (_d, vars) => {
      qc.invalidateQueries({ queryKey: KEYS.userCompanies(vars.userId) });
    },
  });
}

// ─────────────────────────────────────────────────────────────
// COMPANIES
// ─────────────────────────────────────────────────────────────

export function useIamCompanies() {
  return useQuery<{ rows: IamCompany[] }>({
    queryKey: KEYS.companies,
    queryFn: () => iamGet('companies'),
  });
}

export type CreateCompanyInput = {
  code: string;
  name: string;
  taxId?: string | null;
  countryCode?: string;
  timeZone?: string;
  currency?: string;
  email?: string | null;
  phone?: string | null;
};

export function useCreateIamCompany() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: CreateCompanyInput) => iamPost('companies', input),
    onSuccess: () => qc.invalidateQueries({ queryKey: KEYS.companies }),
  });
}

// ─────────────────────────────────────────────────────────────
// APPS y MODULOS (catalogo, lectura)
// ─────────────────────────────────────────────────────────────

export function useIamApps() {
  return useQuery<{ rows: IamApp[] }>({
    queryKey: KEYS.apps,
    queryFn: () => iamGet('apps'),
  });
}

export function useIamAppModules(clientId: string | undefined) {
  return useQuery<{ rows: IamModule[] }>({
    queryKey: KEYS.appModules(clientId ?? ''),
    queryFn: () => iamGet(`apps/${clientId}/modules`),
    enabled: !!clientId,
  });
}

export function useIamModulePermissions(clientId: string | undefined, moduleCode: string | undefined) {
  return useQuery<{ rows: IamPermission[] }>({
    queryKey: KEYS.modulePermissions(clientId ?? '', moduleCode ?? ''),
    queryFn: () => iamGet(`apps/${clientId}/modules/${moduleCode}/permissions`),
    enabled: !!clientId && !!moduleCode,
  });
}
