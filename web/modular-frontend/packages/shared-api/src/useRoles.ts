'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { iamGet, iamPost, iamPut, iamDelete, apiGet, apiPost } from './api';

const QK_ROLES = 'roles';
const QK_ROLE_PERMS = 'role-permissions';
const QK_USER_ROLES = 'user-roles';
const QK_LICENSE = 'license-limits';
const IAM_APP_ID = 'zentto-erp';

// ─── Types ──────────────────────────────────────────────────
//
// RoleId es el UUID del IAM (fuente de verdad para CRUD de roles).
// erpRoleId es el ID numerico local del ERP — se usa exclusivamente
// para los hooks de permisos RBAC (/v1/permisos) que siguen en ERP.
// La pagina /configuracion/roles usa `role.erpRoleId` para los
// dialogs de permisos y `role.RoleId` (UUID) para delete/edit.

export interface Role {
  RoleId: string;       // UUID del IAM
  RoleCode: string;
  RoleName: string;
  IsSystem: boolean;
  IsActive: boolean;
  UserCount: number;
  erpRoleId?: number;   // ID numerico ERP — solo para permission hooks
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
  RoleId: string;
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

// ─── Mapper IAM → Role ──────────────────────────────────────
interface IamRoleRaw {
  RoleId: string;
  Code: string;
  Name: string;
  Description: string | null;
  IsSystem: boolean;
  IsActive: boolean;
  userCount?: number;
}

function iamRoleToRole(r: IamRoleRaw, erpRoleId?: number): Role {
  return {
    RoleId: r.RoleId,
    RoleCode: r.Code,
    RoleName: r.Name,
    IsSystem: r.IsSystem,
    IsActive: r.IsActive,
    UserCount: r.userCount ?? 0,
    erpRoleId,
  };
}

// ─── Roles CRUD (IAM) ────────────────────────────────────────
export function useRolesList() {
  return useQuery<{ rows: Role[] }>({
    queryKey: [QK_ROLES],
    queryFn: async () => {
      // Fetch IAM (fuente de verdad) + ERP en paralelo para obtener erpRoleId
      // El erpRoleId solo se necesita para los hooks de permisos RBAC del ERP.
      const [iamRes, erpRes] = await Promise.all([
        iamGet('roles', { appId: IAM_APP_ID }),
        apiGet('/v1/roles').catch(() => ({ rows: [] })),
      ]);
      const iamRows = (iamRes as { rows: IamRoleRaw[] }).rows ?? [];
      const erpRows = (erpRes as { rows: Array<{ RoleId: number; RoleCode: string }> }).rows ?? [];
      const erpByCode = new Map(erpRows.map((r) => [r.RoleCode, r.RoleId]));
      return {
        rows: iamRows.map((r) => iamRoleToRole(r, erpByCode.get(r.Code))),
      };
    },
  });
}

export function useCreateRole() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: CreateRoleInput) =>
      iamPost('roles', {
        appId: IAM_APP_ID,
        code: input.roleCode.toUpperCase(),
        name: input.roleName,
      }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_ROLES] }),
  });
}

export function useDeleteRole() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (roleId: string) => iamDelete(`roles/${roleId}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_ROLES] }),
  });
}

// ─── Role Permissions (ERP RBAC — permanece en ERP local) ───
//
// La matriz de permisos granulares (CanCreate/Read/Update/Delete/Export/Approve)
// es un concepto del ERP y no existe en el IAM. Estos hooks siguen llamando
// al ERP con el ID numerico local (erpRoleId).
export function useRolePermissions(erpRoleId: number | null) {
  return useQuery<{ rows: RolePermission[] }>({
    queryKey: [QK_ROLE_PERMS, erpRoleId],
    queryFn: () => apiGet(`/v1/permisos/roles/${erpRoleId}/permisos`),
    enabled: !!erpRoleId,
  });
}

export function useSaveRolePermissions(erpRoleId: number) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (perms: BulkPermissionInput[]) =>
      apiPost(`/v1/permisos/roles/${erpRoleId}/permisos/bulk`, { permissions: perms }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_ROLE_PERMS, erpRoleId] }),
  });
}

// ─── User-Role Assignment (IAM) ─────────────────────────────
export function useUserRoles(userId: string | null) {
  return useQuery<{ rows: UserRole[] }>({
    queryKey: [QK_USER_ROLES, userId],
    queryFn: async () => {
      const res = await iamGet(`users/${userId}/roles`, { appId: IAM_APP_ID });
      const rows = (res as { rows: Array<{ RoleId: string; Code: string; Name: string }> }).rows ?? [];
      return {
        rows: rows.map((r) => ({ RoleId: r.RoleId, RoleCode: r.Code, RoleName: r.Name })),
      };
    },
    enabled: !!userId,
  });
}

export function useAssignUserRole(userId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (roleId: string) => {
      // Resolver el Code del rol desde su UUID para la API IAM
      const allRoles = await iamGet('roles', { appId: IAM_APP_ID });
      const role = ((allRoles as { rows: IamRoleRaw[] }).rows ?? []).find(
        (r) => r.RoleId === roleId,
      );
      if (!role) throw new Error('Rol no encontrado');
      return iamPut(`users/${userId}/roles`, {
        appId: IAM_APP_ID,
        roleCodes: [role.Code],
      });
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [QK_USER_ROLES, userId] });
      qc.invalidateQueries({ queryKey: [QK_ROLES] });
    },
  });
}

// ─── License Limits (ERP — se mantiene) ─────────────────────
export function useLicenseLimits() {
  return useQuery<LicenseLimits>({
    queryKey: [QK_LICENSE],
    queryFn: () => apiGet('/v1/roles/license/limits'),
  });
}
