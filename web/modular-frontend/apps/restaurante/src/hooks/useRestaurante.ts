'use client';

import { useEffect, useCallback } from 'react';
import { create } from 'zustand';
import { v4 as uuidv4 } from 'uuid';
import { usePosStore, calcTotals, apiGet, apiPost, resolveAssetUrl } from '@zentto/shared-api';

// ═══════════════════════════════════════════════════════════════
// TIPOS — Modelo de datos del Restaurante
// ═══════════════════════════════════════════════════════════════

export interface Mesa {
    id: string;
    numero: number;
    nombre: string;
    capacidad: number;
    ambienteId: string;
    posicionX: number;
    posicionY: number;
    estado: 'libre' | 'ocupada' | 'reservada' | 'cuenta';
    pedidoActual?: Pedido;
    cliente?: ClienteMesa;
}

export interface Ambiente {
    id: string;
    nombre: string;
    color: string;
    mesas: Mesa[];
}

export interface ClienteMesa {
    id: string;
    nombre: string;
    telefono?: string;
    email?: string;
    cedula?: string;
}

export interface Pedido {
    id: string;              // UUID local hasta que se persista
    dbId?: number;           // ID asignado por la BD al persistir
    mesaId: string;
    cliente?: ClienteMesa;
    clienteNombre?: string;  // Compatibilidad con payload legado de API
    items: ItemPedido[];
    estado: 'abierto' | 'en_preparacion' | 'listo' | 'cerrado';
    fechaApertura: Date;
    fechaCierre?: Date;
    total: number;
    subtotal: number;       // Suma de las bases
    impuestos: number;      // Suma de IVAs
    servicio: number;       // 10% sobre el subtotal (base)
    comentarios?: string;
    persistido: boolean;     // Si ya se guardó en BD con abrir-pedido
}

export interface ItemPedido {
    id: string;              // UUID local
    dbId?: number;           // ID asignado por la BD al persistir
    productoId: string;
    nombre: string;
    cantidad: number;
    precioUnitario: number;
    subtotal: number;       // precio * cantidad (Base renglon)
    iva: number;            // % de iva (e.g. 16, 8, 0)
    montoIva: number;       // Monto calculado de IVA del renglón
    estado: 'pendiente' | 'en_preparacion' | 'listo' | 'entregado';
    comentarios?: string;
    esCompuesto: boolean;
    componentes?: ComponenteItem[];
    enviadoACocina: boolean;   // true = ya fue enviado y persistido
    horaEnvio?: Date;
}

export interface ComponenteItem {
    id: string;
    nombre: string;
    cantidad: number;
    opcionSeleccionada?: string;
}

export interface ProductoMenu {
    id: string;
    codigo: string;
    nombre: string;
    descripcion?: string;
    precio: number;
    iva: number;
    categoria: string;
    esCompuesto: boolean;
    componentes?: ComponenteProducto[];
    tiempoPreparacion: number;
    imagen?: string;
    esSugerenciaDelDia?: boolean;
    disponible: boolean;
}

export interface ComponenteProducto {
    id: string;
    nombre: string;
    opciones: string[];
    obligatorio: boolean;
}

export interface ComandaCocina {
    id: string;
    pedidoId: string;
    mesaNombre: string;
    item: ItemPedido;
    horaRecibido: Date;
    prioridad: 'normal' | 'alta' | 'urgente';
    ambiente: string;
}

type ApiRow = Record<string, unknown>;

// ═══════════════════════════════════════════════════════════════
// ZUSTAND STORE — Estado global del Restaurante
// ═══════════════════════════════════════════════════════════════
//
// FLUJO REAL:
//
//  1. initFromApi()     → Carga mesas, ambientes y productos SOLO al inicio
//  2. abrirPedido()     → Crea pedido en STORE (sin BD)
//  3. agregarItem()     → Agrega item en STORE (sin BD)
//  4. quitarItem()      → Quita item en STORE (sin BD)
//  5. enviarComanda()   → PERSISTE items nuevos a BD + imprime cocina ESC/POS
//  6. generarCuenta()   → Imprime factura fiscal (lee del STORE)
//  7. cerrarMesa()      → POST cerrar a BD + limpia mesa en STORE
//

const API_BASE = typeof window !== 'undefined'
    ? (process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000')
    : 'http://localhost:4000';

function round2(value: number) {
    return Math.round((value + Number.EPSILON) * 100) / 100;
}

function normalizeIvaPercent(raw: unknown, fallback = 16): number {
    const value = Number(raw);
    if (!Number.isFinite(value)) return fallback;
    if (value < 0) return 0;
    if (value > 100) return 100;
    return Math.round((value + Number.EPSILON) * 10000) / 10000;
}

function calcIvaAmount(baseAmount: number, ivaPercent: number) {
    return round2(baseAmount * (ivaPercent / 100));
}

function asTrimmedString(value: unknown, fallback = ''): string {
    if (value === null || value === undefined) return fallback;
    return String(value).trim();
}

function asOptionalTrimmedString(value: unknown): string | undefined {
    if (value === null || value === undefined) return undefined;
    const normalized = String(value).trim();
    return normalized || undefined;
}

function toDateOrUndefined(value: unknown): Date | undefined {
    if (value === null || value === undefined || value === '') return undefined;
    if (value instanceof Date) {
        return Number.isNaN(value.getTime()) ? undefined : value;
    }
    const parsed = new Date(String(value));
    return Number.isNaN(parsed.getTime()) ? undefined : parsed;
}

function resolveAmbienteActivo(current: string, ambientes: Ambiente[]): string {
    if (current === 'todos') return 'todos';
    if (ambientes.some((amb) => amb.id === current)) return current;
    if (ambientes.length > 0) return ambientes[0].id;
    return 'todos';
}

interface RestauranteState {
    // ─── Data ───
    ambientes: Ambiente[];
    ambienteActivo: string;
    productos: ProductoMenu[];
    loading: boolean;
    syncing: boolean;  // true mientras persiste a BD

    // ─── Actions: Init ───
    initFromApi: () => Promise<void>;
    setAmbienteActivo: (id: string) => void;

    // ─── Actions: Mesas (STORE ONLY — sin BD) ───
    getMesaById: (id: string) => Mesa | undefined;
    actualizarMesa: (mesaId: string, updates: Partial<Mesa>) => void;

    // ─── Actions: Pedido lifecycle (STORE first, BD en momentos clave) ───
    abrirPedido: (mesaId: string, cliente?: ClienteMesa) => void;
    agregarItem: (mesaId: string, item: Omit<ItemPedido, 'id' | 'dbId'>) => void;
    quitarItem: (mesaId: string, itemId: string) => void;
    anularItemEnviado: (
        mesaId: string,
        itemId: string,
        auth: {
            motivo: string;
            supervisorUser: string;
            supervisorPassword?: string;
            biometricBypass?: boolean;
            biometricCredentialId?: string;
        }
    ) => Promise<{ success: boolean; message: string }>;
    editarItem: (mesaId: string, itemId: string, updates: Partial<Pick<ItemPedido, 'cantidad' | 'comentarios'>>) => void;

    // ─── Actions: Persistencia (estos SÍ tocan la BD) ───
    enviarComanda: (mesaId: string) => Promise<{ success: boolean; message: string }>;
    generarCuenta: (mesaId: string) => Promise<{ success: boolean; message: string }>;
    cerrarMesa: (mesaId: string) => Promise<{ success: boolean; message: string }>;

    // ─── Actions: Layout ───
    moverMesa: (mesaId: string, nuevoX: number, nuevoY: number, nuevoAmbienteId?: string) => void;
    transferirMesa: (origenId: string, destinoId: string) => void;

    // ─── Computed ───
    getComandasPendientes: () => ComandaCocina[];
    getItemsPendientes: (mesaId: string) => ItemPedido[];
    getItemsEnviados: (mesaId: string) => ItemPedido[];
    getSubtotalMesa: (mesaId: string) => number;
    getImpuestosMesa: (mesaId: string) => number;
    getServicioMesa: (mesaId: string) => number;
    getTotalMesa: (mesaId: string) => number;
}

export const useRestauranteStore = create<RestauranteState>((set, get) => ({
    // ─── Estado Inicial ───
    ambientes: [],
    ambienteActivo: 'todos',
    productos: [],
    loading: true,
    syncing: false,

    // ═══════════════════════════════════════════════════════════════
    // 1. INIT — Carga inicial desde la API (solo una vez)
    // ═══════════════════════════════════════════════════════════════
    initFromApi: async () => {
        try {
            set({ loading: true });

            // Paralelo: mesas + ambientes + productos
            const [mesasRes, ambRes, prodsRes] = await Promise.all([
                apiGet(`/v1/restaurante/mesas`).catch(() => ({ rows: [] })),
                apiGet(`/v1/restaurante/admin/ambientes`).catch(() => ({ rows: [] })),
                apiGet(`/v1/restaurante/admin/productos`).catch(() => ({ rows: [] })),
            ]);

            const mesas: Mesa[] = (mesasRes.rows ?? []).map((r: ApiRow) => ({
                id: String(r.id),
                numero: r.numero,
                nombre: asTrimmedString(r.nombre),
                capacidad: r.capacidad,
                ambienteId: String(r.ambienteId),
                posicionX: r.posicionX,
                posicionY: r.posicionY,
                estado: r.estado || 'libre',
            }));

            // Para mesas ocupadas, cargar su pedido activo
            for (const mesa of mesas) {
                if (mesa.estado === 'ocupada' || mesa.estado === 'cuenta') {
                    try {
                        const data = await apiGet(`/v1/restaurante/mesas/${mesa.id}/pedido`);
                        if (data && data.pedido) {
                            mesa.pedidoActual = {
                                id: uuidv4(),
                                dbId: data.pedido.id,
                                mesaId: mesa.id,
                                clienteNombre: data.pedido.clienteNombre,
                                items: (data.items ?? []).map((i: ApiRow) => ({
                                    iva: normalizeIvaPercent(i.iva ?? i.IvaPct ?? i.PORCENTAJE, 16),
                                    montoIva: calcIvaAmount(Number(i.subtotal ?? 0), normalizeIvaPercent(i.iva ?? i.IvaPct ?? i.PORCENTAJE, 16)),
                                    id: uuidv4(),
                                    dbId: i.id,
                                    productoId: i.productoId,
                                    nombre: asTrimmedString(i.nombre),
                                    cantidad: Number(i.cantidad),
                                    precioUnitario: Number(i.precioUnitario),
                                    subtotal: Number(i.subtotal),
                                    estado: i.estado || 'entregado',
                                    esCompuesto: Boolean(i.esCompuesto),
                                    enviadoACocina: Boolean(i.enviadoACocina),
                                    horaEnvio: toDateOrUndefined(i.horaEnvio),
                                    comentarios: i.comentarios,
                                })),
                                estado: data.pedido.estado || 'abierto',
                                fechaApertura: toDateOrUndefined(data.pedido.fechaApertura) ?? new Date(),
                                total: Number(data.pedido.total ?? 0),
                                subtotal: Number(data.pedido.subtotal ?? 0),
                                impuestos: Number(data.pedido.impuestos ?? 0),
                                servicio: Number(data.pedido.servicio ?? 0),
                                persistido: true,
                            };
                        }
                    } catch { /* mesa sin pedido */ }
                }
            }

            const ambientesDb = ambRes.rows ?? [];
            const defaultColors = ['#4CAF50', '#FF9800', '#9C27B0', '#2196F3'];
            const uniqueAmbIds = [...new Set(mesas.map(m => m.ambienteId))];

            const ambientes: Ambiente[] = uniqueAmbIds.map((ambId, idx) => {
                const dbAmb = ambientesDb.find((a: ApiRow) => String(a.id) === ambId);
                return {
                    id: ambId,
                    nombre: dbAmb?.nombre || `Ambiente ${ambId}`,
                    color: dbAmb?.color || defaultColors[idx % defaultColors.length],
                    mesas: mesas.filter(m => m.ambienteId === ambId),
                };
            });

            const productos: ProductoMenu[] = (prodsRes.rows ?? []).map((r: ApiRow) => ({
                id: String(r.id),
                codigo: asTrimmedString(r.codigo),
                nombre: asTrimmedString(r.nombre),
                descripcion: asOptionalTrimmedString(r.descripcion),
                precio: Number(r.precio ?? 0),
                iva: Number(r.iva ?? r.PORCENTAJE ?? 16),
                categoria: asTrimmedString(r.categoria),
                esCompuesto: Boolean(r.esCompuesto),
                tiempoPreparacion: Number(r.tiempoPreparacion ?? 0),
                imagen: resolveAssetUrl(r.imagen ?? r.IMAGEN ?? r.image),
                esSugerenciaDelDia: Boolean(r.esSugerenciaDelDia),
                disponible: r.disponible !== false,
            }));

            set((state) => ({
                ambientes,
                ambienteActivo: resolveAmbienteActivo(state.ambienteActivo, ambientes),
                productos,
                loading: false,
            }));
        } catch (err) {
            console.error('Error cargando datos del restaurante:', err);
            set((state) => ({
                ambientes: state.ambientes,
                loading: false,
            }));
        }
    },

    setAmbienteActivo: (id) => set({ ambienteActivo: id }),

    // ═══════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════

    getMesaById: (id) => {
        for (const amb of get().ambientes) {
            const mesa = amb.mesas.find(m => m.id === id);
            if (mesa) return mesa;
        }
        return undefined;
    },

    actualizarMesa: (mesaId, updates) => {
        set(state => ({
            ambientes: state.ambientes.map(amb => ({
                ...amb,
                mesas: amb.mesas.map(m => m.id === mesaId ? { ...m, ...updates } : m),
            })),
        }));
    },

    // ═══════════════════════════════════════════════════════════════
    // 2. ABRIR PEDIDO — Solo en STORE (sin BD)
    //    La BD se toca en enviarComanda cuando es la primera vez
    // ═══════════════════════════════════════════════════════════════

    abrirPedido: (mesaId, cliente) => {
        const nuevoPedido: Pedido = {
            id: uuidv4(),
            mesaId,
            cliente,
            items: [],
            estado: 'abierto',
            fechaApertura: new Date(),
            total: 0,
            subtotal: 0,
            impuestos: 0,
            servicio: 0,
            persistido: false,   // ← AÚN NO existe en la BD
        };
        get().actualizarMesa(mesaId, {
            estado: 'ocupada',
            pedidoActual: nuevoPedido,
            cliente,
        });
    },

    // ═══════════════════════════════════════════════════════════════
    // 3. AGREGAR ITEM — Solo en STORE (sin BD)
    //    El mesero puede agregar y quitar libremente
    // ═══════════════════════════════════════════════════════════════

    agregarItem: (mesaId, item) => {
        const mesa = get().getMesaById(mesaId);
        if (!mesa?.pedidoActual) return;

        const loc = usePosStore.getState().localizacion;
        const ivaPct = normalizeIvaPercent(item.iva, 16);
        const calc = calcTotals(item.cantidad, item.precioUnitario, 0, ivaPct, loc);

        const newItem: ItemPedido = {
            id: uuidv4(),
            ...item,
            precioUnitario: calc.precioBaseUnidad,
            subtotal: calc.totalBase,
            iva: ivaPct,
            montoIva: calc.totalIva,
            estado: item.estado || 'pendiente',
            enviadoACocina: false,
        };

        const nuevosItems = [...mesa.pedidoActual.items, newItem];
        const subtotal = nuevosItems.reduce((sum, i) => sum + i.subtotal, 0);
        const impuestos = nuevosItems.reduce((sum, i) => sum + i.montoIva, 0);
        const servicio = Math.round((subtotal * 0.10) * 100) / 100; // 10% de la base
        const total = subtotal + impuestos + servicio;

        get().actualizarMesa(mesaId, {
            pedidoActual: {
                ...mesa.pedidoActual,
                items: nuevosItems,
                subtotal, impuestos, servicio, total,
            },
        });
    },

    quitarItem: (mesaId, itemId) => {
        const mesa = get().getMesaById(mesaId);
        if (!mesa?.pedidoActual) return;

        const item = mesa.pedidoActual.items.find(i => i.id === itemId);
        // Solo se pueden quitar items NO enviados a cocina
        if (item?.enviadoACocina) return;

        const nuevosItems = mesa.pedidoActual.items.filter(i => i.id !== itemId);
        const subtotal = nuevosItems.reduce((sum, i) => sum + i.subtotal, 0);
        const impuestos = nuevosItems.reduce((sum, i) => sum + i.montoIva, 0);
        const servicio = Math.round((subtotal * 0.10) * 100) / 100; // 10% de la base
        const total = subtotal + impuestos + servicio;

        get().actualizarMesa(mesaId, {
            pedidoActual: {
                ...mesa.pedidoActual,
                items: nuevosItems,
                subtotal, impuestos, servicio, total,
            },
        });
    },

    anularItemEnviado: async (mesaId, itemId, auth) => {
        const mesa = get().getMesaById(mesaId);
        if (!mesa?.pedidoActual) return { success: false, message: 'No hay pedido activo' };

        const pedido = mesa.pedidoActual;
        const item = pedido.items.find((i) => i.id === itemId);
        if (!item) return { success: false, message: 'Item no encontrado en el pedido' };

        const motivo = String(auth?.motivo ?? '').trim() || 'Cliente no desea el producto';
        const supervisorUser = String(auth?.supervisorUser ?? '').trim();
        const supervisorPassword = String(auth?.supervisorPassword ?? '');
        const biometricBypass = Boolean(auth?.biometricBypass);
        const biometricCredentialId = String(auth?.biometricCredentialId ?? '').trim();
        if (!supervisorUser) {
            return { success: false, message: 'Debe indicar usuario supervisor.' };
        }
        if (!biometricBypass && !supervisorPassword) {
            return { success: false, message: 'Debe indicar clave de supervisor para anular.' };
        }
        if (biometricBypass && !biometricCredentialId) {
            return { success: false, message: 'Debe validar huella del supervisor.' };
        }

        if (!item.enviadoACocina) {
            get().quitarItem(mesaId, itemId);
            return { success: true, message: 'Item pendiente eliminado del pedido.' };
        }

        if (!pedido.dbId || !item.dbId) {
            return { success: false, message: 'No se pudo anular: item enviado sin referencia de BD.' };
        }

        set({ syncing: true });

        try {
            const cancelData = await apiPost(`/v1/restaurante/pedidos/${pedido.dbId}/items/${item.dbId}/cancelar`, {
                motivo,
                supervisorUser,
                supervisorPassword: biometricBypass ? '' : supervisorPassword,
                biometricBypass,
                biometricCredentialId: biometricBypass ? biometricCredentialId : undefined,
            });

            if (!cancelData.ok) {
                const errorCode = String(cancelData.error ?? '').trim().toLowerCase();
                if (errorCode === 'item_already_voided') {
                    const nuevosItems = pedido.items.filter((i) => i.id !== itemId);
                    const subtotal = nuevosItems.reduce((sum, i) => sum + i.subtotal, 0);
                    const impuestos = nuevosItems.reduce((sum, i) => sum + i.montoIva, 0);
                    const servicio = Math.round((subtotal * 0.10) * 100) / 100;
                    const total = subtotal + impuestos + servicio;

                    get().actualizarMesa(mesaId, {
                        pedidoActual: {
                            ...pedido,
                            items: nuevosItems,
                            subtotal,
                            impuestos,
                            servicio,
                            total,
                        },
                    });

                    set({ syncing: false });
                    return { success: true, message: 'El item ya estaba anulado. Pedido actualizado.' };
                }

                set({ syncing: false });
                return { success: false, message: `Error anulando item: ${cancelData.error || 'desconocido'}` };
            }

            const printResult = await usePosStore.getState().printKitchenOrder('Cocina Principal', {
                texto: `ANULAR - Mesa: ${mesa.nombre}\n${item.cantidad}x ${item.nombre}${motivo ? ` >> ${motivo}` : ''}`,
                renglones: [
                    {
                        articulo: `ANULAR ${item.nombre}`,
                        cantidad: item.cantidad,
                        nota: motivo || '',
                    },
                ],
            });

            const nuevosItems = pedido.items.filter((i) => i.id !== itemId);
            const subtotal = nuevosItems.reduce((sum, i) => sum + i.subtotal, 0);
            const impuestos = nuevosItems.reduce((sum, i) => sum + i.montoIva, 0);
            const servicio = Math.round((subtotal * 0.10) * 100) / 100;
            const total = subtotal + impuestos + servicio;

            get().actualizarMesa(mesaId, {
                pedidoActual: {
                    ...pedido,
                    items: nuevosItems,
                    subtotal,
                    impuestos,
                    servicio,
                    total,
                },
            });

            set({ syncing: false });
            return {
                success: true,
                message: printResult.success
                    ? 'Item anulado y notificado a cocina.'
                    : `Item anulado, pero no se pudo imprimir aviso de anulación: ${printResult.message}`,
            };
        } catch (e: unknown) {
            set({ syncing: false });
            return { success: false, message: `Error anulando item: ${e instanceof Error ? e.message : 'desconocido'}` };
        }
    },

    editarItem: (mesaId, itemId, updates) => {
        const mesa = get().getMesaById(mesaId);
        if (!mesa?.pedidoActual) return;

        const loc = usePosStore.getState().localizacion;

        const nuevosItems = mesa.pedidoActual.items.map(item => {
            if (item.id !== itemId) return item;
            // Solo editar si NO fue enviado a cocina
            if (item.enviadoACocina) return item;

            const cantidad = updates.cantidad ?? item.cantidad;

            // Asumimos que para editar la cantidad o el precio usamos el original o si cambió
            // Nota: Aquí se debería quizá mantener el precioUnitario base ya calculado, pero para ser seguros
            // si modifican algo, recalculamos (aunque editarItem rara vez cambia el precio base aquí).
            // Para mantener consistencia con POS, asumiendo precioUnitario original, pero el store ya guardó precioBaseUnidad.
            // Asi que en restaurante item.precioUnitario YA está depurado de IVA si lo tenía.
            // Por lo tanto, no volvemos a pasar `calcTotals` a menos que usemos un Flag, o asumimos que ya no incluya iva:
            // Vamos a forzar un objeto loc local sin preciosIncluyenIva para que no descuente el IVA de nuevo.
            const locAjustado = { ...loc, preciosIncluyenIva: false, tasaCambio: 1 };
            const ivaPct = normalizeIvaPercent(item.iva, 16);
            const calc = calcTotals(cantidad, item.precioUnitario, 0, ivaPct, locAjustado);

            return {
                ...item,
                cantidad,
                iva: ivaPct,
                subtotal: calc.totalBase,
                montoIva: calc.totalIva,
                comentarios: updates.comentarios ?? item.comentarios
            };
        });

        const subtotal = nuevosItems.reduce((sum, i) => sum + i.subtotal, 0);
        const impuestos = nuevosItems.reduce((sum, i) => sum + i.montoIva, 0);
        const servicio = Math.round((subtotal * 0.10) * 100) / 100; // 10% de la base
        const total = subtotal + impuestos + servicio;

        get().actualizarMesa(mesaId, {
            pedidoActual: {
                ...mesa.pedidoActual,
                items: nuevosItems,
                subtotal, impuestos, servicio, total,
            },
        });
    },

    // ═══════════════════════════════════════════════════════════════
    // 5. ENVIAR COMANDA — AQUÍ SÍ se persiste a la BD + imprime
    //
    //    Flujo:
    //    a) Si el pedido no existe en BD → POST /pedidos/abrir
    //    b) Para cada item NO enviado → POST /pedidos/item
    //    c) POST /pedidos/:id/comanda (marca como enviados en BD)
    //    d) Imprime comanda ESC/POS a cocina
    //    e) Actualiza store: items marcados como enviadoACocina=true
    // ═══════════════════════════════════════════════════════════════

    enviarComanda: async (mesaId) => {
        const mesa = get().getMesaById(mesaId);
        if (!mesa?.pedidoActual) return { success: false, message: 'No hay pedido activo' };

        const pedido = mesa.pedidoActual;
        const itemsPendientes = pedido.items.filter(i => !i.enviadoACocina);
        if (itemsPendientes.length === 0) return { success: false, message: 'No hay items nuevos para enviar' };

        set({ syncing: true });

        try {
            let dbPedidoId = pedido.dbId;

            // ─── (a) Si el pedido no existe en BD, crearlo ───
            if (!pedido.persistido || !dbPedidoId) {
                const abrirData = await apiPost(`/v1/restaurante/pedidos/abrir`, {
                    mesaId: Number(mesaId),
                    clienteNombre: pedido.cliente?.nombre,
                    clienteRif: pedido.cliente?.cedula,
                });
                if (!abrirData.ok) {
                    set({ syncing: false });
                    return { success: false, message: `Error abriendo pedido: ${abrirData.error || 'desconocido'}` };
                }
                dbPedidoId = abrirData.pedidoId;
            }

            // ─── (b) Persistir cada item nuevo ───
            for (const item of itemsPendientes) {
                const ivaPct = normalizeIvaPercent(item.iva, 16);
                const itemData = await apiPost(`/v1/restaurante/pedidos/item`, {
                    pedidoId: dbPedidoId,
                    productoId: item.productoId,
                    nombre: item.nombre,
                    cantidad: item.cantidad,
                    precioUnitario: item.precioUnitario,
                    iva: ivaPct,
                    esCompuesto: item.esCompuesto,
                    componentes: item.componentes ? JSON.stringify(item.componentes) : undefined,
                    comentarios: item.comentarios,
                });
                if (itemData.ok) {
                    item.dbId = itemData.itemId;
                }
            }

            // ─── (c) Marcar como enviado en BD ───
            await apiPost(`/v1/restaurante/pedidos/${dbPedidoId}/comanda`, {});

            // ─── (d) Imprimir comanda en cocina ───
            const printResult = await usePosStore.getState().printKitchenOrder('Cocina Principal', {
                texto: `Mesa: ${mesa.nombre}\n${itemsPendientes.map(i => `${i.cantidad}x ${i.nombre}${i.comentarios ? ` >> ${i.comentarios}` : ''}`).join('\n')}`,
                renglones: itemsPendientes.map(i => ({
                    articulo: i.nombre,
                    cantidad: i.cantidad,
                    nota: i.comentarios || '',
                })),
            });

            // ─── (e) Actualizar store ───
            const itemsActualizados = pedido.items.map(item => {
                if (item.enviadoACocina) return item;
                return { ...item, enviadoACocina: true, horaEnvio: new Date(), estado: 'en_preparacion' as const };
            });

            get().actualizarMesa(mesaId, {
                pedidoActual: {
                    ...pedido,
                    dbId: dbPedidoId,
                    items: itemsActualizados,
                    estado: 'en_preparacion',
                    persistido: true,
                },
            });

            set({ syncing: false });
            return {
                success: true,
                message: printResult.success
                    ? `✅ Comanda enviada (${itemsPendientes.length} items) e impresa.`
                    : `⚠️ Comanda guardada pero impresión falló: ${printResult.message}`,
            };

        } catch (e: unknown) {
            set({ syncing: false });
            return { success: false, message: `Error: ${e instanceof Error ? e.message : 'desconocido'}` };
        }
    },

    // ═══════════════════════════════════════════════════════════════
    // 6. GENERAR CUENTA — Impresión fiscal (lee del STORE)
    //    No persiste nada extra, solo imprime
    // ═══════════════════════════════════════════════════════════════

    generarCuenta: async (mesaId) => {
        const mesa = get().getMesaById(mesaId);
        if (!mesa?.pedidoActual) return { success: false, message: 'No hay pedido activo' };

        const itemsToPrint = mesa.pedidoActual.items.map(i => ({
            nombre: i.nombre,
            cantidad: i.cantidad,
            precio: i.precioUnitario,
            iva: i.iva ?? 16,
        }));

        if (mesa.pedidoActual.servicio > 0) {
            itemsToPrint.push({
                nombre: "SERVICIO 10%",
                cantidad: 1,
                precio: mesa.pedidoActual.servicio,
                iva: 0, // El servicio es base imponible, pero no genera IVA
            });
        }

        const result = await usePosStore.getState().printFiscalInvoice({
            items: itemsToPrint,
        });

        if (result.success) {
            get().actualizarMesa(mesaId, {
                estado: 'cuenta',
            });
        }

        return result;
    },

    // ═══════════════════════════════════════════════════════════════
    // 7. CERRAR MESA — Persiste cierre a BD + limpia STORE
    // ═══════════════════════════════════════════════════════════════

    cerrarMesa: async (mesaId) => {
        const mesa = get().getMesaById(mesaId);
        if (!mesa?.pedidoActual) return { success: false, message: 'No hay pedido activo' };

        set({ syncing: true });

        try {
            const dbPedidoId = mesa.pedidoActual.dbId;

            // Si hay items sin enviar, persistirlos primero
            const sinEnviar = mesa.pedidoActual.items.filter(i => !i.enviadoACocina);
            if (sinEnviar.length > 0 && dbPedidoId) {
                for (const item of sinEnviar) {
                    const ivaPct = normalizeIvaPercent(item.iva, 16);
                    await apiPost(`/v1/restaurante/pedidos/item`, {
                        pedidoId: dbPedidoId,
                        productoId: item.productoId,
                        nombre: item.nombre,
                        cantidad: item.cantidad,
                        precioUnitario: item.precioUnitario,
                        iva: ivaPct,
                        esCompuesto: item.esCompuesto,
                        componentes: item.componentes ? JSON.stringify(item.componentes) : undefined,
                        comentarios: item.comentarios,
                    });
                }
            }

            // Cerrar pedido en BD
            if (dbPedidoId) {
                await apiPost(`/v1/restaurante/pedidos/${dbPedidoId}/cerrar`, {});
            }

            // Limpiar mesa en store
            get().actualizarMesa(mesaId, {
                estado: 'libre',
                pedidoActual: undefined,
                cliente: undefined,
            });

            set({ syncing: false });
            return { success: true, message: 'Mesa cerrada exitosamente.' };

        } catch (e: unknown) {
            set({ syncing: false });
            return { success: false, message: `Error cerrando mesa: ${e instanceof Error ? e.message : 'desconocido'}` };
        }
    },

    // ═══════════════════════════════════════════════════════════════
    // Layout: mover y transferir mesas
    // ═══════════════════════════════════════════════════════════════

    moverMesa: (mesaId, nuevoX, nuevoY, nuevoAmbienteId) => {
        set(state => {
            let mesaAMover: Mesa | undefined;
            const ambientesSinMesa = state.ambientes.map(amb => {
                const mesa = amb.mesas.find(m => m.id === mesaId);
                if (mesa) {
                    mesaAMover = mesa;
                    return { ...amb, mesas: amb.mesas.filter(m => m.id !== mesaId) };
                }
                return amb;
            });
            if (!mesaAMover) return state;
            const ambienteDestino = nuevoAmbienteId || mesaAMover.ambienteId;
            return {
                ambientes: ambientesSinMesa.map(amb => amb.id === ambienteDestino
                    ? { ...amb, mesas: [...amb.mesas, { ...mesaAMover!, posicionX: nuevoX, posicionY: nuevoY, ambienteId: ambienteDestino }] }
                    : amb
                ),
            };
        });
    },

    transferirMesa: (origenId, destinoId) => {
        set(state => {
            let mesaOrigen: Mesa | undefined;
            let mesaDestino: Mesa | undefined;
            state.ambientes.forEach(amb => {
                amb.mesas.forEach(m => {
                    if (m.id === origenId) mesaOrigen = m;
                    if (m.id === destinoId) mesaDestino = m;
                });
            });
            if (!mesaOrigen || !mesaDestino || mesaOrigen.estado === 'libre' || mesaDestino.estado !== 'libre') return state;
            return {
                ambientes: state.ambientes.map(amb => ({
                    ...amb,
                    mesas: amb.mesas.map(m => {
                        if (m.id === origenId) return { ...m, estado: 'libre' as const, pedidoActual: undefined, cliente: undefined };
                        if (m.id === destinoId) return {
                            ...m,
                            estado: mesaOrigen!.estado,
                            pedidoActual: mesaOrigen!.pedidoActual ? { ...mesaOrigen!.pedidoActual, mesaId: destinoId } : undefined,
                            cliente: mesaOrigen!.cliente,
                        };
                        return m;
                    }),
                })),
            };
        });
    },

    // ═══════════════════════════════════════════════════════════════
    // Computed
    // ═══════════════════════════════════════════════════════════════

    getComandasPendientes: () => {
        const comandas: ComandaCocina[] = [];
        get().ambientes.forEach(amb => {
            amb.mesas.forEach(mesa => {
                if (mesa.pedidoActual) {
                    mesa.pedidoActual.items
                        .filter(item => item.enviadoACocina && (item.estado === 'pendiente' || item.estado === 'en_preparacion'))
                        .forEach(item => {
                            comandas.push({
                                id: `${mesa.pedidoActual!.id}-${item.id}`,
                                pedidoId: mesa.pedidoActual!.id,
                                mesaNombre: mesa.nombre,
                                item,
                                horaRecibido: item.horaEnvio || new Date(),
                                prioridad: item.estado === 'pendiente' ? 'normal' : 'alta',
                                ambiente: amb.nombre,
                            });
                        });
                }
            });
        });
        return comandas.sort((a, b) => a.horaRecibido.getTime() - b.horaRecibido.getTime());
    },

    getItemsPendientes: (mesaId) => {
        const mesa = get().getMesaById(mesaId);
        return mesa?.pedidoActual?.items.filter(i => !i.enviadoACocina) ?? [];
    },

    getItemsEnviados: (mesaId) => {
        const mesa = get().getMesaById(mesaId);
        return mesa?.pedidoActual?.items.filter(i => i.enviadoACocina) ?? [];
    },

    getTotalMesa: (mesaId) => {
        const mesa = get().getMesaById(mesaId);
        return mesa?.pedidoActual?.total ?? 0;
    },

    getSubtotalMesa: (mesaId) => {
        const mesa = get().getMesaById(mesaId);
        return mesa?.pedidoActual?.subtotal ?? 0;
    },

    getImpuestosMesa: (mesaId) => {
        const mesa = get().getMesaById(mesaId);
        return mesa?.pedidoActual?.impuestos ?? 0;
    },

    getServicioMesa: (mesaId) => {
        const mesa = get().getMesaById(mesaId);
        return mesa?.pedidoActual?.servicio ?? 0;
    },
}));


// ═══════════════════════════════════════════════════════════════
// HOOK WRAPPER — Compatibilidad con los componentes existentes
// Inicializa el store al montar + re-exporta todo
// ═══════════════════════════════════════════════════════════════

export function useRestaurante() {
    const store = useRestauranteStore();

    // Inicializar al montar (solo una vez)
    useEffect(() => {
        if (store.loading && store.ambientes.length === 0) {
            store.initFromApi();
        }
    }, []); // eslint-disable-line react-hooks/exhaustive-deps

    // Wrapper para abrirPedido compatible con la firma anterior
    const abrirPedido = useCallback((mesaId: string, cliente?: ClienteMesa) => {
        store.abrirPedido(mesaId, cliente);
    }, [store.abrirPedido]);

    // Wrapper para agregarItem compatible con la firma anterior
    const agregarItemAPedido = useCallback((mesaId: string, item: Omit<ItemPedido, 'id'>) => {
        store.agregarItem(mesaId, item);
    }, [store.agregarItem]);

    // enviarComanda ahora retorna una promesa con { success, message }
    const enviarComandaACocina = useCallback((mesaId: string) => {
        // Marca local sin BD (para compat — la real es enviarComanda)
        const mesa = store.getMesaById(mesaId);
        if (!mesa?.pedidoActual) return;
        const itemsActualizados = mesa.pedidoActual.items.map(item => {
            if (item.enviadoACocina) return item;
            return { ...item, enviadoACocina: true, horaEnvio: new Date(), estado: 'en_preparacion' as const };
        });
        store.actualizarMesa(mesaId, {
            pedidoActual: { ...mesa.pedidoActual, items: itemsActualizados },
        });
    }, [store.getMesaById, store.actualizarMesa]);

    // Impresión integrada: enviarComanda persiste + imprime
    const imprimirComandaCocina = useCallback(async (mesaId: string) => {
        return store.enviarComanda(mesaId);
    }, [store.enviarComanda]);

    const imprimirCuentaFiscal = useCallback(async (mesaId: string) => {
        return store.generarCuenta(mesaId);
    }, [store.generarCuenta]);

    return {
        // Estado
        ambientes: store.ambientes,
        ambienteActivo: store.ambienteActivo,
        setAmbienteActivo: store.setAmbienteActivo,
        productos: store.productos,
        loading: store.loading,
        syncing: store.syncing,

        // Mesas
        getMesaById: store.getMesaById,
        actualizarMesa: store.actualizarMesa,

        // Pedido lifecycle
        abrirPedido,
        agregarItemAPedido,
        quitarItem: store.quitarItem,
        anularItemEnviado: store.anularItemEnviado,
        editarItem: store.editarItem,
        enviarComandaACocina,

        // Persistencia + impresión
        enviarComanda: store.enviarComanda,
        imprimirComandaCocina,
        imprimirCuentaFiscal,
        cerrarMesa: store.cerrarMesa,

        // Layout
        moverMesa: store.moverMesa,
        transferirMesa: store.transferirMesa,

        // Computed
        getComandasPendientes: store.getComandasPendientes,
        getItemsPendientes: store.getItemsPendientes,
        getItemsEnviados: store.getItemsEnviados,
        getTotalMesa: store.getTotalMesa,
        getSubtotalMesa: store.getSubtotalMesa,
        getImpuestosMesa: store.getImpuestosMesa,
        getServicioMesa: store.getServicioMesa,
    };
}

