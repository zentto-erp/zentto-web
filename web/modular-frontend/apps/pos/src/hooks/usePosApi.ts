'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiGet, usePosStore } from '@datqbox/shared-api';

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

export interface PosReporteResumen {
    totalVentas: number;
    transacciones: number;
    productosVendidos: number;
    productosDiferentes: number;
    ticketPromedio: number;
}

export interface PosReporteVenta {
    id: number;
    numFactura: string;
    fecha: string;
    cliente: string;
    total: number;
    estado: string;
    metodoPago?: string;
}

export interface PosReporteProductoTop {
    productoId: string;
    codigo: string;
    nombre: string;
    cantidad: number;
    total: number;
}

export interface PosReporteFormaPago {
    metodoPago: string;
    transacciones: number;
    total: number;
}

const POS_API_BASE = '/v1/pos';

// ═══════════════════════════════════════════════════════════════
// HOOKS - PRODUCTOS (API REAL)
// ═══════════════════════════════════════════════════════════════

export function useBuscarProductos(filtro?: string) {
    return useQuery({
        queryKey: ['pos', 'productos', filtro],
        queryFn: async (): Promise<Producto[]> => {
            const data = await apiGet(`${POS_API_BASE}/productos`, {
                search: filtro,
                limit: 100,
            });
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
            const data = await apiGet(`${POS_API_BASE}/clientes`, {
                search: searchTerm,
            });
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
            const data = await apiGet(`${POS_API_BASE}/categorias`);
            return (data.rows ?? data ?? []).map((row: any) => ({
                id: row.id?.toString().trim() ?? '',
                nombre: row.nombre?.toString().trim() ?? '',
                productCount: Number(row.productCount ?? 0),
            }));
        },
    });
}

// ═══════════════════════════════════════════════════════════════
// HOOKS - REPORTES POS
// ═══════════════════════════════════════════════════════════════

export function usePosReporteResumen(from?: string, to?: string) {
    return useQuery({
        queryKey: ['pos', 'reportes', 'resumen', from, to],
        queryFn: async (): Promise<PosReporteResumen> => {
            const data = await apiGet(`${POS_API_BASE}/reportes/resumen`, { from, to });
            const row = data.row ?? {};
            return {
                totalVentas: Number(row.totalVentas ?? 0),
                transacciones: Number(row.transacciones ?? 0),
                productosVendidos: Number(row.productosVendidos ?? 0),
                productosDiferentes: Number(row.productosDiferentes ?? 0),
                ticketPromedio: Number(row.ticketPromedio ?? 0),
            };
        },
    });
}

export function usePosReporteVentas(from?: string, to?: string, limit = 200) {
    return useQuery({
        queryKey: ['pos', 'reportes', 'ventas', from, to, limit],
        queryFn: async (): Promise<PosReporteVenta[]> => {
            const data = await apiGet(`${POS_API_BASE}/reportes/ventas`, { from, to, limit });
            return (data.rows ?? []).map((row: any) => ({
                id: Number(row.id ?? 0),
                numFactura: row.numFactura?.toString().trim() ?? '',
                fecha: row.fecha,
                cliente: row.cliente?.toString().trim() ?? 'Consumidor Final',
                total: Number(row.total ?? 0),
                estado: row.estado?.toString().trim() ?? 'Completada',
                metodoPago: row.metodoPago?.toString().trim() ?? undefined,
            }));
        },
    });
}

export function usePosReporteProductosTop(from?: string, to?: string, limit = 20) {
    return useQuery({
        queryKey: ['pos', 'reportes', 'productos-top', from, to, limit],
        queryFn: async (): Promise<PosReporteProductoTop[]> => {
            const data = await apiGet(`${POS_API_BASE}/reportes/productos-top`, { from, to, limit });
            return (data.rows ?? []).map((row: any) => ({
                productoId: row.productoId?.toString().trim() ?? '',
                codigo: row.codigo?.toString().trim() ?? '',
                nombre: row.nombre?.toString().trim() ?? '',
                cantidad: Number(row.cantidad ?? 0),
                total: Number(row.total ?? 0),
            }));
        },
    });
}

export function usePosReporteFormasPago(from?: string, to?: string) {
    return useQuery({
        queryKey: ['pos', 'reportes', 'formas-pago', from, to],
        queryFn: async (): Promise<PosReporteFormaPago[]> => {
            const data = await apiGet(`${POS_API_BASE}/reportes/formas-pago`, { from, to });
            return (data.rows ?? []).map((row: any) => ({
                metodoPago: row.metodoPago?.toString().trim() ?? 'No especificado',
                transacciones: Number(row.transacciones ?? 0),
                total: Number(row.total ?? 0),
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
