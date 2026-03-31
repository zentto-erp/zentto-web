'use client';

import React, { useEffect, useMemo, useState } from 'react';
import {
  Alert,
  Box,
  Button,
  CircularProgress,
  FormControl,
  FormControlLabel,
  InputLabel,
  MenuItem,
  Paper,
  Select,
  Stack,
  Switch,
  TextField,
  Typography,
  LinearProgress,
  Chip,
} from '@mui/material';
import { useRouter } from 'next/navigation';
import BusinessIcon from '@mui/icons-material/Business';
import AccountBalanceWalletIcon from '@mui/icons-material/AccountBalanceWallet';
import BadgeIcon from '@mui/icons-material/Badge';
import AccountBalanceIcon from '@mui/icons-material/AccountBalance';
import InventoryIcon from '@mui/icons-material/Inventory';
import PointOfSaleIcon from '@mui/icons-material/PointOfSale';
import RestaurantIcon from '@mui/icons-material/Restaurant';
import ReceiptLongIcon from '@mui/icons-material/ReceiptLong';
import PaymentsIcon from '@mui/icons-material/Payments';
import WorkspacePremiumIcon from '@mui/icons-material/WorkspacePremium';
import PaletteIcon from '@mui/icons-material/Palette';

import { useAuth } from '@zentto/shared-auth';
import { apiPut, useAllSettings, useCountries, useLicenseLimits } from '@zentto/shared-api';
import {
  FormGrid,
  FormField,
  PaymentSettingsPanel,
  SettingsInputGroup,
  SettingsItem,
  SettingsLayout,
  SettingsSection,
} from '@zentto/shared-ui';

type LocalSettings = Record<string, Record<string, any>>;

function deepClone<T>(value: T): T {
  return JSON.parse(JSON.stringify(value));
}

export default function ConfiguracionPage() {
  const router = useRouter();
  const { isAdmin, company, modulos } = useAuth();
  const companyId = company?.companyId ?? 1;
  const branchId = company?.branchId ?? 1;
  const countryCode = company?.countryCode ?? 'VE';

  const { data, isLoading, error, refetch } = useAllSettings(companyId);
  const { data: countries = [] } = useCountries();
  const { data: licenseLimits } = useLicenseLimits();

  const [original, setOriginal] = useState<LocalSettings>({});
  const [draft, setDraft] = useState<LocalSettings>({});
  const [isSaving, setIsSaving] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);

  useEffect(() => {
    if (!data) return;
    const normalized = deepClone(data);
    setOriginal(normalized);
    setDraft(normalized);
  }, [data]);

  const hasChanges = useMemo(
    () => JSON.stringify(draft) !== JSON.stringify(original),
    [draft, original]
  );

  const hasModule = (name: string) => isAdmin || modulos.includes(name);

  const categories = useMemo(() => {
    const items: { id: string; label: string; icon?: React.ReactNode }[] = [
      { id: 'general', label: 'General / Empresa', icon: <BusinessIcon /> },
      { id: 'contabilidad', label: 'Contabilidad', icon: <AccountBalanceWalletIcon /> },
      { id: 'nomina', label: 'Nómina', icon: <BadgeIcon /> },
      { id: 'bancos', label: 'Bancos', icon: <AccountBalanceIcon /> },
      { id: 'inventario', label: 'Inventario', icon: <InventoryIcon /> },
      { id: 'facturacion', label: 'Facturación / Fiscal', icon: <ReceiptLongIcon /> },
      { id: 'pagos', label: 'Formas de Pago', icon: <PaymentsIcon /> },
      { id: 'suscripcion', label: 'Plan y Suscripción', icon: <WorkspacePremiumIcon /> },
      { id: 'branding', label: 'Marca / Personalización', icon: <PaletteIcon /> },
    ];

    if (hasModule('pos')) {
      items.push({ id: 'pos', label: 'Punto de Venta', icon: <PointOfSaleIcon /> });
    }

    if (hasModule('restaurante')) {
      items.push({ id: 'restaurante', label: 'Restaurante', icon: <RestaurantIcon /> });
    }

    return items;
  }, [isAdmin, modulos]);

  const getValue = (moduleName: string, key: string, fallback: unknown) =>
    draft?.[moduleName]?.[key] ?? fallback;

  const setValue = (moduleName: string, key: string, value: unknown) => {
    setDraft((prev) => ({
      ...prev,
      [moduleName]: {
        ...(prev[moduleName] || {}),
        [key]: value,
      },
    }));
  };

  const handleDiscard = () => {
    setSaveError(null);
    setDraft(deepClone(original));
  };

  const handleSave = async () => {
    setIsSaving(true);
    setSaveError(null);

    try {
      const modulesToSave = Object.keys(draft).filter((m) => m !== 'pagos');
      await Promise.all(
        modulesToSave.map((moduleName) =>
          apiPut(`/v1/settings/${moduleName}?companyId=${companyId}`, draft[moduleName] || {})
        )
      );
      await refetch();
    } catch (err: unknown) {
      setSaveError(err instanceof Error ? err.message : 'No fue posible guardar la configuración.');
    } finally {
      setIsSaving(false);
    }
  };

  if (!isAdmin) {
    return (
      <Box sx={{ p: 2 }}>
        <Alert severity="error">
          No tienes permisos para acceder a esta sección. Solo administradores pueden configurar el sistema.
        </Alert>
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
      <Box sx={{ p: 2 }}>
        <Alert severity="error">No se pudo cargar la configuración global.</Alert>
      </Box>
    );
  }

  return (
    <SettingsLayout
      categories={categories}
      hasChanges={hasChanges}
      isSaving={isSaving}
      onDiscard={handleDiscard}
      onSave={handleSave}
    >
      {saveError && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {saveError}
        </Alert>
      )}

      <Typography variant="h5" sx={{ fontWeight: 700, mb: 1 }}>
        Configuración Global del Sistema
      </Typography>
      <Typography variant="body2" color="text.secondary" sx={{ mb: 4 }}>
        Centraliza aquí la configuración de todos los módulos para {company?.companyName || 'la empresa activa'}.
      </Typography>

      <SettingsSection id="general" title="General / Empresa">
        <SettingsItem
          title="Datos generales de operación"
          description="Parámetros base de la empresa y régimen principal del sistema."
          hasCheckbox={false}
        >
          <SettingsInputGroup>
            <TextField
              size="small"
              label="Nombre de la empresa"
              value={getValue('general', 'nombreEmpresa', company?.companyName || 'Mi Empresa, C.A.')}
              onChange={(e) => setValue('general', 'nombreEmpresa', e.target.value)}
              fullWidth
            />
            <FormControl size="small" fullWidth>
              <InputLabel>País / Régimen Fiscal</InputLabel>
              <Select
                label="País / Régimen Fiscal"
                value={getValue('general', 'pais', countryCode)}
                onChange={(e) => setValue('general', 'pais', e.target.value)}
              >
                {countries.map(c => (
                  <MenuItem key={c.CountryCode} value={c.CountryCode}>
                    {c.CountryName}{c.TaxAuthorityCode ? ` (${c.TaxAuthorityCode})` : ''}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            <FormGrid spacing={2}>
              <FormField xs={12} sm={6}>
                <TextField
                  size="small"
                  label="Moneda base"
                  value={getValue('general', 'monedaBase', 'VES')}
                  onChange={(e) => setValue('general', 'monedaBase', e.target.value)}
                  fullWidth
                />
              </FormField>
              <FormField xs={12} sm={6}>
                <TextField
                  size="small"
                  label="Moneda referencia"
                  value={getValue('general', 'monedaReferencia', 'USD')}
                  onChange={(e) => setValue('general', 'monedaReferencia', e.target.value)}
                  fullWidth
                />
              </FormField>
            </FormGrid>
          </SettingsInputGroup>
        </SettingsItem>
      </SettingsSection>

      <SettingsSection id="contabilidad" title="Contabilidad">
        <SettingsItem
          title="Parámetros contables"
          description="Estructura del plan, período fiscal e integración automática."
          hasCheckbox={false}
        >
          <SettingsInputGroup>
            <TextField
              size="small"
              label="Formato plan de cuentas"
              value={getValue('contabilidad', 'formatoPlanCuentas', 'X.X.XX.XX.XX')}
              onChange={(e) => setValue('contabilidad', 'formatoPlanCuentas', e.target.value)}
              fullWidth
            />
            <FormGrid spacing={2}>
              <FormField xs={12} sm={6}>
                <TextField
                  size="small"
                  label="Impuesto principal"
                  value={getValue('contabilidad', 'nombreImpuestoPrincipal', 'IVA')}
                  onChange={(e) => setValue('contabilidad', 'nombreImpuestoPrincipal', e.target.value)}
                  fullWidth
                />
              </FormField>
              <FormField xs={12} sm={6}>
                <TextField
                  size="small"
                  label="Identificación fiscal"
                  value={getValue('contabilidad', 'nombreIdentificacion', 'RIF')}
                  onChange={(e) => setValue('contabilidad', 'nombreIdentificacion', e.target.value)}
                  fullWidth
                />
              </FormField>
            </FormGrid>
            <FormGrid spacing={2}>
              <FormField xs={12} sm={6}>
                <FormControl size="small" fullWidth>
                  <InputLabel>Mes inicio fiscal</InputLabel>
                  <Select
                    label="Mes inicio fiscal"
                    value={Number(getValue('contabilidad', 'periodoFiscalStartMonth', 1))}
                    onChange={(e) => setValue('contabilidad', 'periodoFiscalStartMonth', Number(e.target.value))}
                  >
                    {Array.from({ length: 12 }).map((_, idx) => (
                      <MenuItem key={idx + 1} value={idx + 1}>{idx + 1}</MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </FormField>
              <FormField xs={12} sm={6}>
                <FormControl size="small" fullWidth>
                  <InputLabel>Cierre anual</InputLabel>
                  <Select
                    label="Cierre anual"
                    value={getValue('contabilidad', 'periodoFiscalCloseYearBehavior', 'soft')}
                    onChange={(e) => setValue('contabilidad', 'periodoFiscalCloseYearBehavior', e.target.value)}
                  >
                    <MenuItem value="soft">Soft</MenuItem>
                    <MenuItem value="hard">Hard</MenuItem>
                  </Select>
                </FormControl>
              </FormField>
            </FormGrid>
            <FormControlLabel
              control={
                <Switch
                  checked={Boolean(getValue('contabilidad', 'asientoAutomaticoVentas', true))}
                  onChange={(e) => setValue('contabilidad', 'asientoAutomaticoVentas', e.target.checked)}
                />
              }
              label="Generar asiento automático en ventas"
            />
            <FormControlLabel
              control={
                <Switch
                  checked={Boolean(getValue('contabilidad', 'asientoAutomaticoCompras', true))}
                  onChange={(e) => setValue('contabilidad', 'asientoAutomaticoCompras', e.target.checked)}
                />
              }
              label="Generar asiento automático en compras"
            />
            <FormControlLabel
              control={
                <Switch
                  checked={Boolean(getValue('contabilidad', 'integracionContable', true))}
                  onChange={(e) => setValue('contabilidad', 'integracionContable', e.target.checked)}
                />
              }
              label="Integración contable activa"
            />
          </SettingsInputGroup>
        </SettingsItem>
      </SettingsSection>

      <SettingsSection id="nomina" title="Nómina">
        <SettingsItem
          title="Política de pagos y deducciones"
          description="Configura la frecuencia de pago y deducciones legales."
          hasCheckbox={false}
        >
          <SettingsInputGroup>
            <FormControl size="small" fullWidth>
              <InputLabel>Frecuencia de pago</InputLabel>
              <Select
                label="Frecuencia de pago"
                value={getValue('nomina', 'periodoPago', 'quincenal')}
                onChange={(e) => setValue('nomina', 'periodoPago', e.target.value)}
              >
                <MenuItem value="semanal">Semanal</MenuItem>
                <MenuItem value="quincenal">Quincenal</MenuItem>
                <MenuItem value="mensual">Mensual</MenuItem>
              </Select>
            </FormControl>
            <FormControlLabel
              control={
                <Switch
                  checked={Boolean(getValue('nomina', 'aplicaISR', true))}
                  onChange={(e) => setValue('nomina', 'aplicaISR', e.target.checked)}
                />
              }
              label="Aplicar ISR / ISLR"
            />
            <FormControlLabel
              control={
                <Switch
                  checked={Boolean(getValue('nomina', 'aplicaSeguroSocial', true))}
                  onChange={(e) => setValue('nomina', 'aplicaSeguroSocial', e.target.checked)}
                />
              }
              label="Aplicar Seguro Social"
            />
            <FormControlLabel
              control={
                <Switch
                  checked={Boolean(getValue('nomina', 'aplicaParoForzoso', true))}
                  onChange={(e) => setValue('nomina', 'aplicaParoForzoso', e.target.checked)}
                />
              }
              label="Aplicar Paro Forzoso"
            />
          </SettingsInputGroup>
        </SettingsItem>
      </SettingsSection>

      <SettingsSection id="bancos" title="Bancos">
        <SettingsItem
          title="Parámetros bancarios"
          description="Precisión, formatos de conciliación y gateway por defecto."
          hasCheckbox={false}
        >
          <SettingsInputGroup>
            <TextField
              size="small"
              label="Precisión bancaria"
              type="number"
              value={Number(getValue('bancos', 'precisionBancaria', 2))}
              onChange={(e) => setValue('bancos', 'precisionBancaria', Number(e.target.value))}
              fullWidth
            />
            <FormControl size="small" fullWidth>
              <InputLabel>Formato exportación</InputLabel>
              <Select
                label="Formato exportación"
                value={getValue('bancos', 'formatoExportacion', 'csv')}
                onChange={(e) => setValue('bancos', 'formatoExportacion', e.target.value)}
              >
                <MenuItem value="csv">CSV</MenuItem>
                <MenuItem value="mt940">MT940</MenuItem>
                <MenuItem value="qbo">QBO</MenuItem>
              </Select>
            </FormControl>
            <TextField
              size="small"
              label="Gateway por defecto"
              value={getValue('bancos', 'defaultGateway', '')}
              onChange={(e) => setValue('bancos', 'defaultGateway', e.target.value)}
              fullWidth
            />
          </SettingsInputGroup>
        </SettingsItem>
      </SettingsSection>

      <SettingsSection id="inventario" title="Inventario">
        <SettingsItem
          title="Políticas de inventario"
          description="Costeo, stock negativo y lotes con vencimiento."
          hasCheckbox={false}
        >
          <SettingsInputGroup>
            <FormControl size="small" fullWidth>
              <InputLabel>Método costeo</InputLabel>
              <Select
                label="Método costeo"
                value={getValue('inventario', 'metodoCosteo', 'PROMEDIO')}
                onChange={(e) => setValue('inventario', 'metodoCosteo', e.target.value)}
              >
                <MenuItem value="PROMEDIO">Promedio</MenuItem>
                <MenuItem value="FIFO">FIFO</MenuItem>
                <MenuItem value="LIFO">LIFO</MenuItem>
              </Select>
            </FormControl>
            <FormControlLabel
              control={
                <Switch
                  checked={Boolean(getValue('inventario', 'permitirStockNegativo', false))}
                  onChange={(e) => setValue('inventario', 'permitirStockNegativo', e.target.checked)}
                />
              }
              label="Permitir stock negativo"
            />
            <FormControlLabel
              control={
                <Switch
                  checked={Boolean(getValue('inventario', 'manejarLotesYVencimiento', true))}
                  onChange={(e) => setValue('inventario', 'manejarLotesYVencimiento', e.target.checked)}
                />
              }
              label="Manejar lotes y vencimientos"
            />
          </SettingsInputGroup>
        </SettingsItem>
      </SettingsSection>

      <SettingsSection id="facturacion" title="Facturación / Fiscal">
        <SettingsItem
          title="Reglas de facturación"
          description="Comportamiento de correlativos, descuentos y salida impresa."
          hasCheckbox={false}
        >
          <SettingsInputGroup>
            <FormControlLabel
              control={
                <Switch
                  checked={Boolean(getValue('facturacion', 'correlativosAutomaticos', true))}
                  onChange={(e) => setValue('facturacion', 'correlativosAutomaticos', e.target.checked)}
                />
              }
              label="Correlativos automáticos"
            />
            <FormGrid spacing={2}>
              <FormField xs={12} sm={6}>
                <TextField
                  size="small"
                  label="Formato impresión"
                  value={getValue('facturacion', 'formatoImpresion', 'carta')}
                  onChange={(e) => setValue('facturacion', 'formatoImpresion', e.target.value)}
                  fullWidth
                />
              </FormField>
              <FormField xs={12} sm={6}>
                <TextField
                  size="small"
                  label="Copias por defecto"
                  type="number"
                  value={Number(getValue('facturacion', 'copiasPorDefecto', 1))}
                  onChange={(e) => setValue('facturacion', 'copiasPorDefecto', Number(e.target.value))}
                  fullWidth
                />
              </FormField>
            </FormGrid>
            <FormControlLabel
              control={
                <Switch
                  checked={Boolean(getValue('facturacion', 'permitirDescuento', true))}
                  onChange={(e) => setValue('facturacion', 'permitirDescuento', e.target.checked)}
                />
              }
              label="Permitir descuentos"
            />
            <TextField
              size="small"
              label="Descuento máximo (%)"
              type="number"
              value={Number(getValue('facturacion', 'descuentoMaximoPct', 20))}
              onChange={(e) => setValue('facturacion', 'descuentoMaximoPct', Number(e.target.value))}
              fullWidth
            />
          </SettingsInputGroup>
        </SettingsItem>
      </SettingsSection>

      {hasModule('pos') && (
        <SettingsSection id="pos" title="Punto de Venta">
          <SettingsItem
            title="Caja e impresora fiscal"
            description="Parámetros operativos por defecto para POS."
            hasCheckbox={false}
          >
            <SettingsInputGroup>
              <FormGrid spacing={2}>
                <FormField xs={12} sm={6}>
                  <TextField
                    size="small"
                    label="Caja ID"
                    value={getValue('pos', 'caja.id', '1')}
                    onChange={(e) => setValue('pos', 'caja.id', e.target.value)}
                    fullWidth
                  />
                </FormField>
                <FormField xs={12} sm={6}>
                  <TextField
                    size="small"
                    label="Nombre caja"
                    value={getValue('pos', 'caja.nombre', 'Caja Principal')}
                    onChange={(e) => setValue('pos', 'caja.nombre', e.target.value)}
                    fullWidth
                  />
                </FormField>
                <FormField xs={12} sm={6}>
                  <TextField
                    size="small"
                    label="Serie factura"
                    value={getValue('pos', 'caja.serieFactura', 'A')}
                    onChange={(e) => setValue('pos', 'caja.serieFactura', e.target.value)}
                    fullWidth
                  />
                </FormField>
                <FormField xs={12} sm={6}>
                  <TextField
                    size="small"
                    label="Almacén ID"
                    value={getValue('pos', 'caja.almacenId', '1')}
                    onChange={(e) => setValue('pos', 'caja.almacenId', e.target.value)}
                    fullWidth
                  />
                </FormField>
                <FormField xs={12} sm={6}>
                  <TextField
                    size="small"
                    label="Marca impresora"
                    value={getValue('pos', 'impresora.marca', 'PNP')}
                    onChange={(e) => setValue('pos', 'impresora.marca', e.target.value)}
                    fullWidth
                  />
                </FormField>
                <FormField xs={12} sm={6}>
                  <TextField
                    size="small"
                    label="Conexión"
                    value={getValue('pos', 'impresora.conexion', 'emulador')}
                    onChange={(e) => setValue('pos', 'impresora.conexion', e.target.value)}
                    fullWidth
                  />
                </FormField>
                <FormField xs={12}>
                  <TextField
                    size="small"
                    label="Agent URL"
                    value={getValue('pos', 'impresora.agentUrl', 'http://localhost:7654')}
                    onChange={(e) => setValue('pos', 'impresora.agentUrl', e.target.value)}
                    fullWidth
                  />
                </FormField>
              </FormGrid>
            </SettingsInputGroup>
          </SettingsItem>
        </SettingsSection>
      )}

      {hasModule('restaurante') && (
        <SettingsSection id="restaurante" title="Restaurante">
          <SettingsItem
            title="Políticas operativas del restaurante"
            description="Reglas para comanda, pedidos sin mesa y tiempos de cocina."
            hasCheckbox={false}
          >
            <SettingsInputGroup>
              <FormControlLabel
                control={
                  <Switch
                    checked={Boolean(getValue('restaurante', 'habilitado', true))}
                    onChange={(e) => setValue('restaurante', 'habilitado', e.target.checked)}
                  />
                }
                label="Módulo restaurante habilitado"
              />
              <FormControlLabel
                control={
                  <Switch
                    checked={Boolean(getValue('restaurante', 'imprimirComandaCocina', true))}
                    onChange={(e) => setValue('restaurante', 'imprimirComandaCocina', e.target.checked)}
                  />
                }
                label="Imprimir comanda en cocina"
              />
              <FormControlLabel
                control={
                  <Switch
                    checked={Boolean(getValue('restaurante', 'permitirPedidoSinMesa', false))}
                    onChange={(e) => setValue('restaurante', 'permitirPedidoSinMesa', e.target.checked)}
                  />
                }
                label="Permitir pedido sin mesa"
              />
              <FormGrid spacing={2}>
                <FormField xs={12} sm={6}>
                  <TextField
                    size="small"
                    type="number"
                    label="Alerta preparación (min)"
                    value={Number(getValue('restaurante', 'tiempoAlertaPreparacion', 15))}
                    onChange={(e) => setValue('restaurante', 'tiempoAlertaPreparacion', Number(e.target.value))}
                    fullWidth
                  />
                </FormField>
                <FormField xs={12} sm={6}>
                  <TextField
                    size="small"
                    type="number"
                    label="Propina sugerida (%)"
                    value={Number(getValue('restaurante', 'propinaSugeridaPct', 10))}
                    onChange={(e) => setValue('restaurante', 'propinaSugeridaPct', Number(e.target.value))}
                    fullWidth
                  />
                </FormField>
              </FormGrid>
            </SettingsInputGroup>
          </SettingsItem>
        </SettingsSection>
      )}

      <SettingsSection id="pagos" title="Formas de Pago">
        <Box sx={{ gridColumn: '1 / -1' }}>
          <PaymentSettingsPanel
            empresaId={companyId}
            sucursalId={branchId}
            countryCode={countryCode}
            channels={['POS', 'WEB', 'RESTAURANT']}
          />
        </Box>
      </SettingsSection>

      <SettingsSection id="suscripcion" title="Plan y Suscripción">
        <Box sx={{ gridColumn: '1 / -1' }}>
          <Paper
            variant="outlined"
            sx={{
              p: 3,
              borderRadius: 2,
              background: 'linear-gradient(135deg, #131921 0%, #232f3e 100%)',
              color: '#fff',
            }}
          >
            <Stack direction={{ xs: 'column', sm: 'row' }} alignItems={{ sm: 'center' }} spacing={3}>
              <WorkspacePremiumIcon sx={{ fontSize: 48, color: '#ff9900', flexShrink: 0 }} />
              <Box flex={1}>
                <Typography variant="h6" fontWeight={700} gutterBottom>
                  Gestiona tu suscripción Zentto
                </Typography>
                <Typography variant="body2" sx={{ opacity: 0.85 }}>
                  Actualiza tu plan, cambia de Básico a Profesional o administra tu método de pago en cualquier momento.
                </Typography>
              </Box>
              <Button
                variant="contained"
                size="large"
                onClick={() => router.push('/pricing')}
                sx={{
                  bgcolor: '#ff9900',
                  color: '#131921',
                  fontWeight: 700,
                  whiteSpace: 'nowrap',
                  flexShrink: 0,
                  '&:hover': { bgcolor: '#e68a00' },
                }}
              >
                Ver planes
              </Button>
            </Stack>
          </Paper>

          {/* License limits display */}
          {licenseLimits && (
            <Paper variant="outlined" sx={{ p: 3, borderRadius: 2, mt: 2 }}>
              <Stack spacing={2.5}>
                <Stack direction="row" alignItems="center" spacing={1.5}>
                  <Typography variant="subtitle1" fontWeight={700}>Plan actual:</Typography>
                  <Chip
                    label={licenseLimits.plan || 'FREE'}
                    color={
                      licenseLimits.plan === 'ENTERPRISE' ? 'secondary'
                        : licenseLimits.plan === 'PRO' ? 'primary'
                        : licenseLimits.plan === 'STARTER' ? 'info'
                        : 'default'
                    }
                    sx={{ fontWeight: 700 }}
                  />
                </Stack>

                <Box>
                  <Stack direction="row" justifyContent="space-between" sx={{ mb: 0.5 }}>
                    <Typography variant="body2" fontWeight={600}>Usuarios</Typography>
                    <Typography variant="body2" color="text.secondary">
                      {licenseLimits.currentUsers} de {licenseLimits.maxUsers === -1 ? 'Ilimitados' : licenseLimits.maxUsers}
                    </Typography>
                  </Stack>
                  <LinearProgress
                    variant="determinate"
                    value={licenseLimits.maxUsers === -1 ? 0 : Math.min((licenseLimits.currentUsers / licenseLimits.maxUsers) * 100, 100)}
                    sx={{ height: 8, borderRadius: 4 }}
                    color={
                      licenseLimits.maxUsers !== -1 && (licenseLimits.currentUsers / licenseLimits.maxUsers) > 0.9
                        ? 'error' : 'primary'
                    }
                  />
                </Box>

                <Box>
                  <Stack direction="row" justifyContent="space-between" sx={{ mb: 0.5 }}>
                    <Typography variant="body2" fontWeight={600}>Empresas</Typography>
                    <Typography variant="body2" color="text.secondary">
                      {licenseLimits.currentCompanies} de {licenseLimits.maxCompanies === -1 ? 'Ilimitadas' : licenseLimits.maxCompanies}
                    </Typography>
                  </Stack>
                  <LinearProgress
                    variant="determinate"
                    value={licenseLimits.maxCompanies === -1 ? 0 : Math.min((licenseLimits.currentCompanies / licenseLimits.maxCompanies) * 100, 100)}
                    sx={{ height: 8, borderRadius: 4 }}
                    color={
                      licenseLimits.maxCompanies !== -1 && (licenseLimits.currentCompanies / licenseLimits.maxCompanies) > 0.9
                        ? 'error' : 'primary'
                    }
                  />
                </Box>

                <Stack direction="row" alignItems="center" spacing={1}>
                  <Typography variant="body2" fontWeight={600}>Multi-empresa:</Typography>
                  <Chip
                    label={licenseLimits.multiCompany ? 'Si' : 'No'}
                    size="small"
                    color={licenseLimits.multiCompany ? 'success' : 'default'}
                    variant="outlined"
                  />
                </Stack>
              </Stack>
            </Paper>
          )}
        </Box>
      </SettingsSection>

      {/* ── Branding / Personalización de marca ── */}
      <SettingsSection id="branding" title="Marca / Personalización">
        <SettingsItem
          title="Colores de marca"
          description="Personaliza los colores principales de la interfaz para tu empresa. Al guardar, todos los módulos reflejarán los cambios."
          hasCheckbox={false}
        >
          <SettingsInputGroup>
            <FormGrid spacing={2}>
              <FormField xs={12} sm={4}>
                <Stack spacing={1}>
                  <Typography variant="caption" fontWeight={600}>Color primario</Typography>
                  <Stack direction="row" spacing={1} alignItems="center">
                    <input
                      type="color"
                      value={String(getValue('branding', 'primaryColor', '#ff9900'))}
                      onChange={(e) => setValue('branding', 'primaryColor', e.target.value)}
                      style={{ width: 48, height: 36, border: 'none', cursor: 'pointer', borderRadius: 4 }}
                    />
                    <TextField
                      size="small"
                      value={getValue('branding', 'primaryColor', '#ff9900')}
                      onChange={(e) => setValue('branding', 'primaryColor', e.target.value)}
                      sx={{ maxWidth: 120 }}
                    />
                  </Stack>
                </Stack>
              </FormField>
              <FormField xs={12} sm={4}>
                <Stack spacing={1}>
                  <Typography variant="caption" fontWeight={600}>Color secundario (sidebar)</Typography>
                  <Stack direction="row" spacing={1} alignItems="center">
                    <input
                      type="color"
                      value={String(getValue('branding', 'secondaryColor', '#232f3e'))}
                      onChange={(e) => setValue('branding', 'secondaryColor', e.target.value)}
                      style={{ width: 48, height: 36, border: 'none', cursor: 'pointer', borderRadius: 4 }}
                    />
                    <TextField
                      size="small"
                      value={getValue('branding', 'secondaryColor', '#232f3e')}
                      onChange={(e) => setValue('branding', 'secondaryColor', e.target.value)}
                      sx={{ maxWidth: 120 }}
                    />
                  </Stack>
                </Stack>
              </FormField>
              <FormField xs={12} sm={4}>
                <Stack spacing={1}>
                  <Typography variant="caption" fontWeight={600}>Color accent</Typography>
                  <Stack direction="row" spacing={1} alignItems="center">
                    <input
                      type="color"
                      value={String(getValue('branding', 'accentColor', '#ff9900'))}
                      onChange={(e) => setValue('branding', 'accentColor', e.target.value)}
                      style={{ width: 48, height: 36, border: 'none', cursor: 'pointer', borderRadius: 4 }}
                    />
                    <TextField
                      size="small"
                      value={getValue('branding', 'accentColor', '#ff9900')}
                      onChange={(e) => setValue('branding', 'accentColor', e.target.value)}
                      sx={{ maxWidth: 120 }}
                    />
                  </Stack>
                </Stack>
              </FormField>
            </FormGrid>
          </SettingsInputGroup>
        </SettingsItem>

        <SettingsItem
          title="Identidad visual"
          description="Cambia el nombre, subtítulo y logo que se muestra en el sidebar y login."
          hasCheckbox={false}
        >
          <SettingsInputGroup>
            <TextField
              size="small"
              label="Nombre de la aplicación"
              placeholder="ZENTTO"
              value={getValue('branding', 'appName', '')}
              onChange={(e) => setValue('branding', 'appName', e.target.value)}
              helperText="Vacío = ZENTTO (predeterminado)"
              fullWidth
            />
            <TextField
              size="small"
              label="Subtítulo"
              placeholder="Sistema Administrador"
              value={getValue('branding', 'appSubtitle', '')}
              onChange={(e) => setValue('branding', 'appSubtitle', e.target.value)}
              helperText="Vacío = Sistema Administrador (predeterminado)"
              fullWidth
            />
            <TextField
              size="small"
              label="URL del logo"
              placeholder="https://miempresa.com/logo.svg"
              value={getValue('branding', 'logoUrl', '')}
              onChange={(e) => setValue('branding', 'logoUrl', e.target.value)}
              helperText="URL pública de tu logo (SVG o PNG). Vacío = logo Zentto."
              fullWidth
            />
            {getValue('branding', 'logoUrl', '') && (
              <Paper variant="outlined" sx={{ p: 2, display: 'flex', alignItems: 'center', gap: 2 }}>
                <Box
                  component="img"
                  src={String(getValue('branding', 'logoUrl', ''))}
                  alt="Preview"
                  sx={{ width: 48, height: 48, objectFit: 'contain', borderRadius: 1 }}
                />
                <Typography variant="caption" color="text.secondary">Vista previa del logo</Typography>
              </Paper>
            )}
          </SettingsInputGroup>
        </SettingsItem>

        <SettingsItem
          title="Vista previa"
          description="Así se verá el sidebar con tu marca personalizada."
          hasCheckbox={false}
        >
          <Paper
            variant="outlined"
            sx={{
              p: 2,
              background: String(getValue('branding', 'secondaryColor', '#232f3e')) || '#232f3e',
              borderRadius: 2,
              maxWidth: 280,
            }}
          >
            <Stack direction="row" spacing={1.5} alignItems="center" sx={{ mb: 2 }}>
              <Box sx={{
                width: 36, height: 36, borderRadius: '50%',
                background: `linear-gradient(135deg, ${getValue('branding', 'primaryColor', '#ff9900')}, ${getValue('branding', 'accentColor', '#ff9900')})`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                {getValue('branding', 'logoUrl', '') ? (
                  <Box component="img" src={String(getValue('branding', 'logoUrl', ''))} sx={{ width: 28, height: 28, objectFit: 'contain' }} />
                ) : (
                  <Typography sx={{ color: '#fff', fontWeight: 800, fontSize: 16 }}>Z</Typography>
                )}
              </Box>
              <Box>
                <Typography sx={{ color: '#fff', fontWeight: 800, fontSize: '0.85rem', letterSpacing: '0.1em' }}>
                  {String(getValue('branding', 'appName', '')) || 'ZENTTO'}
                </Typography>
                <Typography sx={{ color: 'rgba(255,255,255,0.5)', fontSize: '0.6rem', fontWeight: 600 }}>
                  {String(getValue('branding', 'appSubtitle', '')) || 'Sistema Administrador'}
                </Typography>
              </Box>
            </Stack>
            {['Dashboard', 'Contabilidad', 'Ventas', 'Inventario'].map((item, i) => (
              <Box
                key={item}
                sx={{
                  py: 0.75, px: 1.5, mb: 0.5, borderRadius: 1,
                  bgcolor: i === 0 ? `${getValue('branding', 'accentColor', '#ff9900')}25` : 'transparent',
                  borderLeft: i === 0 ? `3px solid ${getValue('branding', 'accentColor', '#ff9900')}` : '3px solid transparent',
                }}
              >
                <Typography sx={{ color: i === 0 ? '#fff' : 'rgba(255,255,255,0.6)', fontSize: '0.8rem', fontWeight: i === 0 ? 600 : 400 }}>
                  {item}
                </Typography>
              </Box>
            ))}
            <Box sx={{ mt: 2, pt: 1, borderTop: '1px solid rgba(255,255,255,0.1)' }}>
              <Typography sx={{ color: 'rgba(255,255,255,0.4)', fontSize: '0.65rem', textAlign: 'center' }}>
                Powered by Zentto
              </Typography>
            </Box>
          </Paper>
        </SettingsItem>

        <Box>
          <Button
            variant="outlined"
            size="small"
            color="warning"
            onClick={() => {
              setValue('branding', 'primaryColor', '#ff9900');
              setValue('branding', 'primaryDark', '#e68a00');
              setValue('branding', 'secondaryColor', '#232f3e');
              setValue('branding', 'secondaryDark', '#131921');
              setValue('branding', 'accentColor', '#ff9900');
              setValue('branding', 'appName', '');
              setValue('branding', 'appSubtitle', '');
              setValue('branding', 'logoUrl', '');
            }}
          >
            Restaurar colores predeterminados
          </Button>
        </Box>
      </SettingsSection>
    </SettingsLayout>
  );
}
