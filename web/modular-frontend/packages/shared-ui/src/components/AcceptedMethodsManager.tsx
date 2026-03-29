'use client';

/**
 * AcceptedMethodsManager — Configure which payment methods a company/branch accepts.
 *
 * Shows all available methods with toggles for POS, Web, Restaurant channels.
 * Reusable across shell configuración and individual app settings pages.
 */

import React from 'react';
import {
  Box, Typography, Chip, Switch, IconButton, Tooltip,
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow,
  Paper, Button,
} from '@mui/material';
import DeleteIcon from '@mui/icons-material/Delete';
import AddIcon from '@mui/icons-material/Add';

import type { PaymentMethod, AcceptedPaymentMethod, PaymentProvider } from '@zentto/shared-api';

interface AcceptedMethodsManagerProps {
  allMethods: PaymentMethod[];
  allProviders: PaymentProvider[];
  acceptedMethods: AcceptedPaymentMethod[];
  /** Which channels to show toggles for. Defaults to all 3. */
  channels?: ('POS' | 'WEB' | 'RESTAURANT')[];
  onAdd: (data: { paymentMethodId: number; providerId?: number; appliesToPOS: boolean; appliesToWeb: boolean; appliesToRestaurant: boolean }) => void;
  onRemove: (id: number) => void;
  onToggleChannel: (id: number, channel: 'POS' | 'WEB' | 'RESTAURANT', value: boolean) => void;
}

const CATEGORY_ICONS: Record<string, string> = {
  CASH: '💵',
  CARD: '💳',
  MOBILE: '📱',
  TRANSFER: '🏦',
  CRYPTO: '₿',
  DIGITAL_WALLET: '👛',
  QR: '📲',
  OTHER: '📋',
};

export default function AcceptedMethodsManager({
  allMethods, allProviders, acceptedMethods,
  channels = ['POS', 'WEB', 'RESTAURANT'],
  onAdd, onRemove, onToggleChannel,
}: AcceptedMethodsManagerProps) {
  const acceptedIds = new Set(acceptedMethods.map(a => a.paymentMethodId));
  const availableToAdd = allMethods.filter(m => !acceptedIds.has(m.id));
  const getAcceptedMethodKey = (am: AcceptedPaymentMethod, index: number) => {
    const identity = [
      am.id || 'no-id',
      am.paymentMethodId,
      am.providerId ?? 'no-provider',
      am.methodCode || 'no-code',
      index,
    ];

    return identity.join(':');
  };

  const [showAddMenu, setShowAddMenu] = React.useState(false);

  return (
    <Box>
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
        <Typography variant="subtitle1" fontWeight={600}>
          Formas de Pago Aceptadas
        </Typography>
        <Button
          startIcon={<AddIcon />}
          variant="outlined"
          size="small"
          onClick={() => setShowAddMenu(!showAddMenu)}
          disabled={availableToAdd.length === 0}
        >
          Agregar método
        </Button>
      </Box>

      {/* Quick-add chips */}
      {showAddMenu && (
        <Box sx={{ mb: 2, display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
          {availableToAdd.map(m => (
            <Chip
              key={m.id}
              label={`${CATEGORY_ICONS[m.category] || ''} ${m.name}`}
              onClick={() => {
                onAdd({
                  paymentMethodId: m.id,
                  appliesToPOS: channels.includes('POS'),
                  appliesToWeb: channels.includes('WEB'),
                  appliesToRestaurant: channels.includes('RESTAURANT'),
                });
                setShowAddMenu(false);
              }}
              variant="outlined"
              clickable
              sx={{ fontWeight: 500 }}
            />
          ))}
        </Box>
      )}

      <TableContainer component={Paper} variant="outlined">
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>Método</TableCell>
              <TableCell>Categoría</TableCell>
              <TableCell>Proveedor</TableCell>
              {channels.includes('POS') && <TableCell align="center">POS</TableCell>}
              {channels.includes('WEB') && <TableCell align="center">Web</TableCell>}
              {channels.includes('RESTAURANT') && <TableCell align="center">Rest.</TableCell>}
              <TableCell align="center" width={50}></TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {acceptedMethods.length === 0 && (
              <TableRow>
                <TableCell colSpan={channels.length + 4} align="center" sx={{ py: 4, color: 'text.secondary' }}>
                  No hay formas de pago configuradas. Agrega al menos una.
                </TableCell>
              </TableRow>
            )}
            {acceptedMethods.map((am, index) => (
              <TableRow key={getAcceptedMethodKey(am, index)}>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <span>{CATEGORY_ICONS[am.methodCategory] || '📋'}</span>
                    <Typography variant="body2" fontWeight={500}>{am.methodName}</Typography>
                  </Box>
                </TableCell>
                <TableCell>
                  <Chip label={am.methodCategory} size="small" variant="outlined" />
                </TableCell>
                <TableCell>
                  <Typography variant="body2" color="text.secondary">
                    {am.providerName || '—'}
                  </Typography>
                </TableCell>
                {channels.includes('POS') && (
                  <TableCell align="center">
                    <Switch
                      size="small" checked={am.appliesToPOS}
                      onChange={e => onToggleChannel(am.id, 'POS', e.target.checked)}
                    />
                  </TableCell>
                )}
                {channels.includes('WEB') && (
                  <TableCell align="center">
                    <Switch
                      size="small" checked={am.appliesToWeb}
                      onChange={e => onToggleChannel(am.id, 'WEB', e.target.checked)}
                    />
                  </TableCell>
                )}
                {channels.includes('RESTAURANT') && (
                  <TableCell align="center">
                    <Switch
                      size="small" checked={am.appliesToRestaurant}
                      onChange={e => onToggleChannel(am.id, 'RESTAURANT', e.target.checked)}
                    />
                  </TableCell>
                )}
                <TableCell align="center">
                  <Tooltip title="Quitar método">
                    <IconButton size="small" color="error" onClick={() => onRemove(am.id)}>
                      <DeleteIcon fontSize="small" />
                    </IconButton>
                  </Tooltip>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </Box>
  );
}
