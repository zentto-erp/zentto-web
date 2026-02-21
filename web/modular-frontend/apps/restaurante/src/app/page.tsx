'use client';

import React, { useState } from 'react';
import {
    Box,
    Paper,
    Typography,
    Button,
    Switch,
    FormControlLabel,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    TextField,
} from '@mui/material';
import EditIcon from '@mui/icons-material/Edit';
import AddIcon from '@mui/icons-material/Add';
import { MapaMesas } from '@/components/MapaMesas';
import { PanelPedido } from '@/components/PanelPedido';
import { useRestaurante, Mesa, ClienteMesa } from '@/hooks/useRestaurante';

export default function RestaurantePage() {
    const {
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
    } = useRestaurante();

    const [mesaSeleccionada, setMesaSeleccionada] = useState<Mesa | null>(null);
    const [modoEdicion, setModoEdicion] = useState(false);
    const [dialogCliente, setDialogCliente] = useState(false);
    const [clienteInfo, setClienteInfo] = useState<Partial<ClienteMesa>>({});

    const handleMesaClick = (mesa: Mesa) => {
        if (modoEdicion) return;

        if (mesa.estado === 'libre') {
            // Abrir nueva cuenta
            setMesaSeleccionada(mesa);
            setDialogCliente(true);
        } else if (mesa.estado === 'ocupada') {
            // Continuar pedido existente
            const mesaActualizada = getMesaById(mesa.id);
            if (mesaActualizada) {
                setMesaSeleccionada(mesaActualizada);
            }
        }
    };

    const handleCrearPedido = () => {
        if (!mesaSeleccionada) return;

        const cliente: ClienteMesa | undefined = clienteInfo.nombre ? {
            id: Date.now().toString(),
            nombre: clienteInfo.nombre,
            telefono: clienteInfo.telefono,
        } : undefined;

        abrirPedido(mesaSeleccionada.id, cliente);
        const mesaActualizada = getMesaById(mesaSeleccionada.id);
        if (mesaActualizada) {
            setMesaSeleccionada(mesaActualizada);
        }
        setDialogCliente(false);
        setClienteInfo({});
    };

    const handleAgregarItem = (item: Parameters<typeof agregarItemAPedido>[1]) => {
        if (!mesaSeleccionada) return;
        agregarItemAPedido(mesaSeleccionada.id, item);
        const mesaActualizada = getMesaById(mesaSeleccionada.id);
        if (mesaActualizada) {
            setMesaSeleccionada(mesaActualizada);
        }
    };

    const handleEnviarComanda = () => {
        if (!mesaSeleccionada) return;
        enviarComandaACocina(mesaSeleccionada.id);
        const mesaActualizada = getMesaById(mesaSeleccionada.id);
        if (mesaActualizada) {
            setMesaSeleccionada(mesaActualizada);
        }
    };

    const handleCrearMesa = (ambienteId: string, mesa: Omit<Mesa, 'id' | 'ambienteId'>) => {
        // En una app real, esto llamaría a la API
        // Por ahora, recargamos la página para ver los cambios
        window.location.reload();
    };

    return (
        <Box sx={{ height: 'calc(100vh - 100px)', p: 2 }}>
            {/* Header */}
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                <Typography variant="h4" fontWeight="bold">
                    🍽️ Gestión de Salón
                </Typography>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                    <FormControlLabel
                        control={
                            <Switch
                                checked={modoEdicion}
                                onChange={(e) => setModoEdicion(e.target.checked)}
                            />
                        }
                        label="Modo Edición"
                    />
                    <Button
                        variant="outlined"
                        startIcon={<EditIcon />}
                        onClick={() => setModoEdicion(!modoEdicion)}
                    >
                        {modoEdicion ? 'Guardar Layout' : 'Editar Layout'}
                    </Button>
                </Box>
            </Box>

            {mesaSeleccionada && mesaSeleccionada.estado === 'ocupada' ? (
                /* Panel de pedido activo */
                <Box sx={{ height: 'calc(100% - 60px)' }}>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                        <Typography variant="h6">
                            Pedido en {mesaSeleccionada.nombre}
                        </Typography>
                        <Button variant="outlined" onClick={() => setMesaSeleccionada(null)}>
                            Volver al Salón
                        </Button>
                    </Box>
                    <PanelPedido
                        mesa={mesaSeleccionada}
                        productos={productos}
                        onAgregarItem={handleAgregarItem}
                        onEnviarComanda={handleEnviarComanda}
                        onCerrar={() => setMesaSeleccionada(null)}
                    />
                </Box>
            ) : (
                /* Mapa de mesas */
                <Box sx={{ height: 'calc(100% - 60px)' }}>
                    <MapaMesas
                        ambientes={ambientes}
                        ambienteActivo={ambienteActivo}
                        onAmbienteChange={setAmbienteActivo}
                        onMesaClick={handleMesaClick}
                        onMoverMesa={moverMesa}
                        onTransferirMesa={transferirMesa}
                        onCrearMesa={handleCrearMesa}
                        modoEdicion={modoEdicion}
                    />
                </Box>
            )}

            {/* Dialog para datos del cliente */}
            <Dialog open={dialogCliente} onClose={() => setDialogCliente(false)} maxWidth="xs" fullWidth>
                <DialogTitle>Nueva Cuenta - {mesaSeleccionada?.nombre}</DialogTitle>
                <DialogContent>
                    <TextField
                        fullWidth
                        label="Nombre del Cliente (opcional)"
                        value={clienteInfo.nombre || ''}
                        onChange={(e) => setClienteInfo({ ...clienteInfo, nombre: e.target.value })}
                        sx={{ mb: 2, mt: 1 }}
                    />
                    <TextField
                        fullWidth
                        label="Teléfono (opcional)"
                        value={clienteInfo.telefono || ''}
                        onChange={(e) => setClienteInfo({ ...clienteInfo, telefono: e.target.value })}
                    />
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setDialogCliente(false)}>Cancelar</Button>
                    <Button variant="contained" onClick={handleCrearPedido}>
                        Abrir Cuenta
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
}
