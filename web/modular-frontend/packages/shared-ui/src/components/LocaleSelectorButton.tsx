'use client';

import React, { useContext, useState } from 'react';
import IconButton from '@mui/material/IconButton';
import Menu from '@mui/material/Menu';
import MenuItem from '@mui/material/MenuItem';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import Tooltip from '@mui/material/Tooltip';
import LanguageIcon from '@mui/icons-material/Language';

import { I18nContext, SUPPORTED_LOCALES } from '@zentto/shared-i18n';
import type { Locale } from '@zentto/shared-i18n';

/**
 * MUI-styled locale selector for the ZenttoLayout toolbar.
 * Shows a globe icon that opens a dropdown with ES/EN/PT options.
 * Renders nothing if I18nProvider is not present (graceful degradation).
 */
export default function LocaleSelectorButton() {
  const ctx = useContext(I18nContext);
  const [anchorEl, setAnchorEl] = useState<HTMLElement | null>(null);

  // If no I18nProvider wraps the tree, hide the selector
  if (!ctx) return null;

  const { locale, setLocale, t } = ctx;

  return (
    <>
      <Tooltip title={t('i18n.language')}>
        <IconButton
          size="small"
          onClick={(e) => setAnchorEl(e.currentTarget)}
          aria-label={t('i18n.language')}
        >
          <LanguageIcon fontSize="small" />
        </IconButton>
      </Tooltip>

      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={() => setAnchorEl(null)}
        slotProps={{ paper: { sx: { minWidth: 160 } } }}
      >
        {SUPPORTED_LOCALES.map((loc) => (
          <MenuItem
            key={loc.code}
            selected={loc.code === locale}
            onClick={() => {
              setLocale(loc.code as Locale);
              setAnchorEl(null);
            }}
          >
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <Typography component="span" sx={{ fontSize: '1.1rem' }}>
                {loc.flag}
              </Typography>
              <Typography variant="body2" fontWeight={loc.code === locale ? 600 : 400}>
                {loc.label}
              </Typography>
              <Typography variant="caption" color="text.secondary" sx={{ ml: 'auto' }}>
                {loc.code.toUpperCase()}
              </Typography>
            </Box>
          </MenuItem>
        ))}
      </Menu>
    </>
  );
}
