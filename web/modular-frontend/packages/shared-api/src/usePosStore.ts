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
// STORE PRINCIPAL — POS con flujo de supermercado
//
// FLUJO:
//  1. addToCart()       → Solo Store (escanear productos)
//  2. updateCartItem()  → Solo Store (editar cantidad)
//  3. removeFromCart()  → Solo Store (quitar item)
//  4. facturar()        → Fiscal + Persist BD + clear cart
//     Si falla fiscal:
//  5. ponerEnEspera()   → Persist carrito a BD + clear local
//  6. listarEspera()    → Carga lista de espera (multi-estación)
//  7. recuperarEspera() → Carga de BD al carrito + elimina de espera
//  8. anularEspera()    → Elimina de espera en BD
// ═══════════════════════════════════════════════════════════════

export interface VentaEnEspera {
    id: number;
    cajaId: string;
    estacionNombre?: string;
    codUsuario?: string;
    clienteNombre?: string;
    clienteRif?: string;
    tipoPrecio?: string;
    motivo?: string;
    total: number;
    fechaCreacion: string;
    cantItems: number;
}

export interface LocalizacionConfig {
    pais: string; // ej. "VE", "CO", "MX", "ES", "US"
    preciosIncluyenIva: boolean;
    tasaCambio: number;
    monedaPrincipal: string; // ej. "Bs"
    monedaReferencia: string; // ej. "REF $"
    tasaIgtf: number;         // ej. 3 (%)
    aplicarIgtf: boolean;     // flag para habilitar IGTF
}

const API_BASE = typeof window !== 'undefined'
    ? (process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000')
    : 'http://localhost:4000';

interface PosState {
    // --- Configuración Hardware ---
    fiscalPrinter: PrinterConfig;
    kitchenPrinters: KitchenPrinterConfig[];
    printerStatus: PrinterStatus | null;

    // --- Configuración Localización ---
    localizacion: LocalizacionConfig;

    // --- Caja ---
    caja: CajaConfig;

    // --- Cliente activo ---
    cliente: ClientePos;

    // --- Carrito ---
    cart: CartItem[];
    selectedCartItemId: string | null;
    esperaOrigenId: number | null;  // Si el carrito fue recuperado de espera

    // --- Ventas en Espera (multi-estación) ---
    ventasEnEspera: VentaEnEspera[];
    loadingEspera: boolean;
    syncing: boolean;

    // --- UI State ---
    paymentModalOpen: boolean;
    customerModalOpen: boolean;

    // --- Actions: Hardware ---
    setFiscalPrinter: (config: Partial<PrinterConfig>) => void;
    addKitchenPrinter: (printer: KitchenPrinterConfig) => void;
    removeKitchenPrinter: (nombre: string) => void;
    setPrinterStatus: (status: PrinterStatus | null) => void;
    fetchPrinterStatus: () => Promise<void>;

    // --- Actions: Caja y Configuración ---
    setCaja: (caja: Partial<CajaConfig>) => void;
    setLocalizacion: (loc: Partial<LocalizacionConfig>) => void;

    // --- Actions: Cliente ---
    setCliente: (cliente: ClientePos) => void;
    resetCliente: () => void;

    // --- Actions: Carrito (SOLO STORE — sin BD) ---
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

    // --- Actions: ESPERA (PERSISTE a BD) ---
    ponerEnEspera: (motivo?: string) => Promise<{ success: boolean; esperaId?: number; message: string }>;
    listarEspera: () => Promise<void>;
    recuperarEspera: (id: number) => Promise<{ success: boolean; message: string }>;
    anularEspera: (id: number) => Promise<{ success: boolean; message: string }>;

    // --- Actions: FACTURAR (Fiscal + BD) ---
    facturar: (metodoPago?: string) => Promise<{ success: boolean; message: string; ventaId?: number }>;

    // --- Computed (derivados) ---
    getSubtotal: () => number;
    getImpuestos: () => number;
    getTotal: () => number;
    getDescuento: () => number;
    getCartCount: () => number;
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
    agentUrl: 'http://localhost:5059',
};

function normalizeAgentUrl(url: string | undefined): string {
    if (!url || !url.trim()) {
        return 'http://localhost:5059';
    }

    const trimmed = url.trim();
    if (trimmed.includes('localhost:5000') || trimmed.includes('127.0.0.1:5000')) {
        return trimmed.replace(':5000', ':5059');
    }

    return trimmed;
}

export function calcTotals(cantidad: number, precioRaw: number, descuento: number, iva: number, loc: LocalizacionConfig) {
    // 1. Convertir a moneda local usando la tasa de cambio vigente
    const precioLocalBruto = precioRaw * loc.tasaCambio;

    // 2. Extraer Base Pura si el precio incluye IVA
    const precioBaseUnidad = loc.preciosIncluyenIva && iva > 0
        ? precioLocalBruto / (1 + (iva / 100))
        : precioLocalBruto;

    // 3. Calculamos Base, IVA y Total Renglón con 2 decimales según lógica fiscal PNP
    const totalBase = Math.round((cantidad * precioBaseUnidad * (1 - descuento / 100)) * 100) / 100;
    const totalIva = Math.round((totalBase * (iva / 100)) * 100) / 100;
    const totalRenglon = Math.round((totalBase + totalIva) * 100) / 100;

    return {
        precioBaseUnidad,
        precioLocalBruto,
        totalBase,
        totalIva,
        totalRenglon
    };
}

export const usePosStore = create<PosState>()(
    persist(
        (set, get) => ({
            // ─── Estado Inicial ───
            fiscalPrinter: DEFAULT_FISCAL_PRINTER,
            kitchenPrinters: [
                { nombre: 'Cocina Principal', conexion: 'emulador', destino: '', agentUrl: 'http://localhost:5059' },
            ],
            printerStatus: null,
            localizacion: {
                pais: 'VE',
                preciosIncluyenIva: true,
                tasaCambio: 1, // Por defecto 1 (misma moneda)
                monedaPrincipal: 'Bs',
                monedaReferencia: '$',
                tasaIgtf: 3,
                aplicarIgtf: true,
            },
            caja: DEFAULT_CAJA,
            cliente: DEFAULT_CLIENTE,
            cart: [],
            selectedCartItemId: null,
            esperaOrigenId: null,
            ventasEnEspera: [],
            loadingEspera: false,
            syncing: false,
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
            setLocalizacion: (loc) => set((s) => ({ localizacion: { ...s.localizacion, ...loc } })),

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
                                return { ...c, cantidad, ...calcTotals(cantidad, c.precio, c.descuento, c.iva, get().localizacion) };
                            }),
                        };
                    }
                    const newItem: CartItem = {
                        ...item,
                        id: `${item.productoId}-${Date.now()}`,
                        ...calcTotals(item.cantidad, item.precio, item.descuento, item.iva, get().localizacion),
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
                        return { ...c, cantidad, precio, descuento, ...calcTotals(cantidad, precio, descuento, c.iva, get().localizacion) };
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
                            precio: c.totalBase / c.cantidad, // La impresora PNP asume Precio Unitario BASE, el store ya lo tiene pre-calculado
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
            getCartCount: () => get().cart.reduce((sum, c) => sum + c.cantidad, 0),

            // ═══════════════════════════════════════════════════════════════
            // PONER EN ESPERA — Persiste el carrito completo a BD
            // Visible para TODAS las estaciones
            // ═══════════════════════════════════════════════════════════════
            ponerEnEspera: async (motivo) => {
                const { cart, caja, cliente } = get();
                if (cart.length === 0) return { success: false, message: 'El carrito está vacío.' };

                set({ syncing: true });
                try {
                    const res = await fetch(`${API_BASE}/v1/pos/espera`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({
                            cajaId: caja.id,
                            estacionNombre: caja.nombre,
                            clienteNombre: cliente.nombre,
                            clienteRif: cliente.rif,
                            clienteId: cliente.id !== '0' ? cliente.codigo : undefined,
                            tipoPrecio: cliente.tipoPrecio,
                            motivo: motivo || 'Puesta en espera',
                            items: cart.map(c => ({
                                productoId: c.productoId,
                                codigo: c.codigo,
                                nombre: c.nombre,
                                cantidad: c.cantidad,
                                precioUnitario: c.precio,
                                descuento: c.descuento,
                                iva: c.iva,
                                subtotal: c.totalBase,
                            })),
                        }),
                    });
                    const data = await res.json();
                    if (!data.ok) {
                        set({ syncing: false });
                        return { success: false, message: data.error || 'Error al poner en espera' };
                    }

                    // Limpiar carrito local
                    set({ cart: [], selectedCartItemId: null, esperaOrigenId: null, cliente: DEFAULT_CLIENTE, syncing: false });
                    // Refrescar lista
                    get().listarEspera();

                    return { success: true, esperaId: data.esperaId, message: `✅ Venta #${data.esperaId} puesta en espera. ${cart.length} items guardados.` };
                } catch (e: any) {
                    set({ syncing: false });
                    return { success: false, message: e?.message || 'Error de red.' };
                }
            },

            // ═══════════════════════════════════════════════════════════════
            // LISTAR ESPERA — Visible para todas las estaciones
            // ═══════════════════════════════════════════════════════════════
            listarEspera: async () => {
                set({ loadingEspera: true });
                try {
                    const res = await fetch(`${API_BASE}/v1/pos/espera`);
                    const data = await res.json();
                    set({ ventasEnEspera: data.rows ?? [], loadingEspera: false });
                } catch {
                    set({ loadingEspera: false });
                }
            },

            // ═══════════════════════════════════════════════════════════════
            // RECUPERAR ESPERA — Carga desde BD al carrito local
            // Marca como "recuperado" en BD para que no aparezca en otras cajas
            // ═══════════════════════════════════════════════════════════════
            recuperarEspera: async (id) => {
                const { cart, caja } = get();
                if (cart.length > 0) {
                    return { success: false, message: 'Hay items en el carrito. Vacíe o ponga en espera antes de recuperar.' };
                }

                set({ syncing: true });
                try {
                    const res = await fetch(`${API_BASE}/v1/pos/espera/${id}/recuperar`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ cajaId: caja.id }),
                    });
                    const data = await res.json();
                    if (!data.ok) {
                        set({ syncing: false });
                        return { success: false, message: data.error || 'Error al recuperar.' };
                    }

                    // Restaurar carrito desde los items de la BD
                    const items: CartItem[] = (data.items ?? []).map((i: any) => {
                        const cantidad = Number(i.cantidad);
                        const precio = Number(i.precioUnitario);
                        const descuento = Number(i.descuento ?? 0);
                        const iva = Number(i.iva ?? 16);
                        return {
                            id: `${i.productoId}-${Date.now()}-${Math.random()}`,
                            productoId: String(i.productoId),
                            codigo: i.codigo || '',
                            nombre: i.nombre,
                            cantidad,
                            precio,
                            descuento,
                            iva,
                            ...calcTotals(cantidad, precio, descuento, iva, get().localizacion),
                        };
                    });

                    // Restaurar cliente si lo tiene
                    const header = data.header;
                    const cliente: ClientePos = header?.clienteNombre && header.clienteNombre !== 'Consumidor Final'
                        ? {
                            id: header.clienteId || '0',
                            codigo: header.clienteId || 'CF',
                            nombre: header.clienteNombre,
                            rif: header.clienteRif || 'J-00000000-0',
                            tipoPrecio: header.tipoPrecio || 'Detal',
                            credito: 0,
                        }
                        : DEFAULT_CLIENTE;

                    set({
                        cart: items,
                        cliente,
                        esperaOrigenId: id,
                        selectedCartItemId: null,
                        syncing: false,
                    });

                    // Refrescar lista
                    get().listarEspera();

                    return { success: true, message: `✅ Venta recuperada con ${items.length} items.` };
                } catch (e: any) {
                    set({ syncing: false });
                    return { success: false, message: e?.message || 'Error de red.' };
                }
            },

            // ═══════════════════════════════════════════════════════════════
            // ANULAR ESPERA
            // ═══════════════════════════════════════════════════════════════
            anularEspera: async (id) => {
                try {
                    await fetch(`${API_BASE}/v1/pos/espera/${id}`, { method: 'DELETE' });
                    set(s => ({ ventasEnEspera: s.ventasEnEspera.filter(e => e.id !== id) }));
                    return { success: true, message: 'Venta en espera anulada.' };
                } catch (e: any) {
                    return { success: false, message: e?.message || 'Error al anular.' };
                }
            },

            // ═══════════════════════════════════════════════════════════════
            // FACTURAR — Imprimir fiscal + Persistir venta a BD + Limpiar
            //
            // Flujo:
            // 1. Intenta imprimir fiscal
            // 2. Si OK: guarda venta en BD con trama fiscal
            // 3. Limpia carrito
            // 4. Si FALLA fiscal: retorna error (cajero decide: espera/reintentar)
            // ═══════════════════════════════════════════════════════════════
            facturar: async (metodoPago) => {
                const { cart, caja, cliente, esperaOrigenId } = get();
                if (cart.length === 0) return { success: false, message: 'El carrito está vacío.' };

                set({ syncing: true });

                // 1. Imprimir fiscal
                const printResult = await get().printFiscalInvoice({
                    items: cart.map(c => ({
                        nombre: c.nombre,
                        cantidad: c.cantidad,
                        precio: c.precio,
                        iva: c.iva,
                    })),
                });

                if (!printResult.success) {
                    set({ syncing: false });
                    return {
                        success: false,
                        message: `❌ Error fiscal: ${printResult.message}. Puede poner la venta en espera.`,
                    };
                }

                // 2. Generar número de factura
                const numFactura = `${caja.serieFactura}-${String(caja.numeroActual + 1).padStart(8, '0')}`;

                // 3. Persistir venta a BD
                try {
                    const res = await fetch(`${API_BASE}/v1/pos/ventas`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({
                            numFactura,
                            cajaId: caja.id,
                            clienteNombre: cliente.nombre,
                            clienteRif: cliente.rif,
                            clienteId: cliente.id !== '0' ? cliente.codigo : undefined,
                            tipoPrecio: cliente.tipoPrecio,
                            metodoPago: metodoPago || 'Efectivo',
                            tramaFiscal: printResult.tramas?.join('|') || '',
                            esperaOrigenId: esperaOrigenId || undefined,
                            items: cart.map(c => ({
                                productoId: c.productoId,
                                codigo: c.codigo,
                                nombre: c.nombre,
                                cantidad: c.cantidad,
                                precioUnitario: c.precio,
                                descuento: c.descuento,
                                iva: c.iva,
                                subtotal: c.totalBase,
                            })),
                        }),
                    });
                    const data = await res.json();

                    // 4. Incrementar número de factura y limpiar
                    set(s => ({
                        cart: [],
                        selectedCartItemId: null,
                        esperaOrigenId: null,
                        cliente: DEFAULT_CLIENTE,
                        syncing: false,
                        caja: { ...s.caja, numeroActual: s.caja.numeroActual + 1 },
                    }));

                    return {
                        success: true,
                        message: `✅ Factura ${numFactura} emitida exitosamente.`,
                        ventaId: data.ventaId,
                    };
                } catch (e: any) {
                    set({ syncing: false });
                    return {
                        success: false,
                        message: `Fiscal imprimió pero falló guardado en BD: ${e?.message}. Contacte soporte.`,
                    };
                }
            },
        }),
        {
            name: 'datqbox-pos-store',
            version: 2,
            migrate: (persistedState: any) => {
                const nextState = { ...(persistedState || {}) };

                if (nextState.fiscalPrinter) {
                    nextState.fiscalPrinter = {
                        ...nextState.fiscalPrinter,
                        agentUrl: normalizeAgentUrl(nextState.fiscalPrinter.agentUrl),
                    };
                }

                if (Array.isArray(nextState.kitchenPrinters)) {
                    nextState.kitchenPrinters = nextState.kitchenPrinters.map((printer: any) => ({
                        ...printer,
                        agentUrl: normalizeAgentUrl(printer?.agentUrl),
                    }));
                }

                return nextState;
            },
            partialize: (state) => ({
                fiscalPrinter: state.fiscalPrinter,
                kitchenPrinters: state.kitchenPrinters,
                caja: state.caja,
                // No persistimos cart ni cliente para evitar data stale
            }),
        }
    )
);
