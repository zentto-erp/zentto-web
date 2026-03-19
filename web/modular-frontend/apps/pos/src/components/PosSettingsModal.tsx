'use client';

/**
 * PosSettingsModal
 * ─────────────────────────────────────────────────────────────────────────────
 * Modal unificado para la configuración completa del módulo POS.
 * Contiene exactamente los mismos campos que la página /configuracion,
 * más el formulario de Localización/Fiscal que antes solo existía en el
 * botón ⚙️ de PosHeader.
 *
 * Fuente de datos: useModuleSettings('pos') → DB (persistente).
 * Al guardar también sincroniza usePosStore().setLocalizacion() para
 * que los cálculos de carrito usen la tasa/moneda correcta al instante.
 */

import React, { useEffect, useMemo, useState } from 'react';
import {
    Alert,
    Box,
    Button,
    CircularProgress,
    Dialog,
    DialogActions,
    DialogContent,
    DialogTitle,
    Divider,
    FormControlLabel,
    Grid,
    MenuItem,
    Stack,
    Switch,
    TextField,
    Tooltip,
    Typography,
} from '@mui/material';
import { useAuth } from '@zentto/shared-auth';
import {
    apiPut, useModuleSettings, usePosStore,
    useCountries, getCountryDefaults, fetchBcvRates as fetchBcvRatesApi, settingsToLocalizacion,
    type BcvRates,
} from '@zentto/shared-api';
import { PaymentSettingsPanel } from '@zentto/shared-ui';

type Settings = Record<string, unknown>;

interface PosSettingsModalProps {
    open: boolean;
    onClose: () => void;
}

export function PosSettingsModal({ open, onClose }: PosSettingsModalProps) {
    const { data: countries = [] } = useCountries();
    const { isAdmin, company } = useAuth();
    const companyId = company?.companyId ?? 1;
    const branchId = company?.branchId ?? 1;
    const countryCode = company?.countryCode ?? 'VE';

    const { data, isLoading, error, refetch } = useModuleSettings('pos', companyId);
    const { setLocalizacion } = usePosStore();

    const [draft, setDraft] = useState<Settings>({});
    const [original, setOriginal] = useState<Settings>({});
    const [isSaving, setIsSaving] = useState(false);
    const [saveError, setSaveError] = useState<string | null>(null);

    // BCV
    const [bcvRates, setBcvRates] = useState<BcvRates | null>(null);
    const [loadingBcv, setLoadingBcv] = useState(false);
    const [bcvError, setBcvError] = useState<string | null>(null);

    useEffect(() => {
        if (open && data) {
            setDraft({ ...data });
            setOriginal({ ...data });

            const currentRate = Number(data['localizacion.tasaCambio'] ?? 1);
            fetchBcvRates(currentRate === 1 || currentRate === 45.0);
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [open, data]);

    const hasChanges = useMemo(
        () => JSON.stringify(draft) !== JSON.stringify(original),
        [draft, original]
    );

    const set = (key: string, value: unknown) =>
        setDraft((prev) => ({ ...prev, [key]: value }));

    const handleCountryChange = (code: string) => {
        const preset = getCountryDefaults(countries, code);
        if (preset) {
            setDraft(prev => {
                let newRate = preset.tasaCambio;
                if (code === 'VE' && bcvRates) {
                    newRate = preset.monedaReferencia === '€' ? (bcvRates.EUR ?? newRate) : (bcvRates.USD ?? newRate);
                }
                return {
                    ...prev,
                    'localizacion.pais': code,
                    'localizacion.preciosIncluyenIva': preset.preciosIncluyenIva,
                    'localizacion.tasaCambio': newRate,
                    'localizacion.monedaPrincipal': preset.monedaPrincipal,
                    'localizacion.monedaReferencia': preset.monedaReferencia,
                    'localizacion.tasaIgtf': preset.tasaIgtf,
                    'localizacion.aplicarIgtf': preset.aplicarIgtf,
                };
            });
        } else {
            set('localizacion.pais', code);
        }
    };

    const handleMonedaReferenciaChange = (val: string) => {
        setDraft(prev => {
            let newRate = prev['localizacion.tasaCambio'];
            if (String(prev['localizacion.pais'] ?? 'VE') === 'VE' && bcvRates) {
                newRate = (val === '€' || val.includes('EUR')) ? (bcvRates.EUR ?? newRate) : (bcvRates.USD ?? newRate);
            }
            return {
                ...prev,
                'localizacion.monedaReferencia': val,
                'localizacion.tasaCambio': newRate
            };
        });
    };

    const fetchBcvRates = async (updateDraftState = true) => {
        setLoadingBcv(true);
        setBcvError(null);
        try {
            const rates = await fetchBcvRatesApi();
            setBcvRates(rates);

            if (updateDraftState) {
                setDraft(prev => {
                    const ref = String(prev['localizacion.monedaReferencia'] ?? '$').toUpperCase();
                    let appliedRate = prev['localizacion.tasaCambio'];
                    if (ref.includes('USD') || ref === '$') {
                        appliedRate = Number(rates.USD ?? prev['localizacion.tasaCambio']);
                    } else if (ref.includes('EUR') || ref === '€') {
                        appliedRate = Number(rates.EUR ?? prev['localizacion.tasaCambio']);
                    }
                    return { ...prev, 'localizacion.tasaCambio': appliedRate };
                });
            }
        } catch {
            setBcvError('No se pudo cargar la tasa BCV.');
        } finally {
            setLoadingBcv(false);
        }
    };

    const handleSave = async () => {
        setIsSaving(true);
        setSaveError(null);
        try {
            await apiPut(`/v1/settings/pos?companyId=${companyId}`, draft);
            // Sync localizacion with runtime POS store
            setLocalizacion(settingsToLocalizacion(draft));
            await refetch();
            setOriginal({ ...draft });
        } catch (err: unknown) {
            setSaveError(err instanceof Error ? err.message : 'No fue posible guardar configuración POS.');
        } finally {
            setIsSaving(false);
        }
    };

    const handleDiscard = () => {
        setSaveError(null);
        setDraft({ ...original });
    };

    const bcvLabel = () => {
        if (!bcvRates) return 'Tasa BCV no cargada';
        const ref = String(draft['localizacion.monedaReferencia'] ?? '').toUpperCase();
        const val = (ref.includes('EUR') || ref === '€') ? bcvRates.EUR : bcvRates.USD;
        const cur = (ref.includes('EUR') || ref === '€') ? 'EUR' : 'USD';
        return `BCV ${cur}: ${Number(val ?? 0).toFixed(2)} (${bcvRates.fechaInformativa || 's/f'})`;
    };

    return (
        <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth scroll="paper">
            <DialogTitle sx={{ fontWeight: 700 }}>Configuración POS</DialogTitle>
            <DialogContent dividers>
                {isLoading && (
                    <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}>
                        <CircularProgress />
                    </Box>
                )}

                {error && (
                    <Alert severity="error">No se pudo cargar la configuración de POS.</Alert>
                )}

                {!isAdmin && !isLoading && (
                    <Alert severity="warning" sx={{ mb: 2 }}>
                        Solo administradores pueden editar esta configuración.
                    </Alert>
                )}

                {saveError && (
                    <Alert severity="error" sx={{ mb: 2 }}>{saveError}</Alert>
                )}

                {!isLoading && !error && (
                    <Stack spacing={3} sx={{ pt: 1 }}>

                        {/* ── Sección: Caja ─────────────────────────────── */}
                        <Box>
                            <Typography variant="subtitle1" fontWeight={700} gutterBottom>
                                Caja
                            </Typography>
                            <Grid container spacing={2}>
                                <Grid item xs={12} sm={6}>
                                    <Tooltip title="Identificador numérico interno de la caja dentro del sistema." arrow placement="top">
                                        <TextField fullWidth label="Caja ID"
                                            value={String(draft['caja.id'] ?? '1')}
                                            onChange={e => set('caja.id', e.target.value)}
                                            disabled={!isAdmin} />
                                    </Tooltip>
                                </Grid>
                                <Grid item xs={12} sm={6}>
                                    <Tooltip title="Nombre público de la caja visible para los usuarios del POS." arrow placement="top">
                                        <TextField fullWidth label="Nombre Caja"
                                            value={String(draft['caja.nombre'] ?? 'Caja Principal')}
                                            onChange={e => set('caja.nombre', e.target.value)}
                                            disabled={!isAdmin} />
                                    </Tooltip>
                                </Grid>
                                <Grid item xs={12} sm={6}>
                                    <Tooltip title="Prefijo o letra que identifica la serie de correlativos para la facturación desde esta caja." arrow placement="top">
                                        <TextField fullWidth label="Serie Factura"
                                            value={String(draft['caja.serieFactura'] ?? 'A')}
                                            onChange={e => set('caja.serieFactura', e.target.value)}
                                            disabled={!isAdmin} />
                                    </Tooltip>
                                </Grid>
                                <Grid item xs={12} sm={6}>
                                    <Tooltip title="ID del almacén o bodega del cual esta caja descontará el inventario." arrow placement="top">
                                        <TextField fullWidth label="Almacén ID"
                                            value={String(draft['caja.almacenId'] ?? '1')}
                                            onChange={e => set('caja.almacenId', e.target.value)}
                                            disabled={!isAdmin} />
                                    </Tooltip>
                                </Grid>
                            </Grid>
                        </Box>

                        <Divider />

                        {/* ── Sección: Impresora Fiscal ─────────────────── */}
                        <Box>
                            <Typography variant="subtitle1" fontWeight={700} gutterBottom>
                                Impresora Fiscal
                            </Typography>
                            <Grid container spacing={2}>
                                <Grid item xs={12} sm={6}>
                                    <Tooltip title="Marca de la impresora fiscal (ej, BIXOLON, PNP, EPSON). Usado para formatear los comandos." arrow placement="top">
                                        <TextField fullWidth label="Marca Impresora"
                                            value={String(draft['impresora.marca'] ?? 'PNP')}
                                            onChange={e => set('impresora.marca', e.target.value)}
                                            disabled={!isAdmin} />
                                    </Tooltip>
                                </Grid>
                                <Grid item xs={12} sm={6}>
                                    <Tooltip title="Medio físico por el cual la caja se comunica con la impresora fiscal." arrow placement="top">
                                        <TextField fullWidth label="Conexión"
                                            value={String(draft['impresora.conexion'] ?? 'emulador')}
                                            onChange={e => set('impresora.conexion', e.target.value)}
                                            disabled={!isAdmin} />
                                    </Tooltip>
                                </Grid>
                                <Grid item xs={12}>
                                    <Tooltip title="Dirección de red o IP local donde reside ejecutándose el Zentto Fiscal Agent." arrow placement="top">
                                        <TextField fullWidth label="Agent URL"
                                            value={String(draft['impresora.agentUrl'] ?? 'http://localhost:7654')}
                                            onChange={e => set('impresora.agentUrl', e.target.value)}
                                            disabled={!isAdmin} />
                                    </Tooltip>
                                </Grid>
                            </Grid>
                        </Box>

                        <Divider />

                        {/* ── Sección: Moneda & Fiscal ──────────────────── */}
                        <Box>
                            <Typography variant="subtitle1" fontWeight={700} gutterBottom>
                                Moneda & Fiscal
                            </Typography>
                            <Grid container spacing={2}>
                                <Grid item xs={12}>
                                    <Tooltip title="Asigna los valores y regímenes fiscales base por defecto para la región seleccionada." arrow placement="top">
                                        <TextField
                                            select fullWidth
                                            label="País (Pre-configuración)"
                                            value={String(draft['localizacion.pais'] ?? 'VE')}
                                            onChange={e => handleCountryChange(e.target.value)}
                                            helperText="Seleccionar un país carga los defaults para moneda e impuestos automáticos."
                                            disabled={!isAdmin}
                                        >
                                            {countries.map(c => (
                                                <MenuItem key={c.CountryCode} value={c.CountryCode}>{c.CountryName}</MenuItem>
                                            ))}
                                        </TextField>
                                    </Tooltip>
                                </Grid>
                                <Grid item xs={12} sm={6}>
                                    <Tooltip title="Moneda transaccional de curso legal en la cual se reportan los registros fiscales." arrow placement="top">
                                        <TextField fullWidth label="Moneda Principal"
                                            value={String(draft['localizacion.monedaPrincipal'] ?? 'Bs')}
                                            onChange={e => set('localizacion.monedaPrincipal', e.target.value)}
                                            disabled={!isAdmin} />
                                    </Tooltip>
                                </Grid>
                                <Grid item xs={12} sm={6}>
                                    <Tooltip title="Moneda secundaria utilizada para estabilizar o indexar los precios frente a fluctuaciones." arrow placement="top">
                                        <TextField select fullWidth label="Moneda de Referencia"
                                            value={String(draft['localizacion.monedaReferencia'] ?? '$')}
                                            onChange={e => handleMonedaReferenciaChange(e.target.value)}
                                            disabled={!isAdmin}
                                        >
                                            <MenuItem value="$">USD ($)</MenuItem>
                                            <MenuItem value="€">EUR (€)</MenuItem>
                                        </TextField>
                                    </Tooltip>
                                </Grid>
                                <Grid item xs={12} sm={6}>
                                    <Tooltip title="Cantidad de unidades en Moneda Principal que equivale a 1 unidad en Moneda de Referencia." arrow placement="top">
                                        <TextField fullWidth type="number"
                                            label="Tasa de Cambio (1 Ref = X Principal)"
                                            value={Number(draft['localizacion.tasaCambio'] ?? 1)}
                                            onChange={e => set('localizacion.tasaCambio', parseFloat(e.target.value))}
                                            disabled={!isAdmin} />
                                    </Tooltip>
                                </Grid>
                                <Grid item xs={12} sm={6}>
                                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, height: '100%', mt: 0.5 }}>
                                        <Typography variant="body2" color="text.secondary" sx={{ flexGrow: 1, fontSize: '0.75rem' }}>
                                            {bcvLabel()}
                                        </Typography>
                                        <Tooltip title="Cargar tasa oficial del BCV al día de hoy para actualizar el campo Tasa de Cambio automáticamente." arrow placement="top">
                                            <span>
                                                <Button onClick={() => fetchBcvRates()} disabled={loadingBcv || !isAdmin}>
                                                    {loadingBcv ? <CircularProgress size={14} /> : 'Actualizar BCV'}
                                                </Button>
                                            </span>
                                        </Tooltip>
                                    </Box>
                                    {bcvError && (
                                        <Typography variant="caption" color="warning.main">{bcvError}</Typography>
                                    )}
                                </Grid>
                                <Grid item xs={12} sm={6}>
                                    <Tooltip title="Indica que todos los precios en la lista de productos ya llevan IVA incorporado o si se suma al final." arrow placement="top">
                                        <FormControlLabel
                                            control={
                                                <Switch
                                                    checked={Boolean(draft['localizacion.preciosIncluyenIva'] ?? true)}
                                                    onChange={e => set('localizacion.preciosIncluyenIva', e.target.checked)}
                                                    disabled={!isAdmin}
                                                />
                                            }
                                            label="Precios incluyen IVA"
                                        />
                                    </Tooltip>
                                </Grid>
                                <Grid item xs={12}>
                                    <Divider sx={{ my: 0.5 }} />
                                    <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                                        Impuestos Locales (Ej. IGTF Venezuela)
                                    </Typography>
                                </Grid>
                                <Grid item xs={12} sm={6}>
                                    <Tooltip title="Aplica cobro de porcentaje de IGTF cuando un pago sea detectado como divisa en medio de un cobro." arrow placement="top">
                                        <FormControlLabel
                                            control={
                                                <Switch
                                                    checked={Boolean(draft['localizacion.aplicarIgtf'] ?? true)}
                                                    onChange={e => set('localizacion.aplicarIgtf', e.target.checked)}
                                                    disabled={!isAdmin}
                                                />
                                            }
                                            label="Aplicar IGTF (Divisas Efectivo)"
                                        />
                                    </Tooltip>
                                </Grid>
                                <Grid item xs={12} sm={6}>
                                    <Tooltip title="Porcentaje del arancel o IGTF a calcular sobre el monto gravado de la transacción física." arrow placement="top">
                                        <TextField fullWidth type="number"
                                            label="Tasa IGTF (%)"
                                            value={Number(draft['localizacion.tasaIgtf'] ?? 3)}
                                            onChange={e => set('localizacion.tasaIgtf', parseFloat(e.target.value))}
                                            disabled={!isAdmin || !Boolean(draft['localizacion.aplicarIgtf'] ?? true)} />
                                    </Tooltip>
                                </Grid>
                            </Grid>
                        </Box>

                        <Divider />

                        {/* ── Sección: Formas de Pago ───────────────────── */}
                        <Box>
                            <Typography variant="subtitle1" fontWeight={700} gutterBottom>
                                Formas de Pago (POS)
                            </Typography>
                            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                                Selecciona cuáles métodos están permitidos en caja y sus reglas operativas.
                            </Typography>
                            {isAdmin ? (
                                <PaymentSettingsPanel
                                    empresaId={companyId}
                                    sucursalId={branchId}
                                    countryCode={countryCode}
                                    channels={['POS']}
                                    methodsOnly
                                />
                            ) : (
                                <Alert severity="info">Solo administradores pueden gestionar las formas de pago.</Alert>
                            )}
                        </Box>

                    </Stack>
                )}
            </DialogContent>
            <DialogActions>
                <Button onClick={handleDiscard} variant="outlined" disabled={!hasChanges || isSaving}>
                    Descartar
                </Button>
                <Button onClick={onClose} variant="outlined">
                    Cerrar
                </Button>
                {isAdmin && (
                    <Button onClick={handleSave} variant="contained" disabled={!hasChanges || isSaving}>
                        {isSaving ? 'Guardando...' : 'Guardar Configuración'}
                    </Button>
                )}
            </DialogActions>
        </Dialog>
    );
}
