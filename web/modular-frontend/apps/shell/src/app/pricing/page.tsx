'use client';

import React, { useEffect, useState } from 'react';
import {
  Box, Container, Typography, ToggleButtonGroup, ToggleButton,
  Card, CardContent, CardActions, Button, Chip, List, ListItem,
  ListItemIcon, ListItemText, CircularProgress, Alert, Tabs, Tab,
} from '@mui/material';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import RocketLaunchIcon from '@mui/icons-material/RocketLaunch';

const API_BASE = process.env.NEXT_PUBLIC_API_BASE_URL || process.env.NEXT_PUBLIC_API_URL || 'https://api.zentto.net';

const COLORS = {
  darkPrimary: '#131921',
  accent: '#ff9900',
  purple: '#6C63FF',
  bg: '#f5f5f5',
  white: '#ffffff',
} as const;

const VERTICALS = [
  { key: 'erp', label: 'ERP' },
  { key: 'medical', label: 'Salud' },
  { key: 'tickets', label: 'Tickets' },
  { key: 'hotel', label: 'Hoteleria' },
  { key: 'education', label: 'Educacion' },
] as const;

interface PricingPlan {
  PricingPlanId: number;
  Name: string;
  Slug: string;
  VerticalType: string;
  MonthlyPrice: number;
  AnnualPrice: number;
  TransactionFeePercent: number;
  MaxUsers: number;
  MaxTransactions: number;
  Features: string[];
  IsActive: boolean;
}

export default function PricingPage() {
  const [plans, setPlans] = useState<PricingPlan[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [billing, setBilling] = useState<'monthly' | 'annual'>('monthly');
  const [vertical, setVertical] = useState('erp');

  useEffect(() => {
    setLoading(true);
    setError(null);
    fetch(`${API_BASE}/v1/pricing/plans?vertical=${vertical}`)
      .then(async (res) => {
        if (!res.ok) throw new Error('Error al cargar planes');
        const data = await res.json();
        setPlans(data);
      })
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, [vertical]);

  const formatPrice = (price: number) =>
    new Intl.NumberFormat('es', { style: 'currency', currency: 'USD', minimumFractionDigits: 0 }).format(price);

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: COLORS.bg, py: { xs: 4, md: 8 } }}>
      <Container maxWidth="lg">
        {/* Header */}
        <Box sx={{ textAlign: 'center', mb: 5 }}>
          <Typography variant="h3" fontWeight={800} sx={{ color: COLORS.darkPrimary, mb: 1, fontSize: { xs: '1.8rem', md: '2.5rem' } }}>
            Planes y Precios
          </Typography>
          <Typography variant="h6" sx={{ color: 'text.secondary', mb: 3, fontWeight: 400 }}>
            Elige el plan perfecto para tu negocio. Sin contratos, cancela cuando quieras.
          </Typography>

          {/* Vertical tabs */}
          <Tabs
            value={vertical}
            onChange={(_, v) => setVertical(v)}
            centered
            sx={{ mb: 3, '& .MuiTab-root': { fontWeight: 600, textTransform: 'none', fontSize: '0.95rem' } }}
          >
            {VERTICALS.map((v) => (
              <Tab key={v.key} label={v.label} value={v.key} />
            ))}
          </Tabs>

          {/* Billing toggle */}
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

        {/* Loading / Error */}
        {loading && (
          <Box sx={{ textAlign: 'center', py: 6 }}>
            <CircularProgress sx={{ color: COLORS.purple }} />
          </Box>
        )}
        {error && (
          <Alert severity="error" sx={{ mb: 3 }}>{error}</Alert>
        )}

        {/* Plans grid */}
        {!loading && !error && (
          <Box sx={{
            display: 'grid',
            gridTemplateColumns: { xs: '1fr', md: `repeat(${Math.min(plans.length, 3)}, 1fr)` },
            gap: 3,
            alignItems: 'stretch',
          }}>
            {plans.map((plan, idx) => {
              const price = billing === 'monthly' ? plan.MonthlyPrice : plan.AnnualPrice;
              const perMonth = billing === 'annual' ? plan.AnnualPrice / 12 : plan.MonthlyPrice;
              const isPopular = idx === Math.min(1, plans.length - 1);

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
                      label="Mas popular"
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
                      <Chip label={`${plan.MaxTransactions.toLocaleString()} tx/mes`} size="small" variant="outlined" />
                      {plan.TransactionFeePercent > 0 && (
                        <Chip label={`${plan.TransactionFeePercent}% fee`} size="small" variant="outlined" />
                      )}
                    </Box>

                    <List dense disablePadding>
                      {(plan.Features as string[]).map((feat, i) => (
                        <ListItem key={i} disableGutters sx={{ py: 0.3 }}>
                          <ListItemIcon sx={{ minWidth: 28 }}>
                            <CheckCircleIcon sx={{ fontSize: 18, color: '#4caf50' }} />
                          </ListItemIcon>
                          <ListItemText
                            primary={feat}
                            primaryTypographyProps={{ variant: 'body2' }}
                          />
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
                      href={`/signup?plan=${plan.Slug}`}
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
                      Comenzar ahora
                    </Button>
                  </CardActions>
                </Card>
              );
            })}
          </Box>
        )}

        {/* Empty state */}
        {!loading && !error && plans.length === 0 && (
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
