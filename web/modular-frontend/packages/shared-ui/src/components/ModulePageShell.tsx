'use client';

import * as React from 'react';
import Box from '@mui/material/Box';
import Stack from '@mui/material/Stack';
import type { SxProps, Theme } from '@mui/material/styles';

export interface ModulePageShellProps {
  /**
   * Botones/acciones primarias y secundarias en la zona izquierda del toolbar.
   * Ej: `<Button>+ Nuevo</Button>` o `<><Button>A</Button><Button>B</Button></>`.
   */
  actions?: React.ReactNode;
  /**
   * Controles de filtrado/búsqueda en la zona derecha del toolbar.
   * Ej: TextField de búsqueda, Select de tipo, DatePicker, etc.
   */
  filters?: React.ReactNode;
  /**
   * Tabs opcionales renderizados debajo del toolbar (encima del contenido).
   */
  tabs?: React.ReactNode;
  /** Contenido principal de la página. */
  children: React.ReactNode;
  /** Spacing extra o ajustes puntuales sobre el contenedor raíz. */
  sx?: SxProps<Theme>;
}

/**
 * Shell común para subpáginas de microapps Zentto.
 *
 * No renderiza título: la navegación lateral ya indica la ubicación.
 * Provee estructura consistente (toolbar + tabs + contenido) con estilos
 * theme-aware (dark mode safe). Reemplaza a `ContextActionHeader` donde
 * éste sólo servía para pintar un título.
 */
export default function ModulePageShell({
  actions,
  filters,
  tabs,
  children,
  sx,
}: ModulePageShellProps) {
  const hasToolbar = Boolean(actions || filters);

  return (
    <Box sx={{ width: '100%', ...sx }}>
      {hasToolbar && (
        <Box
          sx={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            gap: 2,
            flexWrap: 'wrap',
            mb: 2,
          }}
        >
          <Stack direction="row" spacing={1} alignItems="center" flexWrap="wrap">
            {actions}
          </Stack>
          {filters && (
            <Stack direction="row" spacing={1} alignItems="center" flexWrap="wrap">
              {filters}
            </Stack>
          )}
        </Box>
      )}

      {tabs && <Box sx={{ mb: 2 }}>{tabs}</Box>}

      {children}
    </Box>
  );
}
