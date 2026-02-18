'use client';

import { Box, Card, Stack, Typography } from '@mui/material';
import Grid from '@mui/material/Grid2';
import React from 'react';
import Logo from '@/app/(dashboard)/shared/logo/Logo';
import Link from 'next/link';

export default function RegisterPage() {
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
          <Card
            elevation={9}
            sx={{ p: 4, zIndex: 1, width: '100%', maxWidth: '500px', mx: 2 }}
          >
            <Box display="flex" alignItems="center" justifyContent="center" mb={3}>
              <Logo />
            </Box>
            
            <Typography
              variant="subtitle1"
              textAlign="center"
              color="textSecondary"
              mb={3}
            >
              Para obtener acceso al sistema, contacta al administrador
            </Typography>

            <Stack spacing={3}>
              <Box
                sx={{
                  p: 3,
                  backgroundColor: 'grey.50',
                  borderRadius: 2,
                  border: '1px solid',
                  borderColor: 'grey.200',
                }}
              >
                <Typography variant="body2" color="textSecondary" textAlign="center">
                  <strong>Email:</strong> admin@datqbox.com
                </Typography>
                <Typography variant="body2" color="textSecondary" textAlign="center" mt={1}>
                  <strong>Teléfono:</strong> +58 (xxx) xxx-xxxx
                </Typography>
              </Box>

              <Typography variant="body2" color="textSecondary" textAlign="center">
                O visita nuestras oficinas para mayor información
              </Typography>
            </Stack>

            <Stack
              direction="row"
              spacing={1}
              justifyContent="center"
              mt={3}
              pt={2}
              sx={{ borderTop: '1px solid', borderColor: 'grey.200' }}
            >
              <Typography
                color="textSecondary"
                variant="body2"
                fontWeight="500"
              >
                ¿Ya tienes cuenta?
              </Typography>
              <Typography
                component={Link}
                href="/authentication/login"
                fontWeight="500"
                sx={{
                  color: 'primary.main',
                  cursor: 'pointer',
                  textDecoration: 'none',
                  '&:hover': {
                    textDecoration: 'underline',
                  },
                }}
              >
                Iniciar sesión
              </Typography>
            </Stack>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}
