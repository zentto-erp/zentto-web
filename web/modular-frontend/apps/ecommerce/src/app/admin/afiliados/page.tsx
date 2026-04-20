'use client';

import { useMemo, useState } from 'react';
import {
  Box, Typography, Card, Tabs, Tab, Dialog, DialogTitle, DialogContent, DialogActions,
  Button, Stack, Alert,
} from '@mui/material';
import { ZenttoRecordTable, type ColumnSpec } from '@zentto/shared-ui';
import {
  useAdminAffiliates, useAdminSetAffiliateStatus,
} from '@zentto/module-ecommerce';

const STATUS_TABS = ['all', 'pending', 'active', 'suspended', 'rejected'];
const STATUS_LABEL: Record<string, string> = {
  pending: 'Pendiente', active: 'Activo', suspended: 'Suspendido', rejected: 'Rechazado',
};

const columns: ColumnSpec[] = [
  { field: 'referralCode', header: 'Código', width: 150, sortable: true },
  { field: 'legalName', header: 'Nombre legal', flex: 1, minWidth: 220, sortable: true },
  { field: 'contactEmail', header: 'Email', width: 240, sortable: true },
  { field: 'taxId', header: 'Tax ID', width: 130, sortable: true },
  { field: 'statusLabel', header: 'Estado', width: 140, sortable: true,
    statusColors: { Activo: 'success', Pendiente: 'warning', Suspendido: 'error', Rechazado: 'default' } as any,
  },
  { field: 'pendingAmount', header: 'Pendiente USD', width: 140, type: 'number', sortable: true },
  { field: 'paidAmount',    header: 'Pagado USD',    width: 140, type: 'number', sortable: true },
  { field: 'createdAt', header: 'Creado', width: 170, sortable: true },
];

export default function AdminAfiliadosPage() {
  const [tab, setTab] = useState(0);
  const status = STATUS_TABS[tab] === 'all' ? undefined : STATUS_TABS[tab];
  const { data, isLoading, refetch } = useAdminAffiliates({ status, page: 1, limit: 100 });
  const setStatus = useAdminSetAffiliateStatus();

  const [selected, setSelected] = useState<number | null>(null);
  const [err, setErr] = useState('');

  const rows = useMemo(() => (data?.rows ?? []).map((a) => ({
    id: a.id,
    referralCode: a.referralCode,
    legalName: a.legalName ?? '—',
    contactEmail: a.contactEmail ?? '—',
    taxId: a.taxId ?? '—',
    statusLabel: STATUS_LABEL[a.status] ?? a.status,
    statusRaw: a.status,
    pendingAmount: Number(a.pendingAmount).toFixed(2),
    paidAmount: Number(a.paidAmount).toFixed(2),
    createdAt: new Date(a.createdAt).toLocaleString('es-VE'),
  })), [data]);

  const apply = async (newStatus: 'active' | 'suspended' | 'rejected') => {
    if (!selected) return;
    setErr('');
    try {
      const r = await setStatus.mutateAsync({ id: selected, status: newStatus });
      if (!(r as { ok?: boolean }).ok) setErr((r as { error?: string }).error || 'Error');
      else {
        setSelected(null);
        refetch();
      }
    } catch (e) {
      setErr(e instanceof Error ? e.message : String(e));
    }
  };

  return (
    <Box>
      <Typography variant="h5" fontWeight={700} sx={{ mb: 2 }}>Afiliados</Typography>

      <Tabs value={tab} onChange={(_, v) => setTab(v)} variant="scrollable" sx={{ mb: 2 }}>
        <Tab label="Todos" /><Tab label="Pendientes" /><Tab label="Activos" /><Tab label="Suspendidos" /><Tab label="Rechazados" />
      </Tabs>

      <Card sx={{ borderRadius: 2 }}>
        <Box sx={{ p: 1 }}>
          <ZenttoRecordTable
            recordType="admin-affiliates"
            rows={rows}
            columns={columns}
            loading={isLoading}
            height="auto"
            onOpenRecord={(id) => setSelected(Number(id))}
            emptyState={{ title: 'Sin afiliados', description: 'No hay afiliados en este estado.' }}
          />
        </Box>
      </Card>

      <Dialog open={selected !== null} onClose={() => setSelected(null)} maxWidth="xs" fullWidth>
        <DialogTitle>Cambiar estado del afiliado</DialogTitle>
        <DialogContent dividers>
          <Stack spacing={1}>
            <Typography variant="body2">
              Afiliado #{selected}. Selecciona la acción a aplicar.
            </Typography>
            {err && <Alert severity="error">{err}</Alert>}
          </Stack>
        </DialogContent>
        <DialogActions sx={{ gap: 1, flexWrap: 'wrap' }}>
          <Button onClick={() => setSelected(null)}>Cerrar</Button>
          <Button color="error" onClick={() => apply('rejected')} disabled={setStatus.isPending}>Rechazar</Button>
          <Button color="warning" onClick={() => apply('suspended')} disabled={setStatus.isPending}>Suspender</Button>
          <Button variant="contained" color="success" onClick={() => apply('active')} disabled={setStatus.isPending}>
            Aprobar / Activar
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
