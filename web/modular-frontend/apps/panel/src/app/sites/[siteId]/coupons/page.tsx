"use client";

import { useParams, useRouter } from "next/navigation";
import { useEffect, useState, useCallback } from "react";
import {
  Box,
  Typography,
  Paper,
  Button,
  Chip,
  Skeleton,
  Alert,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogContentText,
  DialogActions,
  Breadcrumbs,
  Link,
  Grid,
  TextField,
  Switch,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import LocalOfferIcon from "@mui/icons-material/LocalOffer";
import { couponsApi } from "@/lib/api";

const EMPTY_COUPON = {
  code: "",
  type: "percentage",
  value: "",
  minOrderAmount: "",
  maxUses: "",
  expiresAt: "",
  active: true,
};

export default function CouponsPage() {
  const params = useParams<{ siteId: string }>();
  const router = useRouter();
  const siteId = params.siteId;

  const [coupons, setCoupons] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [deleteId, setDeleteId] = useState<string | null>(null);
  const [editOpen, setEditOpen] = useState(false);
  const [editCoupon, setEditCoupon] = useState<any>(null);
  const [form, setForm] = useState(EMPTY_COUPON);
  const [saving, setSaving] = useState(false);

  const fetchCoupons = useCallback(async () => {
    if (!siteId) return;
    setLoading(true);
    setError(null);
    try {
      const result = await couponsApi.list(siteId);
      const items = Array.isArray(result) ? result : result?.data ?? result?.coupons ?? [];
      setCoupons(items);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, [siteId]);

  useEffect(() => {
    fetchCoupons();
  }, [fetchCoupons]);

  const openCreate = () => {
    setEditCoupon(null);
    setForm(EMPTY_COUPON);
    setEditOpen(true);
  };

  const openEdit = (coupon: any) => {
    setEditCoupon(coupon);
    setForm({
      code: coupon.code || "",
      type: coupon.type || "percentage",
      value: coupon.value?.toString() || "",
      minOrderAmount: coupon.minOrderAmount?.toString() || "",
      maxUses: coupon.maxUses?.toString() || "",
      expiresAt: coupon.expiresAt ? coupon.expiresAt.slice(0, 10) : "",
      active: coupon.active !== false,
    });
    setEditOpen(true);
  };

  const handleSave = async () => {
    setSaving(true);
    setError(null);
    try {
      const data = {
        code: form.code.toUpperCase(),
        type: form.type,
        value: parseFloat(form.value) || 0,
        minOrderAmount: form.minOrderAmount ? parseFloat(form.minOrderAmount) : undefined,
        maxUses: form.maxUses ? parseInt(form.maxUses, 10) : undefined,
        expiresAt: form.expiresAt || undefined,
        active: form.active,
      };
      if (editCoupon) {
        await couponsApi.update(siteId, editCoupon.id, data);
      } else {
        await couponsApi.create(siteId, data);
      }
      setEditOpen(false);
      fetchCoupons();
    } catch (err: any) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!deleteId) return;
    try {
      await couponsApi.delete(siteId, deleteId);
      setDeleteId(null);
      fetchCoupons();
    } catch (err: any) {
      setError(err.message);
    }
  };

  const toggleActive = async (coupon: any) => {
    setError(null);
    try {
      await couponsApi.update(siteId, coupon.id, { active: !coupon.active });
      fetchCoupons();
    } catch (err: any) {
      setError(err.message);
    }
  };

  const updateField = (field: string, value: any) => {
    setForm((prev) => ({ ...prev, [field]: value }));
  };

  const formatValue = (coupon: any) => {
    if (coupon.type === "percentage") return `${coupon.value}%`;
    return `$${typeof coupon.value === "number" ? coupon.value.toFixed(2) : coupon.value}`;
  };

  return (
    <Box sx={{ p: 3, maxWidth: 1200, mx: "auto" }}>
      {/* Breadcrumbs */}
      <Breadcrumbs sx={{ mb: 2 }}>
        <Link underline="hover" color="inherit" sx={{ cursor: "pointer" }} onClick={() => router.push("/sites")}>
          Mis Sitios
        </Link>
        <Link underline="hover" color="inherit" sx={{ cursor: "pointer" }} onClick={() => router.push(`/sites/${siteId}`)}>
          Sitio
        </Link>
        <Typography color="text.primary">Cupones</Typography>
      </Breadcrumbs>

      {/* Header */}
      <Box sx={{ display: "flex", alignItems: "center", justifyContent: "space-between", mb: 3, flexWrap: "wrap", gap: 2 }}>
        <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
          <LocalOfferIcon color="primary" sx={{ fontSize: 32 }} />
          <Typography variant="h4" fontWeight={700}>
            Cupones
          </Typography>
        </Box>
        <Button variant="contained" startIcon={<AddIcon />} onClick={openCreate}>
          Nuevo Cupon
        </Button>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {/* Table */}
      <Paper>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell sx={{ fontWeight: 600 }}>Codigo</TableCell>
                <TableCell sx={{ fontWeight: 600 }}>Tipo</TableCell>
                <TableCell sx={{ fontWeight: 600 }}>Valor</TableCell>
                <TableCell sx={{ fontWeight: 600 }}>Usos</TableCell>
                <TableCell sx={{ fontWeight: 600 }}>Expira</TableCell>
                <TableCell sx={{ fontWeight: 600 }}>Estado</TableCell>
                <TableCell sx={{ fontWeight: 600 }} align="right">Acciones</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {loading ? (
                Array.from({ length: 3 }).map((_, i) => (
                  <TableRow key={i}>
                    {Array.from({ length: 7 }).map((_, j) => (
                      <TableCell key={j}><Skeleton /></TableCell>
                    ))}
                  </TableRow>
                ))
              ) : coupons.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={7} align="center" sx={{ py: 6 }}>
                    <Typography color="text.secondary">No hay cupones. Crea el primero.</Typography>
                  </TableCell>
                </TableRow>
              ) : (
                coupons.map((coupon) => {
                  const isExpired = coupon.expiresAt && new Date(coupon.expiresAt) < new Date();
                  return (
                    <TableRow key={coupon.id} hover>
                      <TableCell>
                        <Typography fontWeight={600} sx={{ fontFamily: "monospace", letterSpacing: 1 }}>
                          {coupon.code}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Chip
                          label={coupon.type === "percentage" ? "Porcentaje" : "Monto fijo"}
                          size="small"
                          variant="outlined"
                        />
                      </TableCell>
                      <TableCell>
                        <Typography fontWeight={500}>{formatValue(coupon)}</Typography>
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2">
                          {coupon.usesCount ?? coupon.uses ?? 0}
                          {coupon.maxUses ? ` / ${coupon.maxUses}` : ""}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2" color={isExpired ? "error.main" : "text.secondary"}>
                          {coupon.expiresAt ? new Date(coupon.expiresAt).toLocaleDateString("es") : "Sin limite"}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                          <Switch
                            size="small"
                            checked={coupon.active !== false}
                            onChange={() => toggleActive(coupon)}
                          />
                          <Chip
                            label={coupon.active !== false ? "Activo" : "Inactivo"}
                            color={coupon.active !== false ? "success" : "default"}
                            size="small"
                          />
                        </Box>
                      </TableCell>
                      <TableCell align="right">
                        <IconButton size="small" onClick={() => openEdit(coupon)} title="Editar">
                          <EditIcon fontSize="small" />
                        </IconButton>
                        <IconButton size="small" onClick={() => setDeleteId(coupon.id)} title="Eliminar" color="error">
                          <DeleteIcon fontSize="small" />
                        </IconButton>
                      </TableCell>
                    </TableRow>
                  );
                })
              )}
            </TableBody>
          </Table>
        </TableContainer>
      </Paper>

      {/* Create/Edit Dialog */}
      <Dialog open={editOpen} onClose={() => setEditOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editCoupon ? "Editar Cupon" : "Nuevo Cupon"}</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 0.5 }}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Codigo"
                value={form.code}
                onChange={(e) => updateField("code", e.target.value.toUpperCase())}
                inputProps={{ style: { textTransform: "uppercase", fontFamily: "monospace", letterSpacing: 2 } }}
                helperText="Ej: VERANO20, DESCUENTO10"
              />
            </Grid>
            <Grid item xs={6}>
              <TextField
                fullWidth
                label="Tipo"
                select
                value={form.type}
                onChange={(e) => updateField("type", e.target.value)}
                SelectProps={{ native: true }}
              >
                <option value="percentage">Porcentaje (%)</option>
                <option value="fixed">Monto fijo ($)</option>
              </TextField>
            </Grid>
            <Grid item xs={6}>
              <TextField
                fullWidth
                label={form.type === "percentage" ? "Valor (%)" : "Valor ($)"}
                type="number"
                value={form.value}
                onChange={(e) => updateField("value", e.target.value)}
              />
            </Grid>
            <Grid item xs={6}>
              <TextField
                fullWidth
                label="Monto minimo de orden"
                type="number"
                value={form.minOrderAmount}
                onChange={(e) => updateField("minOrderAmount", e.target.value)}
                helperText="Opcional"
              />
            </Grid>
            <Grid item xs={6}>
              <TextField
                fullWidth
                label="Usos maximos"
                type="number"
                value={form.maxUses}
                onChange={(e) => updateField("maxUses", e.target.value)}
                helperText="Opcional (vacio = ilimitado)"
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Fecha de expiracion"
                type="date"
                value={form.expiresAt}
                onChange={(e) => updateField("expiresAt", e.target.value)}
                InputLabelProps={{ shrink: true }}
                helperText="Opcional (vacio = sin expiracion)"
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEditOpen(false)}>Cancelar</Button>
          <Button onClick={handleSave} variant="contained" disabled={saving || !form.code || !form.value}>
            {saving ? "Guardando..." : "Guardar"}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Delete dialog */}
      <Dialog open={!!deleteId} onClose={() => setDeleteId(null)}>
        <DialogTitle>Eliminar cupon</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Esta accion no se puede deshacer. El cupon sera eliminado permanentemente.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteId(null)}>Cancelar</Button>
          <Button onClick={handleDelete} color="error" variant="contained">
            Eliminar
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
