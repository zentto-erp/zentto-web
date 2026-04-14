'use client';

import React, { useEffect, useMemo, useState } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import {
  Box, Container, Typography, Card, CardContent, Stepper, Step, StepLabel,
  TextField, Button, Alert, CircularProgress, Chip, InputAdornment, ToggleButtonGroup, ToggleButton,
} from '@mui/material';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import ErrorOutlineIcon from '@mui/icons-material/ErrorOutline';
import RocketLaunchIcon from '@mui/icons-material/RocketLaunch';
import {
  useCatalogPlan, useCheckSubdomain, useStartTrial, useStartCheckout, useCaptureLead,
} from '@zentto/shared-api';
import { CountrySelect, PhoneInput } from '@zentto/shared-ui';

const STEPS = ['Plan', 'Datos', 'Confirmar'];
const COLORS = { darkPrimary: '#131921', accent: '#ff9900', purple: '#6C63FF' };

function slugify(raw: string): string {
  return raw
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9-]/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '')
    .slice(0, 63);
}

export default function RegistroPage() {
  const params = useSearchParams();
  const router = useRouter();

  const planSlug = params.get('plan') || 'erp-trial-30d';
  const modeParam = params.get('mode');
  const cycleParam = (params.get('cycle') === 'annual' ? 'annual' : 'monthly') as 'monthly' | 'annual';
  const addonSlugsCsv = params.get('addons') || '';
  const addonSlugs = addonSlugsCsv ? addonSlugsCsv.split(',').filter(Boolean) : [];

  const { data: planData, isLoading: loadingPlan, error: planError } = useCatalogPlan(planSlug);
  const plan = planData?.plan;

  const intendedMode: 'trial' | 'checkout' = useMemo(() => {
    if (modeParam === 'trial') return 'trial';
    if (modeParam === 'checkout') return 'checkout';
    return plan?.IsTrialOnly ? 'trial' : 'checkout';
  }, [modeParam, plan]);

  const [step, setStep] = useState(0);
  const [billing, setBilling] = useState<'monthly' | 'annual'>(cycleParam);

  const [email, setEmail] = useState('');
  const [fullName, setFullName] = useState('');
  const [companyName, setCompanyName] = useState('');
  const [countryCode, setCountryCode] = useState<string>('VE');
  const [phone, setPhone] = useState('');
  const [subdomain, setSubdomain] = useState('');
  const [subdomainTouched, setSubdomainTouched] = useState(false);

  // Auto-suggest subdomain from company name
  useEffect(() => {
    if (!subdomainTouched && companyName) {
      setSubdomain(slugify(companyName));
    }
  }, [companyName, subdomainTouched]);

  const { data: subdomainCheck, isFetching: checkingSubdomain } = useCheckSubdomain(subdomain);
  const subdomainAvailable = subdomainCheck?.available === true;

  const captureLead = useCaptureLead();
  const startTrial = useStartTrial();
  const startCheckout = useStartCheckout();

  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);

  const utm = {
    source: params.get('utm_source') || undefined,
    medium: params.get('utm_medium') || undefined,
    campaign: params.get('utm_campaign') || undefined,
  };

  // Captura lead al llegar al paso 2 (datos)
  useEffect(() => {
    if (step === 1 && email && /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
      captureLead.mutate({
        email,
        fullName,
        companyName,
        countryCode,
        planSlug,
        addonSlugs,
        subdomain,
        vertical: plan?.VerticalType,
        utm,
        source: 'registro-form',
      });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [step]);

  const emailValid = /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email);
  const step1Valid = Boolean(plan);
  const step2Valid = emailValid && fullName.length >= 2 && companyName.length >= 2 && subdomain.length >= 3 && subdomainAvailable;

  async function handleSubmit() {
    setSubmitting(true);
    setSubmitError(null);
    try {
      if (intendedMode === 'trial') {
        const result = await startTrial.mutateAsync({
          email, fullName, companyName, countryCode, subdomain, planSlug, addonSlugs, utm, vertical: plan?.VerticalType,
        });
        if (!result.ok) {
          setSubmitError(result.mensaje);
          return;
        }
        router.push(`/registro/exito?subdomain=${result.subdomain}&trial=1&magic=${result.magicLinkSent ? 1 : 0}&expires=${encodeURIComponent(result.expiresAt || '')}`);
      } else {
        const result = await startCheckout.mutateAsync({
          email, fullName, companyName, countryCode, subdomain, planSlug, addonSlugs, utm, vertical: plan?.VerticalType, billingCycle: billing,
        });
        if (!result.ok) {
          setSubmitError(result.mensaje);
          return;
        }
        if (result.checkoutUrl) {
          window.location.href = result.checkoutUrl;
        } else {
          setSubmitError('No se recibió URL de checkout de Paddle');
        }
      }
    } catch (err: any) {
      setSubmitError(err?.message || 'Error al procesar registro');
    } finally {
      setSubmitting(false);
    }
  }

  if (loadingPlan) {
    return (
      <Box sx={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <CircularProgress sx={{ color: COLORS.purple }} />
      </Box>
    );
  }

  if (planError || !plan) {
    return (
      <Container maxWidth="sm" sx={{ py: 8 }}>
        <Alert severity="error">Plan no encontrado: {planSlug}</Alert>
        <Button sx={{ mt: 2 }} href="/pricing">Ver planes disponibles</Button>
      </Container>
    );
  }

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: '#f5f5f5', py: { xs: 3, md: 6 } }}>
      <Container maxWidth="md">
        <Box sx={{ textAlign: 'center', mb: 4 }}>
          <Typography variant="h4" fontWeight={800} sx={{ color: COLORS.darkPrimary, mb: 1 }}>
            Crea tu cuenta en Zentto
          </Typography>
          <Typography variant="body1" color="text.secondary">
            {intendedMode === 'trial'
              ? `Prueba ${plan.Name} durante ${plan.TrialDays} días sin tarjeta de crédito.`
              : `Suscríbete a ${plan.Name}.`}
          </Typography>
        </Box>

        <Stepper activeStep={step} sx={{ mb: 4 }}>
          {STEPS.map((label) => (
            <Step key={label}><StepLabel>{label}</StepLabel></Step>
          ))}
        </Stepper>

        <Card elevation={3} sx={{ borderRadius: 3 }}>
          <CardContent sx={{ p: { xs: 3, md: 4 } }}>

            {step === 0 && (
              <Box>
                <Typography variant="h6" fontWeight={700} sx={{ mb: 2 }}>{plan.Name}</Typography>
                {plan.Description && (
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>{plan.Description}</Typography>
                )}

                {intendedMode === 'checkout' && !plan.IsTrialOnly && (
                  <Box sx={{ mb: 3 }}>
                    <Typography variant="body2" sx={{ mb: 1 }}>Ciclo de facturación</Typography>
                    <ToggleButtonGroup value={billing} exclusive onChange={(_, v) => v && setBilling(v)}>
                      <ToggleButton value="monthly" sx={{ px: 3, textTransform: 'none' }}>
                        Mensual — ${plan.MonthlyPrice.toFixed(2)}/mes
                      </ToggleButton>
                      <ToggleButton value="annual" sx={{ px: 3, textTransform: 'none' }} disabled={plan.AnnualPrice <= 0}>
                        Anual — ${(plan.AnnualPrice / 12).toFixed(2)}/mes (facturado ${plan.AnnualPrice.toFixed(2)})
                      </ToggleButton>
                    </ToggleButtonGroup>
                  </Box>
                )}

                <Box sx={{ display: 'flex', gap: 1, mb: 2, flexWrap: 'wrap' }}>
                  <Chip label={`${plan.MaxUsers} usuarios`} size="small" />
                  {plan.TrialDays > 0 && <Chip label={`${plan.TrialDays} días gratis`} color="warning" size="small" />}
                  {plan.IsAddon && <Chip label="Add-on vertical" color="info" size="small" />}
                </Box>

                <Box component="ul" sx={{ pl: 3, my: 2 }}>
                  {plan.Features.map((f, i) => (
                    <li key={i}><Typography variant="body2">{f}</Typography></li>
                  ))}
                </Box>

                <Box sx={{ display: 'flex', justifyContent: 'flex-end', mt: 3 }}>
                  <Button
                    variant="contained"
                    size="large"
                    onClick={() => setStep(1)}
                    disabled={!step1Valid}
                    sx={{ bgcolor: COLORS.purple, textTransform: 'none', fontWeight: 700, px: 4 }}
                  >
                    Continuar
                  </Button>
                </Box>
              </Box>
            )}

            {step === 1 && (
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                <TextField
                  label="Tu nombre completo"
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  required
                  fullWidth
                />
                <TextField
                  label="Email de trabajo"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value.trim())}
                  required
                  fullWidth
                  error={email.length > 0 && !emailValid}
                  helperText={email.length > 0 && !emailValid ? 'Email no válido' : undefined}
                />
                <TextField
                  label="Nombre de la empresa"
                  value={companyName}
                  onChange={(e) => setCompanyName(e.target.value)}
                  required
                  fullWidth
                />
                <CountrySelect value={countryCode} onChange={(c) => c && setCountryCode(c)} required />
                <PhoneInput
                  value={phone}
                  onChange={(v) => setPhone(v)}
                  defaultCountry={countryCode}
                  label="Teléfono (opcional)"
                />
                <TextField
                  label="Subdominio"
                  value={subdomain}
                  onChange={(e) => { setSubdomain(slugify(e.target.value)); setSubdomainTouched(true); }}
                  required
                  fullWidth
                  helperText={
                    subdomain.length < 3
                      ? 'Mínimo 3 caracteres, solo minúsculas, números y guiones'
                      : checkingSubdomain
                        ? 'Verificando disponibilidad...'
                        : subdomainCheck?.available
                          ? `✓ Disponible: ${subdomain}.zentto.net`
                          : subdomainCheck?.mensaje || 'Elige un subdominio disponible'
                  }
                  error={subdomain.length >= 3 && !checkingSubdomain && subdomainCheck?.available === false}
                  InputProps={{
                    endAdornment: (
                      <InputAdornment position="end">
                        {checkingSubdomain ? <CircularProgress size={16} /> :
                          subdomainAvailable ? <CheckCircleIcon sx={{ color: '#4caf50' }} /> :
                            subdomain.length >= 3 && subdomainCheck ? <ErrorOutlineIcon sx={{ color: '#f44336' }} /> : null}
                        <Typography variant="caption" sx={{ ml: 0.5, color: 'text.secondary' }}>.zentto.net</Typography>
                      </InputAdornment>
                    ),
                  }}
                />

                <Box sx={{ display: 'flex', justifyContent: 'space-between', mt: 2 }}>
                  <Button onClick={() => setStep(0)}>Atrás</Button>
                  <Button
                    variant="contained"
                    onClick={() => setStep(2)}
                    disabled={!step2Valid}
                    sx={{ bgcolor: COLORS.purple, textTransform: 'none', fontWeight: 700, px: 4 }}
                  >
                    Continuar
                  </Button>
                </Box>
              </Box>
            )}

            {step === 2 && (
              <Box>
                <Typography variant="h6" fontWeight={700} sx={{ mb: 2 }}>Revisa tus datos</Typography>
                <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: 'auto 1fr' }, rowGap: 1, columnGap: 2, mb: 3 }}>
                  <Typography color="text.secondary">Plan:</Typography>
                  <Typography fontWeight={600}>{plan.Name}{intendedMode === 'trial' ? ` — ${plan.TrialDays} días gratis` : ` — $${(billing === 'monthly' ? plan.MonthlyPrice : plan.AnnualPrice).toFixed(2)}/${billing === 'monthly' ? 'mes' : 'año'}`}</Typography>
                  <Typography color="text.secondary">Empresa:</Typography>
                  <Typography fontWeight={600}>{companyName}</Typography>
                  <Typography color="text.secondary">Email:</Typography>
                  <Typography fontWeight={600}>{email}</Typography>
                  <Typography color="text.secondary">URL:</Typography>
                  <Typography fontWeight={600}>{subdomain}.zentto.net</Typography>
                  <Typography color="text.secondary">País:</Typography>
                  <Typography fontWeight={600}>{countryCode}</Typography>
                </Box>

                {intendedMode === 'trial' && (
                  <Alert severity="info" sx={{ mb: 2 }}>
                    Te enviaremos un email con un link para configurar tu contraseña (válido 24h).
                    Tu prueba expira en {plan.TrialDays} días.
                  </Alert>
                )}
                {intendedMode === 'checkout' && (
                  <Alert severity="info" sx={{ mb: 2 }}>
                    Te redirigiremos al checkout seguro de Paddle para completar el pago.
                    Después crearemos automáticamente tu tenant en {subdomain}.zentto.net.
                  </Alert>
                )}

                {submitError && <Alert severity="error" sx={{ mb: 2 }}>{submitError}</Alert>}

                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Button onClick={() => setStep(1)} disabled={submitting}>Atrás</Button>
                  <Button
                    variant="contained"
                    size="large"
                    startIcon={submitting ? <CircularProgress size={18} color="inherit" /> : <RocketLaunchIcon />}
                    onClick={handleSubmit}
                    disabled={submitting}
                    sx={{ bgcolor: COLORS.accent, '&:hover': { bgcolor: '#e68a00' }, textTransform: 'none', fontWeight: 700, px: 4 }}
                  >
                    {submitting ? 'Procesando...' : intendedMode === 'trial' ? 'Crear mi cuenta gratis' : 'Ir al checkout seguro'}
                  </Button>
                </Box>
              </Box>
            )}

          </CardContent>
        </Card>

        <Box sx={{ textAlign: 'center', mt: 3 }}>
          <Typography variant="caption" color="text.secondary">
            Al continuar aceptas nuestros{' '}
            <a href="/terminos" style={{ color: COLORS.purple }}>Términos</a> y{' '}
            <a href="/privacidad" style={{ color: COLORS.purple }}>Privacidad</a>.
          </Typography>
        </Box>
      </Container>
    </Box>
  );
}
