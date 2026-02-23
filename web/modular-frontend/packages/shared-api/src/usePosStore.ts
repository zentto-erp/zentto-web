'use client';

import { create } from 'zustand';
import { persist } from 'zustand/middleware';

// ═══════════════════════════════════════════════════════════════
// TIPOS
// ═══════════════════════════════════════════════════════════════

export interface PrinterConfig {
    marca: 'PNP' | 'Rigaza' | 'TheFactory' | 'Tfhka' | 'Generica';
    conexion: 'serial' | 'dll' | 'spooler' | 'emulador';
    puerto: string; // COM1, COM2, EMULADOR, IP:9100, etc.
    agentUrl: string; // URL del agente local C# (ej: http://localhost:5000)
}

export interface KitchenPrinterConfig {
    nombre: string;
    conexion: 'ip' | 'usb' | 'serial' | 'emulador';
    destino: string; // IP:9100, \\servidor\impresora, COM3, etc.
    agentUrl: string;
}

export interface PrinterStatus {
    success: boolean;
    statusCode: number;   // 0=OK, 1=Warning, 2=Fatal
    message: string;
    sensors?: {
        Papel: boolean;
        Tapa: boolean;
        Gaveta: boolean;
        ErrorFatal: boolean;
    };
    hardware?: string;
    lastCheck: number; // timestamp
}

export interface CajaConfig {
    id: string;
    nombre: string;
    serieFactura: string;
    numeroActual: number;
    almacenId: string;
    almacenNombre: string;
}

export interface ClientePos {
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

export interface CartItem {
    id: string;
    productoId: string;
    codigo: string;
    nombre: string;
    cantidad: number;
    precio: number;
    descuento: number;
    iva: number;
    totalBase: number;
    totalIva: number;
    totalRenglon: number;
}

// ═══════════════════════════════════════════════════════════════
// STORE PRINCIPAL
// ═══════════════════════════════════════════════════════════════

interface PosState {
    // --- Configuración Hardware ---
    fiscalPrinter: PrinterConfig;
    kitchenPrinters: KitchenPrinterConfig[];
    printerStatus: PrinterStatus | null;

    // --- Caja ---
    caja: CajaConfig;

    // --- Cliente activo ---
    cliente: ClientePos;

    // --- Carrito ---
    cart: CartItem[];
    selectedCartItemId: string | null;

    // --- UI State ---
    paymentModalOpen: boolean;
    customerModalOpen: boolean;

    // --- Actions: Hardware ---
    setFiscalPrinter: (config: Partial<PrinterConfig>) => void;
    addKitchenPrinter: (printer: KitchenPrinterConfig) => void;
    removeKitchenPrinter: (nombre: string) => void;
    setPrinterStatus: (status: PrinterStatus | null) => void;
    fetchPrinterStatus: () => Promise<void>;

    // --- Actions: Caja ---
    setCaja: (caja: Partial<CajaConfig>) => void;

    // --- Actions: Cliente ---
    setCliente: (cliente: ClientePos) => void;
    resetCliente: () => void;

    // --- Actions: Carrito ---
    addToCart: (item: Omit<CartItem, 'id' | 'totalBase' | 'totalIva' | 'totalRenglon'>) => void;
    updateCartItem: (id: string, updates: Partial<Pick<CartItem, 'cantidad' | 'precio' | 'descuento'>>) => void;
    removeFromCart: (id: string) => void;
    clearCart: () => void;
    setSelectedCartItem: (id: string | null) => void;

    // --- Actions: UI ---
    setPaymentModal: (open: boolean) => void;
    setCustomerModal: (open: boolean) => void;

    // --- Actions: Impresión ---
    printFiscalInvoice: (payload: Record<string, unknown>) => Promise<{ success: boolean; message: string; tramas?: string[] }>;
    printKitchenOrder: (printerName: string, payload: Record<string, unknown>) => Promise<{ success: boolean; message: string }>;

    // --- Computed (derivados) ---
    getSubtotal: () => number;
    getImpuestos: () => number;
    getTotal: () => number;
    getDescuento: () => number;
}

const DEFAULT_CLIENTE: ClientePos = {
    id: '0',
    codigo: 'CF',
    nombre: 'Consumidor Final',
    rif: 'J-00000000-0',
    tipoPrecio: 'Detal',
    credito: 0,
};

const DEFAULT_CAJA: CajaConfig = {
    id: '1',
    nombre: 'Caja Principal',
    serieFactura: 'A',
    numeroActual: 0,
    almacenId: '1',
    almacenNombre: 'Almacén Central',
};

const DEFAULT_FISCAL_PRINTER: PrinterConfig = {
    marca: 'PNP',
    conexion: 'emulador',
    puerto: 'EMULADOR',
    agentUrl: 'http://localhost:5000',
};

function calcTotals(cantidad: number, precio: number, descuento: number, iva: number) {
    const totalBase = Number((cantidad * precio * (1 - descuento / 100)).toFixed(2));
    const totalIva = Number((totalBase * (iva / 100)).toFixed(2));
    const totalRenglon = Number((totalBase + totalIva).toFixed(2));
    return { totalBase, totalIva, totalRenglon };
}

export const usePosStore = create<PosState>()(
    persist(
        (set, get) => ({
            // ─── Estado Inicial ───
            fiscalPrinter: DEFAULT_FISCAL_PRINTER,
            kitchenPrinters: [
                { nombre: 'Cocina Principal', conexion: 'emulador', destino: '', agentUrl: 'http://localhost:5000' },
            ],
            printerStatus: null,
            caja: DEFAULT_CAJA,
            cliente: DEFAULT_CLIENTE,
            cart: [],
            selectedCartItemId: null,
            paymentModalOpen: false,
            customerModalOpen: false,

            // ─── Hardware ───
            setFiscalPrinter: (config) =>
                set((s) => ({ fiscalPrinter: { ...s.fiscalPrinter, ...config } })),

            addKitchenPrinter: (printer) =>
                set((s) => ({ kitchenPrinters: [...s.kitchenPrinters, printer] })),

            removeKitchenPrinter: (nombre) =>
                set((s) => ({ kitchenPrinters: s.kitchenPrinters.filter((p) => p.nombre !== nombre) })),

            setPrinterStatus: (status) => set({ printerStatus: status }),

            fetchPrinterStatus: async () => {
                const { fiscalPrinter } = get();
                try {
                    const url = `${fiscalPrinter.agentUrl}/api/status?marca=${fiscalPrinter.marca}&puerto=${fiscalPrinter.puerto}&conexion=${fiscalPrinter.conexion}`;
                    const res = await fetch(url);
                    if (!res.ok) {
                        set({
                            printerStatus: {
                                success: false,
                                statusCode: 2,
                                message: 'Falla al conectar con el agente. Revise cable o inicie el Agente Local.',
                                lastCheck: Date.now(),
                            },
                        });
                        return;
                    }
                    const data = await res.json();
                    set({
                        printerStatus: {
                            success: data.Success ?? data.success ?? false,
                            statusCode: data.StatusCode ?? data.statusCode ?? 2,
                            message: data.Message ?? data.message ?? '',
                            sensors: data.Sensors ?? data.sensors,
                            hardware: data.Hardware ?? data.hardware,
                            lastCheck: Date.now(),
                        },
                    });
                } catch {
                    set({
                        printerStatus: {
                            success: false,
                            statusCode: 2,
                            message: 'Agente Fiscal Apagado o bloqueado. Inícielo en esta PC.',
                            lastCheck: Date.now(),
                        },
                    });
                }
            },

            // ─── Caja ───
            setCaja: (caja) => set((s) => ({ caja: { ...s.caja, ...caja } })),

            // ─── Cliente ───
            setCliente: (cliente) => set({ cliente }),
            resetCliente: () => set({ cliente: DEFAULT_CLIENTE }),

            // ─── Carrito ───
            addToCart: (item) =>
                set((s) => {
                    const existing = s.cart.find((c) => c.productoId === item.productoId);
                    if (existing) {
                        return {
                            cart: s.cart.map((c) => {
                                if (c.productoId !== item.productoId) return c;
                                const cantidad = c.cantidad + item.cantidad;
                                return { ...c, cantidad, ...calcTotals(cantidad, c.precio, c.descuento, c.iva) };
                            }),
                        };
                    }
                    const newItem: CartItem = {
                        ...item,
                        id: `${item.productoId}-${Date.now()}`,
                        ...calcTotals(item.cantidad, item.precio, item.descuento, item.iva),
                    };
                    return { cart: [...s.cart, newItem] };
                }),

            updateCartItem: (id, updates) =>
                set((s) => ({
                    cart: s.cart.map((c) => {
                        if (c.id !== id) return c;
                        const cantidad = updates.cantidad ?? c.cantidad;
                        const precio = updates.precio ?? c.precio;
                        const descuento = updates.descuento ?? c.descuento;
                        return { ...c, cantidad, precio, descuento, ...calcTotals(cantidad, precio, descuento, c.iva) };
                    }),
                })),

            removeFromCart: (id) => set((s) => ({ cart: s.cart.filter((c) => c.id !== id) })),

            clearCart: () => set({ cart: [], selectedCartItemId: null }),

            setSelectedCartItem: (id) => set({ selectedCartItemId: id }),

            // ─── UI ───
            setPaymentModal: (open) => set({ paymentModalOpen: open }),
            setCustomerModal: (open) => set({ customerModalOpen: open }),

            // ─── Impresión Fiscal ───
            printFiscalInvoice: async (payload) => {
                const { fiscalPrinter, cliente, cart } = get();
                try {
                    const body = {
                        marca: fiscalPrinter.marca,
                        conexion: fiscalPrinter.conexion,
                        puerto: fiscalPrinter.puerto,
                        cliente: { nombre: cliente.nombre, rif: cliente.rif },
                        items: cart.map((c) => ({
                            nombre: c.nombre,
                            cantidad: c.cantidad,
                            precio: c.precio,
                            iva: c.iva,
                        })),
                        ...payload,
                    };
                    const res = await fetch(`${fiscalPrinter.agentUrl}/api/print`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify(body),
                    });
                    const data = await res.json();
                    return {
                        success: data.Success ?? data.success ?? false,
                        message: data.Message ?? data.message ?? 'Error desconocido',
                        tramas: data.TramasFiscales ?? data.tramasFiscales,
                    };
                } catch (e: any) {
                    return { success: false, message: e?.message || 'Error al comunicar con el Agente Fiscal.' };
                }
            },

            // ─── Impresión Cocina (ESC/POS libre) ───
            printKitchenOrder: async (printerName, payload) => {
                const { kitchenPrinters } = get();
                const printer = kitchenPrinters.find((p) => p.nombre === printerName) || kitchenPrinters[0];
                if (!printer) return { success: false, message: 'No hay impresora de cocina configurada.' };

                try {
                    const body = {
                        conexion: printer.conexion,
                        destino: printer.destino,
                        ...payload,
                    };
                    const res = await fetch(`${printer.agentUrl}/api/escpos`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify(body),
                    });
                    const data = await res.json();
                    return {
                        success: data.Success ?? data.success ?? false,
                        message: data.Message ?? data.message ?? 'Error desconocido',
                    };
                } catch (e: any) {
                    return { success: false, message: e?.message || 'Error al comunicar con la impresora de cocina.' };
                }
            },

            // ─── Computed ───
            getSubtotal: () => get().cart.reduce((sum, c) => sum + c.totalBase, 0),
            getImpuestos: () => get().cart.reduce((sum, c) => sum + c.totalIva, 0),
            getTotal: () => get().cart.reduce((sum, c) => sum + c.totalRenglon, 0),
            getDescuento: () =>
                get().cart.reduce((sum, c) => sum + c.cantidad * c.precio * (c.descuento / 100), 0),
        }),
        {
            name: 'datqbox-pos-store',
            partialize: (state) => ({
                fiscalPrinter: state.fiscalPrinter,
                kitchenPrinters: state.kitchenPrinters,
                caja: state.caja,
                // No persistimos cart ni cliente para evitar data stale
            }),
        }
    )
);
