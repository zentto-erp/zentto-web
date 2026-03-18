'use client';

import React, { useEffect, useState, useCallback } from 'react';
import {
  Box,
  Typography,
  Button,
  Paper,
  Chip,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  CircularProgress,
  Container,
} from '@mui/material';
import Grid from '@mui/material/Grid2';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import SecurityIcon from '@mui/icons-material/Security';
import SupportAgentIcon from '@mui/icons-material/SupportAgent';
import UpdateIcon from '@mui/icons-material/Update';
import CloudDoneIcon from '@mui/icons-material/CloudDone';
import StorageIcon from '@mui/icons-material/Storage';
import DevicesIcon from '@mui/icons-material/Devices';

/* ---------- Types ---------- */

declare global {
  interface Window {
    Paddle?: {
      Initialize: (opts: { token: string }) => void;
      Checkout: {
        open: (opts: {
          items: { priceId: string; quantity: number }[];
          customer?: { email?: string };
          settings?: {
            successUrl?: string;
            displayMode?: string;
            theme?: string;
            locale?: string;
          };
        }) => void;
      };
    };
  }
}

interface Plan {
  name: string;
  price: number;
  priceId: string;
  highlighted: boolean;
  features: string[];
}

/* ---------- Constants ---------- */

const COLORS = {
  darkPrimary: '#131921',
  darkSecondary: '#232f3e',
  accent: '#ff9900',
  bg: '#eaeded',
  white: '#ffffff',
} as const;

const plans: Plan[] = [
  {
    name: 'Zentto Básico',
    price: 29,
    priceId: 'pri_01kky59xnge4kenjp2hav35rx0',
    highlighted: false,
    features: [
      '1 empresa',
      '2 sucursales',
      '5 usuarios',
      'Facturación',
      'Inventario',
      'Cuentas por cobrar / por pagar',
      'Reportes básicos',
    ],
  },
  {
    name: 'Zentto Profesional',
    price: 79,
    priceId: 'pri_01kky5a0mwzk38j23hkcgmxn47',
    highlighted: true,
    features: [
      '3 empresas',
      '10 sucursales',
      '25 usuarios',
      'Todo lo de Básico',
      'Contabilidad',
      'Nómina',
      'Multi-moneda',
      'Reportes avanzados',
      'API access',
      'Soporte prioritario',
    ],
  },
];

const includedBenefits = [
  { icon: <SecurityIcon />, label: 'Cifrado SSL de extremo a extremo' },
  { icon: <SupportAgentIcon />, label: 'Soporte técnico incluido' },
  { icon: <UpdateIcon />, label: 'Actualizaciones automáticas' },
  { icon: <CloudDoneIcon />, label: 'Respaldos diarios en la nube' },
  { icon: <StorageIcon />, label: 'Infraestructura escalable' },
  { icon: <DevicesIcon />, label: 'Acceso desde cualquier dispositivo' },
];

const faqs = [
  {
    question: '¿Puedo cambiar de plan?',
    answer:
      'Sí, puedes cambiar de plan en cualquier momento desde tu panel de configuración. El cambio se aplica de inmediato y se prorratea el monto correspondiente.',
  },
  {
    question: '¿Hay período de prueba?',
    answer:
      'Sí, todos los planes incluyen 14 días gratis sin compromiso. No se requiere tarjeta de crédito para comenzar.',
  },
  {
    question: '¿Qué métodos de pago aceptan?',
    answer:
      'Aceptamos tarjeta de crédito (Visa, Mastercard, AMEX), PayPal y transferencia bancaria. Todos los pagos son procesados de forma segura a través de Paddle.',
  },
  {
    question: '¿Puedo cancelar en cualquier momento?',
    answer:
      'Sí, puedes cancelar tu suscripción en cualquier momento sin penalización. Tu acceso se mantendrá activo hasta el final del período facturado.',
  },
];

/* ---------- Component ---------- */

export default function PricingPage() {
  const [paddleReady, setPaddleReady] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    // Read query params for auto-checkout from docs-site redirect
    const params = new URLSearchParams(window.location.search);
    const autoCheckoutPlan = params.get('plan'); // 'basico' or 'profesional'
    const autoCheckoutEmail = params.get('email');
    const autoCheckoutCustomerId = params.get('customerId');

    async function init() {
      try {
        // 1. Get Paddle client token (try API first, fallback to env)
        let clientToken = process.env.NEXT_PUBLIC_PADDLE_CLIENT_TOKEN ?? '';
        try {
          const apiBase = process.env.NEXT_PUBLIC_API_BASE_URL ?? '';
          const res = await fetch(`${apiBase}/v1/billing/config`);
          if (res.ok) {
            const data = await res.json();
            clientToken = data.clientToken ?? data.token ?? clientToken;
          }
        } catch { /* use fallback token */ }

        if (!clientToken) throw new Error('Token de Paddle no disponible');

        // 2. Load Paddle.js
        await new Promise<void>((resolve, reject) => {
          if (window.Paddle) {
            resolve();
            return;
          }
          const script = document.createElement('script');
          script.src = 'https://cdn.paddle.com/paddle/v2/paddle.js';
          script.async = true;
          script.onload = () => resolve();
          script.onerror = () => reject(new Error('No se pudo cargar Paddle.js'));
          document.head.appendChild(script);
        });

        // 3. Initialize Paddle
        if (!cancelled && window.Paddle) {
          window.Paddle.Initialize({ token: clientToken });
          setPaddleReady(true);

          // Auto-open checkout if redirected from docs-site with ?plan=
          if (autoCheckoutPlan) {
            const planMap: Record<string, string> = {
              basico: 'pri_01kky59xnge4kenjp2hav35rx0',
              profesional: 'pri_01kky5a0mwzk38j23hkcgmxn47',
              test: 'pri_01km136n0k9xwj50e6s3t3jnk1',
            };
            const priceId = planMap[autoCheckoutPlan];
            if (priceId) {
              setTimeout(() => {
                window.Paddle?.Checkout.open({
                  items: [{ priceId, quantity: 1 }],
                  ...(autoCheckoutCustomerId
                    ? { customer: { id: autoCheckoutCustomerId } }
                    : autoCheckoutEmail
                      ? { customer: { email: autoCheckoutEmail } }
                      : {}),
                  settings: {
                    successUrl: 'https://app.zentto.net/billing/success',
                    displayMode: 'overlay',
                    theme: 'light',
                    locale: 'es',
                  },
                });
              }, 500);
            }
          }
        }
      } catch (err: unknown) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : 'Error desconocido');
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    init();
    return () => {
      cancelled = true;
    };
  }, []);

  const handleCheckout = useCallback(
    (priceId: string) => {
      if (!paddleReady || !window.Paddle) return;
      window.Paddle.Checkout.open({
        items: [{ priceId, quantity: 1 }],
        settings: {
          successUrl: 'https://app.zentto.net/billing/success',
          displayMode: 'overlay',
          theme: 'light',
          locale: 'es',
        },
      });
    },
    [paddleReady],
  );

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: COLORS.bg }}>
      {/* ── Hero ── */}
      <Box
        sx={{
          background: `linear-gradient(135deg, ${COLORS.darkPrimary} 0%, ${COLORS.darkSecondary} 100%)`,
          color: COLORS.white,
          py: { xs: 8, md: 12 },
          px: 2,
          textAlign: 'center',
        }}
      >
        <Container maxWidth="md">
          <Typography
            variant="h3"
            fontWeight={700}
            sx={{ fontSize: { xs: '1.75rem', md: '2.75rem' }, mb: 2 }}
          >
            Elige el plan perfecto para tu negocio
          </Typography>
          <Typography
            variant="h6"
            sx={{ opacity: 0.85, fontWeight: 400, fontSize: { xs: '1rem', md: '1.25rem' } }}
          >
            Gestiona tu empresa con Zentto. Sin contratos, cancela cuando quieras.
          </Typography>
        </Container>
      </Box>

      {/* ── Pricing Cards ── */}
      <Container maxWidth="md" sx={{ mt: { xs: -4, md: -6 }, position: 'relative', zIndex: 1 }}>
        {loading && (
          <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}>
            <CircularProgress sx={{ color: COLORS.accent }} />
          </Box>
        )}

        {error && (
          <Paper sx={{ p: 3, mb: 3, textAlign: 'center' }}>
            <Typography color="error">{error}</Typography>
          </Paper>
        )}

        <Grid container spacing={4} sx={{ justifyContent: 'center' }}>
          {plans.map((plan) => (
            <Grid key={plan.priceId} size={{ xs: 12, sm: 6 }}>
              <Paper
                elevation={plan.highlighted ? 12 : 3}
                sx={{
                  p: 4,
                  borderRadius: 3,
                  position: 'relative',
                  border: plan.highlighted ? `2px solid ${COLORS.accent}` : '2px solid transparent',
                  transition: 'transform 0.2s, box-shadow 0.2s',
                  '&:hover': {
                    transform: 'translateY(-4px)',
                    boxShadow: 8,
                  },
                }}
              >
                {plan.highlighted && (
                  <Chip
                    label="Recomendado"
                    size="small"
                    sx={{
                      position: 'absolute',
                      top: -12,
                      left: '50%',
                      transform: 'translateX(-50%)',
                      bgcolor: COLORS.accent,
                      color: COLORS.darkPrimary,
                      fontWeight: 700,
                      fontSize: '0.8rem',
                    }}
                  />
                )}

                <Typography
                  variant="h5"
                  fontWeight={700}
                  sx={{ color: COLORS.darkPrimary, mb: 1, textAlign: 'center' }}
                >
                  {plan.name}
                </Typography>

                <Box sx={{ textAlign: 'center', mb: 3 }}>
                  <Typography
                    component="span"
                    sx={{ fontSize: '2.5rem', fontWeight: 800, color: COLORS.darkPrimary }}
                  >
                    ${plan.price}
                  </Typography>
                  <Typography
                    component="span"
                    sx={{ fontSize: '1rem', color: 'text.secondary', ml: 0.5 }}
                  >
                    /mes
                  </Typography>
                </Box>

                <Box sx={{ mb: 3 }}>
                  {plan.features.map((feat) => (
                    <Box key={feat} sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                      <CheckCircleIcon
                        sx={{ color: COLORS.accent, fontSize: 20, mr: 1, flexShrink: 0 }}
                      />
                      <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                        {feat}
                      </Typography>
                    </Box>
                  ))}
                </Box>

                <Button
                  variant={plan.highlighted ? 'contained' : 'outlined'}
                  fullWidth
                  size="large"
                  disabled={!paddleReady}
                  onClick={() => handleCheckout(plan.priceId)}
                  sx={{
                    py: 1.5,
                    fontWeight: 700,
                    fontSize: '1rem',
                    borderRadius: 2,
                    ...(plan.highlighted
                      ? {
                          bgcolor: COLORS.accent,
                          color: COLORS.darkPrimary,
                          '&:hover': { bgcolor: '#e68a00' },
                        }
                      : {
                          borderColor: COLORS.darkSecondary,
                          color: COLORS.darkSecondary,
                          '&:hover': { borderColor: COLORS.accent, color: COLORS.accent },
                        }),
                  }}
                >
                  Comenzar
                </Button>
              </Paper>
            </Grid>
          ))}
        </Grid>
      </Container>

      {/* ── Todos los planes incluyen ── */}
      <Container maxWidth="md" sx={{ mt: 8, mb: 4 }}>
        <Typography
          variant="h5"
          fontWeight={700}
          sx={{ textAlign: 'center', mb: 4, color: COLORS.darkPrimary }}
        >
          Todos los planes incluyen
        </Typography>

        <Grid container spacing={3}>
          {includedBenefits.map((b) => (
            <Grid key={b.label} size={{ xs: 6, sm: 4 }}>
              <Box sx={{ textAlign: 'center' }}>
                <Box sx={{ color: COLORS.accent, mb: 1, '& svg': { fontSize: 36 } }}>{b.icon}</Box>
                <Typography variant="body2" fontWeight={500} sx={{ color: COLORS.darkSecondary }}>
                  {b.label}
                </Typography>
              </Box>
            </Grid>
          ))}
        </Grid>
      </Container>

      {/* ── FAQ ── */}
      <Container maxWidth="md" sx={{ py: 6 }}>
        <Typography
          variant="h5"
          fontWeight={700}
          sx={{ textAlign: 'center', mb: 4, color: COLORS.darkPrimary }}
        >
          Preguntas frecuentes
        </Typography>

        {faqs.map((faq) => (
          <Accordion
            key={faq.question}
            disableGutters
            elevation={1}
            sx={{
              mb: 1.5,
              borderRadius: '8px !important',
              '&:before': { display: 'none' },
              overflow: 'hidden',
            }}
          >
            <AccordionSummary expandIcon={<ExpandMoreIcon />}>
              <Typography fontWeight={600} sx={{ color: COLORS.darkPrimary }}>
                {faq.question}
              </Typography>
            </AccordionSummary>
            <AccordionDetails>
              <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                {faq.answer}
              </Typography>
            </AccordionDetails>
          </Accordion>
        ))}
      </Container>

      {/* ── Footer note ── */}
      <Box sx={{ textAlign: 'center', pb: 6 }}>
        <Typography variant="caption" sx={{ color: 'text.disabled' }}>
          Precios en USD. Impuestos pueden aplicar según tu ubicación.
        </Typography>
      </Box>
    </Box>
  );
}
