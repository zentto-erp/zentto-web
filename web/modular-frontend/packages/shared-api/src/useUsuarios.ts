"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { iamGet, iamPost, iamPut, iamDelete } from "./api";

const QK = "usuarios";

// ─── Types ──────────────────────────────────────────────────
//
// Mantenemos los tipos legacy del ERP (Usuario, ModuloAcceso, etc.)
// como SHAPE EXTERNO para no romper las paginas existentes
// (/configuracion/usuarios, /configuracion/roles). Internamente
// los hooks llaman a zentto-auth via /api/iam/* y mapean el
// IamUser → Usuario.
//
// Mapping ERP ↔ zentto-auth:
//   Cod_Usuario  ←→  Username (UPPER)
//   Nombre       ←→  DisplayName
//   Tipo         ←→  isAdmin? "ADMIN" : "USER" (legacy: "SUP" tambien admin)
//   Updates/Addnews/Deletes/etc → derivados de UserModulePermission o
//                                  asumidos true para admin
//   modulosAcceso → derivado de UserModuleAccess

export interface Usuario {
  Cod_Usuario: string;
  Nombre: string;
  Tipo: string;
  Updates: boolean;
  Addnews: boolean;
  Deletes: boolean;
  Creador: boolean;
  Cambiar: boolean;
  PrecioMinimo: boolean;
  Credito: boolean;
  modulosAcceso?: ModuloAcceso[];
  // Campos extra IAM expuestos para futuras paginas:
  UserId?: string;
  Email?: string | null;
  IsActive?: boolean;
  EmailVerified?: boolean;
  UserType?: string;
}

export interface ModuloAcceso {
  Modulo: string;
  Permitido: boolean;
}

export interface CreateUsuarioInput {
  Cod_Usuario: string;
  Password: string;
  Nombre?: string;
  Tipo?: string;
  Updates?: boolean;
  Addnews?: boolean;
  Deletes?: boolean;
  Creador?: boolean;
  Cambiar?: boolean;
  PrecioMinimo?: boolean;
  Credito?: boolean;
  Email?: string | null;
}

export interface UpdateUsuarioInput {
  Nombre?: string;
  Tipo?: string;
  Password?: string;
  Updates?: boolean;
  Addnews?: boolean;
  Deletes?: boolean;
  Creador?: boolean;
  Cambiar?: boolean;
  PrecioMinimo?: boolean;
  Credito?: boolean;
  Email?: string | null;
  IsActive?: boolean;
}

export interface SystemModuleInfo {
  id: string;
  label: string;
}

// ─── Mappers ────────────────────────────────────────────────
interface IamUserRaw {
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
}

function iamUserToUsuario(u: IamUserRaw): Usuario {
  return {
    Cod_Usuario: u.Username,
    Nombre: u.DisplayName ?? u.Username,
    Tipo: u.IsAdmin ? "ADMIN" : "USER",
    // Permisos: para admin TODO true; para no-admin TODO false por default.
    // El control fino se hace via UserModulePermission (sub-paso futuro).
    Updates: u.IsAdmin,
    Addnews: u.IsAdmin,
    Deletes: u.IsAdmin,
    Creador: u.IsAdmin,
    Cambiar: u.IsAdmin,
    PrecioMinimo: u.IsAdmin,
    Credito: u.IsAdmin,
    UserId: u.UserId,
    Email: u.Email,
    IsActive: u.IsActive,
    EmailVerified: u.EmailVerified,
    UserType: u.UserType,
  };
}

// ─── List usuarios ──────────────────────────────────────────
export function useUsuariosList(search?: string) {
  return useQuery<{ rows: Usuario[]; total: number }>({
    queryKey: [QK, "list", search],
    queryFn: async () => {
      const res = await iamGet("users", search ? { search, limit: 200 } : { limit: 200 });
      const raw = (res as { rows: IamUserRaw[]; total: number }).rows ?? [];
      return {
        rows: raw.map(iamUserToUsuario),
        total: (res as { total: number }).total ?? raw.length,
      };
    },
  });
}

// ─── Get single usuario ─────────────────────────────────────
export function useUsuario(codigo: string | null) {
  return useQuery<Usuario>({
    queryKey: [QK, "detail", codigo],
    queryFn: async () => {
      // El IAM usa UserId (UUID), no Cod_Usuario. Tenemos que buscar primero.
      const list = await iamGet("users", { search: codigo, limit: 1 });
      const raw = (list as { rows: IamUserRaw[] }).rows?.[0];
      if (!raw) throw new Error("Usuario no encontrado");
      return iamUserToUsuario(raw);
    },
    enabled: !!codigo,
  });
}

// ─── Create usuario ─────────────────────────────────────────
export function useCreateUsuario() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (data: CreateUsuarioInput) => {
      // El admin/users de zentto-auth requiere email. Si no viene,
      // se genera desde Cod_Usuario.
      const username = data.Cod_Usuario.toUpperCase();
      const email =
        data.Email ?? `${username.toLowerCase().replace(/[^a-z0-9._-]/g, "")}@zentto.local`;
      const isAdmin = data.Tipo === "ADMIN" || data.Tipo === "SUP";
      return iamPost("users", {
        username,
        email,
        password: data.Password,
        displayName: data.Nombre ?? username,
        isAdmin,
        userType: "staff",
      });
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK] }),
  });
}

// ─── Update usuario ─────────────────────────────────────────
export function useUpdateUsuario(codigo: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (data: UpdateUsuarioInput) => {
      // Resolver UserId desde Cod_Usuario
      const list = await iamGet("users", { search: codigo, limit: 1 });
      const raw = (list as { rows: IamUserRaw[] }).rows?.[0];
      if (!raw) throw new Error("Usuario no encontrado");
      const updates: Record<string, unknown> = {};
      if (data.Nombre !== undefined) updates.displayName = data.Nombre;
      if (data.Email !== undefined) updates.email = data.Email;
      if (data.IsActive !== undefined) updates.isActive = data.IsActive;
      if (data.Tipo !== undefined) {
        updates.isAdmin = data.Tipo === "ADMIN" || data.Tipo === "SUP";
      }
      return iamPut(`users/${raw.UserId}`, updates);
      // Nota: change-password va por endpoint separado /admin/users/:id/password (no implementado aun)
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK] }),
  });
}

// ─── Delete usuario ─────────────────────────────────────────
export function useDeleteUsuario() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (codigo: string) => {
      const list = await iamGet("users", { search: codigo, limit: 1 });
      const raw = (list as { rows: IamUserRaw[] }).rows?.[0];
      if (!raw) throw new Error("Usuario no encontrado");
      return iamDelete(`users/${raw.UserId}`);
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK] }),
  });
}

// ─── Get system modules list ────────────────────────────────
export function useSystemModules() {
  return useQuery<SystemModuleInfo[]>({
    queryKey: [QK, "modules"],
    queryFn: async () => {
      const res = await iamGet("apps/zentto-erp/modules");
      const rows = (res as { rows: Array<{ Code: string; Name: string }> }).rows ?? [];
      return rows.map((m) => ({ id: m.Code, label: m.Name }));
    },
  });
}

// ─── Get module access for a user ───────────────────────────
export function useUsuarioModulos(codigo: string | null) {
  return useQuery<ModuloAcceso[]>({
    queryKey: [QK, "modulos", codigo],
    queryFn: async () => {
      // Resolver UserId
      const list = await iamGet("users", { search: codigo, limit: 1 });
      const raw = (list as { rows: IamUserRaw[] }).rows?.[0];
      if (!raw) return [];
      const res = await iamGet(`users/${raw.UserId}/modules`, { appId: "zentto-erp" });
      const rows = (res as { rows: Array<{ Code: string }> }).rows ?? [];
      return rows.map((m) => ({ Modulo: m.Code, Permitido: true }));
    },
    enabled: !!codigo,
  });
}

// ─── Set module access for a user ───────────────────────────
export function useSetUsuarioModulos(codigo: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (modulos: { modulo: string; permitido: boolean }[]) => {
      const list = await iamGet("users", { search: codigo, limit: 1 });
      const raw = (list as { rows: IamUserRaw[] }).rows?.[0];
      if (!raw) throw new Error("Usuario no encontrado");
      const moduleCodes = modulos.filter((m) => m.permitido).map((m) => m.modulo);
      return iamPut(`users/${raw.UserId}/modules`, {
        appId: "zentto-erp",
        moduleCodes,
      });
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [QK, "modulos", codigo] });
      qc.invalidateQueries({ queryKey: [QK, "detail", codigo] });
    },
  });
}

// ─── Reset password (admin) ─────────────────────────────────
// TODO: implementar endpoint /admin/users/:id/password en zentto-auth
// Por ahora retorna no-op para no romper la UI.
export function useResetPassword() {
  return useMutation({
    mutationFn: async (_data: { codUsuario: string; newPassword: string }) => {
      throw new Error("Reset password aun no implementado en zentto-auth /admin");
    },
  });
}

// ─── Change own password ────────────────────────────────────
export function useChangePassword() {
  return useMutation({
    mutationFn: async (_data: { currentPassword: string; newPassword: string }) => {
      throw new Error("Change password aun no implementado en zentto-auth");
    },
  });
}
