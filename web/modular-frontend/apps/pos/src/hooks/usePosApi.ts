'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { usePosStore } from '@datqbox/shared-api';

// ═══════════════════════════════════════════════════════════════
// TIPOS
// ═══════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════
// URL BASE DE LA API
// ═══════════════════════════════════════════════════════════════
const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000';
const POS_API = `${API_BASE}/v1/pos`;

// ═══════════════════════════════════════════════════════════════
// HOOKS - PRODUCTOS (API REAL)
// ═══════════════════════════════════════════════════════════════

export function useBuscarProductos(filtro?: string) {
    return useQuery({
        queryKey: ['pos', 'productos', filtro],
        queryFn: async (): Promise<Producto[]> => {
            const params = new URLSearchParams();
            if (filtro) params.set('search', filtro);
            params.set('limit', '100');

            const res = await fetch(`${POS_API}/productos?${params.toString()}`);
            if (!res.ok) throw new Error('Error al cargar productos');
            const data = await res.json();
            return (data.rows ?? data ?? []).map((row: any) => ({
                id: row.id?.toString().trim() ?? '',
                codigo: row.codigo?.toString().trim() ?? row.id?.toString().trim() ?? '',
                nombre: row.nombre?.toString().trim() ?? '',
                precioDetal: Number(row.precioDetal ?? row.PRECIO_VENTA ?? 0),
                precioMayor: Number(row.precioMayor ?? row.PRECIO_VENTA2 ?? 0),
                precioDistribuidor: Number(row.precioDistribuidor ?? row.PRECIO_VENTA3 ?? 0),
                existencia: Number(row.existencia ?? row.EXISTENCIA ?? 0),
                categoria: row.categoria?.toString().trim() ?? '',
                iva: Number(row.iva ?? row.PORCENTAJE ?? 16),
            }));
        },
        enabled: true,
    });
}

// ═══════════════════════════════════════════════════════════════
// HOOKS - CLIENTES (API REAL)
// ═══════════════════════════════════════════════════════════════

export function useBuscarClientes(searchTerm: string) {
    return useQuery({
        queryKey: ['pos', 'clientes', searchTerm],
        queryFn: async (): Promise<Cliente[]> => {
            const params = new URLSearchParams();
            if (searchTerm) params.set('search', searchTerm);

            const res = await fetch(`${POS_API}/clientes?${params.toString()}`);
            if (!res.ok) throw new Error('Error al cargar clientes');
            const data = await res.json();
            return (data.rows ?? data ?? []).map((row: any) => ({
                id: row.id?.toString().trim() ?? '',
                codigo: row.codigo?.toString().trim() ?? '',
                nombre: row.nombre?.toString().trim() ?? '',
                rif: row.rif?.toString().trim() ?? '',
                telefono: row.telefono?.toString().trim(),
                email: row.email?.toString().trim(),
                direccion: row.direccion?.toString().trim(),
                tipoPrecio: row.tipoPrecio ?? 'Detal',
                credito: Number(row.credito ?? 0),
            }));
        },
        enabled: searchTerm.length > 2,
    });
}

// ═══════════════════════════════════════════════════════════════
// HOOKS - CATEGORÍAS (API REAL)
// ═══════════════════════════════════════════════════════════════

export function useCategoriasPOS() {
    return useQuery({
        queryKey: ['pos', 'categorias'],
        queryFn: async () => {
            const res = await fetch(`${POS_API}/categorias`);
            if (!res.ok) throw new Error('Error al cargar categorías');
            const data = await res.json();
            return (data.rows ?? data ?? []).map((row: any) => ({
                id: row.id?.toString().trim() ?? '',
                nombre: row.nombre?.toString().trim() ?? '',
                productCount: Number(row.productCount ?? 0),
            }));
        },
    });
}

// ═══════════════════════════════════════════════════════════════
// HOOKS - FACTURACIÓN (AGENTE FISCAL LOCAL)
// ═══════════════════════════════════════════════════════════════

export function useCrearFactura() {
    const queryClient = useQueryClient();
    const printFiscalInvoice = usePosStore((s) => s.printFiscalInvoice);

    return useMutation({
        mutationFn: async (payload: FacturaPayload) => {
            // Llamar al agente fiscal local via Zustand store
            const result = await printFiscalInvoice(payload as unknown as Record<string, unknown>);

            if (!result.success) {
                throw new Error(result.message || 'Cajero, revise la Impresora Fiscal (Sin Papel, Tapa o Desconectada).');
            }

            return {
                id: `F-${Date.now()}`,
                numero: `0001-${Date.now().toString().slice(-8)}`,
                fecha: new Date().toISOString(),
                ...payload,
                hardwareLog: result.message,
                tramasFiscales: result.tramas,
            };
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['pos', 'facturas'] });
        },
    });
}

// ═══════════════════════════════════════════════════════════════
// HOOKS - STATUS IMPRESORA (VIA ZUSTAND STORE)
// ═══════════════════════════════════════════════════════════════

export function usePrinterStatus(marca: string = "PNP", puerto: string = "EMULADOR", conexion: string = "emulador") {
    const fetchPrinterStatus = usePosStore((s) => s.fetchPrinterStatus);
    const printerStatus = usePosStore((s) => s.printerStatus);

    return useQuery({
        queryKey: ['pos', 'printerStatus', marca, puerto, conexion],
        queryFn: async () => {
            await fetchPrinterStatus();
            return usePosStore.getState().printerStatus ?? {
                success: false,
                message: 'Agente Fiscal Apagado.',
                statusCode: 2,
            };
        },
        refetchInterval: 15000,
    });
}

// ═══════════════════════════════════════════════════════════════
// HOOKS - CONFIGURACIÓN DE CAJA
// ═══════════════════════════════════════════════════════════════

export function useConfiguracionCaja(cajaId: string) {
    const caja = usePosStore((s) => s.caja);
    return useQuery({
        queryKey: ['pos', 'caja', cajaId],
        queryFn: async () => caja,
    });
}

// ═══════════════════════════════════════════════════════════════
// HOOK - CARRITO (RE-EXPORT DEL ZUSTAND STORE)
// ═══════════════════════════════════════════════════════════════

export function useCart() {
    const cart = usePosStore((s) => s.cart);
    const addToCart = usePosStore((s) => s.addToCart);
    const updateCartItem = usePosStore((s) => s.updateCartItem);
    const removeFromCart = usePosStore((s) => s.removeFromCart);
    const clearCartAction = usePosStore((s) => s.clearCart);
    const getSubtotal = usePosStore((s) => s.getSubtotal);
    const getImpuestos = usePosStore((s) => s.getImpuestos);
    const getTotal = usePosStore((s) => s.getTotal);
    const getDescuento = usePosStore((s) => s.getDescuento);

    const addItem = (producto: Producto, cantidad: number = 1, tipoPrecio: string = 'Detal') => {
        const precio = tipoPrecio === 'Mayor'
            ? producto.precioMayor
            : tipoPrecio === 'Distribuidor'
                ? producto.precioDistribuidor
                : producto.precioDetal;

        addToCart({
            productoId: producto.id,
            codigo: producto.codigo,
            nombre: producto.nombre,
            cantidad,
            precio,
            descuento: 0,
            iva: producto.iva || 16,
        });
    };

    const updateItem = (id: string, updates: Partial<{ cantidad: number; precio: number; descuento: number }>) => {
        updateCartItem(id, updates);
    };

    const removeItem = (id: string) => {
        removeFromCart(id);
    };

    const clearCart = () => {
        clearCartAction();
    };

    return {
        items: cart,
        addItem,
        updateItem,
        removeItem,
        clearCart,
        subtotal: getSubtotal(),
        descuento: getDescuento(),
        impuestos: getImpuestos(),
        total: getTotal(),
    };
}
