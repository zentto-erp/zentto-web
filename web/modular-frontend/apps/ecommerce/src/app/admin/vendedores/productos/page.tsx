'use client';

import { useMemo, useState } from 'react';
import {
  Box, Typography, Card, Tabs, Tab, Dialog, DialogTitle, DialogContent, DialogActions,
  Button, Alert, TextField, Stack,
} from '@mui/material';
import { ZenttoRecordTable, type ColumnSpec } from '@zentto/shared-ui';
import { useAdminPendingSellerProducts, useAdminReviewSellerProduct } from '@zentto/module-ecommerce';

const STATUS_TABS = ['pending_review', 'approved', 'rejected', 'draft'];
const STATUS_LABEL: Record<string, string> = {
  pending_review: 'En revisión', approved: 'Aprobado', rejected: 'Rechazado', draft: 'Borrador',
};

const columns: ColumnSpec[] = [
  { field: 'productCode', header: 'Código', width: 140, sortable: true },
  { field: 'name',        header: 'Producto', flex: 1, minWidth: 260, sortable: true },
  { field: 'sellerName',  header: 'Vendedor', width: 200, sortable: true },
  { field: 'price',       header: 'Precio', width: 110, type: 'number', sortable: true },
  { field: 'stock',       header: 'Stock', width: 90, type: 'number', sortable: true },
  { field: 'category',    header: 'Categoría', width: 140, sortable: true },
  { field: 'statusLabel', header: 'Estado', width: 140, sortable: true,
    statusColors: { Aprobado: 'success', 'En revisión': 'warning', Rechazado: 'error', Borrador: 'default' } as any,
  },
  { field: 'createdAt',   header: 'Creado', width: 170, sortable: true },
];

export default function AdminSellerProductsPage() {
  const [tab, setTab] = useState(0);
  const status = STATUS_TABS[tab];
  const { data, isLoading, refetch } = useAdminPendingSellerProducts({ status, page: 1, limit: 100 });
  const review = useAdminReviewSellerProduct();

  const [selected, setSelected] = useState<number | null>(null);
  const [notes, setNotes] = useState('');
  const [err, setErr] = useState('');

  const rows = useMemo(() => (data?.rows ?? []).map((p) => ({
    id: p.id,
    productCode: p.productCode,
    name: p.name,
    sellerName: p.sellerName,
    price: Number(p.price).toFixed(2),
    stock: p.stock,
    category: p.category ?? '—',
    statusLabel: STATUS_LABEL[p.status] ?? p.status,
    createdAt: new Date(p.createdAt).toLocaleString('es-VE'),
  })), [data]);

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

      <Card sx={{ borderRadius: 2 }}>
        <Box sx={{ p: 1 }}>
          <ZenttoRecordTable
            recordType="admin-seller-products"
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
