'use client';

import React, { useMemo, useState } from 'react';
import {
  Box, Container, Typography, ToggleButtonGroup, ToggleButton,
  Card, CardContent, CardActions, Button, Chip, List, ListItem,
  ListItemIcon, ListItemText, CircularProgress, Alert, Tabs, Tab,
} from '@mui/material';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import RocketLaunchIcon from '@mui/icons-material/RocketLaunch';
import { useCatalogPlans } from '@zentto/shared-api';

const COLORS = {
  darkPrimary: '#131921',
  accent: '#ff9900',
  purple: '#6C63FF',
  bg: '#f5f5f5',
  white: '#ffffff',
} as const;

// Vertical 'erp' sección base; el resto son add-ons. 'all' muestra catálogo completo.
const VERTICALS = [
  { key: 'erp', label: 'ERP' },
  { key: 'medical', label: 'Salud' },
  { key: 'tickets', label: 'Tickets' },
  { key: 'hotel', label: 'Hotelería' },
  { key: 'education', label: 'Educación' },
  { key: 'rental', label: 'Rental' },
] as const;

export default function PricingPage() {
  const [billing, setBilling] = useState<'monthly' | 'annual'>('monthly');
  const [vertical, setVertical] = useState<(typeof VERTICALS)[number]['key']>('erp');

  const { data, isLoading, error } = useCatalogPlans({ vertical, includeTrial: true });
  const allPlans = data?.plans ?? [];

  // Separar trial (si existe) del resto de planes pagados
  const trialPlan = allPlans.find((p) => p.IsTrialOnly);
  const paidPlans = allPlans.filter((p) => !p.IsTrialOnly).sort((a, b) => a.SortOrder - b.SortOrder);

  const formatPrice = (price: number) =>
    new Intl.NumberFormat('es', { style: 'currency', currency: 'USD', minimumFractionDigits: 2 }).format(price);

  const popularIdx = useMemo(() => {
    if (paidPlans.length === 0) return -1;
    // El más popular = el que tiene más features o el intermedio
    return Math.min(1, paidPlans.length - 1);
  }, [paidPlans.length]);

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: COLORS.bg, py: { xs: 4, md: 8 } }}>
      <Container maxWidth="lg">
        <Box sx={{ textAlign: 'center', mb: 5 }}>
          <Typography variant="h3" fontWeight={800} sx={{ color: COLORS.darkPrimary, mb: 1, fontSize: { xs: '1.8rem', md: '2.5rem' } }}>
            Planes y Precios
          </Typography>
          <Typography variant="h6" sx={{ color: 'text.secondary', mb: 3, fontWeight: 400 }}>
            Comienza gratis 30 días. Sin contratos, cancela cuando quieras.
          </Typography>

          <Tabs
            value={vertical}
            onChange={(_, v) => setVertical(v)}
            centered
            variant="scrollable"
            scrollButtons="auto"
            sx={{ mb: 3, '& .MuiTab-root': { fontWeight: 600, textTransform: 'none', fontSize: '0.95rem' } }}
          >
            {VERTICALS.map((v) => (
              <Tab key={v.key} label={v.label} value={v.key} />
            ))}
          </Tabs>

          <ToggleButtonGroup
            value={billing}
            exclusive
            onChange={(_, val) => val && setBilling(val)}
            sx={{ mb: 1 }}
          >
            <ToggleButton value="monthly" sx={{ px: 3, fontWeight: 600, textTransform: 'none' }}>
              Mensual
            </ToggleButton>
            <ToggleButton value="annual" sx={{ px: 3, fontWeight: 600, textTransform: 'none' }}>
              Anual
              <Chip label="~17% off" size="small" color="success" sx={{ ml: 1, fontWeight: 700 }} />
            </ToggleButton>
          </ToggleButtonGroup>
        </Box>

        {isLoading && (
          <Box sx={{ textAlign: 'center', py: 6 }}>
            <CircularProgress sx={{ color: COLORS.purple }} />
          </Box>
        )}
        {error && (
          <Alert severity="error" sx={{ mb: 3 }}>{(error as Error).message || 'Error al cargar planes'}</Alert>
        )}

        {/* Trial destacado arriba si hay */}
        {!isLoading && !error && trialPlan && (
          <Card
            elevation={4}
            sx={{
              mb: 4,
              borderRadius: 3,
              border: `2px dashed ${COLORS.accent}`,
              bgcolor: '#fffbf0',
            }}
          >
            <CardContent sx={{ p: 3, display: 'flex', flexDirection: { xs: 'column', md: 'row' }, alignItems: 'center', gap: 2 }}>
              <Box sx={{ flex: 1 }}>
                <Chip label={`${trialPlan.TrialDays} días gratis`} color="warning" sx={{ fontWeight: 700, mb: 1 }} />
                <Typography variant="h5" fontWeight={800} sx={{ color: COLORS.darkPrimary }}>
                  {trialPlan.Name}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  {trialPlan.Description}
                </Typography>
              </Box>
              <Button
                variant="contained"
                size="large"
                href={`/registro?plan=${trialPlan.Slug}&mode=trial`}
                sx={{
                  bgcolor: COLORS.accent,
                  '&:hover': { bgcolor: '#e68a00' },
                  fontWeight: 700,
                  textTransform: 'none',
                  px: 4,
                  py: 1.5,
                  borderRadius: 2,
                }}
              >
                Comenzar prueba gratis
              </Button>
            </CardContent>
          </Card>
        )}

        {!isLoading && !error && (
          <Box sx={{
            display: 'grid',
            gridTemplateColumns: { xs: '1fr', md: `repeat(${Math.min(paidPlans.length, 3)}, 1fr)` },
            gap: 3,
            alignItems: 'stretch',
          }}>
            {paidPlans.map((plan, idx) => {
              const price = billing === 'monthly' ? plan.MonthlyPrice : plan.AnnualPrice;
              const perMonth = billing === 'annual' ? plan.AnnualPrice / 12 : plan.MonthlyPrice;
              const isPopular = idx === popularIdx;
              const canCheckout = Boolean(billing === 'annual' ? plan.PaddlePriceIdAnnual : plan.PaddlePriceIdMonthly);

              return (
                <Card
                  key={plan.PricingPlanId}
                  elevation={isPopular ? 8 : 2}
                  sx={{
                    borderRadius: 3,
                    border: isPopular ? `2px solid ${COLORS.purple}` : '1px solid #e0e0e0',
                    position: 'relative',
                    display: 'flex',
                    flexDirection: 'column',
                  }}
                >
                  {isPopular && (
                    <Chip
                      label="Más popular"
                      size="small"
                      sx={{
                        position: 'absolute', top: -12, left: '50%', transform: 'translateX(-50%)',
                        bgcolor: COLORS.purple, color: '#fff', fontWeight: 700,
                      }}
                    />
                  )}

                  <CardContent sx={{ p: 4, flexGrow: 1 }}>
                    <Typography variant="h5" fontWeight={700} sx={{ color: COLORS.darkPrimary, mb: 1 }}>
                      {plan.Name}
                    </Typography>
                    {plan.Description && (
                      <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                        {plan.Description}
                      </Typography>
                    )}

                    <Box sx={{ mb: 2 }}>
                      <Typography component="span" variant="h3" fontWeight={800} sx={{ color: COLORS.purple }}>
                        {formatPrice(perMonth)}
                      </Typography>
                      <Typography component="span" variant="body1" sx={{ color: 'text.secondary' }}>
                        /mes
                      </Typography>
                      {billing === 'annual' && (
                        <Typography variant="body2" sx={{ color: 'text.disabled' }}>
                          {formatPrice(price)} facturado anual
                        </Typography>
                      )}
                    </Box>

                    <Box sx={{ display: 'flex', gap: 1, mb: 2, flexWrap: 'wrap' }}>
                      <Chip label={`${plan.MaxUsers} usuarios`} size="small" variant="outlined" />
                      {plan.MaxTransactions > 0 && (
                        <Chip label={`${plan.MaxTransactions.toLocaleString()} tx/mes`} size="small" variant="outlined" />
                      )}
                      {plan.IsAddon && (
                        <Chip label="Add-on vertical" size="small" color="warning" />
                      )}
                    </Box>

                    <List dense disablePadding>
                      {plan.Features.map((feat, i) => (
                        <ListItem key={i} disableGutters sx={{ py: 0.3 }}>
                          <ListItemIcon sx={{ minWidth: 28 }}>
                            <CheckCircleIcon sx={{ fontSize: 18, color: '#4caf50' }} />
                          </ListItemIcon>
                          <ListItemText primary={feat} primaryTypographyProps={{ variant: 'body2' }} />
                        </ListItem>
                      ))}
                    </List>
                  </CardContent>

                  <CardActions sx={{ p: 3, pt: 0 }}>
                    <Button
                      fullWidth
                      variant={isPopular ? 'contained' : 'outlined'}
                      size="large"
                      startIcon={<RocketLaunchIcon />}
                      href={`/registro?plan=${plan.Slug}&mode=checkout&cycle=${billing}`}
                      disabled={!canCheckout}
                      sx={{
                        py: 1.5,
                        fontWeight: 700,
                        borderRadius: 2,
                        textTransform: 'none',
                        fontSize: '1rem',
                        ...(isPopular
                          ? { bgcolor: COLORS.purple, '&:hover': { bgcolor: '#5b54e6' } }
                          : { borderColor: COLORS.purple, color: COLORS.purple }),
                      }}
                    >
                      {canCheckout ? 'Comenzar ahora' : 'Próximamente'}
                    </Button>
                  </CardActions>
                </Card>
              );
            })}
          </Box>
        )}

        {!isLoading && !error && paidPlans.length === 0 && !trialPlan && (
          <Box sx={{ textAlign: 'center', py: 6 }}>
            <Typography variant="h6" color="text.secondary">
              No hay planes disponibles para esta vertical.
            </Typography>
          </Box>
        )}
      </Container>
    </Box>
  );
}
