'use client';

import { useEffect, useMemo, useState } from 'react';
import {
  Box, Container, Typography, Card, CardContent, Grid, Chip, Accordion, AccordionSummary,
  AccordionDetails, Button, Dialog, DialogTitle, DialogContent, DialogActions,
  TextField, MenuItem, Alert, CircularProgress,
} from '@mui/material';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import { useRouter } from 'next/navigation';
import { ZenttoRecordTable, type ColumnSpec } from '@zentto/shared-ui';
import {
  useMerchantDashboard, useMerchantProducts, useSubmitMerchantProduct, useCartStore,
} from '@zentto/module-ecommerce';

const productColumns: ColumnSpec[] = [
  { field: 'productCode', header: 'Código', width: 140, sortable: true },
  { field: 'name', header: 'Nombre', flex: 1, minWidth: 260, sortable: true },
  { field: 'category', header: 'Categoría', width: 140, sortable: true },
  { field: 'price', header: 'Precio', width: 110, type: 'number', sortable: true },
  { field: 'stock', header: 'Stock', width: 90, type: 'number', sortable: true },
  { field: 'statusLabel', header: 'Estado', width: 150, sortable: true,
    statusColors: { Aprobado: 'success', 'En revisión': 'warning', Borrador: 'default', Rechazado: 'error' } as any,
  },
];

const STATUS_LABEL: Record<string, string> = {
  draft: 'Borrador', pending_review: 'En revisión', approved: 'Aprobado', rejected: 'Rechazado',
};

export default function VendedorDashboardPage() {
  const router = useRouter();
  const customerToken = useCartStore((s) => s.customerToken);
  const { data: merchant, isLoading } = useMerchantDashboard();
  const { data: products } = useMerchantProducts({ page: 1, limit: 50 });
  const submitProduct = useSubmitMerchantProduct();

  const [dialogOpen, setDialogOpen] = useState(false);
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [price, setPrice] = useState('0');
  const [stock, setStock] = useState('0');
  const [category, setCategory] = useState('Electrónica');
  const [imageUrl, setImageUrl] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    if (!customerToken) router.replace('/login?next=/vender/dashboard');
  }, [customerToken, router]);

  const rows = useMemo(() =>
    (products?.rows ?? []).map((p) => ({
      id: p.id,
      productCode: p.productCode,
      name: p.name,
      category: p.category ?? '—',
      price: Number(p.price).toFixed(2),
      stock: p.stock,
      statusLabel: STATUS_LABEL[p.status] ?? p.status,
    })), [products]);

  if (isLoading) {
    return (
      <Box sx={{ minHeight: '60vh', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
        <CircularProgress />
      </Box>
    );
  }

  if (!merchant) {
    return (
      <Container maxWidth="md" sx={{ py: 6 }}>
        <Alert severity="info">
          Aún no eres vendedor.{' '}
          <Button size="small" onClick={() => router.push('/vender/aplicar')}>Aplicar ahora</Button>
        </Alert>
      </Container>
    );
  }

  const submit = async (asDraft: boolean) => {
    setError('');
    try {
      const res = await submitProduct.mutateAsync({
        name: name.trim(),
        description: description.trim(),
        price: Number(price),
        stock: Number(stock),
        category,
        imageUrl: imageUrl.trim() || undefined,
        submit: !asDraft,
      });
      if (!(res as { ok?: boolean }).ok) {
        setError((res as { error?: string }).error ?? 'Error al guardar');
        return;
      }
      setDialogOpen(false);
      setName(''); setDescription(''); setPrice('0'); setStock('0'); setImageUrl('');
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  const statusChipColor: 'default' | 'success' | 'warning' | 'error' =
    merchant.status === 'approved' ? 'success' :
    merchant.status === 'pending'  ? 'warning' :
    merchant.status === 'suspended' || merchant.status === 'rejected' ? 'error' : 'default';

  return (
    <Box sx={{ bgcolor: '#eaeded', minHeight: '100vh', py: { xs: 3, md: 6 } }}>
      <Container maxWidth="lg">
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 3, flexWrap: 'wrap', gap: 2 }}>
          <Box>
            <Typography variant="h4" sx={{ fontWeight: 700, color: '#131921' }}>Mi tienda</Typography>
            <Typography variant="body2" sx={{ color: '#555' }}>
              {merchant.legalName} — <b>/{merchant.storeSlug}</b>
            </Typography>
          </Box>
          <Chip label={merchant.status} color={statusChipColor} sx={{ textTransform: 'capitalize' }} />
        </Box>

        {/* Métricas */}
        <Grid container spacing={2} sx={{ mb: 3 }}>
          {[
            { label: 'Productos totales', value: merchant.productsTotal },
            { label: 'Aprobados', value: merchant.productsApproved },
            { label: 'En revisión', value: merchant.productsPending },
            { label: 'Órdenes', value: merchant.ordersTotal },
            { label: 'Ventas brutas', value: `USD ${Number(merchant.grossSalesUsd).toFixed(2)}` },
            { label: 'Cobrado', value: `USD ${Number(merchant.payoutsPaidUsd).toFixed(2)}` },
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

        {/* Sección acordeones */}
        <Accordion defaultExpanded sx={{ borderRadius: 2, mb: 2 }}>
          <AccordionSummary expandIcon={<ExpandMoreIcon />}>
            <Typography sx={{ fontWeight: 700 }}>Mis productos</Typography>
          </AccordionSummary>
          <AccordionDetails>
            <Box sx={{ display: 'flex', justifyContent: 'flex-end', mb: 2 }}>
              <Button
                variant="contained"
                disabled={merchant.status !== 'approved'}
                onClick={() => setDialogOpen(true)}
                sx={{ bgcolor: '#ff9900', color: '#131921', fontWeight: 700, '&:hover': { bgcolor: '#e68a00' } }}
              >
                Proponer producto
              </Button>
            </Box>
            {merchant.status !== 'approved' && (
              <Alert severity="info" sx={{ mb: 2 }}>
                Podrás publicar productos cuando tu tienda sea aprobada.
              </Alert>
            )}
            <Card sx={{ borderRadius: 2 }}>
              <Box sx={{ p: 1 }}>
                <ZenttoRecordTable
                  recordType="merchant-products"
                  rows={rows}
                  columns={productColumns}
                  height="auto"
                  emptyState={{
                    title: 'Sin productos aún',
                    description: 'Envía tu primer producto a revisión para aparecer en la tienda.',
                  }}
                />
              </Box>
            </Card>
          </AccordionDetails>
        </Accordion>

        <Accordion sx={{ borderRadius: 2, mb: 2 }}>
          <AccordionSummary expandIcon={<ExpandMoreIcon />}>
            <Typography sx={{ fontWeight: 700 }}>Ventas</Typography>
          </AccordionSummary>
          <AccordionDetails>
            <Typography variant="body2" color="text.secondary">
              Has generado <b>{merchant.ordersTotal}</b> órden(es) por un total bruto de{' '}
              <b>USD {Number(merchant.grossSalesUsd).toFixed(2)}</b>.
            </Typography>
          </AccordionDetails>
        </Accordion>

        <Accordion sx={{ borderRadius: 2 }}>
          <AccordionSummary expandIcon={<ExpandMoreIcon />}>
            <Typography sx={{ fontWeight: 700 }}>Payouts</Typography>
          </AccordionSummary>
          <AccordionDetails>
            <Typography variant="body2" color="text.secondary">
              Total pagado: <b>USD {Number(merchant.payoutsPaidUsd).toFixed(2)}</b>. Los payouts
              se generan mensualmente con comisión del {Number(merchant.commissionRate).toFixed(0)}%.
            </Typography>
          </AccordionDetails>
        </Accordion>

        {/* Dialog de crear producto */}
        <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
          <DialogTitle>Nuevo producto</DialogTitle>
          <DialogContent dividers>
            <Grid container spacing={2} sx={{ mt: 0 }}>
              <Grid item xs={12}>
                <TextField fullWidth label="Nombre *" value={name} onChange={(e) => setName(e.target.value)} />
              </Grid>
              <Grid item xs={12}>
                <TextField fullWidth multiline rows={3} label="Descripción" value={description} onChange={(e) => setDescription(e.target.value)} />
              </Grid>
              <Grid item xs={6}>
                <TextField fullWidth type="number" label="Precio *" value={price} onChange={(e) => setPrice(e.target.value)} />
              </Grid>
              <Grid item xs={6}>
                <TextField fullWidth type="number" label="Stock *" value={stock} onChange={(e) => setStock(e.target.value)} />
              </Grid>
              <Grid item xs={6}>
                <TextField fullWidth select label="Categoría" value={category} onChange={(e) => setCategory(e.target.value)}>
                  {['Electrónica','Ropa','Hogar','Software','Otros'].map((c) => (
                    <MenuItem key={c} value={c}>{c}</MenuItem>
                  ))}
                </TextField>
              </Grid>
              <Grid item xs={6}>
                <TextField fullWidth label="URL de imagen" value={imageUrl} onChange={(e) => setImageUrl(e.target.value)} />
              </Grid>
              {error && <Grid item xs={12}><Alert severity="error">{error}</Alert></Grid>}
            </Grid>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
            <Button onClick={() => submit(true)} disabled={submitProduct.isPending}>Guardar borrador</Button>
            <Button
              onClick={() => submit(false)}
              disabled={submitProduct.isPending || name.trim().length < 2}
              variant="contained"
              sx={{ bgcolor: '#ff9900', color: '#131921', '&:hover': { bgcolor: '#e68a00' } }}
            >
              Enviar a revisión
            </Button>
          </DialogActions>
        </Dialog>
      </Container>
    </Box>
  );
}
