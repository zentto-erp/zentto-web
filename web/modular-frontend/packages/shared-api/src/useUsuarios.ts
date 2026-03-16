"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost, apiPut, apiDelete } from "./api";

const QK = "usuarios";

// ─── Types ──────────────────────────────────────────────────
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
}

export interface SystemModuleInfo {
  id: string;
  label: string;
}

// ─── List usuarios ──────────────────────────────────────────
export function useUsuariosList(search?: string) {
  return useQuery<{ rows: Usuario[]; total: number }>({
    queryKey: [QK, "list", search],
    queryFn: () => apiGet("/v1/usuarios", search ? { search } : undefined),
  });
}

// ─── Get single usuario ─────────────────────────────────────
export function useUsuario(codigo: string | null) {
  return useQuery<Usuario>({
    queryKey: [QK, "detail", codigo],
    queryFn: () => apiGet(`/v1/usuarios/${codigo}`),
    enabled: !!codigo,
  });
}

// ─── Create usuario ─────────────────────────────────────────
export function useCreateUsuario() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateUsuarioInput) => apiPost("/v1/usuarios", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK] }),
  });
}

// ─── Update usuario ─────────────────────────────────────────
export function useUpdateUsuario(codigo: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: UpdateUsuarioInput) => apiPut(`/v1/usuarios/${codigo}`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK] }),
  });
}

// ─── Delete usuario ─────────────────────────────────────────
export function useDeleteUsuario() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (codigo: string) => apiDelete(`/v1/usuarios/${codigo}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK] }),
  });
}

// ─── Get system modules list ────────────────────────────────
export function useSystemModules() {
  return useQuery<SystemModuleInfo[]>({
    queryKey: [QK, "modules"],
    queryFn: () => apiGet("/v1/usuarios/modules"),
  });
}

// ─── Get module access for a user ───────────────────────────
export function useUsuarioModulos(codigo: string | null) {
  return useQuery<ModuloAcceso[]>({
    queryKey: [QK, "modulos", codigo],
    queryFn: async () => {
      const res = await apiGet(`/v1/usuarios/${codigo}/modulos`);
      // Backend returns { modulos: [...], available: [...] }
      return Array.isArray(res) ? res : (res as { modulos?: ModuloAcceso[] }).modulos ?? [];
    },
    enabled: !!codigo,
  });
}

// ─── Set module access for a user ───────────────────────────
export function useSetUsuarioModulos(codigo: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (modulos: { modulo: string; permitido: boolean }[]) =>
      apiPut(`/v1/usuarios/${codigo}/modulos`, { modulos }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [QK, "modulos", codigo] });
      qc.invalidateQueries({ queryKey: [QK, "detail", codigo] });
    },
  });
}

// ─── Reset password (admin) ─────────────────────────────────
export function useResetPassword() {
  return useMutation({
    mutationFn: (data: { codUsuario: string; newPassword: string }) =>
      apiPost("/v1/auth/reset-password", data),
  });
}

// ─── Change own password ────────────────────────────────────
export function useChangePassword() {
  return useMutation({
    mutationFn: (data: { currentPassword: string; newPassword: string }) =>
      apiPost("/v1/auth/change-password", data),
  });
}
