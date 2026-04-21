'use client';

import { useMemo, useState } from 'react';
import {
  Box, Typography, Card, Tabs, Tab, Dialog, DialogTitle, DialogContent, DialogActions,
  Button, Alert, TextField, Stack, MenuItem, Avatar,
} from '@mui/material';
import { ZenttoRecordTable, type ColumnSpec } from '@zentto/shared-ui';
import { useAdminPendingMerchantProducts, useAdminReviewMerchantProduct, useAdminMerchants } from '@zentto/module-ecommerce';

const STATUS_TABS = ['pending_review', 'approved', 'rejected', 'draft'];
const STATUS_LABEL: Record<string, string> = {
  pending_review: 'En revisión', approved: 'Aprobado', rejected: 'Rechazado', draft: 'Borrador',
};

const PLACEHOLDER_THUMB =
  "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='40' height='40'%3E%3Crect fill='%23f0f2f2' width='40' height='40'/%3E%3Ctext fill='%23999' x='50%25' y='55%25' text-anchor='middle' font-size='10'%3E-%3C/text%3E%3C/svg%3E";

const currencyFmt = (v: unknown) =>
  typeof v === 'number'
    ? `$${v.toFixed(2)}`
    : typeof v === 'string' && !Number.isNaN(Number(v))
      ? `$${Number(v).toFixed(2)}`
      : String(v ?? '');

const columns: ColumnSpec[] = [
  {
    field: 'imageUrl', header: '', width: 60, sortable: false,
    renderCell: (_value: unknown, row: any) => (
      <Avatar
        variant="rounded"
        src={row?.imageUrl || PLACEHOLDER_THUMB}
        alt={row?.name}
        sx={{ width: 36, height: 36, bgcolor: '#f0f2f2' }}
      />
    ),
  } as any,
  { field: 'productCode',  header: 'Código', width: 140, sortable: true },
  { field: 'name',         header: 'Producto', flex: 1, minWidth: 240, sortable: true },
  { field: 'merchantName', header: 'Vendedor', width: 200, sortable: true },
  {
    field: 'price', header: 'Precio', width: 120, sortable: true, type: 'number',
    renderCell: (value: unknown) => (
      <Box sx={{ fontWeight: 600, color: '#0f1111' }}>{currencyFmt(value)}</Box>
    ),
  } as any,
  { field: 'stock',        header: 'Stock', width: 90, type: 'number', sortable: true },
  { field: 'category',     header: 'Categoría', width: 140, sortable: true },
  { field: 'statusLabel',  header: 'Estado', width: 140, sortable: true,
    statusColors: { Aprobado: 'success', 'En revisión': 'warning', Rechazado: 'error', Borrador: 'default' } as any,
  },
  { field: 'createdAt',    header: 'Creado', width: 170, sortable: true },
];

export default function AdminMerchantProductsPage() {
  const [tab, setTab] = useState(0);
  const status = STATUS_TABS[tab];
  const { data, isLoading, refetch } = useAdminPendingMerchantProducts({ status, page: 1, limit: 100 });
  const review = useAdminReviewMerchantProduct();

  // Filtros adicionales (Ola 4): vendedor + categoría
  const { data: merchantsData } = useAdminMerchants({ page: 1, limit: 200 });
  const [merchantFilter, setMerchantFilter] = useState<string>('');
  const [categoryFilter, setCategoryFilter] = useState<string>('');

  const [selected, setSelected] = useState<number | null>(null);
  const [notes, setNotes] = useState('');
  const [err, setErr] = useState('');

  const allRows = (data?.rows ?? []).map((p) => ({
    id: p.id,
    productCode: p.productCode,
    name: p.name,
    imageUrl: p.imageUrl,
    merchantId: p.merchantId,
    merchantName: p.merchantName,
    price: Number(p.price),
    stock: p.stock,
    category: p.category ?? '—',
    statusLabel: STATUS_LABEL[p.status] ?? p.status,
    createdAt: new Date(p.createdAt).toLocaleString('es-VE'),
  }));

  const rows = useMemo(() => allRows.filter((r) => {
    if (merchantFilter && String(r.merchantId) !== merchantFilter) return false;
    if (categoryFilter && r.category !== categoryFilter) return false;
    return true;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }), [data, merchantFilter, categoryFilter]);

  const uniqueCategories = Array.from(new Set(allRows.map((r) => r.category).filter((c) => c && c !== '—')));

  const apply = async (newStatus: 'approved' | 'rejected') => {
    if (!selected) return;
    setErr('');
    try {
      const r = await review.mutateAsync({ id: selected, status: newStatus, notes: notes || undefined });
      if (!(r as { ok?: boolean }).ok) setErr((r as { error?: string }).error || 'Error');
      else {
        setSelected(null); setNotes(''); refetch();
      }
    } catch (e) {
      setErr(e instanceof Error ? e.message : String(e));
    }
  };

  return (
    <Box>
      <Typography variant="h5" fontWeight={700} sx={{ mb: 2 }}>Productos del marketplace</Typography>

      <Tabs value={tab} onChange={(_, v) => setTab(v)} variant="scrollable" sx={{ mb: 2 }}>
        <Tab label="En revisión" /><Tab label="Aprobados" /><Tab label="Rechazados" /><Tab label="Borradores" />
      </Tabs>

      {/* Filtros multi-merchant Ola 4 */}
      <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} sx={{ mb: 2 }}>
        <TextField
          select size="small" label="Vendedor"
          value={merchantFilter}
          onChange={(e) => setMerchantFilter(e.target.value)}
          sx={{ minWidth: 220 }}
        >
          <MenuItem value="">Todos los vendedores</MenuItem>
          {(merchantsData?.rows ?? []).map((m) => (
            <MenuItem key={m.id} value={String(m.id)}>{m.legalName}</MenuItem>
          ))}
        </TextField>
        <TextField
          select size="small" label="Categoría"
          value={categoryFilter}
          onChange={(e) => setCategoryFilter(e.target.value)}
          sx={{ minWidth: 180 }}
        >
          <MenuItem value="">Todas las categorías</MenuItem>
          {uniqueCategories.map((c) => (
            <MenuItem key={c} value={c}>{c}</MenuItem>
          ))}
        </TextField>
      </Stack>

      <Card sx={{ borderRadius: 2 }}>
        <Box sx={{ p: 1 }}>
          <ZenttoRecordTable
            recordType="admin-merchant-products"
            rows={rows}
            columns={columns}
            loading={isLoading}
            height="auto"
            onOpenRecord={(id) => setSelected(Number(id))}
            emptyState={{
              title: 'Sin productos en este estado',
              description: 'Los vendedores envían productos a revisión desde su dashboard.',
            }}
          />
        </Box>
      </Card>

      <Dialog open={selected !== null} onClose={() => setSelected(null)} maxWidth="sm" fullWidth>
        <DialogTitle>Revisar producto #{selected}</DialogTitle>
        <DialogContent dividers>
          <Stack spacing={2}>
            <TextField
              label="Notas de revisión (obligatorio para rechazar)"
              value={notes} onChange={(e) => setNotes(e.target.value)}
              fullWidth multiline rows={3}
            />
            {err && <Alert severity="error">{err}</Alert>}
          </Stack>
        </DialogContent>
        <DialogActions sx={{ gap: 1 }}>
          <Button onClick={() => setSelected(null)}>Cerrar</Button>
          <Button color="error" onClick={() => apply('rejected')} disabled={review.isPending}>Rechazar</Button>
          <Button variant="contained" color="success" onClick={() => apply('approved')} disabled={review.isPending}>
            Aprobar
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
