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
} from '@mui/material';

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

const PREDEFINED_COUNTRIES = [
    { code: 'VE', name: 'Venezuela', defaultLoc: { preciosIncluyenIva: true, tasaCambio: 45.0, monedaPrincipal: 'Bs', monedaReferencia: '$', tasaIgtf: 3, aplicarIgtf: true } },
    { code: 'CO', name: 'Colombia', defaultLoc: { preciosIncluyenIva: false, tasaCambio: 4000, monedaPrincipal: '$', monedaReferencia: 'USD', tasaIgtf: 0, aplicarIgtf: false } },
    { code: 'MX', name: 'México', defaultLoc: { preciosIncluyenIva: false, tasaCambio: 18.0, monedaPrincipal: '$', monedaReferencia: 'USD', tasaIgtf: 0, aplicarIgtf: false } },
    { code: 'ES', name: 'España', defaultLoc: { preciosIncluyenIva: true, tasaCambio: 1.0, monedaPrincipal: '€', monedaReferencia: '$', tasaIgtf: 0, aplicarIgtf: false } },
    { code: 'US', name: 'Estados Unidos', defaultLoc: { preciosIncluyenIva: false, tasaCambio: 1.0, monedaPrincipal: '$', monedaReferencia: 'EUR', tasaIgtf: 0, aplicarIgtf: false } },
];

export function LocalizacionModal({ open, onClose, currentConfig, onSave }: LocalizacionModalProps) {
    const [config, setConfig] = useState<LocalizacionConfig>(currentConfig);

    useEffect(() => {
        if (open) {
            setConfig(currentConfig);
        }
    }, [open, currentConfig]);

    const handleCountryChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const pais = e.target.value;
        const preset = PREDEFINED_COUNTRIES.find(c => c.code === pais)?.defaultLoc;
        if (preset) {
            setConfig({
                ...config,
                pais,
                ...preset
            });
        } else {
            setConfig({ ...config, pais });
        }
    };

    const handleChange = (field: keyof LocalizacionConfig, value: any) => {
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
                            {PREDEFINED_COUNTRIES.map(c => (
                                <MenuItem key={c.code} value={c.code}>
                                    {c.name}
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
