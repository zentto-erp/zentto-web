'use client';

import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  CardHeader,
  Chip,
  Divider,
  FormControlLabel,
  Grid,
  MenuItem,
  Stack,
  Switch,
  TextField,
  Typography,
} from '@mui/material';
import { useEffect, useMemo, useState } from 'react';
import { useAuth } from '@/app/authentication/AuthContext';
import {
  CountryCode,
  FiscalConfig,
  useFiscalConfig,
  useFiscalCountries,
  useFiscalCountryKnowledge,
  useSaveFiscalConfig,
} from '@/hooks/useFiscalConfig';

export default function ConfiguracionPage() {
  const { isAdmin } = useAuth();
  const [empresaId, setEmpresaId] = useState(1);
  const [sucursalId, setSucursalId] = useState(0);
  const [countryCode, setCountryCode] = useState<CountryCode>('VE');
  const [form, setForm] = useState<FiscalConfig | null>(null);

  const countriesQuery = useFiscalCountries(isAdmin);
  const knowledgeQuery = useFiscalCountryKnowledge(countryCode, isAdmin);
  const configQuery = useFiscalConfig({ empresaId, sucursalId, countryCode }, isAdmin);
  const saveMutation = useSaveFiscalConfig();

  useEffect(() => {
    if (configQuery.data) {
      setForm(configQuery.data);
    }
  }, [configQuery.data]);

  const taxOptions = useMemo(() => knowledgeQuery.data?.taxes ?? [], [knowledgeQuery.data?.taxes]);
  const invoiceTypes = useMemo(() => knowledgeQuery.data?.invoiceTypes ?? [], [knowledgeQuery.data?.invoiceTypes]);

  function updateField<K extends keyof FiscalConfig>(field: K, value: FiscalConfig[K]) {
    setForm((prev) => {
      if (!prev) return prev;
      return { ...prev, [field]: value };
    });
  }

  function handleCountryChange(nextCountry: CountryCode) {
    setCountryCode(nextCountry);
  }

  async function handleSave() {
    if (!form) return;
    await saveMutation.mutateAsync(form);
  }

  if (!isAdmin) {
    return (
      <Box>
        <Alert severity="error">
          No tienes permisos para acceder a esta seccion. Solo administradores pueden configurar el sistema.
        </Alert>
      </Box>
    );
  }

  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" sx={{ fontWeight: 600, mb: 1 }}>
          Configuracion del Sistema
        </Typography>
        <Typography variant="body1" color="textSecondary">
          Gestion multi-pais fiscal para POS y Restaurante (Venezuela + Espana)
        </Typography>
      </Box>

      {saveMutation.isSuccess && (
        <Alert severity="success" sx={{ mb: 2 }}>
          Configuracion fiscal guardada correctamente.
        </Alert>
      )}
      {saveMutation.isError && (
        <Alert severity="error" sx={{ mb: 2 }}>
          Error al guardar configuracion fiscal.
        </Alert>
      )}

      {!form ? (
        <Alert severity="info" sx={{ mb: 2 }}>
          Cargando configuracion fiscal...
        </Alert>
      ) : null}

      <Grid container spacing={3}>
        <Grid item xs={12} lg={6}>
          <Card>
            <CardHeader title="Contexto de Operacion" />
            <CardContent>
              <Stack spacing={2}>
                <TextField
                  fullWidth
                  type="number"
                  label="Empresa ID"
                  size="small"
                  value={empresaId}
                  onChange={(e) => setEmpresaId(Number(e.target.value || 1))}
                />
                <TextField
                  fullWidth
                  type="number"
                  label="Sucursal ID"
                  size="small"
                  value={sucursalId}
                  onChange={(e) => setSucursalId(Number(e.target.value || 0))}
                />
                <TextField
                  fullWidth
                  select
                  label="Pais Fiscal Activo"
                  size="small"
                  value={countryCode}
                  onChange={(e) => handleCountryChange(e.target.value as CountryCode)}
                >
                  {(countriesQuery.data ?? []).map((country) => (
                    <MenuItem key={country.code} value={country.code}>
                      {country.name} ({country.code}) - {country.authority}
                    </MenuItem>
                  ))}
                </TextField>
                <TextField
                  fullWidth
                  label="Moneda"
                  size="small"
                  value={form?.currency ?? ''}
                  onChange={(e) => updateField('currency', e.target.value)}
                />
                <TextField
                  fullWidth
                  label="Regimen Fiscal"
                  size="small"
                  value={form?.taxRegime ?? ''}
                  onChange={(e) => updateField('taxRegime', e.target.value)}
                />
                <TextField
                  fullWidth
                  select
                  label="Tasa por Defecto"
                  size="small"
                  value={form?.defaultTaxCode ?? ''}
                  onChange={(e) => {
                    const selected = taxOptions.find((tax) => tax.code === e.target.value);
                    updateField('defaultTaxCode', e.target.value);
                    if (selected) {
                      updateField('defaultTaxRate', selected.rate);
                    }
                  }}
                >
                  {taxOptions.map((tax) => (
                    <MenuItem key={tax.code} value={tax.code}>
                      {tax.name} ({(tax.rate * 100).toFixed(2)}%)
                    </MenuItem>
                  ))}
                </TextField>
                <FormControlLabel
                  control={
                    <Switch
                      checked={Boolean(form?.posEnabled)}
                      onChange={(e) => updateField('posEnabled', e.target.checked)}
                    />
                  }
                  label="Aplica a POS"
                />
                <FormControlLabel
                  control={
                    <Switch
                      checked={Boolean(form?.restaurantEnabled)}
                      onChange={(e) => updateField('restaurantEnabled', e.target.checked)}
                    />
                  }
                  label="Aplica a Restaurante"
                />
              </Stack>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} lg={6}>
          <Card>
            <CardHeader title={countryCode === 'VE' ? 'Plugin Fiscal Venezuela' : 'Plugin Fiscal Espana / Verifactu'} />
            <CardContent>
              <Stack spacing={2}>
                {countryCode === 'VE' ? (
                  <>
                    <TextField
                      fullWidth
                      label="RIF Emisor"
                      size="small"
                      value={form?.senderRIF ?? ''}
                      onChange={(e) => updateField('senderRIF', e.target.value)}
                    />
                    <FormControlLabel
                      control={
                        <Switch
                          checked={Boolean(form?.fiscalPrinterEnabled)}
                          onChange={(e) => updateField('fiscalPrinterEnabled', e.target.checked)}
                        />
                      }
                      label="Impresora Fiscal Obligatoria"
                    />
                    <TextField
                      fullWidth
                      label="Marca Impresora Fiscal"
                      size="small"
                      value={form?.printerBrand ?? ''}
                      onChange={(e) => updateField('printerBrand', e.target.value)}
                    />
                    <TextField
                      fullWidth
                      label="Puerto Impresora"
                      size="small"
                      value={form?.printerPort ?? ''}
                      onChange={(e) => updateField('printerPort', e.target.value)}
                    />
                  </>
                ) : (
                  <>
                    <TextField
                      fullWidth
                      label="NIF Emisor"
                      size="small"
                      value={form?.senderNIF ?? ''}
                      onChange={(e) => updateField('senderNIF', e.target.value)}
                    />
                    <FormControlLabel
                      control={
                        <Switch
                          checked={Boolean(form?.verifactuEnabled)}
                          onChange={(e) => updateField('verifactuEnabled', e.target.checked)}
                        />
                      }
                      label="Verifactu Habilitado"
                    />
                    <TextField
                      fullWidth
                      select
                      label="Modo Verifactu"
                      size="small"
                      value={form?.verifactuMode ?? 'manual'}
                      onChange={(e) =>
                        updateField('verifactuMode', (e.target.value as 'auto' | 'manual') ?? 'manual')
                      }
                    >
                      <MenuItem value="manual">manual (sin envio automatico)</MenuItem>
                      <MenuItem value="auto">auto (envio inmediato AEAT)</MenuItem>
                    </TextField>
                    <TextField
                      fullWidth
                      label="Endpoint AEAT"
                      size="small"
                      value={form?.aeatEndpoint ?? ''}
                      onChange={(e) => updateField('aeatEndpoint', e.target.value)}
                      placeholder={knowledgeQuery.data?.verifactu?.testingEndpoint}
                    />
                    <TextField
                      fullWidth
                      label="Certificado (.p12/.pfx) path"
                      size="small"
                      value={form?.certificatePath ?? ''}
                      onChange={(e) => updateField('certificatePath', e.target.value)}
                    />
                    <TextField
                      fullWidth
                      label="Password Certificado"
                      type="password"
                      size="small"
                      value={form?.certificatePassword ?? ''}
                      onChange={(e) => updateField('certificatePassword', e.target.value)}
                    />
                    <TextField
                      fullWidth
                      label="Software ID"
                      size="small"
                      value={form?.softwareId ?? ''}
                      onChange={(e) => updateField('softwareId', e.target.value)}
                    />
                    <TextField
                      fullWidth
                      label="Software Nombre"
                      size="small"
                      value={form?.softwareName ?? ''}
                      onChange={(e) => updateField('softwareName', e.target.value)}
                    />
                    <TextField
                      fullWidth
                      label="Software Version"
                      size="small"
                      value={form?.softwareVersion ?? ''}
                      onChange={(e) => updateField('softwareVersion', e.target.value)}
                    />
                  </>
                )}
              </Stack>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12}>
          <Card>
            <CardHeader title="Tipos de Documento y Cumplimiento" />
            <CardContent>
              <Stack spacing={2}>
                <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
                  {invoiceTypes.map((doc) => (
                    <Chip
                      key={doc.code}
                      label={`${doc.code} - ${doc.name}`}
                      color={doc.isRectificative ? 'warning' : 'default'}
                      variant="outlined"
                    />
                  ))}
                </Box>
                {countryCode === 'ES' && (
                  <Alert severity="info">
                    Para hosteleria/restaurante, el limite de factura simplificada es 3000 EUR IVA incluido segun RD
                    1619/2012 (art. 4). El limite general de simplificada es 400 EUR.
                  </Alert>
                )}
                {countryCode === 'VE' && (
                  <Alert severity="info">
                    En Venezuela el control fiscal operativo se mantiene con impresora fiscal homologada y reporte Z.
                  </Alert>
                )}
              </Stack>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} lg={7}>
          <Card>
            <CardHeader title="Cronograma Normativo y Fuentes Oficiales" />
            <CardContent>
              <Stack spacing={2}>
                {(knowledgeQuery.data?.milestones ?? []).map((item) => (
                  <Box key={item.key} sx={{ p: 1.5, border: '1px solid', borderColor: 'divider', borderRadius: 1 }}>
                    <Typography variant="subtitle2">{item.description}</Typography>
                    <Typography variant="caption" color="textSecondary">
                      Fecha: {item.date}
                    </Typography>
                    <Typography variant="caption" sx={{ display: 'block', wordBreak: 'break-all' }}>
                      Fuente: {item.sourceUrl}
                    </Typography>
                  </Box>
                ))}

                <Divider />

                <Typography variant="subtitle2">Fuentes</Typography>
                {(knowledgeQuery.data?.sources ?? []).map((source) => (
                  <Box key={source.id}>
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>
                      {source.title}
                    </Typography>
                    <Typography variant="caption" color="textSecondary">
                      {source.authority} - {source.type}
                    </Typography>
                    <Typography variant="caption" sx={{ display: 'block', wordBreak: 'break-all' }}>
                      {source.url}
                    </Typography>
                  </Box>
                ))}
              </Stack>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} lg={5}>
          <Card>
            <CardHeader title="Acciones" />
            <CardContent>
              <Stack spacing={2}>
                <Typography variant="body2" color="textSecondary">
                  Pais activo: {countryCode}. Usa este panel para parametrizar el motor fiscal para POS y Restaurante.
                </Typography>
                <Typography variant="body2" color="textSecondary">
                  Estado consulta:{' '}
                  {countriesQuery.isLoading || knowledgeQuery.isLoading || configQuery.isLoading
                    ? 'cargando'
                    : 'listo'}
                </Typography>
                <Button
                  variant="contained"
                  color="primary"
                  onClick={handleSave}
                  disabled={!form || saveMutation.isPending}
                >
                  {saveMutation.isPending ? 'Guardando...' : 'Guardar Configuracion Fiscal'}
                </Button>
              </Stack>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}
