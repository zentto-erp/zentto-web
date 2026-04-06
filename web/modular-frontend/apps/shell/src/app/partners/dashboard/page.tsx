'use client';

import React, { useEffect, useState, useCallback } from 'react';
import {
  Box, Container, Typography, Paper, Card, CardContent, Grid,
  CircularProgress, Alert, Chip, Button,
} from '@mui/material';
import PeopleIcon from '@mui/icons-material/People';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import HourglassTopIcon from '@mui/icons-material/HourglassTop';
import AttachMoneyIcon from '@mui/icons-material/AttachMoney';
import PaidIcon from '@mui/icons-material/Paid';
import PendingActionsIcon from '@mui/icons-material/PendingActions';
import ContentCopyIcon from '@mui/icons-material/ContentCopy';

const API_BASE = process.env.NEXT_PUBLIC_API_BASE_URL || process.env.NEXT_PUBLIC_API_URL || 'https://api.zentto.net';

const COLORS = {
  darkPrimary: '#131921',
  purple: '#6C63FF',
  bg: '#f5f5f5',
} as const;

interface Partner {
  PartnerId: number;
  CompanyName: string;
  ContactName: string;
  Email: string;
  Status: string;
  CommissionPercent: number;
  ApiKey: string;
}

interface Dashboard {
  TotalReferrals: number;
  ConvertedReferrals: number;
  PendingReferrals: number;
  TotalCommission: number;
  PaidCommission: number;
  PendingCommission: number;
}

interface Referral {
  PartnerReferralId: number;
  ReferredCompanyId: number;
  Status: string;
  CommissionAmount: number;
  PaidAt: string | null;
  CreatedAt: string;
}

const STATUS_COLOR: Record<string, 'success' | 'warning' | 'error' | 'default'> = {
  converted: 'success',
  pending: 'warning',
  cancelled: 'error',
};

export default function PartnerDashboardPage() {
  const [partner, setPartner] = useState<Partner | null>(null);
  const [dashboard, setDashboard] = useState<Dashboard | null>(null);
  const [referrals, setReferrals] = useState<Referral[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const opts: RequestInit = { credentials: 'include' };
      const [pRes, dRes, rRes] = await Promise.all([
        fetch(`${API_BASE}/v1/partners/me`, opts),
        fetch(`${API_BASE}/v1/partners/dashboard`, opts),
        fetch(`${API_BASE}/v1/partners/referrals`, opts),
      ]);

      if (!pRes.ok) {
        const body = await pRes.json().catch(() => ({}));
        throw new Error(body.error || 'No se pudo cargar tu perfil de partner');
      }

      const [pData, dData, rData] = await Promise.all([
        pRes.json(),
        dRes.ok ? dRes.json() : null,
        rRes.ok ? rRes.json() : [],
      ]);

      setPartner(pData);
      setDashboard(dData);
      setReferrals(rData);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchData(); }, [fetchData]);

  const referralLink = partner
    ? `https://zentto.net/signup?ref=${partner.ApiKey?.slice(0, 16)}`
    : '';

  const handleCopy = () => {
    navigator.clipboard.writeText(referralLink);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const formatCurrency = (val: number) =>
    new Intl.NumberFormat('es', { style: 'currency', currency: 'USD' }).format(val);

  if (loading) {
    return (
      <Box sx={{ minHeight: '60vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <CircularProgress sx={{ color: COLORS.purple }} />
      </Box>
    );
  }

  if (error) {
    return (
      <Container maxWidth="sm" sx={{ py: 8 }}>
        <Alert severity="error">{error}</Alert>
      </Container>
    );
  }

  const kpis = [
    { label: 'Referidos totales', value: dashboard?.TotalReferrals ?? 0, icon: <PeopleIcon /> },
    { label: 'Convertidos', value: dashboard?.ConvertedReferrals ?? 0, icon: <CheckCircleIcon /> },
    { label: 'Pendientes', value: dashboard?.PendingReferrals ?? 0, icon: <HourglassTopIcon /> },
    { label: 'Comision total', value: formatCurrency(dashboard?.TotalCommission ?? 0), icon: <AttachMoneyIcon /> },
    { label: 'Comision pagada', value: formatCurrency(dashboard?.PaidCommission ?? 0), icon: <PaidIcon /> },
    { label: 'Comision pendiente', value: formatCurrency(dashboard?.PendingCommission ?? 0), icon: <PendingActionsIcon /> },
  ];

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: COLORS.bg, py: { xs: 3, md: 6 } }}>
      <Container maxWidth="lg">
        {/* Header */}
        <Box sx={{ mb: 4 }}>
          <Typography variant="h4" fontWeight={700} sx={{ color: COLORS.darkPrimary }}>
            Dashboard Partner
          </Typography>
          <Typography variant="body1" color="text.secondary">
            {partner?.CompanyName} — {partner?.ContactName}
            <Chip
              label={partner?.Status}
              size="small"
              color={partner?.Status === 'active' ? 'success' : partner?.Status === 'approved' ? 'info' : 'warning'}
              sx={{ ml: 1 }}
            />
          </Typography>
        </Box>

        {/* Referral Link */}
        <Paper sx={{ p: 3, mb: 4, borderRadius: 2, display: 'flex', alignItems: 'center', gap: 2, flexWrap: 'wrap' }}>
          <Box sx={{ flexGrow: 1 }}>
            <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 0.5 }}>
              Tu link de referido
            </Typography>
            <Typography variant="body1" fontWeight={600} sx={{ wordBreak: 'break-all', color: COLORS.purple }}>
              {referralLink}
            </Typography>
          </Box>
          <Button
            variant="outlined"
            startIcon={<ContentCopyIcon />}
            onClick={handleCopy}
            sx={{ borderColor: COLORS.purple, color: COLORS.purple, textTransform: 'none', fontWeight: 600 }}
          >
            {copied ? 'Copiado!' : 'Copiar'}
          </Button>
        </Paper>

        {/* KPIs */}
        <Grid container spacing={2} sx={{ mb: 4 }}>
          {kpis.map((kpi, i) => (
            <Grid item xs={6} md={2} key={i}>
              <Card elevation={1} sx={{ borderRadius: 2, textAlign: 'center' }}>
                <CardContent sx={{ py: 2 }}>
                  <Box sx={{ color: COLORS.purple, mb: 0.5 }}>{kpi.icon}</Box>
                  <Typography variant="h5" fontWeight={700} sx={{ color: COLORS.darkPrimary }}>
                    {kpi.value}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    {kpi.label}
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>

        {/* Referrals table */}
        <Paper sx={{ borderRadius: 2, overflow: 'hidden' }}>
          <Box sx={{ p: 2, borderBottom: '1px solid #e0e0e0' }}>
            <Typography variant="h6" fontWeight={600}>Referidos</Typography>
          </Box>
          {referrals.length === 0 ? (
            <Box sx={{ p: 4, textAlign: 'center' }}>
              <Typography color="text.secondary">Aun no tienes referidos. Comparte tu link para empezar.</Typography>
            </Box>
          ) : (
            <Box sx={{ overflowX: 'auto' }}>
              <Box
                component="table"
                sx={{ width: '100%', borderCollapse: 'collapse', '& th, & td': { p: 1.5, textAlign: 'left', borderBottom: '1px solid #f0f0f0' }, '& th': { fontWeight: 600, bgcolor: '#fafafa' } }}
              >
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Empresa referida</th>
                    <th>Estado</th>
                    <th>Comision</th>
                    <th>Fecha</th>
                    <th>Pagado</th>
                  </tr>
                </thead>
                <tbody>
                  {referrals.map((r) => (
                    <tr key={r.PartnerReferralId}>
                      <td>{r.PartnerReferralId}</td>
                      <td>#{r.ReferredCompanyId}</td>
                      <td>
                        <Chip
                          label={r.Status}
                          size="small"
                          color={STATUS_COLOR[r.Status] ?? 'default'}
                        />
                      </td>
                      <td>{formatCurrency(r.CommissionAmount)}</td>
                      <td>{new Date(r.CreatedAt).toLocaleDateString('es')}</td>
                      <td>{r.PaidAt ? new Date(r.PaidAt).toLocaleDateString('es') : '-'}</td>
                    </tr>
                  ))}
                </tbody>
              </Box>
            </Box>
          )}
        </Paper>
      </Container>
    </Box>
  );
}
