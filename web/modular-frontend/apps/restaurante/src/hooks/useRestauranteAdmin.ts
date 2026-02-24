'use client';

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { apiDelete, apiGet, apiPost } from '@datqbox/shared-api';

export interface CategoriaMenu {
    id: number;
    nombre: string;
}

export interface ProductoMenuAdmin {
    id: number;
    codigo: string;
    nombre: string;
    descripcion?: string;
    precio: number;
    iva: number;
    categoriaId?: number;
    disponible: boolean;
}

export interface AmbienteAdmin {
    id: number;
    nombre: string;
    color: string;
    orden: number;
}

const RESTAURANTE_ADMIN_KEYS = {
    productos: ['restaurante', 'admin', 'productos'] as const,
    categorias: ['restaurante', 'admin', 'categorias'] as const,
    ambientes: ['restaurante', 'admin', 'ambientes'] as const,
};

export function useProductosAdminQuery() {
    return useQuery({
        queryKey: RESTAURANTE_ADMIN_KEYS.productos,
        queryFn: async () => apiGet('/v1/restaurante/admin/productos') as Promise<{ rows: ProductoMenuAdmin[] }>,
    });
}

export function useCategoriasAdminQuery() {
    return useQuery({
        queryKey: RESTAURANTE_ADMIN_KEYS.categorias,
        queryFn: async () => apiGet('/v1/restaurante/admin/categorias') as Promise<{ rows: CategoriaMenu[] }>,
    });
}

export function useAmbientesAdminQuery() {
    return useQuery({
        queryKey: RESTAURANTE_ADMIN_KEYS.ambientes,
        queryFn: async () => apiGet('/v1/restaurante/admin/ambientes') as Promise<{ rows: AmbienteAdmin[] }>,
    });
}

export function useUpsertProductoAdminMutation() {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: async (payload: Record<string, unknown>) => apiPost('/v1/restaurante/admin/productos', payload),
        onSuccess: async () => {
            await queryClient.invalidateQueries({ queryKey: RESTAURANTE_ADMIN_KEYS.productos });
        },
    });
}

export function useDeleteProductoAdminMutation() {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: async (id: number) => apiDelete(`/v1/restaurante/admin/productos/${id}`),
        onSuccess: async () => {
            await queryClient.invalidateQueries({ queryKey: RESTAURANTE_ADMIN_KEYS.productos });
        },
    });
}

export function useUpsertAmbienteAdminMutation() {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: async (payload: Record<string, unknown>) => apiPost('/v1/restaurante/admin/ambientes', payload),
        onSuccess: async () => {
            await queryClient.invalidateQueries({ queryKey: RESTAURANTE_ADMIN_KEYS.ambientes });
        },
    });
}
