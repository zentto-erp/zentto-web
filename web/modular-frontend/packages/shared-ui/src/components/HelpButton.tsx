'use client';

import * as React from 'react';
import { IconButton, Tooltip, Menu, MenuItem, Typography, Box, Divider, ListItemIcon } from '@mui/material';
import HelpOutlineIcon from '@mui/icons-material/HelpOutline';
import OpenInNewIcon from '@mui/icons-material/OpenInNew';
import MenuBookIcon from '@mui/icons-material/MenuBook';
import SupportAgentIcon from '@mui/icons-material/SupportAgent';
import { usePathname } from 'next/navigation';
import { getHelpForPath } from '../lib/help-map';

/**
 * Botón de ayuda contextual.
 * Muestra documentación relevante según la página actual.
 * Se integra en el AppBar del ZenttoLayout.
 */
export default function HelpButton() {
  const pathname = usePathname();
  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);

  // Limpiar pathname de basePath (ej: /contabilidad/asientos → /asientos si estamos en app contabilidad)
  const cleanPath = pathname || '/';
  const help = getHelpForPath(cleanPath);

  return (
    <>
      <Tooltip title="Ayuda">
        <IconButton
          size="small"
          onClick={(e) => setAnchorEl(e.currentTarget)}
          sx={{ color: 'text.secondary', '&:hover': { bgcolor: 'action.hover' } }}
        >
          <HelpOutlineIcon />
        </IconButton>
      </Tooltip>

      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={() => setAnchorEl(null)}
        slotProps={{ paper: { sx: { minWidth: 300, maxWidth: 360 } } }}
      >
        {help ? [
          <Box key="help-box" sx={{ px: 2, py: 1.5 }}>
            <Typography variant="subtitle2" fontWeight={700} color="primary">
              {help.title}
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
              {help.description}
            </Typography>
          </Box>,
          <Divider key="help-divider" />,
        ] : null}

        <MenuItem
          onClick={() => {
            if (help) window.open(help.url, '_blank');
            setAnchorEl(null);
          }}
        >
          <ListItemIcon><MenuBookIcon fontSize="small" /></ListItemIcon>
          <Box>
            <Typography variant="body2" fontWeight={600}>Ver documentación</Typography>
            <Typography variant="caption" color="text.secondary">Guía completa de esta sección</Typography>
          </Box>
          <OpenInNewIcon fontSize="small" sx={{ ml: 'auto', color: 'text.secondary' }} />
        </MenuItem>

        <MenuItem
          onClick={() => {
            window.open('https://zentto.net/docs', '_blank');
            setAnchorEl(null);
          }}
        >
          <ListItemIcon><MenuBookIcon fontSize="small" /></ListItemIcon>
          <Box>
            <Typography variant="body2">Centro de ayuda</Typography>
            <Typography variant="caption" color="text.secondary">Toda la documentación</Typography>
          </Box>
        </MenuItem>

        <MenuItem
          onClick={() => {
            window.open('mailto:soporte@zentto.net', '_blank');
            setAnchorEl(null);
          }}
        >
          <ListItemIcon><SupportAgentIcon fontSize="small" /></ListItemIcon>
          <Box>
            <Typography variant="body2">Contactar soporte</Typography>
            <Typography variant="caption" color="text.secondary">soporte@zentto.net</Typography>
          </Box>
        </MenuItem>
      </Menu>
    </>
  );
}
