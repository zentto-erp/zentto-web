'use client';

/**
 * Configuración > Formas de Pago — Shell (Admin global)
 *
 * Full payment gateway configuration: providers, credentials, accepted methods.
 * Uses PaymentSettingsPanel from shared-ui.
 */

import React from 'react';
import { Box, Typography, Alert } from '@mui/material';
import { useAuth } from '@zentto/shared-auth';
import { PaymentSettingsPanel } from '@zentto/shared-ui';

export default function FormasDePagoPage() {
  const { isAdmin, company } = useAuth();

  if (!isAdmin) {
    return (
      <Box sx={{ p: 3 }}>
        <Alert severity="error">
          Solo administradores pueden configurar las formas de pago.
        </Alert>
      </Box>
    );
  }

  if (!company) {
    return (
      <Box sx={{ p: 3 }}>
        <Alert severity="warning">
          No se ha seleccionado una empresa activa. Selecciona una empresa para configurar sus formas de pago.
        </Alert>
      </Box>
    );
  }

  return (
    <Box sx={{ p: { xs: 2, md: 3 }, maxWidth: 1200 }}>
      <Typography variant="h5" fontWeight={700} sx={{ mb: 0.5 }}>
        Formas de Pago
      </Typography>
      <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
        Configura los proveedores de pago (bancos, gateways, crypto) y las formas de pago aceptadas
        para <strong>{company.companyName}</strong> — Sucursal: {company.branchName || 'Principal'}
      </Typography>

      <PaymentSettingsPanel
        empresaId={company.companyId}
        sucursalId={company.branchId}
        countryCode={company.countryCode}
        channels={['POS', 'WEB', 'RESTAURANT']}
      />
    </Box>
  );
}
