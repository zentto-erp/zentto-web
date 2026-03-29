'use client';
import React, { useState, useEffect } from 'react';
import { Chip, Tooltip } from '@mui/material';
import ScienceIcon from '@mui/icons-material/Science';
import BusinessIcon from '@mui/icons-material/Business';

export function DbModeToggle() {
  const [mode, setMode] = useState<'production' | 'demo'>('production');

  useEffect(() => {
    const saved = localStorage.getItem('zentto-db-mode');
    if (saved === 'demo') setMode('demo');
  }, []);

  const toggle = () => {
    const newMode = mode === 'demo' ? 'production' : 'demo';
    localStorage.setItem('zentto-db-mode', newMode);
    setMode(newMode);
    // Recargar para que todas las queries usen el nuevo modo
    window.location.reload();
  };

  return (
    <Tooltip title={mode === 'demo' ? 'Viendo datos de demostración. Click para cambiar a tu empresa.' : 'Viendo datos reales de tu empresa. Click para ver demo.'}>
      <Chip
        icon={mode === 'demo' ? <ScienceIcon /> : <BusinessIcon />}
        label={mode === 'demo' ? 'Demo' : 'Mi empresa'}
        onClick={toggle}
        color={mode === 'demo' ? 'warning' : 'primary'}
        variant={mode === 'demo' ? 'filled' : 'outlined'}
        size="small"
        sx={{ cursor: 'pointer', fontWeight: 600 }}
      />
    </Tooltip>
  );
}
