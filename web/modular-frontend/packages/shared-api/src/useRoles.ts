'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiGet, apiPost, apiDelete } from './api';

const QK_ROLES = 'roles';
const QK_ROLE_PERMS = 'role-permissions';
const QK_USER_ROLES = 'user-roles';
const QK_LICENSE = 'license-limits';

// ─── Types ──────────────────────────────────────────────────
export interface Role {
  RoleId: number;
  RoleCode: string;
  RoleName: string;
  IsSystem: boolean;
  IsActive: boolean;
  UserCount: number;
}

export interface CreateRoleInput {
  roleCode: string;
  roleName: string;
}

export interface RolePermission {
  PermissionId: number;
  PermissionCode: string;
  PermissionName: string;
  ModuleName: string;
  CanCreate: boolean;
  CanRead: boolean;
  CanUpdate: boolean;
  CanDelete: boolean;
  CanExport: boolean;
  CanApprove: boolean;
}

export interface BulkPermissionInput {
  permissionId: number;
  canCreate: boolean;
  canRead: boolean;
  canUpdate: boolean;
  canDelete: boolean;
  canExport: boolean;
  canApprove: boolean;
}

export interface UserRole {
  RoleId: number;
  RoleCode: string;
  RoleName: string;
}

export interface LicenseLimits {
  plan: string;
  maxUsers: number;
  currentUsers: number;
  maxCompanies: number;
  currentCompanies: number;
  multiCompany: boolean;
}

// ─── Roles CRUD ─────────────────────────────────────────────
export function useRolesList() {
  return useQuery<{ rows: Role[] }>({
    queryKey: [QK_ROLES],
    queryFn: () => apiGet('/v1/roles'),
  });
}

export function useCreateRole() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: CreateRoleInput) => apiPost('/v1/roles', input),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_ROLES] }),
  });
}

export function useDeleteRole() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (roleId: number) => apiDelete(`/v1/roles/${roleId}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_ROLES] }),
  });
}

// ─── Role Permissions ───────────────────────────────────────
export function useRolePermissions(roleId: number | null) {
  return useQuery<{ rows: RolePermission[] }>({
    queryKey: [QK_ROLE_PERMS, roleId],
    queryFn: () => apiGet(`/v1/permisos/roles/${roleId}/permisos`),
    enabled: !!roleId,
  });
}

export function useSaveRolePermissions(roleId: number) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (perms: BulkPermissionInput[]) =>
      apiPost(`/v1/permisos/roles/${roleId}/permisos/bulk`, { permissions: perms }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_ROLE_PERMS, roleId] }),
  });
}

// ─── User-Role Assignment ───────────────────────────────────
export function useUserRoles(userId: string | null) {
  return useQuery<{ rows: UserRole[] }>({
    queryKey: [QK_USER_ROLES, userId],
    queryFn: () => apiGet(`/v1/roles/usuarios/${userId}`),
    enabled: !!userId,
  });
}

export function useAssignUserRole(userId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (roleId: number) =>
      apiPost(`/v1/roles/usuarios/${userId}`, { roleId }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [QK_USER_ROLES, userId] });
      qc.invalidateQueries({ queryKey: [QK_ROLES] });
    },
  });
}

// ─── License Limits ─────────────────────────────────────────
export function useLicenseLimits() {
  return useQuery<LicenseLimits>({
    queryKey: [QK_LICENSE],
    queryFn: () => apiGet('/v1/roles/license/limits'),
  });
}
