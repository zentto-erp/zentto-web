'use client';

import React, { useState, useEffect } from 'react';
import {
    Box,
    Typography,
    Button,
    Switch,
    FormControlLabel,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    TextField,
    Snackbar,
    Alert,
    LinearProgress,
} from '@mui/material';
import EditIcon from '@mui/icons-material/Edit';
import SettingsIcon from '@mui/icons-material/Settings';
import IconButton from '@mui/material/IconButton';
import { LocalizacionModal } from '@datqbox/shared-ui';
import { usePosStore } from '@datqbox/shared-api';
import { MapaMesas } from '@/components/MapaMesas';
import { PanelPedido } from '@/components/PanelPedido';
import { useRestaurante, Mesa, ClienteMesa } from '@/hooks/useRestaurante';

export default function RestaurantePage() {
    const {
        ambientes,
        ambienteActivo,
        setAmbienteActivo,
        productos,
        loading,
        syncing,
        getMesaById,
        abrirPedido,
        agregarItemAPedido,
        quitarItem,
        editarItem,
        moverMesa,
        transferirMesa,
        // ─── Acciones con BD ───
        enviarComanda,
        imprimirCuentaFiscal,
        cerrarMesa,
    } = useRestaurante();

    const [mesaSeleccionadaId, setMesaSeleccionadaId] = useState<string | null>(null);
    const [modoEdicion, setModoEdicion] = useState(false);
    const [dialogCliente, setDialogCliente] = useState(false);
    const [clienteInfo, setClienteInfo] = useState<Partial<ClienteMesa>>({});
    const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' | 'warning' }>({
        open: false, message: '', severity: 'success',
    });

    // Configuración compartida con POS (Multi-moneda / Multi-país)
    const [settingsOpen, setSettingsOpen] = useState(false);
    const { localizacion, setLocalizacion } = usePosStore();

    // La mesa seleccionada SIEMPRE se lee del store (fuente de verdad)
    const mesaSeleccionada = mesaSeleccionadaId ? getMesaById(mesaSeleccionadaId) ?? null : null;

    // Sincronizar estado: si la mesa pasa a libre, deseleccionar
    useEffect(() => {
        if (mesaSeleccionada && mesaSeleccionada.estado === 'libre') {
            setMesaSeleccionadaId(null);
        }
    }, [mesaSeleccionada]);

    const showMsg = (message: string, severity: 'success' | 'error' | 'warning' = 'success') => {
        setSnackbar({ open: true, message, severity });
    };

    // ─── Abrir mesa ───
    const handleMesaClick = (mesa: Mesa) => {
        if (modoEdicion) return;
        if (mesa.estado === 'libre') {
            setMesaSeleccionadaId(mesa.id);
            setDialogCliente(true);
        } else if (mesa.estado === 'ocupada' || mesa.estado === 'cuenta') {
            setMesaSeleccionadaId(mesa.id);
        }
    };

    // ─── Crear pedido (SOLO en Store — sin BD) ───
    const handleCrearPedido = () => {
        if (!mesaSeleccionadaId) return;
        const cliente: ClienteMesa | undefined = clienteInfo.nombre ? {
            id: Date.now().toString(),
            nombre: clienteInfo.nombre,
            telefono: clienteInfo.telefono,
        } : undefined;
        abrirPedido(mesaSeleccionadaId, cliente);
        setDialogCliente(false);
        setClienteInfo({});
    };

    // ─── Agregar item (SOLO en Store — sin BD) ───
    const handleAgregarItem = (item: Parameters<typeof agregarItemAPedido>[1]) => {
        if (!mesaSeleccionadaId) return;
        agregarItemAPedido(mesaSeleccionadaId, item);
    };

    // ─── ENVIAR COMANDA → Persiste items a BD + Imprime ESC/POS ───
    const handleEnviarComanda = async () => {
        if (!mesaSeleccionadaId) return;
        const result = await enviarComanda(mesaSeleccionadaId);
        showMsg(result.message, result.success ? 'success' : 'error');
    };

    // ─── GENERAR CUENTA FISCAL → Imprime factura fiscal ───
    const handleImprimirCuenta = async () => {
        if (!mesaSeleccionadaId) return;
        const result = await imprimirCuentaFiscal(mesaSeleccionadaId);
        showMsg(
            result.success ? 'Cuenta fiscal generada exitosamente.' : `Error Fiscal: ${result.message}`,
            result.success ? 'success' : 'error',
        );
    };

    // ─── CERRAR MESA → Persiste cierre a BD + Limpia Store ───
    const handleCerrarMesa = async () => {
        if (!mesaSeleccionadaId) return;
        const result = await cerrarMesa(mesaSeleccionadaId);
        if (result.success) {
            setMesaSeleccionadaId(null);
        }
        showMsg(result.message, result.success ? 'success' : 'error');
    };

    const handleCrearMesa = (_ambienteId: string, _mesa: any) => {
        window.location.reload();
    };

    if (loading) {
        return (
            <Box sx={{ p: 4, textAlign: 'center' }}>
                <Typography variant="h5" sx={{ mb: 2 }}>🍽️ Cargando Salón...</Typography>
                <LinearProgress />
            </Box>
        );
    }

    return (
        <Box sx={{ display: 'flex', flexDirection: 'column', height: 'calc(100vh - 100px)', p: { xs: 1, md: 2 } }}>
            {/* Barra de sincronización */}
            {syncing && <LinearProgress sx={{ position: 'fixed', top: 0, left: 0, right: 0, zIndex: 9999 }} />}

            {/* Header */}
            <Box sx={{ flexShrink: 0, display: { xs: mesaSeleccionada ? 'none' : 'flex', md: 'flex' }, flexDirection: { xs: 'column', md: 'row' }, justifyContent: 'space-between', alignItems: { xs: 'flex-start', md: 'center' }, mb: 2, gap: { xs: 1, md: 0 } }}>
                <Typography variant="h4" fontWeight="bold" sx={{ fontSize: { xs: '1.5rem', md: '2.125rem' }, display: 'flex', alignItems: 'center' }}>
                    🍽️ Gestión de Salón
                    <IconButton sx={{ ml: 1 }} size="small" onClick={() => setSettingsOpen(true)}>
                        <SettingsIcon fontSize="small" />
                    </IconButton>
                </Typography>
                {(!mesaSeleccionada) && (
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, width: { xs: '100%', md: 'auto' }, justifyContent: { xs: 'space-between', md: 'flex-end' } }}>
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
                )}
            </Box>

            {mesaSeleccionada && (mesaSeleccionada.estado === 'ocupada' || mesaSeleccionada.estado === 'cuenta') ? (
                /* Panel de pedido activo */
                <Box sx={{ flexGrow: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
                    <Box sx={{ flexShrink: 0, display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2, gap: 1 }}>
                        <Typography variant="h6" sx={{ fontSize: { xs: '1.1rem', md: '1.25rem' } }}>
                            Pedido en {mesaSeleccionada.nombre}
                            {syncing && ' ⏳'}
                        </Typography>
                        <Box sx={{ display: 'flex', gap: 1 }}>
                            {mesaSeleccionada.estado === 'cuenta' && (
                                <Button
                                    variant="contained"
                                    color="error"
                                    size="small"
                                    onClick={handleCerrarMesa}
                                    disabled={syncing}
                                >
                                    Cerrar Mesa
                                </Button>
                            )}
                            <Button variant="outlined" size="small" onClick={() => setMesaSeleccionadaId(null)}>
                                Volver
                            </Button>
                        </Box>
                    </Box>
                    <PanelPedido
                        mesa={mesaSeleccionada}
                        productos={productos}
                        onAgregarItem={handleAgregarItem}
                        onQuitarItem={quitarItem}
                        onEditarItem={editarItem}
                        onEnviarComanda={handleEnviarComanda}
                        onImprimirCuenta={handleImprimirCuenta}
                        onCerrarMesa={handleCerrarMesa}
                        onCerrar={() => setMesaSeleccionadaId(null)}
                        syncing={syncing}
                    />
                </Box>
            ) : (
                /* Mapa de mesas */
                <Box sx={{ flexGrow: 1, position: 'relative', minHeight: 0 }}>
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

            {/* Snackbar de feedback */}
            <Snackbar
                open={snackbar.open}
                autoHideDuration={4000}
                onClose={() => setSnackbar(s => ({ ...s, open: false }))}
                anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
            >
                <Alert severity={snackbar.severity} variant="filled" onClose={() => setSnackbar(s => ({ ...s, open: false }))}>
                    {snackbar.message}
                </Alert>
            </Snackbar>

            {/* Modal de Configuración Fiscal & Multimoneda (Compartido con POS) */}
            <LocalizacionModal
                open={settingsOpen}
                onClose={() => setSettingsOpen(false)}
                currentConfig={localizacion}
                onSave={(newLoc) => setLocalizacion(newLoc)}
            />

        </Box>
    );
}
