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

  // ========== QUERIES ==========

  const list = (filters?: any) =>
    useQuery({
      queryKey: [endpoint, 'list', filters],
      queryFn: async () => {
        const params = new URLSearchParams();
        if (filters) {
          Object.entries(filters).forEach(([key, value]) => {
            if (value !== undefined && value !== null) {
              params.append(key, String(value));
            }
          });
        }
        const res = await fetch(`${url}?${params.toString()}`);
        if (!res.ok) throw new Error(res.statusText);
        return res.json();
      },
    });

  const getById = (id: string) =>
    useQuery({
      queryKey: [endpoint, 'detail', id],
      queryFn: async () => {
        const res = await fetch(`${url}/${id}`);
        if (!res.ok) throw new Error(res.statusText);
        return res.json();
      },
      enabled: !!id,
    });

  // ========== MUTATIONS ==========

  const create = () =>
    useMutation({
      mutationFn: async (data: CreateDTO) => {
        const res = await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(data),
        });
        if (!res.ok) throw new Error(res.statusText);
        return res.json();
      },
      onSuccess: () => {
        queryClient.invalidateQueries({ queryKey: [endpoint, 'list'] });
      },
    });

  const update = (id: string) =>
    useMutation({
      mutationFn: async (data: Partial<CreateDTO>) => {
        const res = await fetch(`${url}/${id}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(data),
        });
        if (!res.ok) throw new Error(res.statusText);
        return res.json();
      },
      onSuccess: () => {
        queryClient.invalidateQueries({ queryKey: [endpoint, 'list'] });
        queryClient.invalidateQueries({ queryKey: [endpoint, 'detail', id] });
      },
    });

  const deleteItem = (id: string) =>
    useMutation({
      mutationFn: async () => {
        const res = await fetch(`${url}/${id}`, { method: 'DELETE' });
        if (!res.ok) throw new Error(res.statusText);
        return res.json();
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
} from '@/lib/types';

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

