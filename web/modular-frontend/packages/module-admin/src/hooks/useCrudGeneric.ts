// hooks/useCrudGeneric.ts
/**
 * HOOK GENÉRICO REUSABLE PARA CUALQUIER ENTIDAD CRUD
 * Este hook encapsula la lógica de consumo de API con React Query
 * 
 * Uso:
 * const clientes = useCrudGeneric<Cliente, CreateClienteDTO>('clientes');
 * const { list, details, create, update, delete: remove } = clientes;
 */

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { apiDelete, apiGet, apiPost, apiPut } from '@datqbox/shared-api';

interface CrudGenericOptions {
  baseUrl: string;
  endpoint: string;
}

interface UseCrudGenericReturn<T, CreateDTO> {
  // Queries
  list: (filters?: any) => any;
  getById: (id: string) => any;

  // Mutations
  create: () => any;
  update: (id: string) => any;
  delete: (id: string) => any;

  // Utils
  invalidateList: () => void;
}

export function useCrudGeneric<T extends { codigo?: string; id?: string }, CreateDTO = any>(
  endpoint: string,
  baseUrl = '/api/v1'
): UseCrudGenericReturn<T, CreateDTO> {
  const queryClient = useQueryClient();
  const url = `${baseUrl}/${endpoint}`;

  const normalizeRow = (row: any): T => {
    if (!row || typeof row !== 'object') return row as T;
    const get = (...keys: string[]) => {
      for (const key of keys) {
        if (row[key] !== undefined && row[key] !== null) return row[key];
      }
      return undefined;
    };

    return {
      ...row,
      codigo: get('codigo', 'CODIGO', 'Codigo'),
      nombre: get('nombre', 'NOMBRE', 'Nombre'),
      rif: get('rif', 'RIF', 'Rif'),
      email: get('email', 'EMAIL', 'Email'),
      telefono: get('telefono', 'TELEFONO', 'Telefono'),
      direccion: get('direccion', 'DIRECCION', 'Direccion'),
      estado: get('estado', 'ESTADO', 'Estado'),
      saldo: Number(get('saldo', 'SALDO', 'SALDO_TOT') ?? 0),
    } as T;
  };

  const normalizeListPayload = (raw: any, filters?: any) => {
    const rows = (raw?.items ?? raw?.data ?? raw?.rows ?? []) as any[];
    const items = rows.map(normalizeRow);
    const total = Number(raw?.total ?? items.length);
    const page = Number(raw?.page ?? filters?.page ?? 1);
    const pageSize = Number(raw?.pageSize ?? raw?.limit ?? filters?.limit ?? (items.length || 1));
    const totalPages = Number(raw?.totalPages ?? Math.max(1, Math.ceil(total / Math.max(1, pageSize))));
    return { items, data: items, total, page, pageSize, totalPages };
  };

  // ========== QUERIES ==========

  const list = (filters?: any) =>
    useQuery({
      queryKey: [endpoint, 'list', filters],
      queryFn: async () => {
        const params = new URLSearchParams();
        if (filters) {
          const normalizedFilters = { ...filters } as Record<string, unknown>;
          if (normalizedFilters.status != null && normalizedFilters.estado == null) {
            const status = String(normalizedFilters.status).toLowerCase();
            if (status === 'active') normalizedFilters.estado = 'Activo';
            else if (status === 'inactive') normalizedFilters.estado = 'Inactivo';
            else normalizedFilters.estado = normalizedFilters.status;
          }
          delete normalizedFilters.status;

          Object.entries(normalizedFilters).forEach(([key, value]) => {
            if (value !== undefined && value !== null) {
              params.append(key, String(value));
            }
          });
        }
        const query = params.toString();
        const raw = await apiGet(`${url}${query ? `?${query}` : ''}`);
        return normalizeListPayload(raw, filters);
      },
    });

  const getById = (id: string) =>
    useQuery({
      queryKey: [endpoint, 'detail', id],
      queryFn: async () => normalizeRow(await apiGet(`${url}/${id}`)),
      enabled: !!id,
    });

  // ========== MUTATIONS ==========

  const create = () =>
    useMutation({
      mutationFn: async (data: CreateDTO) => {
        return apiPost(url, data);
      },
      onSuccess: () => {
        queryClient.invalidateQueries({ queryKey: [endpoint, 'list'] });
      },
    });

  const update = (id: string) =>
    useMutation({
      mutationFn: async (data: Partial<CreateDTO>) => {
        return apiPut(`${url}/${id}`, data);
      },
      onSuccess: () => {
        queryClient.invalidateQueries({ queryKey: [endpoint, 'list'] });
        queryClient.invalidateQueries({ queryKey: [endpoint, 'detail', id] });
      },
    });

  const deleteItem = (id: string) =>
    useMutation({
      mutationFn: async () => {
        return apiDelete(`${url}/${id}`);
      },
      onSuccess: () => {
        queryClient.invalidateQueries({ queryKey: [endpoint, 'list'] });
      },
    });

  // ========== UTILS ==========

  const invalidateList = () => {
    queryClient.invalidateQueries({ queryKey: [endpoint, 'list'] });
  };

  return {
    list,
    getById,
    create,
    update,
    delete: deleteItem,
    invalidateList,
  };
}

// ============================================================================
// HOOKS ESPECÍFICOS - Ejemplos de uso
// ============================================================================

import {
  Cliente,
  CreateClienteDTO,
  UpdateClienteDTO,
  Proveedor,
  CreateProveedorDTO,
  Articulo,
  CreateArticuloDTO,
} from '@datqbox/shared-api/types';

/**
 * Hook para CLIENTES
 * Uso:
 * const { list, getById, create } = useClientes();
 * const { data, isLoading } = list({ search: 'juan' });
 */
export function useClientes() {
  const crud = useCrudGeneric<Cliente, CreateClienteDTO>('clientes');
  const queryClient = useQueryClient();

  return {
    ...crud,
    // Puedes agregar métodos específicos si es necesario
    listActive: (filters?: any) =>
      queryClient.getQueryData([
        'clientes',
        'list',
        { ...filters, estado: 'Activo' },
      ]),
  };
}

/**
 * Hook para PROVEEDORES
 */
export function useProveedores() {
  return useCrudGeneric<Proveedor, CreateProveedorDTO>('proveedores');
}

/**
 * Hook para ARTÍCULOS
 */
export function useArticulos() {
  return useCrudGeneric<Articulo, CreateArticuloDTO>('articulos');
}

