import React, { useState, useEffect } from 'react';
import {
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    Button,
    Grid,
    TextField,
    Typography,
    Box,
    Switch,
    FormControlLabel,
    MenuItem,
    Divider,
    Alert,
    CircularProgress,
} from '@mui/material';
import { getSession } from 'next-auth/react';
import { useCountries, type CountryRecord } from '@zentto/shared-api';

export interface LocalizacionConfig {
    pais: string;
    preciosIncluyenIva: boolean;
    tasaCambio: number;
    monedaPrincipal: string;
    monedaReferencia: string;
    tasaIgtf: number;
    aplicarIgtf: boolean;
}

interface LocalizacionModalProps {
    open: boolean;
    onClose: () => void;
    currentConfig: LocalizacionConfig;
    onSave: (newConfig: LocalizacionConfig) => void;
}


type TasasBcvResponse = {
    success?: boolean;
    USD?: number;
    EUR?: number;
    fechaInformativa?: string;
    origen?: string;
};

const API_BASE = process.env.NEXT_PUBLIC_API_URL || process.env.NEXT_PUBLIC_API_BASE || 'http://localhost:4000';

function normalizeRefCurrency(monedaReferencia: string): 'USD' | 'EUR' | null {
    const ref = (monedaReferencia || '').trim().toUpperCase();
    if (!ref) return null;
    if (ref === '$' || ref.includes('USD') || ref.includes('DOLAR')) return 'USD';
    if (ref === '€' || ref.includes('EUR')) return 'EUR';
    return null;
}

export function LocalizacionModal({ open, onClose, currentConfig, onSave }: LocalizacionModalProps) {
    const { data: countries = [] } = useCountries();
    const [config, setConfig] = useState<LocalizacionConfig>(currentConfig);
    const [bcvRates, setBcvRates] = useState<TasasBcvResponse | null>(null);
    const [loadingRates, setLoadingRates] = useState(false);
    const [ratesError, setRatesError] = useState<string | null>(null);

    const applyBcvRateIfNeeded = (baseConfig: LocalizacionConfig, rates?: TasasBcvResponse | null): LocalizacionConfig => {
        const source = rates ?? bcvRates;
        const refCurrency = normalizeRefCurrency(baseConfig.monedaReferencia);
        if (!source || !refCurrency) return baseConfig;

        const rateValue = refCurrency === 'USD' ? Number(source.USD ?? 0) : Number(source.EUR ?? 0);
        if (!Number.isFinite(rateValue) || rateValue <= 0) return baseConfig;

        return {
            ...baseConfig,
            tasaCambio: rateValue,
        };
    };

    const fetchBcvRates = async () => {
        setLoadingRates(true);
        setRatesError(null);
        try {
            const endpoints = [`${API_BASE}/v1/config/tasas`, `${API_BASE}/api/v1/config/tasas`];
            let data: TasasBcvResponse | null = null;
            const session = await getSession();
            const accessToken = (session as unknown as { accessToken?: string } | null)?.accessToken;
            const headers: Record<string, string> = accessToken
                ? { Authorization: `Bearer ${accessToken}` }
                : {};

            for (const endpoint of endpoints) {
                const res = await fetch(endpoint, {
                    headers,
                    credentials: 'include',
                });
                if (!res.ok) continue;
                data = await res.json() as TasasBcvResponse;
                break;
            }

            if (!data) throw new Error('BCV_ENDPOINT_UNAVAILABLE');
            setBcvRates(data);
            setConfig(prev => applyBcvRateIfNeeded(prev, data));
        } catch {
            setRatesError('No se pudo cargar la tasa BCV en este momento.');
        } finally {
            setLoadingRates(false);
        }
    };

    useEffect(() => {
        if (open) {
            setConfig(currentConfig);
            fetchBcvRates();
        }
    }, [open, currentConfig]);

    useEffect(() => {
        if (!open) return;
        setConfig(prev => applyBcvRateIfNeeded(prev));
    }, [config.monedaReferencia, bcvRates, open]);

    const handleCountryChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const pais = e.target.value;
        const country = countries.find(c => c.CountryCode === pais);
        if (country) {
            const nextConfig: LocalizacionConfig = {
                ...config,
                pais,
                preciosIncluyenIva: country.PricesIncludeTax,
                tasaCambio: country.DefaultExchangeRate,
                monedaPrincipal: country.CurrencySymbol,
                monedaReferencia: country.ReferenceCurrencySymbol,
                tasaIgtf: country.SpecialTaxRate,
                aplicarIgtf: country.SpecialTaxEnabled,
            };
            setConfig(applyBcvRateIfNeeded(nextConfig));
        } else {
            setConfig({ ...config, pais });
        }
    };

    const handleChange = (field: keyof LocalizacionConfig, value: unknown) => {
        setConfig(prev => ({ ...prev, [field]: value }));
    };

    const handleSave = () => {
        onSave(config);
        onClose();
    };

    return (
        <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
            <DialogTitle>Configuración Global y Fiscal</DialogTitle>
            <DialogContent dividers>
                <Grid container spacing={3}>
                    <Grid item xs={12}>
                        <TextField
                            select
                            fullWidth
                            label="País (Pre-configuración)"
                            value={config.pais}
                            onChange={handleCountryChange}
                            helperText="Seleccionar un país carga los defaults para moneda e impuestos automáticos."
                        >
                            {countries.map(c => (
                                <MenuItem key={c.CountryCode} value={c.CountryCode}>
                                    {c.CountryName}
                                </MenuItem>
                            ))}
                        </TextField>
                    </Grid>

                    <Grid item xs={12} sm={6}>
                        <TextField
                            fullWidth
                            label="Moneda Principal"
                            value={config.monedaPrincipal}
                            onChange={(e) => handleChange('monedaPrincipal', e.target.value)}
                        />
                    </Grid>
                    <Grid item xs={12} sm={6}>
                        <TextField
                            fullWidth
                            label="Moneda de Referencia"
                            value={config.monedaReferencia}
                            onChange={(e) => handleChange('monedaReferencia', e.target.value)}
                        />
                    </Grid>

                    <Grid item xs={12} sm={6}>
                        <TextField
                            fullWidth
                            type="number"
                            label="Tasa de Cambio (1 Ref = X Principal)"
                            value={config.tasaCambio}
                            onChange={(e) => handleChange('tasaCambio', parseFloat(e.target.value))}
                        />
                    </Grid>

                    <Grid item xs={12} sm={6}>
                        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', height: '100%' }}>
                            <Typography variant="body2" color="text.secondary">
                                {bcvRates
                                    ? `BCV ${normalizeRefCurrency(config.monedaReferencia) || '-'}: ${normalizeRefCurrency(config.monedaReferencia) === 'EUR' ? Number(bcvRates.EUR ?? 0).toFixed(2) : Number(bcvRates.USD ?? 0).toFixed(2)} (${bcvRates.fechaInformativa || 's/f'})`
                                    : 'Tasa BCV no cargada'}
                            </Typography>
                            <Button onClick={fetchBcvRates} size="small" disabled={loadingRates}>
                                {loadingRates ? <CircularProgress size={16} /> : 'Actualizar BCV'}
                            </Button>
                        </Box>
                    </Grid>

                    {ratesError && (
                        <Grid item xs={12}>
                            <Alert severity="warning">{ratesError}</Alert>
                        </Grid>
                    )}

                    <Grid item xs={12} sm={6}>
                        <Box sx={{ mt: 1 }}>
                            <FormControlLabel
                                control={<Switch checked={config.preciosIncluyenIva} onChange={(e) => handleChange('preciosIncluyenIva', e.target.checked)} />}
                                label="¿Precios en menú incluyen IVA?"
                            />
                        </Box>
                    </Grid>

                    <Grid item xs={12}>
                        <Divider sx={{ my: 1 }} />
                        <Typography variant="subtitle2" gutterBottom color="text.secondary">
                            Impuestos Locales (Ej. IGTF Venezuela)
                        </Typography>
                    </Grid>

                    <Grid item xs={12} sm={6}>
                        <FormControlLabel
                            control={<Switch checked={config.aplicarIgtf} onChange={(e) => handleChange('aplicarIgtf', e.target.checked)} />}
                            label="Aplicar IGTF (Divisas Efectivo)"
                        />
                    </Grid>
                    <Grid item xs={12} sm={6}>
                        <TextField
                            fullWidth
                            type="number"
                            label="Tasa IGTF (%)"
                            value={config.tasaIgtf}
                            onChange={(e) => handleChange('tasaIgtf', parseFloat(e.target.value))}
                            disabled={!config.aplicarIgtf}
                        />
                    </Grid>
                </Grid>
            </DialogContent>
            <DialogActions>
                <Button onClick={onClose} variant="outlined">Cancelar</Button>
                <Button onClick={handleSave} variant="contained" color="primary">Guardar Configuración</Button>
            </DialogActions>
        </Dialog>
    );
}
