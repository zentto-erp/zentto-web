'use client';

import { useState, useCallback } from 'react';
import { v4 as uuidv4 } from 'uuid';

// Tipos
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
    id: string;
    mesaId: string;
    cliente?: ClienteMesa;
    items: ItemPedido[];
    estado: 'abierto' | 'en_preparacion' | 'listo' | 'cerrado';
    fechaApertura: Date;
    fechaCierre?: Date;
    total: number;
    comentarios?: string;
}

export interface ItemPedido {
    id: string;
    productoId: string;
    nombre: string;
    cantidad: number;
    precioUnitario: number;
    subtotal: number;
    estado: 'pendiente' | 'en_preparacion' | 'listo' | 'entregado';
    comentarios?: string;
    esCompuesto: boolean;
    componentes?: ComponenteItem[];
    enviadoACocina: boolean;
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
    categoria: string;
    esCompuesto: boolean;
    componentes?: ComponenteProducto[];
    tiempoPreparacion: number; // minutos
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

// Hook principal del restaurante
export function useRestaurante() {
    const [ambientes, setAmbientes] = useState<Ambiente[]>([
        {
            id: '1',
            nombre: 'Salón Principal',
            color: '#4CAF50',
            mesas: [
                { id: 'm1', numero: 1, nombre: 'Mesa 1', capacidad: 4, ambienteId: '1', posicionX: 20, posicionY: 20, estado: 'libre' },
                { id: 'm2', numero: 2, nombre: 'Mesa 2', capacidad: 2, ambienteId: '1', posicionX: 180, posicionY: 20, estado: 'libre' },
                {
                    id: 'm3', numero: 3, nombre: 'Mesa 3', capacidad: 6, ambienteId: '1', posicionX: 340, posicionY: 20, estado: 'ocupada',
                    pedidoActual: {
                        id: 'p1',
                        mesaId: 'm3',
                        cliente: { id: 'c1', nombre: 'Juan Pérez', telefono: '0414-1234567' },
                        items: [
                            { id: 'i1', productoId: 'p1', nombre: 'Pasta Carbonara', cantidad: 2, precioUnitario: 15, subtotal: 30, estado: 'entregado', esCompuesto: false, enviadoACocina: true, horaEnvio: new Date() },
                            { id: 'i2', productoId: 'p2', nombre: 'Coca Cola', cantidad: 2, precioUnitario: 3, subtotal: 6, estado: 'entregado', esCompuesto: false, enviadoACocina: true, horaEnvio: new Date() },
                        ],
                        estado: 'abierto',
                        fechaApertura: new Date(),
                        total: 36
                    },
                    cliente: { id: 'c1', nombre: 'Juan Pérez', telefono: '0414-1234567' }
                },
                { id: 'm4', numero: 4, nombre: 'Mesa 4', capacidad: 4, ambienteId: '1', posicionX: 20, posicionY: 180, estado: 'libre' },
                { id: 'm5', numero: 5, nombre: 'Mesa 5', capacidad: 8, ambienteId: '1', posicionX: 180, posicionY: 180, estado: 'reservada' },
            ]
        },
        {
            id: '2',
            nombre: 'Terraza',
            color: '#FF9800',
            mesas: [
                { id: 'm6', numero: 6, nombre: 'Mesa 6', capacidad: 4, ambienteId: '2', posicionX: 20, posicionY: 340, estado: 'libre' },
                { id: 'm7', numero: 7, nombre: 'Mesa 7', capacidad: 2, ambienteId: '2', posicionX: 180, posicionY: 340, estado: 'cuenta' },
            ]
        },
        {
            id: '3',
            nombre: 'Barra',
            color: '#9C27B0',
            mesas: [
                { id: 'm8', numero: 8, nombre: 'Barra 1', capacidad: 1, ambienteId: '3', posicionX: 20, posicionY: 500, estado: 'libre' },
                { id: 'm9', numero: 9, nombre: 'Barra 2', capacidad: 1, ambienteId: '3', posicionX: 180, posicionY: 500, estado: 'ocupada' },
                { id: 'm10', numero: 10, nombre: 'Barra 3', capacidad: 1, ambienteId: '3', posicionX: 340, posicionY: 500, estado: 'libre' },
            ]
        }
    ]);

    const [ambienteActivo, setAmbienteActivo] = useState<string>('1');

    // Productos de ejemplo
    const productos: ProductoMenu[] = [
        { id: 'p1', codigo: 'ENT001', nombre: 'Bruschetta', descripcion: 'Pan tostado con tomate y albahaca', precio: 8, categoria: 'Entradas', esCompuesto: false, tiempoPreparacion: 10, disponible: true },
        { id: 'p2', codigo: 'ENT002', nombre: 'Calamares Fritos', descripcion: 'Con salsa tártara', precio: 12, categoria: 'Entradas', esCompuesto: false, tiempoPreparacion: 15, disponible: true, esSugerenciaDelDia: true },
        {
            id: 'p3', codigo: 'PAST001', nombre: 'Pasta Carbonara', descripcion: 'Con huevo, queso y panceta', precio: 15, categoria: 'Pastas', esCompuesto: true,
            componentes: [
                { id: 'c1', nombre: 'Tipo de Pasta', opciones: ['Spaghetti', 'Penne', 'Fettuccine'], obligatorio: true },
                { id: 'c2', nombre: 'Extra Queso', opciones: ['Sí', 'No'], obligatorio: false }
            ],
            tiempoPreparacion: 20, disponible: true
        },
        { id: 'p4', codigo: 'PAST002', nombre: 'Lasagna', descripcion: 'Casera con carne', precio: 16, categoria: 'Pastas', esCompuesto: false, tiempoPreparacion: 25, disponible: true },
        {
            id: 'p5', codigo: 'CARNE001', nombre: 'Filete de Res', descripcion: 'Con vegetales grillados', precio: 25, categoria: 'Carnes', esCompuesto: true,
            componentes: [
                { id: 'c3', nombre: 'Cocción', opciones: ['Poco hecho', 'Al punto', 'Bien hecho'], obligatorio: true },
                { id: 'c4', nombre: 'Guarnición', opciones: ['Papas', 'Ensalada', 'Arroz'], obligatorio: true }
            ],
            tiempoPreparacion: 30, disponible: true, esSugerenciaDelDia: true
        },
        { id: 'p6', codigo: 'BEB001', nombre: 'Coca Cola', precio: 3, categoria: 'Bebidas', esCompuesto: false, tiempoPreparacion: 0, disponible: true },
        { id: 'p7', codigo: 'BEB002', nombre: 'Agua Mineral', precio: 2, categoria: 'Bebidas', esCompuesto: false, tiempoPreparacion: 0, disponible: true },
        { id: 'p8', codigo: 'POST001', nombre: 'Tiramisú', descripcion: 'Postre italiano clásico', precio: 8, categoria: 'Postres', esCompuesto: false, tiempoPreparacion: 5, disponible: true },
    ];

    const getMesaById = useCallback((id: string) => {
        for (const ambiente of ambientes) {
            const mesa = ambiente.mesas.find(m => m.id === id);
            if (mesa) return mesa;
        }
        return undefined;
    }, [ambientes]);

    const actualizarMesa = useCallback((mesaId: string, updates: Partial<Mesa>) => {
        setAmbientes(prev => prev.map(amb => ({
            ...amb,
            mesas: amb.mesas.map(m => m.id === mesaId ? { ...m, ...updates } : m)
        })));
    }, []);

    const abrirPedido = useCallback((mesaId: string, cliente?: ClienteMesa) => {
        const nuevoPedido: Pedido = {
            id: uuidv4(),
            mesaId,
            cliente,
            items: [],
            estado: 'abierto',
            fechaApertura: new Date(),
            total: 0
        };
        actualizarMesa(mesaId, {
            estado: 'ocupada',
            pedidoActual: nuevoPedido,
            cliente
        });
        return nuevoPedido;
    }, [actualizarMesa]);

    const agregarItemAPedido = useCallback((mesaId: string, item: Omit<ItemPedido, 'id'>) => {
        const mesa = getMesaById(mesaId);
        if (!mesa?.pedidoActual) return;

        const nuevoItem: ItemPedido = { ...item, id: uuidv4() };
        const nuevosItems = [...mesa.pedidoActual.items, nuevoItem];
        const nuevoTotal = nuevosItems.reduce((sum, i) => sum + i.subtotal, 0);

        actualizarMesa(mesaId, {
            pedidoActual: {
                ...mesa.pedidoActual,
                items: nuevosItems,
                total: nuevoTotal
            }
        });
    }, [getMesaById, actualizarMesa]);

    const enviarComandaACocina = useCallback((mesaId: string, itemIds?: string[]) => {
        const mesa = getMesaById(mesaId);
        if (!mesa?.pedidoActual) return;

        const itemsActualizados = mesa.pedidoActual.items.map(item => {
            if (itemIds && !itemIds.includes(item.id)) return item;
            if (item.enviadoACocina) return item;
            return { ...item, enviadoACocina: true, horaEnvio: new Date(), estado: 'en_preparacion' as const };
        });

        actualizarMesa(mesaId, {
            pedidoActual: {
                ...mesa.pedidoActual,
                items: itemsActualizados
            }
        });
    }, [getMesaById, actualizarMesa]);

    const moverMesa = useCallback((mesaId: string, nuevoX: number, nuevoY: number, nuevoAmbienteId?: string) => {
        setAmbientes(prev => {
            let mesaAMover: Mesa | undefined;
            const ambientesSinMesa = prev.map(amb => {
                const mesa = amb.mesas.find(m => m.id === mesaId);
                if (mesa) {
                    mesaAMover = mesa;
                    return { ...amb, mesas: amb.mesas.filter(m => m.id !== mesaId) };
                }
                return amb;
            });

            if (!mesaAMover) return prev;
            const ambienteDestino = nuevoAmbienteId || mesaAMover.ambienteId;

            return ambientesSinMesa.map(amb => {
                if (amb.id === ambienteDestino) {
                    return {
                        ...amb,
                        mesas: [...amb.mesas, { ...mesaAMover!, posicionX: nuevoX, posicionY: nuevoY, ambienteId: ambienteDestino }]
                    };
                }
                return amb;
            });
        });
    }, []);

    const transferirMesa = useCallback((origenId: string, destinoId: string) => {
        setAmbientes(prev => {
            let mesaOrigen: Mesa | undefined;
            let mesaDestino: Mesa | undefined;

            prev.forEach(amb => {
                amb.mesas.forEach(m => {
                    if (m.id === origenId) mesaOrigen = m;
                    if (m.id === destinoId) mesaDestino = m;
                });
            });

            if (!mesaOrigen || !mesaDestino || mesaOrigen.estado === 'libre' || mesaDestino.estado !== 'libre') {
                return prev;
            }

            return prev.map(amb => ({
                ...amb,
                mesas: amb.mesas.map(m => {
                    if (m.id === origenId) {
                        return { ...m, estado: 'libre', pedidoActual: undefined, cliente: undefined };
                    }
                    if (m.id === destinoId) {
                        return {
                            ...m,
                            estado: mesaOrigen!.estado,
                            pedidoActual: mesaOrigen!.pedidoActual ? { ...mesaOrigen!.pedidoActual, mesaId: destinoId } : undefined,
                            cliente: mesaOrigen!.cliente
                        };
                    }
                    return m;
                })
            }));
        });
    }, []);

    const getComandasPendientes = useCallback((): ComandaCocina[] => {
        const comandas: ComandaCocina[] = [];
        ambientes.forEach(amb => {
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
                                ambiente: amb.nombre
                            });
                        });
                }
            });
        });
        return comandas.sort((a, b) => a.horaRecibido.getTime() - b.horaRecibido.getTime());
    }, [ambientes]);

    return {
        ambientes,
        ambienteActivo,
        setAmbienteActivo,
        productos,
        getMesaById,
        actualizarMesa,
        abrirPedido,
        agregarItemAPedido,
        enviarComandaACocina,
        moverMesa,
        transferirMesa,
        getComandasPendientes
    };
}
