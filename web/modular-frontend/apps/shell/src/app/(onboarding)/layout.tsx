'use client';

import * as React from 'react';
import { Box, Typography } from '@mui/material';
import { usePathname } from 'next/navigation';
import dynamic from 'next/dynamic';

// Importar el stepper como componente dinamico para evitar SSR
const CustomStepper = dynamic(
  () => import('@zentto/shared-ui').then(m => m.CustomStepper),
  { ssr: false }
);

const CheckCircleIcon = dynamic(() => import('@mui/icons-material/CheckCircle'), { ssr: false });
const StorageIcon = dynamic(() => import('@mui/icons-material/Storage'), { ssr: false });
const KeyIcon = dynamic(() => import('@mui/icons-material/Key'), { ssr: false });
const SettingsIcon = dynamic(() => import('@mui/icons-material/Settings'), { ssr: false });
const RocketLaunchIcon = dynamic(() => import('@mui/icons-material/RocketLaunch'), { ssr: false });
const CelebrationIcon = dynamic(() => import('@mui/icons-material/Celebration'), { ssr: false });
const WavingHandIcon = dynamic(() => import('@mui/icons-material/WavingHand'), { ssr: false });

// ─── Definicion de pasos del wizard ──────────────────────────────────────────

const WIZARD_STEPS = [
  { label: 'Bienvenida',    icon: <WavingHandIcon sx={{ fontSize: 22 }} /> },
  { label: 'Proveedor',     icon: <StorageIcon sx={{ fontSize: 22 }} /> },
  { label: 'Credenciales',  icon: <KeyIcon sx={{ fontSize: 22 }} /> },
  { label: 'Configurar',    icon: <SettingsIcon sx={{ fontSize: 22 }} /> },
  { label: 'Instalando',    icon: <RocketLaunchIcon sx={{ fontSize: 22 }} /> },
  { label: 'Listo',         icon: <CelebrationIcon sx={{ fontSize: 22 }} /> },
];

// Mapeo de segmento de ruta a indice de paso
function getActiveStep(pathname: string): number {
  if (pathname.includes('/complete')) return 5;
  if (pathname.includes('/deploy'))   return 4;
  if (pathname.includes('/configure')) return 3;
  if (pathname.includes('/credentials')) return 2;
  if (pathname.includes('/provider'))  return 1;
  return 0; // bienvenida (raiz del token)
}

// ─── Layout limpio de onboarding (sin sidebar, sin navbar) ───────────────────

export default function OnboardingLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const activeStep = getActiveStep(pathname);

  return (
    <Box sx={{ minHeight: '100vh', background: '#f0f2f5', display: 'flex', flexDirection: 'column' }}>
      {/* Header minimo con logo */}
      <Box
        sx={{
          background: '#1a1a2e',
          py: 2,
          px: 3,
          textAlign: 'center',
          boxShadow: '0 2px 8px rgba(0,0,0,0.3)',
        }}
      >
        <Typography
          sx={{
            color: '#ff9900',
            fontWeight: 900,
            fontSize: { xs: 20, sm: 24 },
            letterSpacing: 3,
            display: 'inline-block',
          }}
        >
          ZENTTO
        </Typography>
        <Typography
          sx={{
            color: 'rgba(255,255,255,0.5)',
            fontSize: 11,
            letterSpacing: 2,
            textTransform: 'uppercase',
            mt: 0.25,
          }}
        >
          Configuracion de tu instancia
        </Typography>
      </Box>

      {/* Stepper visual */}
      <Box
        sx={{
          background: '#fff',
          borderBottom: '1px solid #e0e0e0',
          py: 3,
          px: { xs: 2, sm: 4, md: 8 },
        }}
      >
        <React.Suspense fallback={null}>
          <CustomStepper activeStep={activeStep} steps={WIZARD_STEPS} />
        </React.Suspense>
      </Box>

      {/* Contenido del paso */}
      <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
        {children}
      </Box>

      {/* Footer minimo */}
      <Box sx={{ textAlign: 'center', py: 2 }}>
        <Typography variant="caption" sx={{ color: '#9e9e9e' }}>
          &copy; {new Date().getFullYear()} Zentto ERP — Todos los derechos reservados
        </Typography>
      </Box>
    </Box>
  );
}
