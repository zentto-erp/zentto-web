'use client';

import React from 'react';
import { Box, Typography } from '@mui/material';
import { useAuth } from '@datqbox/shared-auth';

interface ProtectedComponentProps {
  requiredAdmin?: boolean;
  children: React.ReactNode;
  fallback?: React.ReactNode;
}

/**
 * Componente para proteger parte de la UI según rol del usuario
 * Útil para mostrar/ocultar opciones solo para administradores
 */
export function ProtectedComponent({
  requiredAdmin = false,
  children,
  fallback = null,
}: ProtectedComponentProps) {
  const { isAdmin, isLoading } = useAuth();

  if (isLoading) {
    return <Box>Cargando...</Box>;
  }

  if (requiredAdmin && !isAdmin) {
    return <>{fallback}</>;
  }

  return <>{children}</>;
}

/**
 * HOC para proteger componentes
 */
export function withProtection<P extends object>(
  Component: React.ComponentType<P>,
  requiredAdmin: boolean = false
) {
  return function ProtectedComponentWrapper(props: P) {
    const { isAdmin, isLoading } = useAuth();

    if (isLoading) {
      return <Box>Cargando...</Box>;
    }

    if (requiredAdmin && !isAdmin) {
      return (
        <Box sx={{ p: 2 }}>
          <Typography color="error">
            No tienes permisos para acceder a esta sección
          </Typography>
        </Box>
      );
    }

    return <Component {...props} />;
  };
}
