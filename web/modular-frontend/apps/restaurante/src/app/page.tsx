'use client';

import React, { useState, useEffect, useRef } from 'react';
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
    Tabs,
    Tab,
    CircularProgress,
} from '@mui/material';
import EditIcon from '@mui/icons-material/Edit';
import SettingsIcon from '@mui/icons-material/Settings';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import FingerprintIcon from '@mui/icons-material/Fingerprint';
import CloseIcon from '@mui/icons-material/Close';
import CheckCircleOutlineIcon from '@mui/icons-material/CheckCircleOutline';
import IconButton from '@mui/material/IconButton';
import { MapaMesas } from '@/components/MapaMesas';
import { RestauranteSettingsModal } from '@/components/RestauranteSettingsModal';
import { PanelPedido } from '@/components/PanelPedido';
import { useRestaurante, Mesa, ClienteMesa } from '@/hooks/useRestaurante';
import {
    authenticateSupervisorBiometricCredential,
    enrollSupervisorBiometricCredential,
    isWebAuthnSupported,
} from '@datqbox/shared-api';

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
        anularItemEnviado,
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

    // Configuración completa del módulo Restaurante
    const [settingsOpen, setSettingsOpen] = useState(false);
    const [voidDialogOpen, setVoidDialogOpen] = useState(false);
    const [voidTargetItemId, setVoidTargetItemId] = useState<string | null>(null);
    const [voidAuth, setVoidAuth] = useState({
        motivo: 'Cliente no desea el producto',
        supervisorUser: '',
        supervisorPassword: '',
        biometricCredentialId: '',
    });
    const [voidAuthMode, setVoidAuthMode] = useState<'password' | 'biometric'>('biometric');
    const [biometricBusy, setBiometricBusy] = useState(false);
    const biometricAutoStartedRef = useRef(false);

    // La mesa seleccionada SIEMPRE se lee del store (fuente de verdad)
    const mesaSeleccionada = mesaSeleccionadaId ? getMesaById(mesaSeleccionadaId) ?? null : null;

    // Sincronizar estado: si la mesa pasa a libre, deseleccionar
    useEffect(() => {
        if (mesaSeleccionada && mesaSeleccionada.estado === 'libre' && !dialogCliente) {
            setMesaSeleccionadaId(null);
        }
    }, [mesaSeleccionada, dialogCliente]);

    useEffect(() => {
        if (!mesaSeleccionadaId) return;

        const handleEscToBack = (event: KeyboardEvent) => {
            if (event.key !== 'Escape') return;
            const target = event.target as HTMLElement | null;
            const tagName = target?.tagName?.toLowerCase();
            const isTypingContext = tagName === 'input' || tagName === 'textarea' || tagName === 'select' || target?.isContentEditable;
            if (isTypingContext) return;
            event.preventDefault();
            setMesaSeleccionadaId(null);
        };

        window.addEventListener('keydown', handleEscToBack);
        return () => window.removeEventListener('keydown', handleEscToBack);
    }, [mesaSeleccionadaId]);

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

    const handleSolicitarAnulacionItemEnviado = async (_mesaId: string, itemId: string) => {
        const mesaActual = mesaSeleccionadaId ? getMesaById(mesaSeleccionadaId) : null;
        const itemActual = mesaActual?.pedidoActual?.items.find((it) => it.id === itemId);
        if (!itemActual) {
            showMsg('El item ya no existe en el pedido actual.', 'warning');
            return;
        }
        const estadoItem = String(itemActual.estado ?? '').trim().toLowerCase();
        const yaAnulado = estadoItem === 'anulado' || estadoItem === 'voided' || estadoItem === 'cancelado';
        if (yaAnulado || itemActual.cantidad <= 0) {
            showMsg('Este item ya fue anulado.', 'warning');
            return;
        }
        if (!itemActual.enviadoACocina) {
            showMsg('Este item no fue enviado a cocina; se elimina directo sin supervisión.', 'warning');
            return;
        }

        setVoidTargetItemId(itemId);
        setVoidAuthMode('biometric');
        setVoidAuth((prev) => ({ ...prev, supervisorPassword: '', biometricCredentialId: '' }));
        setVoidDialogOpen(true);
    };

    const handleEnrollBiometric = async () => {
        const supervisorUser = String(voidAuth.supervisorUser ?? '').trim().toUpperCase();
        const supervisorPassword = String(voidAuth.supervisorPassword ?? '');
        if (!supervisorUser || !supervisorPassword) {
            showMsg('Para registrar huella debe indicar usuario y clave del supervisor.', 'warning');
            return;
        }

        setBiometricBusy(true);
        try {
            await enrollSupervisorBiometricCredential({
                supervisorUser,
                supervisorPassword,
                credentialLabel: `Restaurante ${window.location.hostname}`,
            });
            showMsg(`Huella registrada para ${supervisorUser}.`, 'success');
        } catch (error) {
            showMsg(error instanceof Error ? error.message : 'No se pudo registrar huella.', 'error');
        } finally {
            setBiometricBusy(false);
        }
    };

    const handleReadBiometric = async () => {
        if (!mesaSeleccionadaId || !voidTargetItemId) {
            showMsg('No hay item seleccionado para anular.', 'warning');
            return;
        }
        const reason = String(voidAuth.motivo ?? '').trim();
        if (!reason) {
            showMsg('Indique el motivo de anulacion.', 'warning');
            return;
        }
        if (!isWebAuthnSupported()) {
            showMsg('Este equipo no soporta WebAuthn/huella.', 'error');
            return;
        }

        setBiometricBusy(true);
        try {
            const result = await authenticateSupervisorBiometricCredential();
            setVoidAuth((prev) => ({
                ...prev,
                supervisorUser: result.supervisorUser,
                biometricCredentialId: result.credentialId,
            }));
            const authResult = await anularItemEnviado(mesaSeleccionadaId, voidTargetItemId, {
                ...voidAuth,
                supervisorUser: result.supervisorUser,
                supervisorPassword: '',
                biometricBypass: true,
                biometricCredentialId: result.credentialId,
                motivo: reason,
            });
            showMsg(authResult.message, authResult.success ? 'success' : 'error');
            if (authResult.success) {
                resetVoidDialog();
            }
        } catch (error) {
            showMsg(error instanceof Error ? error.message : 'No se pudo validar huella.', 'error');
        } finally {
            setBiometricBusy(false);
        }
    };

    const resetVoidDialog = () => {
        biometricAutoStartedRef.current = false;
        setVoidDialogOpen(false);
        setVoidTargetItemId(null);
        setVoidAuthMode('biometric');
        setVoidAuth({
            motivo: 'Cliente no desea el producto',
            supervisorUser: '',
            supervisorPassword: '',
            biometricCredentialId: '',
        });
    };

    const handleConfirmarAnulacionItemEnviado = async () => {
        if (!mesaSeleccionadaId || !voidTargetItemId) return;
        const result = await anularItemEnviado(mesaSeleccionadaId, voidTargetItemId, {
            ...voidAuth,
            biometricBypass: voidAuthMode === 'biometric',
        });
        showMsg(result.message, result.success ? 'success' : 'error');
        if (result.success) {
            resetVoidDialog();
        }
    };

    useEffect(() => {
        if (!voidDialogOpen || voidAuthMode !== 'biometric') {
            biometricAutoStartedRef.current = false;
            return;
        }
        if (biometricAutoStartedRef.current) return;
        if (biometricBusy || syncing) return;
        if (!String(voidAuth.motivo ?? '').trim()) return;
        if (!isWebAuthnSupported()) return;

        biometricAutoStartedRef.current = true;
        void handleReadBiometric();
    }, [voidDialogOpen, voidAuthMode, biometricBusy, syncing, voidAuth.motivo]);

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

    const handleCrearMesa = (_ambienteId: string, _mesa: unknown) => {
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
        <Box sx={{ display: 'flex', flexDirection: 'column', height: 'calc(100vh - 100px)', p: { xs: 1, md: 1 } }}>
            {/* Barra de sincronización */}
            {syncing && <LinearProgress sx={{ position: 'fixed', top: 0, left: 0, right: 0, zIndex: 9999 }} />}

            {/* Header */}
            <Box sx={{ flexShrink: 0, display: mesaSeleccionada ? 'none' : 'flex', flexDirection: { xs: 'column', md: 'row' }, justifyContent: 'space-between', alignItems: { xs: 'flex-start', md: 'center' }, mb: 1, gap: { xs: 1, md: 0 } }}>
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
                <Box sx={{ flexGrow: 1, display: 'flex', flexDirection: 'column', minHeight: 0, position: 'relative' }}>
                    <Box sx={{ position: 'absolute', top: 0, right: 0, zIndex: 3 }}>
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
                            <Button
                                variant="outlined"
                                size="small"
                                startIcon={<ArrowBackIcon />}
                                onClick={() => setMesaSeleccionadaId(null)}
                            >
                                Volver al salón (Esc)
                            </Button>
                        </Box>
                    </Box>
                    <PanelPedido
                        mesa={mesaSeleccionada}
                        productos={productos}
                        onAgregarItem={handleAgregarItem}
                        onQuitarItem={quitarItem}
                        onAnularItemEnviado={handleSolicitarAnulacionItemEnviado}
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

            {/* Modal de Configuración Completa Restaurante */}
            <RestauranteSettingsModal
                open={settingsOpen}
                onClose={() => setSettingsOpen(false)}
            />
            <Dialog
                open={voidDialogOpen}
                onClose={resetVoidDialog}
                maxWidth="sm"
                fullWidth
                PaperProps={{ sx: { borderRadius: 3 } }}
            >
                <DialogTitle sx={{ pb: 1, pt: 2.5, fontWeight: 600, fontSize: 20 }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                        <span>Anulacion Supervisada</span>
                        <IconButton onClick={resetVoidDialog} size="small" sx={{ color: 'text.secondary' }}>
                            <CloseIcon />
                        </IconButton>
                    </Box>
                </DialogTitle>
                <DialogContent sx={{ pt: 1 }}>
                    <TextField
                        fullWidth
                        sx={{ mt: 1, mb: 2 }}
                        label="Motivo de anulacion"
                        value={voidAuth.motivo}
                        onChange={(e) => setVoidAuth((prev) => ({ ...prev, motivo: e.target.value }))}
                        InputLabelProps={{ shrink: true }}
                        InputProps={{ sx: { borderRadius: 1.5 } }}
                    />
                    <Box sx={{ mb: 2, pb: 1, borderBottom: '1px solid', borderColor: 'divider' }}>
                        <Typography variant="h6" sx={{ color: 'text.secondary', fontWeight: 500 }}>
                            Supervisor Detectado automaticamente
                        </Typography>
                        {voidAuth.supervisorUser ? (
                            <Typography variant="h5" sx={{ mt: 0.5, fontWeight: 400 }}>
                                {voidAuth.supervisorUser}
                            </Typography>
                        ) : null}
                    </Box>
                    <Tabs
                        value={voidAuthMode}
                        onChange={(_e, value) => {
                            const next = value as 'password' | 'biometric';
                            biometricAutoStartedRef.current = false;
                            setVoidAuthMode(next);
                            setVoidAuth((prev) => ({
                                ...prev,
                                supervisorPassword: next === 'password' ? prev.supervisorPassword : '',
                                biometricCredentialId: next === 'biometric' ? prev.biometricCredentialId : '',
                            }));
                        }}
                        variant="fullWidth"
                        sx={{
                            mb: 2,
                            p: 0.5,
                            borderRadius: 999,
                            bgcolor: 'action.hover',
                            minHeight: 46,
                            '& .MuiTabs-indicator': { display: 'none' },
                        }}
                    >
                        <Tab
                            value="biometric"
                            label="Huella"
                            sx={{
                                minHeight: 40,
                                borderRadius: 999,
                                textTransform: 'none',
                                fontSize: '1rem',
                                fontWeight: 350,
                                '&.Mui-selected': { bgcolor: 'primary.main', color: 'primary.contrastText' },
                            }}
                        />
                        <Tab
                            value="password"
                            label="Clave"
                            sx={{
                                minHeight: 40,
                                borderRadius: 999,
                                textTransform: 'none',
                                fontSize: '1rem',
                                fontWeight: 350,
                                '&.Mui-selected': { bgcolor: 'primary.main', color: 'primary.contrastText' },
                            }}
                        />
                    </Tabs>

                    {voidAuthMode === 'password' ? (
                        <Box sx={{ p: 2, borderRadius: 2.5, bgcolor: 'action.hover' }}>
                            <TextField
                                fullWidth
                                label="Codigo supervisor (alternativo)"
                                value={voidAuth.supervisorUser}
                                onChange={(e) => setVoidAuth((prev) => ({ ...prev, supervisorUser: e.target.value.toUpperCase() }))}
                                InputLabelProps={{ shrink: true }}
                                InputProps={{ sx: { borderRadius: 1.5 } }}
                                sx={{ mb: 1.5 }}
                            />
                            <TextField
                                fullWidth
                                type="password"
                                label="Clave supervisor"
                                value={voidAuth.supervisorPassword}
                                onChange={(e) => setVoidAuth((prev) => ({ ...prev, supervisorPassword: e.target.value }))}
                                InputLabelProps={{ shrink: true }}
                                InputProps={{ sx: { borderRadius: 1.5 } }}
                            />
                            <Box sx={{ mt: 2, textAlign: 'center' }}>
                                <IconButton
                                    onClick={handleEnrollBiometric}
                                    disabled={biometricBusy || syncing}
                                    sx={{
                                        width: 76,
                                        height: 76,
                                        borderRadius: '50%',
                                        color: 'common.white',
                                        background: 'linear-gradient(135deg, #4f8fe8, #2f6dd3)',
                                        boxShadow: '0 8px 20px rgba(47,109,211,0.30)',
                                        '&:hover': { background: 'linear-gradient(135deg, #3f7ed8, #245cc0)' },
                                    }}
                                >
                                    {biometricBusy ? <CircularProgress size={28} color="inherit" /> : <FingerprintIcon sx={{ fontSize: 38 }} />}
                                </IconButton>
                                <Typography variant="body1" sx={{ mt: 1, fontWeight: 600 }}>
                                    {biometricBusy ? 'Registrando huella...' : 'Registrar huella en este equipo'}
                                </Typography>
                            </Box>
                        </Box>
                    ) : (
                        <Box sx={{ p: 2.5, borderRadius: 2.5, bgcolor: 'action.hover' }}>
                            {!isWebAuthnSupported() && (
                                <Alert severity="warning" sx={{ mb: 1.5 }}>
                                    Este equipo/navegador no soporta validacion biometrica WebAuthn.
                                </Alert>
                            )}
                            <Box sx={{ textAlign: 'center', mb: 2 }}>
                                <IconButton
                                    disableRipple
                                    disableFocusRipple
                                    disabled
                                    sx={{
                                        width: 132,
                                        height: 132,
                                        borderRadius: '50%',
                                        color: 'common.white',
                                        background: 'linear-gradient(135deg, #4f8fe8, #2f6dd3)',
                                        boxShadow: '0 10px 24px rgba(47,109,211,0.35)',
                                        '&:hover': { background: 'linear-gradient(135deg, #3f7ed8, #245cc0)' },
                                    }}
                                >
                                    {biometricBusy ? <CircularProgress size={42} color="inherit" /> : <FingerprintIcon sx={{ fontSize: 64 }} />}
                                </IconButton>
                                <Typography variant="h4" sx={{ mt: 1.5, fontWeight: 400 }}>
                                    {biometricBusy ? 'Esperando huella' : 'Listo para huella'}
                                </Typography>
                                <Typography variant="h5" color="text.secondary">
                                    {biometricBusy ? 'presione el lector para autorizar' : 'se activa automaticamente al entrar'}
                                </Typography>
                            </Box>
                        </Box>
                    )}
                </DialogContent>
                <DialogActions>
                    <Button onClick={resetVoidDialog} sx={{ textTransform: 'none', fontSize: '1rem' }}>Cancelar</Button>
                    {voidAuthMode === 'password' && (
                        <Button
                            variant="contained"
                            color="error"
                            startIcon={<CheckCircleOutlineIcon />}
                            onClick={handleConfirmarAnulacionItemEnviado}
                            sx={{ textTransform: 'none' }}
                            disabled={
                                syncing
                                || !voidAuth.supervisorUser.trim()
                                || !voidAuth.motivo.trim()
                                || !voidAuth.supervisorPassword.trim()
                            }
                        >
                            Autorizar anulacion
                        </Button>
                    )}
                </DialogActions>
            </Dialog>
</Box>
    );
}


