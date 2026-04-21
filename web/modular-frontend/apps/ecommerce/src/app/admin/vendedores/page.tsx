'use client';

import { useMemo, useState } from 'react';
import {
  Box, Typography, Card, Tabs, Tab, Dialog, DialogTitle, DialogContent, DialogActions,
  Button, Alert, TextField, Stack,
} from '@mui/material';
import { ZenttoRecordTable, type ColumnSpec } from '@zentto/shared-ui';
import {
  useAdminMerchants,
  useAdminSetMerchantStatus,
  useAdminGenerateMerchantPayouts,
} from '@zentto/module-ecommerce';

const STATUS_TABS = ['all', 'pending', 'approved', 'suspended', 'rejected'];
const STATUS_LABEL: Record<string, string> = {
  pending: 'Pendiente', approved: 'Aprobado', suspended: 'Suspendido', rejected: 'Rechazado',
};

const columns: ColumnSpec[] = [
  { field: 'legalName',    header: 'Razón social', flex: 1, minWidth: 220, sortable: true },
  { field: 'storeSlug',    header: 'Slug',         width: 160, sortable: true },
  { field: 'contactEmail', header: 'Email',        width: 220, sortable: true },
  { field: 'taxId',        header: 'Tax ID',       width: 130, sortable: true },
  { field: 'statusLabel',  header: 'Estado',       width: 140, sortable: true,
    statusColors: { Aprobado: 'success', Pendiente: 'warning', Suspendido: 'error', Rechazado: 'default' } as any,
  },
  { field: 'productCount', header: 'Productos', width: 110, type: 'number', sortable: true },
  { field: 'approvedCount', header: 'Aprobados', width: 120, type: 'number', sortable: true },
  { field: 'createdAt',    header: 'Creado',       width: 170, sortable: true },
];

export default function AdminVendedoresPage() {
  const [tab, setTab] = useState(0);
  const status = STATUS_TABS[tab] === 'all' ? undefined : STATUS_TABS[tab];
  const { data, isLoading, refetch } = useAdminMerchants({ status, page: 1, limit: 100 });
  const setStatus = useAdminSetMerchantStatus();
  const genPayouts = useAdminGenerateMerchantPayouts();

  const [selected, setSelected] = useState<number | null>(null);
  const [reason, setReason] = useState('');
  const [err, setErr] = useState('');
  const [payoutMsg, setPayoutMsg] = useState<string>('');
  const [payoutErr, setPayoutErr] = useState<string>('');

  const rows = useMemo(() => (data?.rows ?? []).map((s) => ({
    id: s.id,
    legalName: s.legalName,
    storeSlug: s.storeSlug,
    contactEmail: s.contactEmail ?? '—',
    taxId: s.taxId ?? '—',
    statusLabel: STATUS_LABEL[s.status] ?? s.status,
    productCount: s.productCount,
    approvedCount: s.approvedCount,
    createdAt: new Date(s.createdAt).toLocaleString('es-VE'),
  })), [data]);

  const apply = async (newStatus: 'approved' | 'rejected' | 'suspended') => {
    if (!selected) return;
    setErr('');
    try {
      const r = await setStatus.mutateAsync({ id: selected, status: newStatus, reason: reason || undefined });
      if (!(r as { ok?: boolean }).ok) setErr((r as { error?: string }).error || 'Error');
      else {
        setSelected(null); setReason(''); refetch();
      }
    } catch (e) {
      setErr(e instanceof Error ? e.message : String(e));
    }
  };

  const generatePayouts = async () => {
    setPayoutMsg('');
    setPayoutErr('');
    try {
      const r = await genPayouts.mutateAsync(undefined);
      if (r.ok) {
        setPayoutMsg(
          `${r.payoutsCreated} payout(s) generado(s) por un total de ${r.totalAmount.toFixed(2)} USD.`,
        );
      } else {
        setPayoutErr(r.message || 'No se generaron payouts');
      }
    } catch (e) {
      setPayoutErr(e instanceof Error ? e.message : String(e));
    }
  };

  return (
    <Box>
      <Stack direction="row" spacing={2} alignItems="center" sx={{ mb: 2 }}>
        <Typography variant="h5" fontWeight={700} sx={{ flex: 1 }}>Vendedores del marketplace</Typography>
        <Button
          variant="outlined"
          onClick={generatePayouts}
          disabled={genPayouts.isPending}
        >
          {genPayouts.isPending ? 'Generando…' : 'Generar payouts mensuales'}
        </Button>
      </Stack>

      {payoutMsg && <Alert severity="success" sx={{ mb: 2 }} onClose={() => setPayoutMsg('')}>{payoutMsg}</Alert>}
      {payoutErr && <Alert severity="error" sx={{ mb: 2 }} onClose={() => setPayoutErr('')}>{payoutErr}</Alert>}

      <Tabs value={tab} onChange={(_, v) => setTab(v)} variant="scrollable" sx={{ mb: 2 }}>
        <Tab label="Todos" /><Tab label="Pendientes" /><Tab label="Aprobados" /><Tab label="Suspendidos" /><Tab label="Rechazados" />
      </Tabs>

      <Card sx={{ borderRadius: 2 }}>
        <Box sx={{ p: 1 }}>
          <ZenttoRecordTable
            recordType="admin-merchants"
            rows={rows}
            columns={columns}
            loading={isLoading}
            height="auto"
            onOpenRecord={(id) => setSelected(Number(id))}
            emptyState={{ title: 'Sin vendedores', description: 'No hay vendedores en este estado.' }}
          />
        </Box>
      </Card>

      <Dialog open={selected !== null} onClose={() => setSelected(null)} maxWidth="sm" fullWidth>
        <DialogTitle>Vendedor #{selected}</DialogTitle>
        <DialogContent dividers>
          <Stack spacing={2}>
            <TextField
              label="Motivo (opcional — para rechazar o suspender)"
              value={reason} onChange={(e) => setReason(e.target.value)}
              fullWidth multiline rows={2}
            />
            {err && <Alert severity="error">{err}</Alert>}
          </Stack>
        </DialogContent>
        <DialogActions sx={{ gap: 1, flexWrap: 'wrap' }}>
          <Button onClick={() => setSelected(null)}>Cerrar</Button>
          <Button color="error" onClick={() => apply('rejected')} disabled={setStatus.isPending}>Rechazar</Button>
          <Button color="warning" onClick={() => apply('suspended')} disabled={setStatus.isPending}>Suspender</Button>
          <Button variant="contained" color="success" onClick={() => apply('approved')} disabled={setStatus.isPending}>
            Aprobar
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
