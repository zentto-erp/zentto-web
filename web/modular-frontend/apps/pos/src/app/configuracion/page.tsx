'use client';

import React, { useEffect, useMemo, useState } from 'react';
import {
  Alert,
  Box,
  Button,
  CircularProgress,
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
import { useAuth } from '@datqbox/shared-auth';
import {
  apiPut, useModuleSettings, usePosStore,
  useCountries, getCountryDefaults, fetchBcvRates as fetchBcvRatesApi, settingsToLocalizacion,
  type BcvRates,
} from '@datqbox/shared-api';
import { PaymentSettingsPanel } from '@datqbox/shared-ui';

type PosSettings = Record<string, any>;

export default function PosConfiguracionPage() {
  const { data: countries = [] } = useCountries();
  const { isAdmin, company } = useAuth();
  const companyId = company?.companyId ?? 1;
  const branchId = company?.branchId ?? 1;
  const countryCode = company?.countryCode ?? 'VE';

  const { data, isLoading, error, refetch } = useModuleSettings('pos', companyId);
  const { setLocalizacion } = usePosStore();
  const [draft, setDraft] = useState<PosSettings>({});
  const [original, setOriginal] = useState<PosSettings>({});
  const [isSaving, setIsSaving] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);

  // BCV
  const [bcvRates, setBcvRates] = useState<BcvRates | null>(null);
  const [loadingBcv, setLoadingBcv] = useState(false);
  const [bcvError, setBcvError] = useState<string | null>(null);

  useEffect(() => {
    if (!data) return;
    setDraft({ ...data });
    setOriginal({ ...data });

    // Cargar BCV en background al abrir si no se ha cargado. 
    // Y auto-aplicar SOLO si viene en 1 (que es el defecto inicial)
    const currentRate = Number(data['localizacion.tasaCambio'] ?? 1);
    fetchBcvRates(currentRate === 1 || currentRate === 45.0);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [data]);

  const hasChanges = useMemo(
    () => JSON.stringify(draft) !== JSON.stringify(original),
    [draft, original]
  );

  const setValue = (key: string, value: unknown) => {
    setDraft((prev) => ({ ...prev, [key]: value }));
  };

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
      setValue('localizacion.pais', code);
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

  const bcvLabel = () => {
    if (!bcvRates) return 'Tasa BCV no cargada';
    const ref = String(draft['localizacion.monedaReferencia'] ?? '').toUpperCase();
    const val = (ref.includes('EUR') || ref === '€') ? bcvRates.EUR : bcvRates.USD;
    const cur = (ref.includes('EUR') || ref === '€') ? 'EUR' : 'USD';
    return `BCV ${cur}: ${Number(val ?? 0).toFixed(2)} (${bcvRates.fechaInformativa || 's/f'})`;
  };

  const handleSave = async () => {
    setIsSaving(true);
    setSaveError(null);
    try {
      await apiPut(`/v1/settings/pos?companyId=${companyId}`, draft);
      // Sync localizacion with runtime POS store
      setLocalizacion(settingsToLocalizacion(draft));
      await refetch();
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

  if (!isAdmin) {
    return (
      <Box sx={{ p: 3 }}>
        <Alert severity="error">Solo administradores pueden editar la configuración de POS.</Alert>
      </Box>
    );
  }

  if (isLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Box sx={{ p: 3 }}>
        <Alert severity="error">No se pudo cargar la configuración de POS.</Alert>
      </Box>
    );
  }

  return (
    <Box sx={{ p: { xs: 2, md: 3 }, maxWidth: 1100 }}>
      <Typography variant="h5" sx={{ fontWeight: 700, mb: 0.5 }}>
        Configuración POS
      </Typography>
      <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
        Parámetros de caja, impresora fiscal y formas de pago para {company?.companyName || 'empresa activa'}.
      </Typography>

      {saveError && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {saveError}
        </Alert>
      )}

      <Stack spacing={2} sx={{ mb: 2 }}>
        <Stack direction={{ xs: 'column', md: 'row' }} spacing={2}>
          <Tooltip title="Identificador numérico interno de la caja dentro del sistema." arrow placement="top">
            <TextField
              label="Caja ID"
              value={draft['caja.id'] ?? '1'}
              onChange={(e) => setValue('caja.id', e.target.value)}
              fullWidth
            />
          </Tooltip>
          <Tooltip title="Nombre público de la caja visible para los usuarios del POS." arrow placement="top">
            <TextField
              label="Nombre Caja"
              value={draft['caja.nombre'] ?? 'Caja Principal'}
              onChange={(e) => setValue('caja.nombre', e.target.value)}
              fullWidth
            />
          </Tooltip>
        </Stack>

        <Stack direction={{ xs: 'column', md: 'row' }} spacing={2}>
          <Tooltip title="Prefijo o letra que identifica la serie de correlativos para la facturación desde esta caja." arrow placement="top">
            <TextField
              label="Serie Factura"
              value={draft['caja.serieFactura'] ?? 'A'}
              onChange={(e) => setValue('caja.serieFactura', e.target.value)}
              fullWidth
            />
          </Tooltip>
          <Tooltip title="ID del almacén o bodega del cual esta caja descontará el inventario." arrow placement="top">
            <TextField
              label="Almacén ID"
              value={draft['caja.almacenId'] ?? '1'}
              onChange={(e) => setValue('caja.almacenId', e.target.value)}
              fullWidth
            />
          </Tooltip>
        </Stack>

        <Stack direction={{ xs: 'column', md: 'row' }} spacing={2}>
          <Tooltip title="Marca de la impresora fiscal (ej, BIXOLON, PNP, EPSON). Usado para formatear los comandos." arrow placement="top">
            <TextField
              label="Marca Impresora"
              value={draft['impresora.marca'] ?? 'PNP'}
              onChange={(e) => setValue('impresora.marca', e.target.value)}
              fullWidth
            />
          </Tooltip>
          <Tooltip title="Medio físico por el cual la caja se comunica con la impresora fiscal." arrow placement="top">
            <TextField
              label="Conexión"
              value={draft['impresora.conexion'] ?? 'emulador'}
              onChange={(e) => setValue('impresora.conexion', e.target.value)}
              fullWidth
            />
          </Tooltip>
        </Stack>

        <Tooltip title="Dirección de red o IP local donde reside ejecutándose el DatqBox Fiscal Agent." arrow placement="top">
          <TextField
            label="Agent URL"
            value={draft['impresora.agentUrl'] ?? 'http://localhost:5059'}
            onChange={(e) => setValue('impresora.agentUrl', e.target.value)}
            fullWidth
          />
        </Tooltip>

      </Stack>

      <Divider sx={{ my: 3 }} />

      <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>
        Moneda & Fiscal
      </Typography>
      <Grid container spacing={2} sx={{ mb: 2 }}>
        <Grid item xs={12}>
          <Tooltip title="Asigna los valores y regímenes fiscales base por defecto para la región seleccionada." arrow placement="top">
            <TextField
              select fullWidth
              label="País (Pre-configuración)"
              value={String(draft['localizacion.pais'] ?? 'VE')}
              onChange={(e) => handleCountryChange(e.target.value)}
              helperText="Seleccionar un país carga los defaults para moneda e impuestos automáticos."
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
              onChange={(e) => setValue('localizacion.monedaPrincipal', e.target.value)} />
          </Tooltip>
        </Grid>
        <Grid item xs={12} sm={6}>
          <Tooltip title="Moneda secundaria utilizada para estabilizar o indexar los precios frente a fluctuaciones." arrow placement="top">
            <TextField select fullWidth label="Moneda de Referencia"
              value={String(draft['localizacion.monedaReferencia'] ?? '$')}
              onChange={(e) => handleMonedaReferenciaChange(e.target.value)}
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
              onChange={(e) => setValue('localizacion.tasaCambio', parseFloat(e.target.value))} />
          </Tooltip>
        </Grid>
        <Grid item xs={12} sm={6}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, height: '100%', mt: 0.5 }}>
            <Typography variant="body2" color="text.secondary" sx={{ flexGrow: 1, fontSize: '0.75rem' }}>
              {bcvLabel()}
            </Typography>
            <Tooltip title="Cargar tasa oficial del BCV al día de hoy para actualizar el campo Tasa de Cambio automáticamente." arrow placement="top">
              <span>
                <Button onClick={() => fetchBcvRates(true)} disabled={loadingBcv}>
                  {loadingBcv ? <CircularProgress size={14} /> : 'Actualizar BCV'}
                </Button>
              </span>
            </Tooltip>
          </Box>
          {bcvError && <Typography variant="caption" color="warning.main">{bcvError}</Typography>}
        </Grid>
        <Grid item xs={12} sm={6}>
          <Tooltip title="Indica que todos los precios en la lista de productos ya llevan IVA incorporado o si se suma al final." arrow placement="top">
            <FormControlLabel
              control={
                <Switch
                  checked={Boolean(draft['localizacion.preciosIncluyenIva'] ?? true)}
                  onChange={(e) => setValue('localizacion.preciosIncluyenIva', e.target.checked)}
                />
              }
              label="Precios incluyen IVA"
            />
          </Tooltip>
        </Grid>
        <Grid item xs={12}>
          <Divider sx={{ my: 0.5 }} />
          <Typography variant="body2" color="text.secondary" sx={{ my: 1 }}>Impuestos Locales (Ej. IGTF Venezuela)</Typography>
        </Grid>
        <Grid item xs={12} sm={6}>
          <Tooltip title="Aplica cobro de porcentaje de IGTF cuando un pago sea detectado como divisa en medio de un cobro." arrow placement="top">
            <FormControlLabel
              control={
                <Switch
                  checked={Boolean(draft['localizacion.aplicarIgtf'] ?? true)}
                  onChange={(e) => setValue('localizacion.aplicarIgtf', e.target.checked)}
                />
              }
              label="Aplicar IGTF (Divisas Efectivo)"
            />
          </Tooltip>
        </Grid>
        <Grid item xs={12} sm={6}>
          <Tooltip title="Porcentaje del arancel o IGTF a calcular sobre el monto gravado de la transacción física." arrow placement="top">
            <TextField fullWidth type="number" label="Tasa IGTF (%)"
              value={Number(draft['localizacion.tasaIgtf'] ?? 3)}
              onChange={(e) => setValue('localizacion.tasaIgtf', parseFloat(e.target.value))}
              disabled={!Boolean(draft['localizacion.aplicarIgtf'] ?? true)} />
          </Tooltip>
        </Grid>
      </Grid>

      <Stack direction="row" spacing={1.5} sx={{ mb: 4 }}>
        <Button variant="contained" onClick={handleSave} disabled={!hasChanges || isSaving}>
          {isSaving ? 'Guardando...' : 'Guardar'}
        </Button>
        <Button variant="outlined" onClick={handleDiscard} disabled={!hasChanges || isSaving}>
          Descartar
        </Button>
      </Stack>

      <Typography variant="h6" sx={{ fontWeight: 600, mb: 1 }}>
        Formas de Pago (POS)
      </Typography>
      <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
        Selecciona cuáles métodos están permitidos en caja y sus reglas operativas.
      </Typography>

      <PaymentSettingsPanel
        empresaId={companyId}
        sucursalId={branchId}
        countryCode={countryCode}
        channels={['POS']}
        methodsOnly
      />
    </Box>
  );
}
