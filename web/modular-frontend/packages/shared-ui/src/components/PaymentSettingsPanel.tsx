'use client';

/**
 * PaymentSettingsPanel — Full payment configuration panel.
 *
 * Combines:
 *  - Provider configuration cards (credentials, environment)
 *  - Accepted payment methods table with channel toggles
 *
 * Embeddable in any micro-frontend: shell/configuracion, pos/settings, restaurante/admin.
 * Filter by country to show only relevant providers.
 */

import React, { useMemo } from 'react';
import { Box, Typography, Alert, Tabs, Tab, CircularProgress, Divider } from '@mui/material';

import {
  usePaymentProviders, usePaymentPlugins,
  useCompanyPaymentConfigs, useSaveCompanyPaymentConfig, useDeleteCompanyPaymentConfig,
  usePaymentMethods, useAcceptedPaymentMethods, useSaveAcceptedPaymentMethod, useRemoveAcceptedPaymentMethod,
} from '@datqbox/shared-api';
import type { PaymentProvider, CompanyPaymentConfig, ConfigField } from '@datqbox/shared-api';

import ProviderConfigCard from './ProviderConfigCard';
import AcceptedMethodsManager from './AcceptedMethodsManager';

interface PaymentSettingsPanelProps {
  empresaId: number;
  sucursalId: number;
  countryCode: string;
  /** Filter which channel toggles are visible. e.g. ['POS'] in POS app, ['RESTAURANT'] in Rest app */
  channels?: ('POS' | 'WEB' | 'RESTAURANT')[];
  /** If true, only show the accepted methods table (no provider config). Useful for non-admin users. */
  methodsOnly?: boolean;
}

export default function PaymentSettingsPanel({
  empresaId, sucursalId, countryCode,
  channels = ['POS', 'WEB', 'RESTAURANT'],
  methodsOnly = false,
}: PaymentSettingsPanelProps) {
  const [tab, setTab] = React.useState(0);

  // Data queries
  const { data: providers = [], isLoading: loadingProviders } = usePaymentProviders(countryCode);
  const { data: plugins = [] } = usePaymentPlugins();
  const { data: configs = [], isLoading: loadingConfigs } = useCompanyPaymentConfigs(empresaId, sucursalId);
  const { data: methods = [] } = usePaymentMethods(countryCode);
  const { data: acceptedMethods = [] } = useAcceptedPaymentMethods(empresaId, sucursalId);

  // Mutations
  const saveConfig = useSaveCompanyPaymentConfig();
  const deleteConfig = useDeleteCompanyPaymentConfig();
  const saveAccepted = useSaveAcceptedPaymentMethod();
  const removeAccepted = useRemoveAcceptedPaymentMethod();

  // Map plugin fields by provider code
  const fieldsMap = useMemo(() => {
    const m = new Map<string, ConfigField[]>();
    plugins.forEach(p => m.set(p.providerCode, p.fields));
    return m;
  }, [plugins]);

  // Map existing configs by providerCode
  const configMap = useMemo(() => {
    const m = new Map<string, CompanyPaymentConfig>();
    configs.forEach(c => m.set(c.providerCode, c));
    return m;
  }, [configs]);

  // Separate VE, ES, Global providers
  const grouped = useMemo(() => {
    const groups: Record<string, PaymentProvider[]> = {};
    providers.forEach(p => {
      const key = p.countryCode || 'GLOBAL';
      if (!groups[key]) groups[key] = [];
      groups[key].push(p);
    });
    return groups;
  }, [providers]);

  const isLoading = loadingProviders || loadingConfigs;

  if (isLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}>
        <CircularProgress />
      </Box>
    );
  }

  const handleSaveConfig = (data: Record<string, unknown>) => {
    saveConfig.mutate(data);
  };

  const handleDeleteConfig = (id: number) => {
    deleteConfig.mutate(id);
  };

  const handleAddAccepted = (data: { paymentMethodId: number; providerId?: number; appliesToPOS: boolean; appliesToWeb: boolean; appliesToRestaurant: boolean }) => {
    saveAccepted.mutate({ ...data, empresaId, sucursalId });
  };

  const handleRemoveAccepted = (id: number) => {
    removeAccepted.mutate(id);
  };

  const handleToggleChannel = (id: number, channel: 'POS' | 'WEB' | 'RESTAURANT', value: boolean) => {
    const existing = acceptedMethods.find(a => a.id === id);
    if (!existing) return;
    saveAccepted.mutate({
      empresaId, sucursalId,
      paymentMethodId: existing.paymentMethodId,
      providerId: existing.providerId,
      appliesToPOS: channel === 'POS' ? value : existing.appliesToPOS,
      appliesToWeb: channel === 'WEB' ? value : existing.appliesToWeb,
      appliesToRestaurant: channel === 'RESTAURANT' ? value : existing.appliesToRestaurant,
    });
  };

  if (methodsOnly) {
    return (
      <AcceptedMethodsManager
        allMethods={methods}
        allProviders={providers}
        acceptedMethods={acceptedMethods}
        channels={channels}
        onAdd={handleAddAccepted}
        onRemove={handleRemoveAccepted}
        onToggleChannel={handleToggleChannel}
      />
    );
  }

  return (
    <Box>
      <Tabs value={tab} onChange={(_, v) => setTab(v)} sx={{ mb: 3, borderBottom: 1, borderColor: 'divider' }}>
        <Tab label="Proveedores / Gateways" />
        <Tab label="Formas de Pago Aceptadas" />
      </Tabs>

      {/* Tab 0: Provider Configuration */}
      {tab === 0 && (
        <Box>
          {Object.entries(grouped).map(([group, provs]) => (
            <Box key={group} sx={{ mb: 4 }}>
              <Typography variant="overline" color="text.secondary" sx={{ mb: 1, display: 'block' }}>
                {group === 'VE' ? '🇻🇪 Venezuela' : group === 'ES' ? '🇪🇸 España' : '🌐 Global / Internacional'}
              </Typography>
              {provs.map((p, index) => (
                <ProviderConfigCard
                  key={`${group}-${p.code}-${index}`}
                  provider={p}
                  existingConfig={configMap.get(p.code)}
                  configFields={fieldsMap.get(p.code) || []}
                  empresaId={empresaId}
                  sucursalId={sucursalId}
                  countryCode={countryCode}
                  onSave={handleSaveConfig}
                  onDelete={handleDeleteConfig}
                  isSaving={saveConfig.isPending}
                />
              ))}
            </Box>
          ))}
          {providers.length === 0 && (
            <Alert severity="info">No hay proveedores disponibles para el país {countryCode}.</Alert>
          )}
        </Box>
      )}

      {/* Tab 1: Accepted Payment Methods */}
      {tab === 1 && (
        <AcceptedMethodsManager
          allMethods={methods}
          allProviders={providers}
          acceptedMethods={acceptedMethods}
          channels={channels}
          onAdd={handleAddAccepted}
          onRemove={handleRemoveAccepted}
          onToggleChannel={handleToggleChannel}
        />
      )}
    </Box>
  );
}
