'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';

// Tipos
export interface Producto {
    id: string;
    codigo: string;
    nombre: string;
    precioDetal: number;
    precioMayor: number;
    precioDistribuidor: number;
    existencia: number;
    imagen?: string;
    categoria?: string;
    iva: number;
}

export interface Cliente {
    id: string;
    codigo: string;
    nombre: string;
    rif: string;
    telefono?: string;
    email?: string;
    direccion?: string;
    tipoPrecio: 'Detal' | 'Mayor' | 'Distribuidor';
    credito: number;
}

export interface FacturaPayload {
    clienteId: string;
    items: Array<{
        productoId: string;
        cantidad: number;
        precio: number;
        descuento?: number;
    }>;
    pagos: Array<{
        metodo: string;
        monto: number;
        referencia?: string;
    }>;
    total: number;
    subtotal: number;
    impuestos: number;
    cajaId: string;
}

// URLs base (placeholder - cambiar por la URL real de la API)
const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';

// Hook para buscar productos
export function useBuscarProductos(filtro?: string) {
    return useQuery({
        queryKey: ['pos', 'productos', filtro],
        queryFn: async (): Promise<Producto[]> => {
            // TODO: Implementar llamada real a la API
            // const response = await fetch(`${API_BASE}/v1/productos?search=${filtro || ''}`);
            // if (!response.ok) throw new Error('Error al cargar productos');
            // return response.json();
            
            // Mock data por ahora
            return new Promise((resolve) => {
                setTimeout(() => {
                    resolve([
                        { id: '1', codigo: 'PROD001', nombre: 'Escritorio Esquinero', precioDetal: 97.75, precioMayor: 85.00, precioDistribuidor: 75.00, existencia: 15, categoria: 'escritorios', iva: 16 },
                        { id: '2', codigo: 'PROD002', nombre: 'Silla Ergonómica', precioDetal: 245.00, precioMayor: 220.00, precioDistribuidor: 195.00, existencia: 8, categoria: 'sillas', iva: 16 },
                        { id: '3', codigo: 'PROD003', nombre: 'Lámpara LED Escritorio', precioDetal: 45.90, precioMayor: 40.00, precioDistribuidor: 35.00, existencia: 25, categoria: 'accesorios', iva: 16 },
                    ]);
                }, 300);
            });
        },
        enabled: true,
    });
}

// Hook para buscar clientes
export function useBuscarClientes(searchTerm: string) {
    return useQuery({
        queryKey: ['pos', 'clientes', searchTerm],
        queryFn: async (): Promise<Cliente[]> => {
            // TODO: Implementar llamada real a la API
            // const response = await fetch(`${API_BASE}/v1/clientes?search=${searchTerm}`);
            // if (!response.ok) throw new Error('Error al cargar clientes');
            // return response.json();
            
            return new Promise((resolve) => {
                setTimeout(() => {
                    resolve([
                        { id: '1', codigo: 'CF', nombre: 'Consumidor Final', rif: 'J-00000000-0', tipoPrecio: 'Detal', credito: 0 },
                        { id: '2', codigo: 'C001', nombre: 'Juan Pérez', rif: 'V-12345678-9', telefono: '0414-1234567', tipoPrecio: 'Detal', credito: 500 },
                    ]);
                }, 200);
            });
        },
        enabled: searchTerm.length > 2,
    });
}

// Hook para crear factura
export function useCrearFactura() {
    const queryClient = useQueryClient();
    
    return useMutation({
        mutationFn: async (payload: FacturaPayload) => {
            // TODO: Implementar llamada real a la API
            // const response = await fetch(`${API_BASE}/v1/facturas`, {
            //     method: 'POST',
            //     headers: { 'Content-Type': 'application/json' },
            //     body: JSON.stringify(payload),
            // });
            // if (!response.ok) throw new Error('Error al crear factura');
            // return response.json();
            
            return new Promise((resolve) => {
                setTimeout(() => {
                    resolve({
                        id: `F-${Date.now()}`,
                        numero: `0001-${Date.now().toString().slice(-8)}`,
                        fecha: new Date().toISOString(),
                        ...payload,
                    });
                }, 500);
            });
        },
        onSuccess: () => {
            // Invalidar caches relevantes
            queryClient.invalidateQueries({ queryKey: ['pos', 'facturas'] });
        },
    });
}

// Hook para obtener configuración de caja
export function useConfiguracionCaja(cajaId: string) {
    return useQuery({
        queryKey: ['pos', 'caja', cajaId],
        queryFn: async () => {
            // TODO: Implementar llamada real
            return {
                id: cajaId,
                nombre: 'Caja Principal',
                serieFactura: 'A',
                numeroActual: 1250,
                almacenId: '1',
                almacenNombre: 'Almacén Central',
            };
        },
    });
}

// Hook local para manejar el estado del carrito
export function useCart() {
    const [items, setItems] = useState<Array<{
        id: string;
        productoId: string;
        nombre: string;
        cantidad: number;
        precio: number;
        descuento: number;
        total: number;
    }>>([]);

    const addItem = (producto: Producto, cantidad: number = 1, tipoPrecio: string = 'Detal') => {
        const precio = tipoPrecio === 'Mayor' 
            ? producto.precioMayor 
            : tipoPrecio === 'Distribuidor' 
                ? producto.precioDistribuidor 
                : producto.precioDetal;

        setItems(prev => {
            const existing = prev.find(item => item.productoId === producto.id);
            if (existing) {
                return prev.map(item =>
                    item.productoId === producto.id
                        ? {
                            ...item,
                            cantidad: item.cantidad + cantidad,
                            total: (item.cantidad + cantidad) * item.precio * (1 - item.descuento / 100),
                        }
                        : item
                );
            }
            return [...prev, {
                id: `${producto.id}-${Date.now()}`,
                productoId: producto.id,
                nombre: producto.nombre,
                cantidad,
                precio,
                descuento: 0,
                total: cantidad * precio,
            }];
        });
    };

    const updateItem = (id: string, updates: Partial<{ cantidad: number; precio: number; descuento: number }>) => {
        setItems(prev => prev.map(item => {
            if (item.id !== id) return item;
            const cantidad = updates.cantidad ?? item.cantidad;
            const precio = updates.precio ?? item.precio;
            const descuento = updates.descuento ?? item.descuento;
            return {
                ...item,
                cantidad,
                precio,
                descuento,
                total: cantidad * precio * (1 - descuento / 100),
            };
        }));
    };

    const removeItem = (id: string) => {
        setItems(prev => prev.filter(item => item.id !== id));
    };

    const clearCart = () => {
        setItems([]);
    };

    const totals = items.reduce((acc, item) => ({
        subtotal: acc.subtotal + (item.cantidad * item.precio),
        descuento: acc.descuento + (item.cantidad * item.precio * item.descuento / 100),
        total: acc.total + item.total,
    }), { subtotal: 0, descuento: 0, total: 0 });

    return {
        items,
        addItem,
        updateItem,
        removeItem,
        clearCart,
        ...totals,
    };
}
