'use client';

import { useEffect, useMemo, useState } from 'react';
import {
  Box, Container, Typography, Card, CardContent, Grid, Button, Chip, TextField,
  InputAdornment, IconButton, CircularProgress, Alert, Stack,
  Accordion, AccordionSummary, AccordionDetails,
} from '@mui/material';
import ContentCopyIcon from '@mui/icons-material/ContentCopy';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import QrCode2Icon from '@mui/icons-material/QrCode2';
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

const materialBanners = [
  { size: '728x90', label: 'Leaderboard', color: '#131921' },
  { size: '300x250', label: 'Medium Rectangle', color: '#232f3e' },
  { size: '160x600', label: 'Wide Skyscraper', color: '#ff9900' },
  { size: '320x100', label: 'Large Mobile Banner', color: '#131921' },
  { size: '970x250', label: 'Billboard', color: '#232f3e' },
  { size: '336x280', label: 'Large Rectangle', color: '#ff9900' },
];

/**
 * LineChart minimalista en SVG puro (sin deps extra).
 * Eje X: meses (últimos 6), eje Y: monto USD.
 */
function InlineLineChart({ data, height = 180 }: { data: Array<{ mon: string; amount: number }>; height?: number }) {
  const width = 720;
  const pad = { left: 40, right: 20, top: 20, bottom: 30 };
  const max = Math.max(...data.map((d) => d.amount), 1);
  const points = data.map((d, i) => {
    const x = pad.left + (i * (width - pad.left - pad.right)) / Math.max(data.length - 1, 1);
    const y = height - pad.bottom - (d.amount / max) * (height - pad.top - pad.bottom);
    return { x, y, ...d };
  });
  const path = points.map((p, i) => (i === 0 ? 'M' : 'L') + p.x.toFixed(1) + ' ' + p.y.toFixed(1)).join(' ');

  return (
    <Box sx={{ width: '100%', overflowX: 'auto' }}>
      <svg viewBox={`0 0 ${width} ${height}`} width="100%" height={height} style={{ maxWidth: width, display: 'block' }}>
        {/* grid Y */}
        {[0.25, 0.5, 0.75].map((p) => (
          <line key={p}
            x1={pad.left} x2={width - pad.right}
            y1={pad.top + p * (height - pad.top - pad.bottom)}
            y2={pad.top + p * (height - pad.top - pad.bottom)}
            stroke="#e8eaed" strokeDasharray="2,3"
          />
        ))}
        {/* X labels */}
        {points.map((p) => (
          <text key={p.mon} x={p.x} y={height - 8} fontSize={11} textAnchor="middle" fill="#565959">
            {p.mon}
          </text>
        ))}
        {/* Línea + área */}
        <path d={`${path} L${points[points.length - 1]?.x ?? pad.left} ${height - pad.bottom} L${pad.left} ${height - pad.bottom} Z`} fill="rgba(255,153,0,0.12)" />
        <path d={path} fill="none" stroke="#ff9900" strokeWidth={2} />
        {/* Puntos */}
        {points.map((p) => (
          <g key={p.mon}>
            <circle cx={p.x} cy={p.y} r={3.5} fill="#ff9900" />
            <title>{p.mon}: ${p.amount.toFixed(2)}</title>
          </g>
        ))}
      </svg>
    </Box>
  );
}

export default function AfiliadoDashboardPage() {
  const router = useRouter();
  const customerToken = useCartStore((s) => s.customerToken);
  const { data: dashboard, isLoading, error } = useAffiliateDashboard();
  const { data: commissions } = useAffiliateCommissions({ page: 1, limit: 25 });
  const [copied, setCopied] = useState(false);
  const [showQr, setShowQr] = useState(false);

  useEffect(() => {
    if (!customerToken) router.replace('/login?next=/afiliados/dashboard');
  }, [customerToken, router]);

  const referralUrl = useMemo(() => (dashboard ? buildReferralUrl(dashboard.referralCode) : ''), [dashboard]);

  // QR: usamos `qrcode-generator` (ya es dep del paquete module-ecommerce).
  // Fallback a servicio externo si falla la importación dinámica (ej. SSR).
  const [qrDataUrl, setQrDataUrl] = useState<string>('');
  const qrImgUrl = useMemo(() => {
    if (!referralUrl) return '';
    return qrDataUrl || `https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=${encodeURIComponent(referralUrl)}`;
  }, [referralUrl, qrDataUrl]);
  useEffect(() => {
    if (!referralUrl) { setQrDataUrl(''); return; }
    let cancelled = false;
    (async () => {
      try {
        const mod = await import('qrcode-generator');
        const QRCode = (mod as any).default ?? (mod as any);
        const qr = QRCode(0, 'M');
        qr.addData(referralUrl);
        qr.make();
        const svgTag = qr.createSvgTag({ cellSize: 4, margin: 2 });
        const dataUrl = `data:image/svg+xml;utf8,${encodeURIComponent(svgTag)}`;
        if (!cancelled) setQrDataUrl(dataUrl);
      } catch {
        /* deja fallback al servicio externo */
      }
    })();
    return () => { cancelled = true; };
  }, [referralUrl]);

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

  // KPIs Ola 4 (4 cards principales)
  const kpiCards = [
    { label: 'Clicks este mes', value: dashboard.clicksTotal, accent: '#131921' },
    { label: 'Conversiones',    value: dashboard.conversions, accent: '#232f3e' },
    { label: 'Comisión pendiente', value: `${dashboard.currencyCode} ${dashboard.pendingAmount.toFixed(2)}`, accent: '#ff9900' },
    { label: 'Balance disponible', value: `${dashboard.currencyCode} ${dashboard.approvedAmount.toFixed(2)}`, accent: '#16a34a' },
  ];

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

        {/* KPI cards (4 columnas desktop, 2 mobile) */}
        <Grid container spacing={2} sx={{ mb: 3 }}>
          {kpiCards.map((m) => (
            <Grid item xs={6} md={3} key={m.label}>
              <Card sx={{ borderRadius: 2, boxShadow: '0 1px 3px rgba(0,0,0,0.06)' }}>
                <CardContent sx={{ p: 2.5 }}>
                  <Typography variant="caption" sx={{ color: '#565959', fontSize: 12 }}>{m.label}</Typography>
                  <Typography variant="h5" sx={{ fontWeight: 700, color: '#0f1111', mt: 0.5 }}>
                    {m.value}
                  </Typography>
                  <Box sx={{ mt: 1, height: 3, borderRadius: 2, bgcolor: m.accent, width: 32 }} />
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>

        {/* Link de referido + QR */}
        <Card sx={{ borderRadius: 2, mb: 3 }}>
          <CardContent>
            <Typography variant="subtitle2" color="text.secondary">Tu enlace de referido</Typography>
            <Typography variant="h6" sx={{ fontWeight: 700, mb: 2 }}>
              Código: <span style={{ color: '#ff9900' }}>{dashboard.referralCode}</span>
            </Typography>
            <Stack direction={{ xs: 'column', md: 'row' }} spacing={2} alignItems={{ md: 'center' }}>
              <TextField
                fullWidth
                value={referralUrl}
                InputProps={{
                  readOnly: true,
                  endAdornment: (
                    <InputAdornment position="end">
                      <IconButton onClick={copyLink} edge="end" aria-label="Copiar enlace">
                        <ContentCopyIcon />
                      </IconButton>
                    </InputAdornment>
                  ),
                }}
              />
              <Button
                variant="outlined" startIcon={<QrCode2Icon />}
                onClick={() => setShowQr((v) => !v)}
                sx={{ borderColor: '#ff9900', color: '#131921', minWidth: 140 }}
              >
                {showQr ? 'Ocultar QR' : 'Ver QR'}
              </Button>
            </Stack>
            {showQr && qrImgUrl && (
              <Box sx={{ mt: 2, display: 'flex', gap: 2, alignItems: 'center' }}>
                <img src={qrImgUrl} alt="QR del enlace de referido" width={180} height={180} style={{ borderRadius: 8, border: '1px solid #e0e0e0' }} />
                <Typography variant="body2" color="text.secondary">
                  Imprime o comparte este QR en tus publicaciones. Cuando alguien lo escanee, tus comisiones se acreditarán automáticamente.
                </Typography>
              </Box>
            )}
            {copied && <Alert severity="success" sx={{ mt: 2 }}>Link copiado</Alert>}
            {dashboard.status !== 'active' && (
              <Alert severity="info" sx={{ mt: 2 }}>
                Tu cuenta está en <b>{dashboard.status}</b>. El link empezará a acumular comisiones cuando sea aprobada.
              </Alert>
            )}
          </CardContent>
        </Card>

        {/* Gráfico ventas/comisiones últimos 6 meses */}
        <Card sx={{ borderRadius: 2, mb: 3 }}>
          <CardContent>
            <Typography variant="h6" sx={{ fontWeight: 700, mb: 2 }}>Ventas (últimos 6 meses)</Typography>
            {dashboard.monthly.length === 0 ? (
              <Typography variant="body2" color="text.secondary">
                Sin datos todavía — comparte tu enlace para empezar a generar comisiones.
              </Typography>
            ) : (
              <InlineLineChart data={dashboard.monthly.slice(-6).map((m) => ({ mon: m.mon, amount: Number(m.amount) }))} />
            )}
          </CardContent>
        </Card>

        {/* Acordeón: Comisiones (default open) */}
        <Accordion defaultExpanded sx={{ borderRadius: 2, mb: 2 }}>
          <AccordionSummary expandIcon={<ExpandMoreIcon />}>
            <Typography sx={{ fontWeight: 700 }}>Comisiones</Typography>
          </AccordionSummary>
          <AccordionDetails>
            <Card sx={{ borderRadius: 2 }}>
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
          </AccordionDetails>
        </Accordion>

        {/* Acordeón: Retiros */}
        <Accordion sx={{ borderRadius: 2, mb: 2 }}>
          <AccordionSummary expandIcon={<ExpandMoreIcon />}>
            <Typography sx={{ fontWeight: 700 }}>Retiros</Typography>
          </AccordionSummary>
          <AccordionDetails>
            <Stack spacing={2}>
              <Typography variant="body2" color="text.secondary">
                Balance disponible para retiro: <b>{dashboard.currencyCode} {dashboard.approvedAmount.toFixed(2)}</b>.
                Monto mínimo de retiro: <b>USD 50</b>.
              </Typography>
              <Box>
                <Button
                  variant="contained"
                  disabled={dashboard.approvedAmount < 50 || dashboard.status !== 'active'}
                  sx={{ bgcolor: '#ff9900', color: '#131921', fontWeight: 700, '&:hover': { bgcolor: '#e68a00' } }}
                >
                  Solicitar retiro
                </Button>
              </Box>
              <Typography variant="caption" color="text.secondary">
                Los retiros se procesan los días 1 y 15 de cada mes. Método configurado: <b>{(dashboard as { payoutMethod?: string }).payoutMethod ?? 'pendiente'}</b>.
              </Typography>
            </Stack>
          </AccordionDetails>
        </Accordion>

        {/* Acordeón: Material promocional */}
        <Accordion sx={{ borderRadius: 2 }}>
          <AccordionSummary expandIcon={<ExpandMoreIcon />}>
            <Typography sx={{ fontWeight: 700 }}>Material promocional</Typography>
          </AccordionSummary>
          <AccordionDetails>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
              Descarga banners listos para usar en tus publicaciones. Todos incluyen tu código {dashboard.referralCode} automáticamente.
            </Typography>
            <Grid container spacing={2}>
              {materialBanners.map((b) => (
                <Grid item xs={12} sm={6} md={4} key={b.size}>
                  <Card sx={{ borderRadius: 2, border: '1px solid #e0e0e0' }}>
                    <Box sx={{ bgcolor: b.color, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', py: 3 }}>
                      <Typography variant="caption" sx={{ fontWeight: 700, letterSpacing: 0.5 }}>{b.size}</Typography>
                    </Box>
                    <CardContent sx={{ p: 1.5 }}>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>{b.label}</Typography>
                      <Button size="small" sx={{ mt: 1, color: '#ff9900' }} disabled>
                        Descargar (próximamente)
                      </Button>
                    </CardContent>
                  </Card>
                </Grid>
              ))}
            </Grid>
          </AccordionDetails>
        </Accordion>
      </Container>
    </Box>
  );
}
