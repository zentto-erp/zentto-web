'use client';

import React, { useState, useMemo, useCallback, useEffect, useRef } from 'react';
import {
    Box,
    Paper,
    Typography,
    Chip,
    IconButton,
    Tooltip,
    useTheme,
    useMediaQuery,
    Button,
    Badge,
    Snackbar,
    Alert,
    LinearProgress,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    TextField,
    Tabs,
    Tab,
    CircularProgress,
} from '@mui/material';
import dynamic from 'next/dynamic';
import {
    PosCart,
    PosNumpad,
    PosPaymentButton,
    PosProductGrid,
    PosHeader,
    PosPaymentModal,
    PosCustomerSearch,
    PosEsperaDrawer,
    type Customer,
} from '@/components';
import { useBuscarProductos, useCategoriasPOS, useBarcodeScanner } from '@/hooks';
import {
    authenticateSupervisorBiometricCredential,
    enrollSupervisorBiometricCredential,
    isWebAuthnSupported,
    usePosStore,
} from '@zentto/shared-api';

// Iconos dinámicos
const PersonIcon = dynamic(() => import('@mui/icons-material/Person'), { ssr: false });
const DeleteSweepIcon = dynamic(() => import('@mui/icons-material/DeleteSweep'), { ssr: false });
const PauseCircleIcon = dynamic(() => import('@mui/icons-material/PauseCircle'), { ssr: false });
const AccessTimeIcon = dynamic(() => import('@mui/icons-material/AccessTime'), { ssr: false });
const FingerprintIcon = dynamic(() => import('@mui/icons-material/Fingerprint'), { ssr: false });
const CloseIcon = dynamic(() => import('@mui/icons-material/Close'), { ssr: false });
const CheckCircleOutlineIcon = dynamic(() => import('@mui/icons-material/CheckCircleOutline'), { ssr: false });

const MAX_CATEGORY_TABS = 24;

type PrecioCliente = 'Detal' | 'Mayor' | 'Distribuidor';

function normalizeTipoPrecio(value?: string): PrecioCliente {
    if (value === 'Mayor' || value === 'Distribuidor' || value === 'Detal') {
        return value;
    }
    return 'Detal';
}

export default function PosFacturacionPage() {
    // ─── State local (UI only) ───
    const [searchTerm, setSearchTerm] = useState('');
    const [selectedCategory, setSelectedCategory] = useState<string | null>(null);
    const [selectedItemId, setSelectedItemId] = useState<string | null>(null);
    const [numpadValue, setNumpadValue] = useState('');
    const [numpadMode, setNumpadMode] = useState<'qty' | 'discount' | 'price'>('qty');
    const [numpadReplaceNext, setNumpadReplaceNext] = useState(true);
    const [showMobileMenu, setShowMobileMenu] = useState(false);
    const [esperaDrawerOpen, setEsperaDrawerOpen] = useState(false);
    const [esperaMotiveDialog, setEsperaMotiveDialog] = useState(false);
    const [esperaMotive, setEsperaMotive] = useState('');
    const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' | 'warning' }>({
        open: false, message: '', severity: 'success',
    });
    const [customerModalOpen, setCustomerModalOpen] = useState(false);
    const [voidDialogOpen, setVoidDialogOpen] = useState(false);
    const [voidTargetItemId, setVoidTargetItemId] = useState<string | null>(null);
    const [voidAuthMode, setVoidAuthMode] = useState<'password' | 'biometric'>('biometric');
    const [biometricBusy, setBiometricBusy] = useState(false);
    const biometricAutoStartedRef = useRef(false);
    const [voidAuth, setVoidAuth] = useState({
        motivo: 'Cliente no desea el producto',
        supervisorUser: '',
        supervisorPassword: '',
        biometricCredentialId: '',
    });

    // ─── Zustand Store (source of truth) ───
    const cart = usePosStore(s => s.cart);
    const cliente = usePosStore(s => s.cliente);
    const caja = usePosStore(s => s.caja);
    const syncing = usePosStore(s => s.syncing);
    const ventasEnEspera = usePosStore(s => s.ventasEnEspera);
    const esperaOrigenId = usePosStore(s => s.esperaOrigenId);
    const addToCart = usePosStore(s => s.addToCart);
    const updateCartItem = usePosStore(s => s.updateCartItem);
    const voidCartItemWithSupervisor = usePosStore(s => s.voidCartItemWithSupervisor);
    const clearCart = usePosStore(s => s.clearCart);
    const setCliente = usePosStore(s => s.setCliente);
    const resetCliente = usePosStore(s => s.resetCliente);
    const getSubtotal = usePosStore(s => s.getSubtotal);
    const getImpuestos = usePosStore(s => s.getImpuestos);
    const getTotal = usePosStore(s => s.getTotal);
    const ponerEnEspera = usePosStore(s => s.ponerEnEspera);
    const facturar = usePosStore(s => s.facturar);
    const listarEspera = usePosStore(s => s.listarEspera);
    const paymentModalOpen = usePosStore(s => s.paymentModalOpen);
    const setPaymentModal = usePosStore(s => s.setPaymentModal);

    const subtotal = getSubtotal();
    const impuestos = getImpuestos();
    const totalConImpuesto = getTotal();

    // ─── Theme & Responsive ───
    const theme = useTheme();
    const isMobileLandscape = useMediaQuery('(max-height: 500px) and (orientation: landscape)');
    const isMobilePortrait = useMediaQuery(theme.breakpoints.down('md'));
    const isMobileLayout = isMobilePortrait || isMobileLandscape;

    // ─── API Data ───
    const { data: productos = [] } = useBuscarProductos(searchTerm);
    const { data: categoriasApi = [] } = useCategoriasPOS();

    const categories = useMemo(() => {
        const fromApi: Array<{ id: string; nombre: string; productCount: number }> = (categoriasApi ?? [])
            .map((category: unknown) => {
                const item = category as { nombre?: string; productCount?: number };
                return {
                    id: String(item.nombre ?? '').trim(),
                    nombre: String(item.nombre ?? '').trim(),
                    productCount: Number(item.productCount ?? 0),
                };
            })
            .filter((category: { id: string }) => category.id.length > 0);

        const dedup = new Map<string, { id: string; nombre: string; productCount: number }>();
        for (const category of fromApi) {
            const key = category.nombre.toLowerCase();
            const existing = dedup.get(key);
            if (!existing || category.productCount > existing.productCount) {
                dedup.set(key, category);
            }
        }

        const apiSorted = Array.from(dedup.values())
            .sort((a, b) => b.productCount - a.productCount || a.nombre.localeCompare(b.nombre))
            .slice(0, MAX_CATEGORY_TABS)
            .map(({ id, nombre }) => ({ id, nombre }));

        if (apiSorted.length > 0) {
            return apiSorted;
        }

        const fallbackFromProducts = Array.from(
            new Set(
                productos
                    .map((product) => String(product.categoria ?? '').trim())
                    .filter((name) => name.length > 0)
            )
        )
            .slice(0, MAX_CATEGORY_TABS)
            .map((name) => ({ id: name, nombre: name }));

        return fallbackFromProducts;
    }, [categoriasApi, productos]);

    React.useEffect(() => {
        if (!selectedCategory) return;
        const exists = categories.some((category) => category.id === selectedCategory);
        if (!exists) {
            setSelectedCategory(null);
        }
    }, [categories, selectedCategory]);

    // ─── Barcode Scanner ───
    useBarcodeScanner((barcode) => {
        const prod = productos.find(p => p.codigo.toLowerCase() === barcode.toLowerCase() || p.id === barcode);
        if (prod) {
            handleAddProduct({
                id: prod.id,
                codigo: prod.codigo,
                nombre: prod.nombre,
                precio: prod.precioDetal,
                iva: prod.iva,
            });
        }
    });

    // Refrescar lista de espera al montar
    React.useEffect(() => { listarEspera(); }, []); // eslint-disable-line

    const showMsg = useCallback((message: string, severity: 'success' | 'error' | 'warning' = 'success') => {
        setSnackbar({ open: true, message, severity });
    }, []);

    // ─── Filtrar productos ───
    const filteredProducts = useMemo(() => {
        return productos.filter(p => !selectedCategory || p.categoria === selectedCategory);
    }, [productos, selectedCategory]);

    const selectedCartItem = useMemo(
        () => cart.find((item) => item.id === selectedItemId) ?? null,
        [cart, selectedItemId]
    );

    const getNumpadValueFromItem = useCallback((mode: 'qty' | 'discount' | 'price', itemId: string | null) => {
        if (!itemId) return '';
        const item = cart.find((cartItem) => cartItem.id === itemId);
        if (!item) return '';

        switch (mode) {
            case 'qty': return String(item.cantidad ?? '');
            case 'price': return String(item.precio ?? '');
            case 'discount': return String(item.descuento ?? 0);
            default: return '';
        }
    }, [cart]);

    const applyNumpadValueToSelectedItem = useCallback((rawValue: string) => {
        if (!selectedItemId || !rawValue || rawValue === '-' || rawValue === '+') return;

        const parsed = parseFloat(rawValue);
        if (Number.isNaN(parsed)) return;

        if (numpadMode === 'qty') {
            if (parsed > 0) updateCartItem(selectedItemId, { cantidad: parsed });
            return;
        }

        if (numpadMode === 'price') {
            if (parsed >= 0) updateCartItem(selectedItemId, { precio: parsed });
            return;
        }

        if (numpadMode === 'discount') {
            const normalized = Math.max(0, Math.min(parsed, 100));
            updateCartItem(selectedItemId, { descuento: normalized });
        }
    }, [numpadMode, selectedItemId, updateCartItem]);

    // ═══════════════════════════════════════════════════════════
    // AGREGAR PRODUCTO — Solo Store (sin BD)
    // ═══════════════════════════════════════════════════════════
    const handleAddProduct = (product: { id: string; codigo?: string; nombre: string; precio: number; iva?: number }) => {
        addToCart({
            productoId: product.id,
            codigo: product.codigo || product.id,
            nombre: product.nombre,
            cantidad: 1,
            precio: product.precio,
            descuento: 0,
            iva: product.iva || 16,
        });
        setShowMobileMenu(false);
    };

    // ─── Teclado numérico ───
    const handleNumberPress = (num: string) => {
        if (!selectedItemId) return;

        if (num === '+/-') {
            const toggled = numpadValue.startsWith('-') ? numpadValue.slice(1) : `-${numpadValue || '0'}`;
            setNumpadValue(toggled);
            setNumpadReplaceNext(false);
            applyNumpadValueToSelectedItem(toggled);
            return;
        }

        if (num === '.' && numpadValue.includes('.') && !numpadReplaceNext) return;

        const base = numpadReplaceNext ? '' : numpadValue;
        const newValue = `${base}${num}`;
        setNumpadValue(newValue);
        setNumpadReplaceNext(false);
        applyNumpadValueToSelectedItem(newValue);
    };

    const handleBackspace = () => {
        if (!selectedItemId) return;
        const newValue = numpadValue.slice(0, -1);
        setNumpadValue(newValue);
        setNumpadReplaceNext(false);
        applyNumpadValueToSelectedItem(newValue);
    };

    const handleClear = () => {
        setNumpadValue('');
        setNumpadReplaceNext(true);
    };

    const handleSelectItem = (itemId: string) => {
        setSelectedItemId(itemId);
        setNumpadValue(getNumpadValueFromItem(numpadMode, itemId));
        setNumpadReplaceNext(true);
    };

    const handleModeChange = (mode: 'qty' | 'discount' | 'price') => {
        setNumpadMode(mode);
        setNumpadValue(getNumpadValueFromItem(mode, selectedItemId));
        setNumpadReplaceNext(true);
    };

    // ═══════════════════════════════════════════════════════════
    // FACTURAR — Imprimir fiscal + Guardar en BD + Limpiar
    // ═══════════════════════════════════════════════════════════
    const handlePaymentComplete = async (payments: Array<{ metodo: string; monto: number; referencia?: string }>) => {
        const metodoPago = payments.map(p => p.metodo).join(', ');
        const result = await facturar(metodoPago);
        showMsg(result.message, result.success ? 'success' : 'error');
    };

    // ═══════════════════════════════════════════════════════════
    // PONER EN ESPERA — Guardar carrito en BD + Limpiar local
    // ═══════════════════════════════════════════════════════════
    const handlePonerEnEspera = async () => {
        const result = await ponerEnEspera(esperaMotive || undefined);
        setEsperaMotiveDialog(false);
        setEsperaMotive('');
        showMsg(result.message, result.success ? 'success' : 'error');
    };

    // ─── Cambiar cliente ───
    const handleCustomerChange = (newCustomer: Customer) => {
        setCliente({
            id: newCustomer.id,
            codigo: newCustomer.codigo,
            nombre: newCustomer.nombre,
            rif: newCustomer.rif,
            telefono: newCustomer.telefono,
            email: newCustomer.email,
            direccion: newCustomer.direccion,
            tipoPrecio: normalizeTipoPrecio(newCustomer.tipoPrecio),
            credito: newCustomer.credito || 0,
        });
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

    const handleRequestSupervisorVoid = (itemId: string) => {
        const target = cart.find((item) => item.id === itemId);
        if (!target) {
            showMsg('Item no encontrado en el carrito.', 'warning');
            return;
        }
        if (target.esAnulacion) {
            showMsg('La linea ya es una anulacion y no puede eliminarse.', 'warning');
            return;
        }
        if (target.bloqueadoPorAnulacion) {
            showMsg('La linea ya fue anulada previamente.', 'warning');
            return;
        }
        setVoidTargetItemId(itemId);
        setVoidDialogOpen(true);
    };

    const handleEnrollBiometric = async () => {
        const supervisorUser = String(voidAuth.supervisorUser ?? '').trim().toUpperCase();
        const supervisorPassword = String(voidAuth.supervisorPassword ?? '');
        if (!supervisorUser || !supervisorPassword) {
            showMsg('Para registrar huella indique usuario y clave del supervisor.', 'warning');
            return;
        }

        setBiometricBusy(true);
        try {
            await enrollSupervisorBiometricCredential({
                supervisorUser,
                supervisorPassword,
                credentialLabel: `POS ${window.location.hostname}`,
            });
            showMsg(`Huella registrada para ${supervisorUser}.`, 'success');
        } catch (error) {
            showMsg(error instanceof Error ? error.message : 'No se pudo registrar huella.', 'error');
        } finally {
            setBiometricBusy(false);
        }
    };

    const handleReadBiometric = async () => {
        if (!voidTargetItemId) {
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
            const authResult = await voidCartItemWithSupervisor(voidTargetItemId, {
                supervisorUser: result.supervisorUser,
                supervisorPassword: '',
                biometricBypass: true,
                biometricCredentialId: result.credentialId,
                reason,
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

    const handleConfirmSupervisorVoid = async () => {
        if (!voidTargetItemId) return;
        const result = await voidCartItemWithSupervisor(voidTargetItemId, {
            supervisorUser: voidAuth.supervisorUser,
            supervisorPassword: voidAuthMode === 'password' ? voidAuth.supervisorPassword : '',
            biometricBypass: voidAuthMode === 'biometric',
            biometricCredentialId: voidAuthMode === 'biometric' ? voidAuth.biometricCredentialId : '',
            reason: voidAuth.motivo,
        });
        showMsg(result.message, result.success ? 'success' : 'error');
        if (result.success) {
            resetVoidDialog();
        }
    };

    return (
        <Box sx={{
            height: 'calc(100vh - 64px)',
            display: 'flex',
            flexDirection: isMobileLayout ? 'column' : 'row',
            overflow: 'hidden',
            bgcolor: 'background.default',
            pb: isMobileLayout ? 8 : 0,
        }}>
            {/* Syncing bar */}
            {syncing && <LinearProgress sx={{ position: 'fixed', top: 0, left: 0, right: 0, zIndex: 9999 }} />}

            {/* Panel Izquierdo - Carrito y Controles */}
            <Box sx={{
                width: isMobileLayout ? '100%' : 470,
                minWidth: isMobileLayout ? 0 : 430,
                display: isMobileLayout ? (showMobileMenu ? 'none' : 'flex') : 'flex',
                flexDirection: 'column',
                borderRight: isMobileLayout ? 'none' : '1px solid #e0e0e0',
                borderColor: 'divider',
                bgcolor: 'background.paper',
                height: '100%',
            }}>
                {/* Header del Carrito con Cliente */}
                <Paper sx={{ p: 1, borderRadius: 0, borderBottom: '1px solid', borderColor: 'divider' }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <PersonIcon color="action" />
                            <Box>
                                <Typography variant="body2" color="text.secondary">
                                    Cliente
                                </Typography>
                                <Typography variant="body1" fontWeight="medium">
                                    {cliente.nombre}
                                </Typography>
                                <Typography variant="caption" color="text.secondary">
                                    {cliente.rif}
                                </Typography>
                            </Box>
                        </Box>
                        <Box sx={{ display: 'flex', gap: 0.5 }}>
                            <Tooltip title="Cambiar Cliente">
                                <IconButton size="small" onClick={() => setCustomerModalOpen(true)} color="primary">
                                    <PersonIcon />
                                </IconButton>
                            </Tooltip>
                            {/* Botón Espera */}
                            <Tooltip title={`Ventas en Espera (${ventasEnEspera.length})`}>
                                <IconButton size="small" onClick={() => setEsperaDrawerOpen(true)} color="warning">
                                    <Badge badgeContent={ventasEnEspera.length} color="error">
                                        <AccessTimeIcon />
                                    </Badge>
                                </IconButton>
                            </Tooltip>
                            {cart.length > 0 && (
                                <>
                                    <Tooltip title="Poner en Espera">
                                        <IconButton size="small" onClick={() => setEsperaMotiveDialog(true)} color="warning">
                                            <PauseCircleIcon />
                                        </IconButton>
                                    </Tooltip>
                                    <Tooltip title="Limpiar Carrito">
                                        <IconButton size="small" onClick={clearCart} color="error">
                                            <DeleteSweepIcon />
                                        </IconButton>
                                    </Tooltip>
                                </>
                            )}
                        </Box>
                    </Box>
                    {cliente.tipoPrecio !== 'Detal' && (
                        <Chip label={`Precio: ${cliente.tipoPrecio}`} color="primary" size="small" sx={{ mt: 1 }} />
                    )}
                    {esperaOrigenId && (
                        <Chip label={`⏳ Recuperada de espera #${esperaOrigenId}`} color="warning" size="small" sx={{ mt: 1, ml: 1 }} />
                    )}
                </Paper>

                {/* Carrito */}
                <Box sx={{ flexGrow: 1, overflow: 'hidden' }}>
                    <PosCart
                        items={cart.map(item => ({
                            id: item.id,
                            nombre: item.nombre,
                            cantidad: item.cantidad,
                            precioUnitario: item.precio,
                            descuento: item.descuento || 0,
                            total: item.totalRenglon,
                        }))}
                        onRemoveItem={handleRequestSupervisorVoid}
                        onUpdateQuantity={() => { }}
                        subtotal={subtotal}
                        impuestos={impuestos}
                        total={totalConImpuesto}
                        cliente={cliente.nombre}
                        puntosGanados={Math.floor(totalConImpuesto / 10)}
                        puntosTotales={1250}
                        selectedItemId={selectedItemId}
                        onSelectItem={handleSelectItem}
                    />
                </Box>

                {/* Numpad */}
                <Box sx={{ height: { xs: 160, md: 220 }, borderTop: '1px solid', borderColor: 'divider' }}>
                    <PosNumpad
                        onNumberPress={handleNumberPress}
                        onBackspace={handleBackspace}
                        onClear={handleClear}
                        onQuantity={() => handleModeChange('qty')}
                        onDiscount={() => handleModeChange('discount')}
                        onPrice={() => handleModeChange('price')}
                        activeMode={numpadMode}
                    />
                </Box>

                {/* Botones de acción */}
                <Box sx={{ p: 0.5, display: 'flex', flexDirection: 'column', gap: 0.5, height: { xs: 52, md: 56 } }}>
                    <PosPaymentButton
                        total={totalConImpuesto}
                        onClick={() => setPaymentModal(true)}
                        disabled={cart.length === 0 || syncing}
                    />
                </Box>
            </Box>

            {/* Panel Derecho - Productos */}
            <Box sx={{
                flexGrow: 1,
                display: isMobileLayout ? (showMobileMenu ? 'flex' : 'none') : 'flex',
                flexDirection: 'column',
                overflow: 'hidden',
                width: isMobileLayout ? '100%' : 'auto',
            }}>
                <PosHeader
                    searchTerm={searchTerm}
                    onSearchChange={setSearchTerm}
                    categories={categories}
                    selectedCategory={selectedCategory}
                    onCategorySelect={setSelectedCategory}
                    cajaName={caja.nombre}
                    userName="Cajero"
                />
                <Box sx={{ flexGrow: 1, overflow: 'hidden' }}>
                    <PosProductGrid
                        products={filteredProducts.map(p => ({
                            id: p.id,
                            nombre: p.nombre,
                            precio: cliente.tipoPrecio === 'Mayor'
                                ? p.precioMayor
                                : cliente.tipoPrecio === 'Distribuidor'
                                    ? p.precioDistribuidor
                                    : p.precioDetal,
                            imagen: p.imagen,
                            categoria: p.categoria,
                        }))}
                        onProductClick={handleAddProduct}
                        selectedCategory={selectedCategory || undefined}
                    />
                </Box>
            </Box>

            {/* Modal de Pago */}
            <PosPaymentModal
                open={paymentModalOpen}
                onClose={() => setPaymentModal(false)}
                total={totalConImpuesto}
                items={cart.map(item => ({
                    nombre: item.nombre,
                    cantidad: item.cantidad,
                    precio: item.precio,
                    total: item.totalRenglon,
                }))}
                cliente={cliente.nombre}
                onPaymentComplete={handlePaymentComplete}
            />

            {/* Modal de Búsqueda de Cliente */}
            <PosCustomerSearch
                open={customerModalOpen}
                onClose={() => setCustomerModalOpen(false)}
                onSelectCustomer={handleCustomerChange}
                selectedCustomerId={cliente.id}
            />

            {/* Drawer de Ventas en Espera */}
            <PosEsperaDrawer
                open={esperaDrawerOpen}
                onClose={() => setEsperaDrawerOpen(false)}
                onRecuperado={(msg) => showMsg(msg, 'success')}
                onError={(msg) => showMsg(msg, 'error')}
            />

            {/* Dialog Motivo de Espera */}
            <Dialog
                open={esperaMotiveDialog}
                onClose={() => setEsperaMotiveDialog(false)}
                maxWidth="xs"
                fullWidth
                PaperProps={{ sx: { borderRadius: 2.5 } }}
            >
                <DialogTitle sx={{ pb: 1, fontWeight: 700 }}>⏸️ Poner Venta en Espera</DialogTitle>
                <DialogContent sx={{ pt: 1 }}>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                        El carrito completo ({cart.length} items, ${totalConImpuesto.toFixed(2)}) será
                        guardado y podrá ser recuperado desde cualquier caja.
                    </Typography>
                    <TextField
                        fullWidth
                        label="Motivo (opcional)"
                        placeholder="Ej: Tarjeta rechazada, cliente sin efectivo..."
                        value={esperaMotive}
                        onChange={(e) => setEsperaMotive(e.target.value)}
                        multiline
                        rows={2}
                        InputLabelProps={{ shrink: true }}
                        InputProps={{ sx: { borderRadius: 1.5 } }}
                    />
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setEsperaMotiveDialog(false)}>Cancelar</Button>
                    <Button variant="contained" color="warning" onClick={handlePonerEnEspera} disabled={syncing}>
                        Poner en Espera
                    </Button>
                </DialogActions>
            </Dialog>

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
                                fontWeight: 700,
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
                                fontWeight: 700,
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
                            onClick={handleConfirmSupervisorVoid}
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
            {/* Mobile Floating Bar */}
            {isMobileLayout && (
                <Paper elevation={8} sx={{ position: 'fixed', bottom: 0, left: 0, right: 0, zIndex: 1200, display: 'flex', height: 50, borderRadius: 0 }}>
                    {!showMobileMenu ? (
                        <Button
                            variant="contained"
                            color="secondary"
                            sx={{ flex: 1, borderRadius: 0, fontSize: '1rem', fontWeight: 'bold', textTransform: 'none' }}
                            onClick={() => setShowMobileMenu(true)}
                        >
                            + Ver Menú de Productos
                        </Button>
                    ) : (
                        <Box sx={{ display: 'flex', width: '100%', borderTop: '1px solid', borderColor: 'divider' }}>
                            <Button
                                variant="contained"
                                sx={{
                                    flex: 1,
                                    borderRadius: 0,
                                    bgcolor: 'primary.main',
                                    color: 'primary.contrastText',
                                    '&:hover': { bgcolor: 'primary.dark' },
                                }}
                                onClick={() => {
                                    setShowMobileMenu(false);
                                    setPaymentModal(true);
                                }}
                                disabled={cart.length === 0}
                            >
                                <Typography sx={{ fontSize: '1.15rem', fontWeight: 'bold', mr: 1 }}>Pagar</Typography>
                                <Typography sx={{ fontSize: '1rem' }}>${totalConImpuesto.toFixed(2)}</Typography>
                            </Button>
                            <Button
                                sx={{ flex: 0.5, borderRadius: 0, bgcolor: 'action.hover', color: 'text.primary', borderLeft: '1px solid', borderColor: 'divider' }}
                                onClick={() => setShowMobileMenu(false)}
                            >
                                <Box sx={{ textAlign: 'center' }}>
                                    <Typography variant="body2" fontWeight="bold">Carrito</Typography>
                                    <Typography variant="caption">{cart.length} items</Typography>
                                </Box>
                            </Button>
                            {ventasEnEspera.length > 0 && (
                                <Button
                                    sx={{ flex: 0.3, borderRadius: 0, bgcolor: 'warning.light', color: 'warning.dark', borderLeft: '1px solid', borderColor: 'divider' }}
                                    onClick={() => { setShowMobileMenu(false); setEsperaDrawerOpen(true); }}
                                >
                                    <Badge badgeContent={ventasEnEspera.length} color="error">
                                        <AccessTimeIcon />
                                    </Badge>
                                </Button>
                            )}
                        </Box>
                    )}
                </Paper>
            )}

            {/* Snackbar */}
            <Snackbar
                open={snackbar.open}
                autoHideDuration={5000}
                onClose={() => setSnackbar(s => ({ ...s, open: false }))}
                anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
            >
                <Alert severity={snackbar.severity} variant="filled" onClose={() => setSnackbar(s => ({ ...s, open: false }))}>
                    {snackbar.message}
                </Alert>
            </Snackbar>
        </Box>
    );
}

