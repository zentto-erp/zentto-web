'use client';

import React, { useState } from 'react';
import {
    Box,
    Paper,
    Typography,
    Chip,
    IconButton,
    Button,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    TextField,
    Tabs,
    Tab,
} from '@mui/material';
import {
    DndContext,
    DragEndEvent,
    MouseSensor,
    TouchSensor,
    useSensor,
    useSensors,
} from '@dnd-kit/core';
import { MesaCard } from './MesaCard';
import { Ambiente, Mesa, ClienteMesa } from '@/hooks/useRestaurante';

interface MapaMesasProps {
    ambientes: Ambiente[];
    ambienteActivo: string;
    onAmbienteChange: (id: string) => void;
    onMesaClick: (mesa: Mesa) => void;
    onMoverMesa: (mesaId: string, x: number, y: number, ambienteId?: string) => void;
    onCrearMesa: (ambienteId: string, mesa: Omit<Mesa, 'id' | 'ambienteId'>) => void;
    onTransferirMesa: (origenId: string, destinoId: string) => void;
    modoEdicion?: boolean;
}

export function MapaMesas({
    ambientes,
    ambienteActivo,
    onAmbienteChange,
    onMesaClick,
    onMoverMesa,
    onCrearMesa,
    onTransferirMesa,
    modoEdicion = false,
}: MapaMesasProps) {
    const [dialogAbierto, setDialogAbierto] = useState(false);
    const [nuevaMesa, setNuevaMesa] = useState({
        numero: 0,
        nombre: '',
        capacidad: 4,
        posicionX: 0,
        posicionY: 0,
    });

    const validTabs = new Set(['todos', ...ambientes.map((a) => a.id)]);
    const tabsValue = validTabs.has(ambienteActivo) ? ambienteActivo : 'todos';

    const isTodos = tabsValue === 'todos';
    const activeAmbiente = ambientes.find((a) => a.id === tabsValue);
    const mesasToShow = isTodos
        ? ambientes.flatMap(a => a.mesas)
        : activeAmbiente?.mesas || [];

    const sensors = useSensors(
        useSensor(MouseSensor, { activationConstraint: { distance: 10 } }),
        useSensor(TouchSensor, { activationConstraint: { delay: 250, tolerance: 5 } })
    );

    const handleDragEnd = (event: DragEndEvent) => {
        const { active, over, delta } = event;
        const mesaId = active.id as string;

        // Transferencia de cuentas
        if (!modoEdicion && over) {
            const destinoId = over.id as string;
            if (mesaId !== destinoId) {
                onTransferirMesa(mesaId, destinoId);
            }
            return;
        }

        // Movimiento de mesa en modo edición
        if (modoEdicion) {
            const mesa = mesasToShow.find(m => m.id === mesaId);
            if (mesa && (Math.abs(delta.x) > 5 || Math.abs(delta.y) > 5)) {
                const nuevaX = Math.max(0, mesa.posicionX + delta.x);
                const nuevaY = Math.max(0, mesa.posicionY + delta.y);
                onMoverMesa(mesaId, nuevaX, nuevaY, mesa.ambienteId);
            }
        }
    };

    const handleCrearMesa = () => {
        const currentMesaArr = activeAmbiente ? activeAmbiente.mesas : mesasToShow;
        const maxNumero = Math.max(...(currentMesaArr.map(m => m.numero) || [0]), 0);
        const targetAmbienteId = activeAmbiente ? activeAmbiente.id : ambientes[0].id;

        onCrearMesa(targetAmbienteId, {
            ...nuevaMesa,
            numero: maxNumero + 1,
            nombre: nuevaMesa.nombre || `Mesa ${maxNumero + 1}`,
            estado: 'libre',
        });
        setDialogAbierto(false);
        setNuevaMesa({ numero: 0, nombre: '', capacidad: 4, posicionX: 0, posicionY: 0 });
    };

    if (!mesasToShow) return null;

    return (
        <Box sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
            {/* Tabs de ambientes */}
            <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 2 }}>
                <Tabs value={tabsValue} onChange={(_, v) => onAmbienteChange(String(v))}>
                    <Tab
                        value="todos"
                        label="TODOS LOS AMBIENTES"
                        sx={{
                            '&.Mui-selected': {
                                color: '#1976d2',
                                borderBottom: `2px solid #1976d2`
                            }
                        }}
                    />
                    {ambientes.map(amb => (
                        <Tab
                            key={amb.id}
                            value={amb.id}
                            label={amb.nombre.toUpperCase()}
                            sx={{
                                '&.Mui-selected': {
                                    color: amb.color,
                                    borderBottom: `2px solid ${amb.color}`
                                }
                            }}
                        />
                    ))}
                </Tabs>
            </Box>

            {/* Stats del ambiente */}
            <Box sx={{ display: 'flex', gap: 2, mb: 2, flexWrap: 'wrap' }}>
                <Chip
                    label={`${mesasToShow.length} Mesas`}
                    variant="outlined"
                    size="small"
                />
                <Chip
                    label={`${mesasToShow.filter(m => m.estado === 'ocupada').length} Ocupadas`}
                    color="error"
                    size="small"
                />
                <Chip
                    label={`${mesasToShow.filter(m => m.estado === 'libre').length} Libres`}
                    color="success"
                    size="small"
                />
                <Chip
                    label={`${mesasToShow.filter(m => m.estado === 'cuenta').length} Por Cobrar`}
                    color="warning"
                    size="small"
                />
            </Box>

            {/* Grid de mesas */}
            <DndContext sensors={sensors} onDragEnd={handleDragEnd}>
                <Box
                    sx={{
                        flexGrow: 1,
                        position: 'relative',
                        minHeight: 800,
                        bgcolor: '#f5f5f5',
                        borderRadius: 2,
                        p: 2,
                        overflow: 'auto'
                    }}
                >
                    <Box sx={{
                        position: 'relative',
                        width: '100%',
                        height: '100%',
                        display: { xs: 'flex', md: 'block' },
                        flexWrap: { xs: 'wrap', md: 'nowrap' },
                        gap: { xs: 2.5, md: 0 },
                        justifyContent: { xs: 'center', md: 'unset' }
                    }}>
                        {mesasToShow
                            .sort((a, b) => a.posicionY - b.posicionY || a.posicionX - b.posicionX)
                            .map((mesa) => (
                                <MesaCard
                                    key={mesa.id}
                                    mesa={mesa}
                                    onClick={() => onMesaClick(mesa)}
                                    isDraggable={modoEdicion}
                                />
                            ))}
                    </Box>
                </Box>
            </DndContext>

            {/* Botón agregar mesa */}
            {modoEdicion && (
                <Box sx={{ mt: 2, display: 'flex', justifyContent: 'center' }}>
                    <Button
                        variant="outlined"
                        onClick={() => setDialogAbierto(true)}
                    >
                        + Agregar Mesa
                    </Button>
                </Box>
            )}

            {/* Dialog crear mesa */}
            <Dialog open={dialogAbierto} onClose={() => setDialogAbierto(false)} maxWidth="xs" fullWidth>
                <DialogTitle>Nueva Mesa</DialogTitle>
                <DialogContent>
                    <TextField
                        fullWidth
                        label="Nombre"
                        value={nuevaMesa.nombre}
                        onChange={(e) => setNuevaMesa({ ...nuevaMesa, nombre: e.target.value })}
                        sx={{ mb: 2, mt: 1 }}
                    />
                    <TextField
                        fullWidth
                        label="Capacidad"
                        type="number"
                        value={nuevaMesa.capacidad}
                        onChange={(e) => setNuevaMesa({ ...nuevaMesa, capacidad: parseInt(e.target.value) || 1 })}
                    />
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setDialogAbierto(false)}>Cancelar</Button>
                    <Button variant="contained" onClick={handleCrearMesa}>Crear</Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
}
