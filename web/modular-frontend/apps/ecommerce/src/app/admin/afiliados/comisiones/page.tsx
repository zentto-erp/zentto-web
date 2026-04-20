'use client';

import { useMemo, useState } from 'react';
import {
  Box, Typography, Card, Tabs, Tab, Button, Alert, Stack, Checkbox, Tooltip,
} from '@mui/material';
import DownloadIcon from '@mui/icons-material/Download';
import DoneAllIcon from '@mui/icons-material/DoneAll';
import PaidIcon from '@mui/icons-material/Paid';
import { ZenttoRecordTable, type ColumnSpec } from '@zentto/shared-ui';
import {
  useAdminAffiliateCommissions, useAdminGenerateAffiliatePayouts, useAdminBulkSetCommissionStatus,
} from '@zentto/module-ecommerce';

const STATUS_TABS = ['all', 'pending', 'approved', 'paid', 'reversed'];
const STATUS_LABEL: Record<string, string> = {
  pending: 'Pendiente', approved: 'Aprobada', paid: 'Pagada', reversed: 'Revertida',
};

/**
 * Descarga un CSV en el navegador — sin libs extra (Blob + download).
 */
function downloadCsv(filename: string, headers: string[], rows: Array<Array<string | number>>) {
  const esc = (v: unknown) => {
    const s = String(v ?? '');
    if (s.includes(',') || s.includes('"') || s.includes('\n')) {
      return `"${s.replace(/"/g, '""')}"`;
    }
    return s;
  };
  const body = [headers.map(esc).join(','), ...rows.map((r) => r.map(esc).join(','))].join('\n');
  const blob = new Blob(["\uFEFF" + body], { type: 'text/csv;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url; a.download = filename;
  document.body.appendChild(a); a.click(); document.body.removeChild(a);
  setTimeout(() => URL.revokeObjectURL(url), 2000);
}

export default function AdminAfiliadosComisionesPage() {
  const [tab, setTab] = useState(0);
  const status = STATUS_TABS[tab] === 'all' ? undefined : STATUS_TABS[tab];
  const { data, isLoading, refetch } = useAdminAffiliateCommissions({ status, page: 1, limit: 500 });
  const generate = useAdminGenerateAffiliatePayouts();
  const bulkStatus = useAdminBulkSetCommissionStatus();
  const [selected, setSelected] = useState<Record<number, boolean>>({});
  const [msg, setMsg] = useState<string>('');
  const [err, setErr] = useState('');

  const toggleRow = (id: number) => setSelected((s) => ({ ...s, [id]: !s[id] }));
  const selectedIds = useMemo(
    () => Object.entries(selected).filter(([, v]) => v).map(([k]) => Number(k)),
    [selected],
  );

  const columns: ColumnSpec[] = useMemo(() => ([
    { field: 'pick', header: '', width: 52, sortable: false,
      renderCell: (_v: unknown, row: { id?: number | string }) => (
        <Checkbox
          checked={!!selected[Number(row.id)]}
          onChange={() => toggleRow(Number(row.id))}
          onClick={(e) => e.stopPropagation()}
          size="small"
        />
      ),
    } as any,
    { field: 'id',           header: '#',           width: 80,  sortable: true, type: 'number' },
    { field: 'referralCode', header: 'Código',      width: 140, sortable: true },
    { field: 'legalName',    header: 'Afiliado',    flex: 1, minWidth: 200, sortable: true },
    { field: 'orderNumber',  header: 'Orden',       width: 140, sortable: true },
    { field: 'category',     header: 'Categoría',   width: 140, sortable: true },
    { field: 'rateLabel',    header: 'Tasa',        width: 90,  sortable: true },
    { field: 'amount',       header: 'Monto',       width: 140, sortable: true },
    { field: 'statusLabel',  header: 'Estado',      width: 120, sortable: true,
      statusColors: { Pendiente: 'warning', Aprobada: 'info', Pagada: 'success', Revertida: 'error' } as any,
    },
    { field: 'createdAt',    header: 'Creado',      width: 170, sortable: true },
  ]), [selected]);

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

  const handleBulk = async (newStatus: 'approved' | 'paid') => {
    if (selectedIds.length === 0) { setErr('Selecciona al menos una comisión'); return; }
    setMsg(''); setErr('');
    try {
      const r = await bulkStatus.mutateAsync({ ids: selectedIds, status: newStatus });
      if (!(r as { ok?: boolean }).ok) {
        setErr((r as { message?: string }).message ?? 'Error bulk');
        return;
      }
      setMsg((r as { message?: string }).message ?? 'Actualizado');
      setSelected({});
      refetch();
    } catch (e) {
      setErr(e instanceof Error ? e.message : String(e));
    }
  };

  const handleExportCsv = () => {
    const headers = ['id','código','afiliado','orden','categoría','tasa','monto','moneda','estado','creado'];
    const sourceRows = (data?.rows ?? []).filter((c) => selectedIds.length === 0 || selectedIds.includes(c.id));
    const dataRows = sourceRows.map((c) => [
      c.id, c.referralCode, c.legalName ?? '', c.orderNumber, c.category ?? '',
      Number(c.rate).toFixed(2), Number(c.commissionAmount).toFixed(2),
      c.currencyCode ?? 'USD', c.status, new Date(c.createdAt).toISOString(),
    ]);
    const scope = status ?? 'todos';
    const date = new Date().toISOString().slice(0, 10);
    downloadCsv(`comisiones-afiliados-${scope}-${date}.csv`, headers, dataRows);
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2, flexWrap: 'wrap', gap: 2 }}>
        <Typography variant="h5" fontWeight={700}>Comisiones de afiliados</Typography>
        <Stack direction="row" spacing={1} flexWrap="wrap">
          <Tooltip title="Exportar comisiones filtradas o seleccionadas a CSV">
            <Button variant="outlined" startIcon={<DownloadIcon />} onClick={handleExportCsv}>
              Exportar CSV
            </Button>
          </Tooltip>
          <Button
            variant="contained"
            onClick={handleGenerate}
            disabled={generate.isPending}
            sx={{ bgcolor: '#ff9900', color: '#131921', fontWeight: 700, '&:hover': { bgcolor: '#e68a00' } }}
          >
            {generate.isPending ? 'Generando…' : 'Generar payouts'}
          </Button>
        </Stack>
      </Box>

      <Stack spacing={1} sx={{ mb: 2 }}>
        {msg && <Alert severity="success" onClose={() => setMsg('')}>{msg}</Alert>}
        {err && <Alert severity="error" onClose={() => setErr('')}>{err}</Alert>}
      </Stack>

      {/* Bulk actions toolbar */}
      {selectedIds.length > 0 && (
        <Stack direction="row" spacing={1} alignItems="center" sx={{ mb: 2, p: 1.5, borderRadius: 2, bgcolor: '#fff3e0' }}>
          <Typography variant="body2" sx={{ fontWeight: 600 }}>
            {selectedIds.length} seleccionada(s)
          </Typography>
          <Box sx={{ flex: 1 }} />
          <Button
            size="small" startIcon={<DoneAllIcon />} variant="contained"
            onClick={() => handleBulk('approved')} disabled={bulkStatus.isPending}
            color="info"
          >
            Aprobar
          </Button>
          <Button
            size="small" startIcon={<PaidIcon />} variant="contained"
            onClick={() => handleBulk('paid')} disabled={bulkStatus.isPending}
            color="success"
          >
            Marcar pagadas
          </Button>
          <Button size="small" onClick={() => setSelected({})}>Limpiar</Button>
        </Stack>
      )}

      <Tabs value={tab} onChange={(_, v) => { setTab(v); setSelected({}); }} variant="scrollable" sx={{ mb: 2 }}>
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
