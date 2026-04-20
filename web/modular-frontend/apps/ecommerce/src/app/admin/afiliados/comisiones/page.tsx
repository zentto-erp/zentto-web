'use client';

import { useMemo, useState } from 'react';
import {
  Box, Typography, Card, Tabs, Tab, Button, Alert, Stack,
} from '@mui/material';
import { ZenttoRecordTable, type ColumnSpec } from '@zentto/shared-ui';
import {
  useAdminAffiliateCommissions, useAdminGenerateAffiliatePayouts,
} from '@zentto/module-ecommerce';

const STATUS_TABS = ['all', 'pending', 'approved', 'paid', 'reversed'];
const STATUS_LABEL: Record<string, string> = {
  pending: 'Pendiente', approved: 'Aprobada', paid: 'Pagada', reversed: 'Revertida',
};

const columns: ColumnSpec[] = [
  { field: 'id',           header: '#',           width: 80,  sortable: true, type: 'number' },
  { field: 'referralCode', header: 'Código',      width: 150, sortable: true },
  { field: 'legalName',    header: 'Afiliado',    flex: 1, minWidth: 200, sortable: true },
  { field: 'orderNumber',  header: 'Orden',       width: 140, sortable: true },
  { field: 'category',     header: 'Categoría',   width: 140, sortable: true },
  { field: 'rateLabel',    header: 'Tasa',        width: 90,  sortable: true },
  { field: 'amount',       header: 'Monto',       width: 140, sortable: true },
  { field: 'statusLabel',  header: 'Estado',      width: 140, sortable: true,
    statusColors: { Pendiente: 'warning', Aprobada: 'info', Pagada: 'success', Revertida: 'error' } as any,
  },
  { field: 'createdAt',    header: 'Creado',      width: 170, sortable: true },
];

export default function AdminAfiliadosComisionesPage() {
  const [tab, setTab] = useState(0);
  const status = STATUS_TABS[tab] === 'all' ? undefined : STATUS_TABS[tab];
  const { data, isLoading, refetch } = useAdminAffiliateCommissions({ status, page: 1, limit: 200 });
  const generate = useAdminGenerateAffiliatePayouts();
  const [msg, setMsg] = useState<string>('');
  const [err, setErr] = useState('');

  const rows = useMemo(() => (data?.rows ?? []).map((c) => ({
    id: c.id,
    referralCode: c.referralCode,
    legalName: c.legalName,
    orderNumber: c.orderNumber,
    category: c.category ?? '—',
    rateLabel: `${Number(c.rate).toFixed(1)}%`,
    amount: `${c.currencyCode} ${Number(c.commissionAmount).toFixed(2)}`,
    statusLabel: STATUS_LABEL[c.status] ?? c.status,
    createdAt: new Date(c.createdAt).toLocaleString('es-VE'),
  })), [data]);

  const handleGenerate = async () => {
    setMsg(''); setErr('');
    try {
      const r = await generate.mutateAsync({});
      const ok = (r as { ok?: boolean }).ok;
      if (!ok) { setErr((r as { message?: string }).message ?? 'Error'); return; }
      setMsg((r as { message?: string }).message ?? 'Payouts generados');
      refetch();
    } catch (e) {
      setErr(e instanceof Error ? e.message : String(e));
    }
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2, flexWrap: 'wrap', gap: 2 }}>
        <Typography variant="h5" fontWeight={700}>Comisiones de afiliados</Typography>
        <Button
          variant="contained"
          onClick={handleGenerate}
          disabled={generate.isPending}
          sx={{ bgcolor: '#ff9900', color: '#131921', fontWeight: 700, '&:hover': { bgcolor: '#e68a00' } }}
        >
          {generate.isPending ? 'Generando…' : 'Generar payouts del mes'}
        </Button>
      </Box>

      <Stack spacing={1} sx={{ mb: 2 }}>
        {msg && <Alert severity="success">{msg}</Alert>}
        {err && <Alert severity="error">{err}</Alert>}
      </Stack>

      <Tabs value={tab} onChange={(_, v) => setTab(v)} variant="scrollable" sx={{ mb: 2 }}>
        <Tab label="Todas" /><Tab label="Pendientes" /><Tab label="Aprobadas" /><Tab label="Pagadas" /><Tab label="Revertidas" />
      </Tabs>

      <Card sx={{ borderRadius: 2 }}>
        <Box sx={{ p: 1 }}>
          <ZenttoRecordTable
            recordType="admin-affiliate-commissions"
            rows={rows}
            columns={columns}
            loading={isLoading}
            height="auto"
            emptyState={{ title: 'Sin comisiones', description: 'No hay comisiones en este estado.' }}
          />
        </Box>
      </Card>
    </Box>
  );
}
