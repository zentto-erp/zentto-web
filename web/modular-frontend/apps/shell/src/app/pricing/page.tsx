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
          customer?: { email?: string; id?: string };
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
    name: 'Zentto Prueba',
    price: 1,
    priceId: 'pri_01km136n0k9xwj50e6s3t3jnk1',
    highlighted: false,
    features: [
      '1 empresa',
      '1 sucursal',
      '2 usuarios',
      'Todos los módulos',
      'Ideal para probar el sistema',
      '30 días de prueba',
    ],
  },
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

const API_BASE = process.env.NEXT_PUBLIC_API_BASE_URL || process.env.NEXT_PUBLIC_API_URL || 'https://api.zentto.net';

export default function PricingPage() {
  const [paddleReady, setPaddleReady] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Onboarding modal state
  const [showOnboarding, setShowOnboarding] = useState(false);
  const [selectedPriceId, setSelectedPriceId] = useState('');
  const [companyName, setCompanyName] = useState('');
  const [subdomain, setSubdomain] = useState('');
  const [subdomainError, setSubdomainError] = useState('');
  const [checkingSubdomain, setCheckingSubdomain] = useState(false);
  const [subdomainOk, setSubdomainOk] = useState(false);

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
          window.Paddle.Initialize({
            token: clientToken,
            eventCallback: (event: { name?: string; data?: { customer?: { email?: string } } }) => {
              if (event.name === 'checkout.completed' && event.data?.customer?.email) {
                // Redirigir a success con email para polling de tenant
                const email = encodeURIComponent(event.data.customer.email);
                setTimeout(() => {
                  window.location.href = `/billing/success?customer_email=${email}`;
                }, 1500);
              }
            },
          } as any);
          setPaddleReady(true);

          // Auto-open onboarding modal if redirected with ?plan=
          if (autoCheckoutPlan) {
            const planMap: Record<string, string> = {
              basico: 'pri_01kky59xnge4kenjp2hav35rx0',
              profesional: 'pri_01kky5a0mwzk38j23hkcgmxn47',
              test: 'pri_01km136n0k9xwj50e6s3t3jnk1',
            };
            const priceId = planMap[autoCheckoutPlan];
            if (priceId) {
              setTimeout(() => {
                // Abrir modal de onboarding (no Paddle directo)
                setSelectedPriceId(priceId);
                setShowOnboarding(true);
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

  // Sanitizar subdomain: solo letras, numeros, guiones
  const sanitizeSubdomain = (val: string) =>
    val.toLowerCase().replace(/[^a-z0-9-]/g, '').replace(/^-+|-+$/g, '').slice(0, 30);

  // Auto-generar subdomain desde nombre de empresa
  const handleCompanyNameChange = (val: string) => {
    setCompanyName(val);
    const auto = sanitizeSubdomain(val.replace(/\s+/g, '-'));
    setSubdomain(auto);
    setSubdomainOk(false);
    setSubdomainError('');
  };

  // Validar disponibilidad del subdomain
  const checkSubdomainAvailability = useCallback(async (sub: string) => {
    if (sub.length < 3) {
      setSubdomainError('Minimo 3 caracteres');
      setSubdomainOk(false);
      return;
    }
    const reserved = ['app','www','api','notify','notify-dash','broker','vault','mail','admin','smtp','test'];
    if (reserved.includes(sub)) {
      setSubdomainError('Este subdominio esta reservado');
      setSubdomainOk(false);
      return;
    }
    setCheckingSubdomain(true);
    setSubdomainError('');
    try {
      const res = await fetch(`${API_BASE}/api/tenants/resolve/${sub}`);
      if (res.ok) {
        setSubdomainError('Este subdominio ya esta en uso');
        setSubdomainOk(false);
      } else {
        setSubdomainOk(true);
        setSubdomainError('');
      }
    } catch {
      setSubdomainOk(true); // Si la API falla, permitir (se validara en provision)
    } finally {
      setCheckingSubdomain(false);
    }
  }, []);

  // Abrir modal de onboarding antes de Paddle
  const openOnboarding = (priceId: string) => {
    setSelectedPriceId(priceId);
    setCompanyName('');
    setSubdomain('');
    setSubdomainError('');
    setSubdomainOk(false);
    setShowOnboarding(true);
  };

  // Proceder al checkout de Paddle con custom_data
  const proceedToCheckout = useCallback(() => {
    if (!paddleReady || !window.Paddle || !subdomainOk) return;
    setShowOnboarding(false);
    window.Paddle.Checkout.open({
      items: [{ priceId: selectedPriceId, quantity: 1 }],
      customData: { subdomain, companyName },
      settings: {
        successUrl: 'https://app.zentto.net/billing/success?source=paddle',
        displayMode: 'overlay',
        theme: 'light',
        locale: 'es',
      },
    } as any);
  }, [paddleReady, selectedPriceId, subdomain, companyName, subdomainOk]);

  // Legacy handleCheckout para auto-checkout via URL params
  const handleCheckout = useCallback(
    (priceId: string) => {
      openOnboarding(priceId);
    },
    [],
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
            <Grid key={plan.priceId} size={{ xs: 12, sm: 6, md: 4 }}>
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

      {/* ── Modal Onboarding: nombre de empresa + subdomain ── */}
      {showOnboarding && (
        <Box
          onClick={() => setShowOnboarding(false)}
          sx={{
            position: 'fixed', inset: 0, zIndex: 1300,
            bgcolor: 'rgba(0,0,0,0.5)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            px: 2,
          }}
        >
          <Paper
            onClick={(e) => e.stopPropagation()}
            elevation={12}
            sx={{ p: { xs: 3, md: 5 }, borderRadius: 3, maxWidth: 480, width: '100%' }}
          >
            <Typography variant="h5" fontWeight={700} sx={{ color: COLORS.darkPrimary, mb: 1 }}>
              Configura tu empresa
            </Typography>
            <Typography variant="body2" sx={{ color: 'text.secondary', mb: 3 }}>
              Elige un nombre y subdominio para tu empresa. Este sera tu acceso exclusivo a Zentto.
            </Typography>

            {/* Nombre de empresa */}
            <Box sx={{ mb: 2.5 }}>
              <Typography variant="body2" fontWeight={600} sx={{ mb: 0.5 }}>
                Nombre de la empresa
              </Typography>
              <input
                type="text"
                value={companyName}
                onChange={(e) => handleCompanyNameChange(e.target.value)}
                placeholder="Mi Empresa S.A."
                style={{
                  width: '100%', padding: '12px 14px', fontSize: '15px',
                  border: '1px solid #ddd', borderRadius: 8, outline: 'none',
                  fontFamily: 'inherit',
                }}
              />
            </Box>

            {/* Subdomain */}
            <Box sx={{ mb: 3 }}>
              <Typography variant="body2" fontWeight={600} sx={{ mb: 0.5 }}>
                Subdominio
              </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 0 }}>
                <input
                  type="text"
                  value={subdomain}
                  onChange={(e) => {
                    const val = sanitizeSubdomain(e.target.value);
                    setSubdomain(val);
                    setSubdomainOk(false);
                    setSubdomainError('');
                  }}
                  onBlur={() => subdomain && checkSubdomainAvailability(subdomain)}
                  placeholder="mi-empresa"
                  style={{
                    flex: 1, padding: '12px 14px', fontSize: '15px',
                    border: `1px solid ${subdomainError ? '#e74c3c' : subdomainOk ? '#4caf50' : '#ddd'}`,
                    borderRadius: '8px 0 0 8px', outline: 'none',
                    fontFamily: 'monospace',
                  }}
                />
                <Box sx={{
                  bgcolor: '#f5f5f5', px: 2, py: '12px',
                  border: '1px solid #ddd', borderLeft: 'none',
                  borderRadius: '0 8px 8px 0', fontSize: '14px', color: '#666',
                  whiteSpace: 'nowrap',
                }}>
                  .zentto.net
                </Box>
              </Box>
              {checkingSubdomain && (
                <Typography variant="caption" sx={{ color: 'text.secondary', mt: 0.5, display: 'block' }}>
                  Verificando disponibilidad...
                </Typography>
              )}
              {subdomainError && (
                <Typography variant="caption" sx={{ color: '#e74c3c', mt: 0.5, display: 'block' }}>
                  {subdomainError}
                </Typography>
              )}
              {subdomainOk && !subdomainError && (
                <Typography variant="caption" sx={{ color: '#4caf50', mt: 0.5, display: 'block' }}>
                  {subdomain}.zentto.net esta disponible
                </Typography>
              )}
            </Box>

            {/* Botones */}
            <Box sx={{ display: 'flex', gap: 2 }}>
              <Button
                variant="outlined"
                onClick={() => setShowOnboarding(false)}
                sx={{ flex: 1, py: 1.5, borderRadius: 2, borderColor: '#ddd', color: '#666' }}
              >
                Cancelar
              </Button>
              <Button
                variant="contained"
                disabled={!subdomainOk || !companyName.trim() || checkingSubdomain}
                onClick={proceedToCheckout}
                sx={{
                  flex: 1, py: 1.5, borderRadius: 2, fontWeight: 700,
                  bgcolor: COLORS.accent, color: COLORS.darkPrimary,
                  '&:hover': { bgcolor: '#e68a00' },
                }}
              >
                Continuar al pago
              </Button>
            </Box>
          </Paper>
        </Box>
      )}
    </Box>
  );
}
