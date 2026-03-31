'use client';

import { Box, Typography, Stack } from '@mui/material';
import React from 'react';
import Link from 'next/link';
import { AuthLogin } from '@zentto/shared-auth';
import { Logo, ThemeToggle } from '@zentto/shared-ui';
import BrandPanel from '../BrandPanel';

export default function LoginPage() {
  return (
    <Box sx={{ display: 'flex', minHeight: '100vh', width: '100%' }}>
      <BrandPanel
        title={<>Bienvenido a{' '}<Box component="span" sx={{ color: '#FFB547' }}>Zentto</Box></>}
        description="La plataforma empresarial todo-en-uno para PYMEs que crecen."
      />

      {/* Right panel — login form */}
      <Box
        sx={{
          flex: 1,
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          alignItems: 'center',
          p: { xs: 3, sm: 5 },
          bgcolor: 'background.default',
          position: 'relative',
        }}
      >
        <ThemeToggle sx={{ position: 'absolute', top: 16, right: 16 }} />

        <Box sx={{ width: '100%', maxWidth: 400 }}>
          {/* Logo for mobile */}
          <Box sx={{ display: { xs: 'flex', md: 'none' }, justifyContent: 'center', mb: 3 }}>
            <Logo />
          </Box>

          <Typography
            sx={{
              fontFamily: "'Inter', system-ui, sans-serif",
              fontWeight: 700,
              fontSize: '1.25rem',
              letterSpacing: '-0.025em',
              mb: 0.5,
            }}
          >
            Iniciar sesión
          </Typography>
          <Typography
            sx={{
              fontFamily: "'Inter', system-ui, sans-serif",
              color: 'text.secondary',
              fontSize: '0.875rem',
              mb: 3,
            }}
          >
            Ingresa tus credenciales
          </Typography>

          <AuthLogin
            subtext={null}
            subtitle={
              <Stack spacing={1} justifyContent="center" mt={3}>
                <Stack direction="row" spacing={1} justifyContent="center">
                  <Typography color="textSecondary" variant="body2" fontWeight="500" sx={{ fontFamily: "'Inter', system-ui, sans-serif" }}>
                    ¿No tienes cuenta?
                  </Typography>
                  <Typography
                    component={Link}
                    href="/authentication/register"
                    variant="body2"
                    fontWeight="500"
                    sx={{
                      fontFamily: "'Inter', system-ui, sans-serif",
                      color: 'primary.main',
                      cursor: 'pointer',
                      textDecoration: 'none',
                      '&:hover': { textDecoration: 'underline' },
                    }}
                  >
                    Registrarme
                  </Typography>
                </Stack>
                <Stack direction="row" spacing={1} justifyContent="center">
                  <Typography color="textSecondary" variant="body2" fontWeight="500" sx={{ fontFamily: "'Inter', system-ui, sans-serif" }}>
                    ¿Necesitas recuperar acceso?
                  </Typography>
                  <Typography
                    component={Link}
                    href="/authentication/forgot-password"
                    variant="body2"
                    fontWeight="500"
                    sx={{
                      fontFamily: "'Inter', system-ui, sans-serif",
                      color: 'primary.main',
                      cursor: 'pointer',
                      textDecoration: 'none',
                      '&:hover': { textDecoration: 'underline' },
                    }}
                  >
                    Recuperar contraseña
                  </Typography>
                </Stack>
              </Stack>
            }
          />
        </Box>
      </Box>
    </Box>
  );
}
