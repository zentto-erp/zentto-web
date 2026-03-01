'use client';

import { Box, Card, Stack, Typography } from '@mui/material';
import Grid from '@mui/material/Grid2';
import React from 'react';
import AuthLogin from '../auth/AuthLogin';
import Logo from '@/app/(dashboard)/shared/logo/Logo';

export default function LoginPage() {
  return (
    <Box
      sx={{
        position: 'relative',
        width: '100%',
        height: '100vh',
        '&:before': {
          content: '""',
          background: 'radial-gradient(#d2f1df, #d3d7fa, #bad8f4)',
          backgroundSize: '400% 400%',
          animation: 'gradient 15s ease infinite',
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          opacity: 0.3,
        },
      }}
    >
      <Grid
        container
        spacing={0}
        sx={{
          width: '100%',
          height: '100%',
          justifyContent: 'center',
          alignItems: 'center',
        }}
      >
        <Grid
          size={{ xs: 12, sm: 12, lg: 5, xl: 4 }}
          sx={{
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
          }}
        >
          <Card elevation={9} sx={{ p: 4, zIndex: 1, width: '100%', maxWidth: '500px', mx: 2 }}>
            <Box display="flex" alignItems="center" justifyContent="center" mb={3}>
              <Logo />
            </Box>
            <AuthLogin
              subtext={
                <Typography variant="subtitle1" textAlign="center" color="textSecondary" mb={1}>
                  Ingresa tus credenciales para continuar
                </Typography>
              }
              subtitle={
                <Stack spacing={1} justifyContent="center" mt={3}>
                  <Stack direction="row" spacing={1} justifyContent="center">
                    <Typography color="textSecondary" variant="body2" fontWeight="500">
                      No tienes cuenta?
                    </Typography>
                    <Typography
                      component="a"
                      href="/authentication/register"
                      fontWeight="500"
                      sx={{
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
                    <Typography color="textSecondary" variant="body2" fontWeight="500">
                      Necesitas recuperar acceso?
                    </Typography>
                    <Typography
                      component="a"
                      href="/authentication/forgot-password"
                      fontWeight="500"
                      sx={{
                        color: 'primary.main',
                        cursor: 'pointer',
                        textDecoration: 'none',
                        '&:hover': { textDecoration: 'underline' },
                      }}
                    >
                      Recuperar contrasena
                    </Typography>
                  </Stack>
                </Stack>
              }
            />
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}
