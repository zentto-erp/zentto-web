'use client';

/**
 * ProviderConfigCard — Configures a single payment provider for a company.
 *
 * Shows the provider name, status badge, dynamic fields from the plugin registry,
 * and allows saving credentials. Used in shell configuración and embeddable in POS/Restaurante.
 */

import React, { useState, useEffect } from 'react';
import {
  Card, CardContent, CardHeader, CardActions,
  TextField, Button, Stack, Chip, IconButton,
  FormControl, InputLabel, Select, MenuItem,
  Switch, FormControlLabel, Collapse, Tooltip,
  Typography, Box, Alert,
} from '@mui/material';
import type { ChipProps } from '@mui/material/Chip';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import DeleteIcon from '@mui/icons-material/Delete';
import OpenInNewIcon from '@mui/icons-material/OpenInNew';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import PendingIcon from '@mui/icons-material/Pending';

import type { CompanyPaymentConfig, ConfigField, PaymentProvider } from '@datqbox/shared-api';

interface ProviderConfigCardProps {
  provider: PaymentProvider;
  existingConfig?: CompanyPaymentConfig;
  configFields: ConfigField[];
  empresaId: number;
  sucursalId: number;
  countryCode: string;
  onSave: (data: Record<string, unknown>) => void;
  onDelete?: (id: number) => void;
  isSaving?: boolean;
}

export default function ProviderConfigCard({
  provider, existingConfig, configFields, empresaId, sucursalId, countryCode,
  onSave, onDelete, isSaving,
}: ProviderConfigCardProps) {
  const [expanded, setExpanded] = useState(!existingConfig);
  const [values, setValues] = useState<Record<string, unknown>>({});

  useEffect(() => {
    if (existingConfig) {
      setValues({
        clientId: existingConfig.clientId || '',
        clientSecret: existingConfig.clientSecret || '',
        merchantId: existingConfig.merchantId || '',
        terminalId: existingConfig.terminalId || '',
        integratorId: existingConfig.integratorId || '',
        environment: existingConfig.environment || 'sandbox',
        autoCapture: existingConfig.autoCapture,
        allowRefunds: existingConfig.allowRefunds,
        maxRefundDays: existingConfig.maxRefundDays,
        ...(existingConfig.extraConfig || {}),
      });
    } else {
      const defaults: Record<string, unknown> = { environment: 'sandbox', autoCapture: true, allowRefunds: true, maxRefundDays: 30 };
      configFields.forEach(f => { if (!defaults[f.key]) defaults[f.key] = ''; });
      setValues(defaults);
    }
  }, [existingConfig, configFields]);

  const handleSave = () => {
    const { environment, autoCapture, allowRefunds, maxRefundDays, clientId, clientSecret, merchantId, terminalId, integratorId, ...extra } = values;
    onSave({
      empresaId, sucursalId, countryCode,
      providerCode: provider.code,
      environment, autoCapture, allowRefunds, maxRefundDays,
      clientId, clientSecret, merchantId, terminalId, integratorId,
      extraConfig: Object.keys(extra).length ? extra : undefined,
    });
  };

  const isConfigured = !!existingConfig;
  const statusColor: ChipProps['color'] = isConfigured
    ? existingConfig?.environment === 'production' ? 'success' : 'warning'
    : 'default';
  const statusLabel = isConfigured
    ? existingConfig?.environment === 'production' ? 'Producción' : 'Sandbox'
    : 'Sin configurar';

  return (
    <Card variant="outlined" sx={{ mb: 2 }}>
      <CardHeader
        title={
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Typography variant="subtitle1" fontWeight={600}>{provider.name}</Typography>
            <Chip
              label={statusLabel}
              color={statusColor}
              size="small"
              icon={isConfigured ? <CheckCircleIcon /> : <PendingIcon />}
            />
            {provider.countryCode && (
              <Chip label={provider.countryCode} size="small" variant="outlined" />
            )}
          </Box>
        }
        subheader={provider.providerType?.replace(/_/g, ' ')}
        action={
          <Box>
            {provider.docsUrl && (
              <Tooltip title="Documentación del proveedor">
                <IconButton size="small" href={provider.docsUrl} target="_blank">
                  <OpenInNewIcon fontSize="small" />
                </IconButton>
              </Tooltip>
            )}
            <IconButton onClick={() => setExpanded(!expanded)} size="small">
              <ExpandMoreIcon sx={{ transform: expanded ? 'rotate(180deg)' : 'none', transition: '0.3s' }} />
            </IconButton>
          </Box>
        }
      />
      <Collapse in={expanded}>
        <CardContent>
          <Stack spacing={2}>
            {/* Environment selector */}
            <FormControl fullWidth size="small">
              <InputLabel>Ambiente</InputLabel>
              <Select
                value={values.environment || 'sandbox'}
                label="Ambiente"
                onChange={e => setValues({ ...values, environment: e.target.value })}
              >
                <MenuItem value="sandbox">Sandbox (Pruebas)</MenuItem>
                <MenuItem value="production">Producción</MenuItem>
              </Select>
            </FormControl>

            {/* Dynamic config fields from plugin */}
            {configFields.map(field => {
              if (field.type === 'boolean') {
                return (
                  <FormControlLabel key={field.key}
                    control={
                      <Switch checked={!!values[field.key]}
                        onChange={e => setValues({ ...values, [field.key]: e.target.checked })}
                      />
                    }
                    label={field.label}
                  />
                );
              }
              if (field.type === 'select' && field.options) {
                return (
                  <FormControl key={field.key} fullWidth size="small">
                    <InputLabel>{field.label}</InputLabel>
                    <Select
                      value={values[field.key] || ''}
                      label={field.label}
                      onChange={e => setValues({ ...values, [field.key]: e.target.value })}
                    >
                      {field.options.map(o => (
                        <MenuItem key={o.value} value={o.value}>{o.label}</MenuItem>
                      ))}
                    </Select>
                  </FormControl>
                );
              }
              return (
                <TextField key={field.key}
                  fullWidth size="small"
                  label={field.label}
                  placeholder={field.placeholder}
                  helperText={field.helpText}
                  type={field.type === 'password' ? 'password' : 'text'}
                  value={values[field.key] || ''}
                  onChange={e => setValues({ ...values, [field.key]: e.target.value })}
                  required={field.required}
                />
              );
            })}

            {/* Common settings */}
            <FormControlLabel
              control={<Switch checked={!!values.autoCapture} onChange={e => setValues({ ...values, autoCapture: e.target.checked })} />}
              label="Auto-captura de pagos"
            />
            <FormControlLabel
              control={<Switch checked={!!values.allowRefunds} onChange={e => setValues({ ...values, allowRefunds: e.target.checked })} />}
              label="Permitir reembolsos"
            />
            <TextField
              fullWidth size="small" type="number"
              label="Máx. días para reembolso"
              value={values.maxRefundDays || 30}
              onChange={e => setValues({ ...values, maxRefundDays: Number(e.target.value) })}
            />

            {!configFields.length && (
              <Alert severity="info" variant="outlined">
                Este proveedor no requiere credenciales (opera en modo manual/offline).
              </Alert>
            )}
          </Stack>
        </CardContent>
        <CardActions sx={{ px: 2, pb: 2, justifyContent: 'space-between' }}>
          <Button variant="contained" onClick={handleSave} disabled={isSaving}>
            {isSaving ? 'Guardando...' : isConfigured ? 'Actualizar' : 'Configurar'}
          </Button>
          {isConfigured && onDelete && (
            <IconButton color="error" onClick={() => onDelete(existingConfig!.id)}>
              <DeleteIcon />
            </IconButton>
          )}
        </CardActions>
      </Collapse>
    </Card>
  );
}
