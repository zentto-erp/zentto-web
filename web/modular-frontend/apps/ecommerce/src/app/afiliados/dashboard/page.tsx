'use client';

import { useEffect, useMemo, useState } from 'react';
import {
  Box, Container, Typography, Card, CardContent, Grid, Button, Chip, TextField,
  InputAdornment, IconButton, CircularProgress, Alert, Stack, Divider,
} from '@mui/material';
import ContentCopyIcon from '@mui/icons-material/ContentCopy';
import { useRouter } from 'next/navigation';
import { ZenttoRecordTable, type ColumnSpec } from '@zentto/shared-ui';
import {
  useAffiliateDashboard,
  useAffiliateCommissions,
  useCartStore,
  buildReferralUrl,
} from '@zentto/module-ecommerce';

const STATUS_LABELS: Record<string, { label: string; color: 'default' | 'info' | 'primary' | 'success' | 'warning' | 'error' }> = {
  pending:   { label: 'Pendiente', color: 'warning' },
  approved:  { label: 'Aprobada',  color: 'info' },
  paid:      { label: 'Pagada',    color: 'success' },
  reversed:  { label: 'Revertida', color: 'error' },
};

const commissionColumns: ColumnSpec[] = [
  { field: 'orderNumber', header: 'Orden', width: 150, sortable: true },
  { field: 'category', header: 'Categoría', width: 160, sortable: true },
  { field: 'rateLabel', header: 'Comisión %', width: 110, sortable: true },
  { field: 'commissionLabel', header: 'Monto', width: 140, sortable: true },
  { field: 'statusLabel', header: 'Estado', width: 140, sortable: true,
    statusColors: { Pendiente: 'warning', Aprobada: 'info', Pagada: 'success', Revertida: 'error' } as any,
  },
  { field: 'createdAtLabel', header: 'Fecha', width: 160, sortable: true },
];

export default function AfiliadoDashboardPage() {
  const router = useRouter();
  const customerToken = useCartStore((s) => s.customerToken);
  const { data: dashboard, isLoading, error } = useAffiliateDashboard();
  const { data: commissions } = useAffiliateCommissions({ page: 1, limit: 25 });
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    if (!customerToken) router.replace('/login?next=/afiliados/dashboard');
  }, [customerToken, router]);

  const referralUrl = useMemo(() => (dashboard ? buildReferralUrl(dashboard.referralCode) : ''), [dashboard]);

  const commissionRows = useMemo(() => {
    return (commissions?.rows ?? []).map((c) => ({
      id: c.id,
      orderNumber: c.orderNumber,
      category: c.category || '—',
      rateLabel: `${Number(c.rate).toFixed(1)}%`,
      commissionLabel: `${c.currencyCode || 'USD'} ${Number(c.commissionAmount).toFixed(2)}`,
      statusLabel: STATUS_LABELS[c.status]?.label ?? c.status,
      createdAtLabel: new Date(c.createdAt).toLocaleString('es-VE'),
    }));
  }, [commissions]);

  if (isLoading) {
    return (
      <Box sx={{ minHeight: '60vh', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
        <CircularProgress />
      </Box>
    );
  }

  if (error || !dashboard) {
    return (
      <Container maxWidth="md" sx={{ py: 6 }}>
        <Alert severity="warning">
          No tienes una cuenta de afiliado activa.{' '}
          <Button size="small" onClick={() => router.push('/afiliados/registro')}>Aplicar</Button>
        </Alert>
      </Container>
    );
  }

  const copyLink = () => {
    if (typeof navigator !== 'undefined' && navigator.clipboard && referralUrl) {
      navigator.clipboard.writeText(referralUrl).then(() => {
        setCopied(true);
        setTimeout(() => setCopied(false), 1500);
      });
    }
  };

  const statusChipColor: 'default' | 'success' | 'warning' | 'error' =
    dashboard.status === 'active' ? 'success' :
    dashboard.status === 'pending' ? 'warning' :
    dashboard.status === 'suspended' ? 'error' : 'default';

  return (
    <Box sx={{ bgcolor: '#eaeded', minHeight: '100vh', py: { xs: 3, md: 6 } }}>
      <Container maxWidth="lg">
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 3, flexWrap: 'wrap', gap: 2 }}>
          <Box>
            <Typography variant="h4" sx={{ fontWeight: 700, color: '#131921' }}>Mi panel de afiliado</Typography>
            <Typography variant="body2" sx={{ color: '#555' }}>
              {dashboard.legalName ?? 'Cuenta sin nombre legal'}
            </Typography>
          </Box>
          <Chip label={dashboard.status} color={statusChipColor} sx={{ textTransform: 'capitalize' }} />
        </Box>

        {/* Referral link */}
        <Card sx={{ borderRadius: 3, mb: 3 }}>
          <CardContent>
            <Typography variant="subtitle2" color="text.secondary">Tu enlace de referido</Typography>
            <Typography variant="h6" sx={{ fontWeight: 700, mb: 2 }}>
              Código: <span style={{ color: '#ff9900' }}>{dashboard.referralCode}</span>
            </Typography>
            <TextField
              fullWidth
              value={referralUrl}
              InputProps={{
                readOnly: true,
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton onClick={copyLink} edge="end" aria-label="Copiar">
                      <ContentCopyIcon />
                    </IconButton>
                  </InputAdornment>
                ),
              }}
            />
            {copied && <Alert severity="success" sx={{ mt: 1 }}>Enlace copiado</Alert>}
            {dashboard.status !== 'active' && (
              <Alert severity="info" sx={{ mt: 2 }}>
                Tu cuenta está en <b>{dashboard.status}</b>. El link empezará a acumular comisiones cuando sea aprobada.
              </Alert>
            )}
          </CardContent>
        </Card>

        {/* Métricas */}
        <Grid container spacing={2} sx={{ mb: 3 }}>
          {[
            { label: 'Clicks (12m)', value: dashboard.clicksTotal },
            { label: 'Conversiones', value: dashboard.conversions },
            { label: 'Pendiente', value: `${dashboard.currencyCode} ${dashboard.pendingAmount.toFixed(2)}` },
            { label: 'Aprobada',  value: `${dashboard.currencyCode} ${dashboard.approvedAmount.toFixed(2)}` },
            { label: 'Pagada',    value: `${dashboard.currencyCode} ${dashboard.paidAmount.toFixed(2)}` },
            { label: 'Total ganado', value: `${dashboard.currencyCode} ${dashboard.totalEarned.toFixed(2)}` },
          ].map((m) => (
            <Grid item xs={6} md={2} key={m.label}>
              <Card sx={{ borderRadius: 3 }}>
                <CardContent>
                  <Typography variant="caption" color="text.secondary">{m.label}</Typography>
                  <Typography variant="h6" sx={{ fontWeight: 700 }}>{m.value}</Typography>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>

        {/* Serie mensual (texto, sin lib extra) */}
        <Card sx={{ borderRadius: 3, mb: 3 }}>
          <CardContent>
            <Typography variant="h6" sx={{ fontWeight: 700, mb: 2 }}>Comisiones últimos 6 meses</Typography>
            {dashboard.monthly.length === 0 ? (
              <Typography variant="body2" color="text.secondary">
                Sin datos todavía — comparte tu enlace para empezar a generar comisiones.
              </Typography>
            ) : (
              <Stack direction="row" spacing={2} sx={{ overflowX: 'auto' }}>
                {dashboard.monthly.map((m) => (
                  <Box key={m.mon} sx={{ textAlign: 'center', minWidth: 90 }}>
                    <Typography variant="caption" color="text.secondary">{m.mon}</Typography>
                    <Typography variant="subtitle1" sx={{ fontWeight: 700, color: '#ff9900' }}>
                      {dashboard.currencyCode} {Number(m.amount).toFixed(2)}
                    </Typography>
                  </Box>
                ))}
              </Stack>
            )}
          </CardContent>
        </Card>

        <Divider sx={{ my: 3 }} />

        {/* Tabla de comisiones */}
        <Typography variant="h6" sx={{ fontWeight: 700, mb: 2 }}>Comisiones recientes</Typography>
        <Card sx={{ borderRadius: 3 }}>
          <Box sx={{ p: 1 }}>
            <ZenttoRecordTable
              recordType="affiliate-commissions"
              rows={commissionRows}
              columns={commissionColumns}
              height="auto"
              emptyState={{ title: 'Aún no tienes comisiones', description: 'Comparte tu enlace para empezar a generarlas.' }}
            />
          </Box>
        </Card>
      </Container>
    </Box>
  );
}
