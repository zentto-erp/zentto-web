'use client';

import React from 'react';
import {
  Box, Typography, Alert, LinearProgress, Chip, Button,
  CircularProgress,
} from '@mui/material';
import { useAuth } from '@zentto/shared-auth';
import { useLicenseLimits } from '@zentto/shared-api';
import { IamCompaniesTable } from '@zentto/module-admin';

export default function EmpresasPage() {
  const { isAdmin } = useAuth();
  const { data: limits, isLoading } = useLicenseLimits();

  if (!isAdmin) {
    return (
      <Box>
        <Alert severity="error">Solo los administradores pueden gestionar empresas.</Alert>
      </Box>
    );
  }

  if (isLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', p: 4 }}>
        <CircularProgress />
      </Box>
    );
  }

  const current = limits?.currentCompanies ?? 0;
  const max = limits?.maxCompanies ?? 1;
  const multiCompanyEnabled = limits?.multiCompany ?? false;

  return (
    <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
      {/* Banner de uso */}
      <Box
        sx={{
          mb: 3,
          p: 2,
          bgcolor: 'background.paper',
          borderRadius: 2,
          border: '1px solid',
          borderColor: 'divider',
        }}
      >
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 1 }}>
          <Typography variant="subtitle2">Empresas</Typography>
          <Chip
            label={`${current}/${max}`}
            size="small"
            color={current >= max ? 'error' : 'primary'}
          />
        </Box>
        <LinearProgress
          variant="determinate"
          value={Math.min((current / max) * 100, 100)}
          sx={{ height: 8, borderRadius: 4 }}
          color={current >= max ? 'error' : 'primary'}
        />
      </Box>

      {/* Alerta multi-empresa no disponible */}
      {!multiCompanyEnabled && (
        <Alert severity="warning" sx={{ mb: 2 }}>
          La funcionalidad multi-empresa no esta disponible en tu plan actual.
          <Button size="small" href="/configuracion/mi-plan" sx={{ ml: 1 }}>
            Mejorar plan
          </Button>
        </Alert>
      )}

      {/* Alerta limite alcanzado */}
      {multiCompanyEnabled && current >= max && (
        <Alert severity="error" sx={{ mb: 2 }}>
          Has alcanzado el limite de empresas de tu plan ({max}).
          <Button size="small" href="/configuracion/mi-plan" sx={{ ml: 1 }}>
            Mejorar plan
          </Button>
        </Alert>
      )}

      {/* Tabla de empresas */}
      <IamCompaniesTable />
    </Box>
  );
}
