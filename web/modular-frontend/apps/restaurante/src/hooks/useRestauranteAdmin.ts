'use client';

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { apiDelete, apiGet, apiPost, apiPut } from '@zentto/shared-api';

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

export interface RecetaItemAdmin {
    id: number;
    productoId: number;
    inventarioId: string;
    inventarioNombre?: string;
    cantidad: number;
    unidad?: string;
    comentario?: string;
}

export interface ProductoMenuDetalleAdmin {
    producto: ProductoMenuAdmin | null;
    receta: RecetaItemAdmin[];
}

export interface InventarioLookupItem {
    codigo: string;
    descripcion: string;
    unidad?: string;
    existencia?: number;
}

export interface AmbienteAdmin {
    id: number;
    nombre: string;
    color: string;
    orden: number;
}

export interface CompraRestauranteAdmin {
    id: number;
    numCompra?: string;
    proveedorId?: string;
    proveedorNombre?: string;
    fechaCompra?: string;
    estado?: string;
    total?: number;
}

export interface CompraDetalleRowAdmin {
    id?: number;
    compraId?: number;
    inventarioId?: string;
    descripcion?: string;
    cantidad?: number;
    precioUnit?: number;
    subtotal?: number;
    iva?: number;
}

export interface CompraDetalleResponse {
    compra: Record<string, unknown> | null;
    detalle: CompraDetalleRowAdmin[];
}

export interface ProveedorLookupItem {
    id: string;
    codigo: string;
    nombre: string;
    rif?: string;
}

export interface CompraDetalleInput {
    descripcion: string;
    cantidad: number;
    precioUnit: number;
    iva?: number;
    inventarioId?: string;
}

export interface CreateProveedorInput {
    codigo: string;
    nombre: string;
    rif?: string;
    telefono?: string;
    direccion?: string;
}

export interface CreateInventarioInput {
    codigo: string;
    descripcion: string;
    unidad?: string;
}

const RESTAURANTE_ADMIN_KEYS = {
    productos: ['restaurante', 'admin', 'productos'] as const,
    categorias: ['restaurante', 'admin', 'categorias'] as const,
    ambientes: ['restaurante', 'admin', 'ambientes'] as const,
};

type ApiRow = Record<string, unknown>;

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

export function useComprasAdminQuery(filters?: { estado?: string; from?: string; to?: string }) {
    return useQuery({
        queryKey: ['restaurante', 'admin', 'compras', filters],
        queryFn: async () => {
            const data = await apiGet('/v1/restaurante/admin/compras', filters) as { rows?: ApiRow[] };
            const rows: CompraRestauranteAdmin[] = (data.rows ?? []).map((row: ApiRow) => ({
                id: Number(row.id ?? row.Id ?? 0),
                numCompra: String(row.numCompra ?? row.NumCompra ?? ''),
                proveedorId: String(row.proveedorId ?? row.ProveedorId ?? ''),
                proveedorNombre: String(row.proveedorNombre ?? row.ProveedorNombre ?? ''),
                fechaCompra: String(row.fechaCompra ?? row.FechaCompra ?? ''),
                estado: String(row.estado ?? row.Estado ?? ''),
                total: Number(row.total ?? row.Total ?? 0),
            }));
            return { rows };
        },
    });
}

export function useCompraDetalleQuery(compraId?: number) {
    return useQuery({
        queryKey: ['restaurante', 'admin', 'compras', 'detalle', compraId],
        enabled: Boolean(compraId),
        queryFn: async () => {
            const data = await apiGet(`/v1/restaurante/admin/compras/${compraId}`) as { compra?: ApiRow; detalle?: ApiRow[] };
            const compraRaw = data.compra ?? null;
            const compra = compraRaw
                ? {
                    ...compraRaw,
                    id: Number(compraRaw.id ?? compraRaw.Id ?? 0),
                    numCompra: String(compraRaw.numCompra ?? compraRaw.NumCompra ?? ''),
                    proveedorId: String(compraRaw.proveedorId ?? compraRaw.ProveedorId ?? ''),
                    proveedorNombre: String(compraRaw.proveedorNombre ?? compraRaw.ProveedorNombre ?? ''),
                    fechaCompra: String(compraRaw.fechaCompra ?? compraRaw.FechaCompra ?? ''),
                    estado: String(compraRaw.estado ?? compraRaw.Estado ?? ''),
                    subtotal: Number(compraRaw.subtotal ?? compraRaw.Subtotal ?? 0),
                    iva: Number(compraRaw.iva ?? compraRaw.IVA ?? 0),
                    total: Number(compraRaw.total ?? compraRaw.Total ?? 0),
                }
                : null;

            const detalle: CompraDetalleRowAdmin[] = (data.detalle ?? []).map((row: ApiRow) => ({
                id: Number(row.id ?? row.Id ?? 0) || undefined,
                compraId: Number(row.compraId ?? row.CompraId ?? 0) || undefined,
                inventarioId: String(row.inventarioId ?? row.InventarioId ?? ''),
                descripcion: String(row.descripcion ?? row.Descripcion ?? ''),
                cantidad: Number(row.cantidad ?? row.Cantidad ?? 0),
                precioUnit: Number(row.precioUnit ?? row.PrecioUnit ?? 0),
                subtotal: Number(row.subtotal ?? row.Subtotal ?? 0),
                iva: Number(row.iva ?? row.IVA ?? 0),
            }));

            return { compra, detalle } as CompraDetalleResponse;
        },
    });
}

export function useProveedoresLookupQuery(searchText: string, enabled = true) {
    return useQuery({
        queryKey: ['restaurante', 'admin', 'proveedores-lookup', searchText],
        enabled,
        queryFn: async () => {
            const data = await apiGet('/v1/restaurante/admin/proveedores', {
                search: searchText || undefined,
                limit: 20,
            }) as { rows?: ApiRow[] };

            const rows: ProveedorLookupItem[] = (data.rows ?? []).map((row: ApiRow) => ({
                id: String(row.id ?? row.codigo ?? '').trim(),
                codigo: String(row.codigo ?? row.id ?? '').trim(),
                nombre: String(row.nombre ?? '').trim(),
                rif: String(row.rif ?? '').trim() || undefined,
            })).filter((row) => row.id.length > 0);

            return { rows };
        },
    });
}

export function useCreateCompraMutation() {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: async (payload: {
            proveedorId?: string;
            observaciones?: string;
            codUsuario?: string;
            detalle: CompraDetalleInput[];
        }) => apiPost('/v1/restaurante/admin/compras', payload),
        onSuccess: async () => {
            await queryClient.invalidateQueries({ queryKey: ['restaurante', 'admin', 'compras'] });
            await queryClient.invalidateQueries({ queryKey: ['restaurante', 'admin', 'insumos-list'] });
            await queryClient.invalidateQueries({ queryKey: ['restaurante', 'admin', 'insumos-lookup'] });
        },
    });
}

export function useUpdateCompraMutation() {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: async (payload: { id: number; proveedorId?: string; estado?: string; observaciones?: string }) =>
            apiPut(`/v1/restaurante/admin/compras/${payload.id}`, payload),
        onSuccess: async () => {
            await queryClient.invalidateQueries({ queryKey: ['restaurante', 'admin', 'compras'] });
        },
    });
}

export function useUpsertCompraDetalleMutation() {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: async (payload: {
            compraId: number;
            id?: number;
            inventarioId?: string;
            descripcion: string;
            cantidad: number;
            precioUnit: number;
            iva?: number;
        }) => apiPost(`/v1/restaurante/admin/compras/${payload.compraId}/detalle`, payload),
        onSuccess: async (_data, variables) => {
            await queryClient.invalidateQueries({ queryKey: ['restaurante', 'admin', 'compras'] });
            await queryClient.invalidateQueries({ queryKey: ['restaurante', 'admin', 'compras', 'detalle', variables.compraId] });
        },
    });
}

export function useDeleteCompraDetalleMutation() {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: async (payload: { compraId: number; detalleId: number }) =>
            apiDelete(`/v1/restaurante/admin/compras/${payload.compraId}/detalle/${payload.detalleId}`),
        onSuccess: async (_data, variables) => {
            await queryClient.invalidateQueries({ queryKey: ['restaurante', 'admin', 'compras'] });
            await queryClient.invalidateQueries({ queryKey: ['restaurante', 'admin', 'compras', 'detalle', variables.compraId] });
        },
    });
}

export function useCreateProveedorMutation() {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: async (payload: CreateProveedorInput) => apiPost('/v1/proveedores', {
            CODIGO: payload.codigo,
            NOMBRE: payload.nombre,
            RIF: payload.rif,
            TELEFONO: payload.telefono,
            DIRECCION: payload.direccion,
            ESTADO: 'ACTIVO',
        }),
        onSuccess: async () => {
            await queryClient.invalidateQueries({ queryKey: ['restaurante', 'admin', 'proveedores-lookup'] });
        },
    });
}

export function useCreateInventarioMutation() {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: async (payload: CreateInventarioInput) => apiPost('/v1/inventario', {
            CODIGO: payload.codigo,
            DESCRIPCION: payload.descripcion,
            Unidad: payload.unidad || 'UND',
            EXISTENCIA: 0,
            PRECIO_COMPRA: 0,
            PRECIO_VENTA: 0,
            CATEGORIA: 'RESTAURANTE',
            TIPO: 'INSUMO',
            MARCA: '',
            CLASE: '',
            Linea: 'RESTAURANTE',
        }),
        onSuccess: async () => {
            await queryClient.invalidateQueries({ queryKey: ['restaurante', 'admin', 'insumos-list'] });
            await queryClient.invalidateQueries({ queryKey: ['restaurante', 'admin', 'insumos-lookup'] });
        },
    });
}

export function useUpsertProductoAdminMutation() {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: async (payload: Record<string, unknown>) => apiPost('/v1/restaurante/admin/productos', payload),
        onSuccess: async () => {
            await queryClient.invalidateQueries({ queryKey: RESTAURANTE_ADMIN_KEYS.productos });
            await queryClient.invalidateQueries({ queryKey: ['restaurante', 'admin', 'insumos-list'] });
            await queryClient.invalidateQueries({ queryKey: ['restaurante', 'admin', 'insumos-lookup'] });
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

export function useProductoDetalleAdminQuery(productoId?: number) {
    return useQuery({
        queryKey: ['restaurante', 'admin', 'producto', productoId],
        enabled: Boolean(productoId),
        queryFn: async () => apiGet(`/v1/restaurante/admin/productos/${productoId}`) as Promise<ProductoMenuDetalleAdmin>,
    });
}

export function useUpsertRecetaItemMutation() {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: async (payload: Record<string, unknown>) => apiPost('/v1/restaurante/admin/recetas', payload),
        onSuccess: async (_result, variables) => {
            const vars = variables as { productoId?: number | string };
            const productoId = Number(vars?.productoId);
            if (productoId) {
                await queryClient.invalidateQueries({ queryKey: ['restaurante', 'admin', 'producto', productoId] });
            }
        },
    });
}

export function useDeleteRecetaItemMutation() {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: async (payload: { id: number; productoId: number }) => {
            await apiDelete(`/v1/restaurante/admin/recetas/${payload.id}`);
            return payload;
        },
        onSuccess: async (payload) => {
            await queryClient.invalidateQueries({ queryKey: ['restaurante', 'admin', 'producto', payload.productoId] });
        },
    });
}

export function useInsumosRestauranteLookupQuery(searchText: string, enabled = true) {
    return useQuery({
        queryKey: ['restaurante', 'admin', 'insumos-lookup', searchText],
        enabled,
        queryFn: async () => {
            const data = await apiGet('/v1/restaurante/admin/insumos', {
                search: searchText || undefined,
                limit: 20,
            }) as { rows?: ApiRow[] };

            const rows = data?.rows ?? [];
            const mapped: InventarioLookupItem[] = rows.map((row: ApiRow) => ({
                codigo: String(row.CODIGO ?? row.codigo ?? '').trim(),
                descripcion: String(row.DESCRIPCION ?? row.descripcion ?? row.DescripcionCompleta ?? '').trim(),
                unidad: String(row.Unidad ?? row.unidad ?? '').trim() || undefined,
                existencia: Number(row.EXISTENCIA ?? row.existencia ?? 0),
            })).filter((item) => item.codigo.length > 0);

            return { rows: mapped };
        },
    });
}

export function useInsumosAdminQuery(searchText?: string) {
    return useQuery({
        queryKey: ['restaurante', 'admin', 'insumos-list', searchText],
        queryFn: async () => {
            const data = await apiGet('/v1/restaurante/admin/insumos', {
                search: searchText || undefined,
                limit: 100,
            }) as { rows?: ApiRow[] };

            const rows = (data.rows ?? []).map((row: ApiRow) => ({
                codigo: String(row.codigo ?? row.CODIGO ?? '').trim(),
                descripcion: String(row.descripcion ?? row.DESCRIPCION ?? '').trim(),
                unidad: String(row.unidad ?? row.Unidad ?? '').trim() || '',
                existencia: Number(row.existencia ?? row.EXISTENCIA ?? 0),
            }));

            return { rows };
        },
    });
}
