'use client';

import React from 'react';
import {
  Box, Typography, Card, CardContent, Switch, FormControlLabel,
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper, Chip,
} from '@mui/material';
import SettingsIcon from '@mui/icons-material/Settings';

const alertRules = [
  { name: 'Facturas vencidas', module: 'CxC', frequency: 'Cada hora', enabled: true, description: 'Facturas con fecha de vencimiento pasada y saldo pendiente' },
  { name: 'Stock bajo', module: 'Inventario', frequency: 'Cada hora', enabled: true, description: 'Artículos con existencia menor al stock mínimo configurado' },
  { name: 'Pagos por vencer', module: 'CxP', frequency: 'Cada hora', enabled: true, description: 'Documentos por pagar que vencen en los próximos 7 días' },
  { name: 'Conciliación pendiente', module: 'Bancos', frequency: 'Cada hora', enabled: true, description: 'Cuentas bancarias sin conciliación cerrada en el mes actual' },
  { name: 'Nómina pendiente', module: 'Nómina', frequency: 'Cada hora', enabled: true, description: 'Nómina del período actual sin procesar' },
  { name: 'Asientos en borrador', module: 'Contabilidad', frequency: 'Cada hora', enabled: true, description: 'Asientos contables en estado borrador sin aprobar' },
  { name: 'Vacaciones por aprobar', module: 'RRHH', frequency: 'Cada hora', enabled: true, description: 'Solicitudes de vacaciones en estado SOLICITADA' },
];

export default function ConfiguracionAlertasPage() {
  return (
    <Box>
      <Typography variant="h5" fontWeight={700} sx={{ mb: 3, display: 'flex', alignItems: 'center', gap: 1 }}>
        <SettingsIcon color="primary" /> Configuración de Alertas
      </Typography>

      <Card>
        <CardContent>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Las alertas se verifican automáticamente cada hora. Cuando se detecta una condición,
            se genera una notificación visible en la campana del sistema para todos los usuarios.
          </Typography>

          <TableContainer component={Paper} variant="outlined">
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Alerta</TableCell>
                  <TableCell>Módulo</TableCell>
                  <TableCell>Descripción</TableCell>
                  <TableCell>Frecuencia</TableCell>
                  <TableCell align="center">Activa</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {alertRules.map((rule) => (
                  <TableRow key={rule.name}>
                    <TableCell sx={{ fontWeight: 600 }}>{rule.name}</TableCell>
                    <TableCell>
                      <Chip label={rule.module} size="small" variant="outlined" />
                    </TableCell>
                    <TableCell sx={{ color: 'text.secondary', fontSize: '0.85rem' }}>
                      {rule.description}
                    </TableCell>
                    <TableCell>{rule.frequency}</TableCell>
                    <TableCell align="center">
                      <FormControlLabel
                        control={<Switch defaultChecked={rule.enabled} color="success" />}
                        label=""
                      />
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>
    </Box>
  );
}
