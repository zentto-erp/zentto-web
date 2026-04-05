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
  TablePagination,
  Tabs,
  Tab,
  TextField,
  InputAdornment,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogContentText,
  DialogActions,
  Breadcrumbs,
  Link,
  Grid,
  Avatar,
} from "@mui/material";
import SearchIcon from "@mui/icons-material/Search";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import InventoryIcon from "@mui/icons-material/Inventory";
import { productsApi } from "@/lib/api";

const STATUS_TABS = [
  { label: "Todos", value: "" },
  { label: "Activo", value: "active" },
  { label: "Borrador", value: "draft" },
  { label: "Archivado", value: "archived" },
];

const statusChipProps: Record<string, { label: string; color: "default" | "warning" | "success" | "info" | "error" }> = {
  active: { label: "Activo", color: "success" },
  draft: { label: "Borrador", color: "warning" },
  archived: { label: "Archivado", color: "default" },
};

const EMPTY_PRODUCT = {
  name: "",
  price: "",
  compareAtPrice: "",
  description: "",
  images: "",
  stock: "",
  sku: "",
  variants: "",
  status: "draft",
};

export default function ProductsPage() {
  const params = useParams<{ siteId: string }>();
  const router = useRouter();
  const siteId = params.siteId;

  const [products, setProducts] = useState<any[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [statusFilter, setStatusFilter] = useState("");
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);

  const [deleteId, setDeleteId] = useState<string | null>(null);
  const [editOpen, setEditOpen] = useState(false);
  const [editProduct, setEditProduct] = useState<any>(null);
  const [form, setForm] = useState(EMPTY_PRODUCT);
  const [saving, setSaving] = useState(false);

  const fetchProducts = useCallback(async () => {
    if (!siteId) return;
    setLoading(true);
    setError(null);
    try {
      const result = await productsApi.list(siteId, {
        status: statusFilter || undefined,
        search: search || undefined,
        limit: rowsPerPage,
        offset: page * rowsPerPage,
      });
      const items = Array.isArray(result) ? result : result?.data ?? result?.products ?? [];
      const total = result?.totalCount ?? result?.total ?? items.length;
      setProducts(items);
      setTotalCount(total);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, [siteId, statusFilter, search, page, rowsPerPage]);

  useEffect(() => {
    fetchProducts();
  }, [fetchProducts]);

  const openCreate = () => {
    setEditProduct(null);
    setForm(EMPTY_PRODUCT);
    setEditOpen(true);
  };

  const openEdit = async (product: any) => {
    setEditProduct(product);
    setForm({
      name: product.name || "",
      price: product.price?.toString() || "",
      compareAtPrice: product.compareAtPrice?.toString() || "",
      description: product.description || "",
      images: Array.isArray(product.images) ? product.images.join(", ") : (product.images || ""),
      stock: product.stock?.toString() || "",
      sku: product.sku || "",
      variants: typeof product.variants === "object" ? JSON.stringify(product.variants) : (product.variants || ""),
      status: product.status || "draft",
    });
    setEditOpen(true);
  };

  const handleSave = async () => {
    setSaving(true);
    setError(null);
    try {
      const data = {
        name: form.name,
        price: parseFloat(form.price) || 0,
        compareAtPrice: form.compareAtPrice ? parseFloat(form.compareAtPrice) : undefined,
        description: form.description,
        images: form.images ? form.images.split(",").map((s) => s.trim()).filter(Boolean) : [],
        stock: form.stock ? parseInt(form.stock, 10) : 0,
        sku: form.sku || undefined,
        variants: form.variants || undefined,
        status: form.status,
      };
      if (editProduct) {
        await productsApi.update(siteId, editProduct.id, data);
      } else {
        await productsApi.create(siteId, data);
      }
      setEditOpen(false);
      fetchProducts();
    } catch (err: any) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!deleteId) return;
    try {
      await productsApi.delete(siteId, deleteId);
      setDeleteId(null);
      fetchProducts();
    } catch (err: any) {
      setError(err.message);
    }
  };

  const updateField = (field: string, value: string) => {
    setForm((prev) => ({ ...prev, [field]: value }));
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
        <Typography color="text.primary">Productos</Typography>
      </Breadcrumbs>

      {/* Header */}
      <Box sx={{ display: "flex", alignItems: "center", justifyContent: "space-between", mb: 3, flexWrap: "wrap", gap: 2 }}>
        <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
          <InventoryIcon color="primary" sx={{ fontSize: 32 }} />
          <Typography variant="h4" fontWeight={700}>
            Productos
          </Typography>
        </Box>
        <Button variant="contained" startIcon={<AddIcon />} onClick={openCreate}>
          Nuevo Producto
        </Button>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {/* Filters */}
      <Paper sx={{ mb: 3 }}>
        <Tabs
          value={statusFilter}
          onChange={(_, v) => { setStatusFilter(v); setPage(0); }}
          sx={{ borderBottom: 1, borderColor: "divider", px: 2 }}
        >
          {STATUS_TABS.map((tab) => (
            <Tab key={tab.value} label={tab.label} value={tab.value} />
          ))}
        </Tabs>
        <Box sx={{ p: 2 }}>
          <TextField
            size="small"
            placeholder="Buscar productos..."
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(0); }}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon fontSize="small" />
                </InputAdornment>
              ),
            }}
            sx={{ width: { xs: "100%", sm: 320 } }}
          />
        </Box>
      </Paper>

      {/* Table */}
      <Paper>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell sx={{ fontWeight: 600 }}>Imagen</TableCell>
                <TableCell sx={{ fontWeight: 600 }}>Nombre</TableCell>
                <TableCell sx={{ fontWeight: 600 }}>Precio</TableCell>
                <TableCell sx={{ fontWeight: 600 }}>Stock</TableCell>
                <TableCell sx={{ fontWeight: 600 }}>Estado</TableCell>
                <TableCell sx={{ fontWeight: 600 }} align="right">Acciones</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {loading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <TableRow key={i}>
                    {Array.from({ length: 6 }).map((_, j) => (
                      <TableCell key={j}><Skeleton /></TableCell>
                    ))}
                  </TableRow>
                ))
              ) : products.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={6} align="center" sx={{ py: 6 }}>
                    <Typography color="text.secondary">No hay productos. Crea el primero.</Typography>
                  </TableCell>
                </TableRow>
              ) : (
                products.map((product) => {
                  const chip = statusChipProps[product.status] || { label: product.status, color: "default" as const };
                  const imgSrc = Array.isArray(product.images) ? product.images[0] : product.image || product.imageUrl;
                  return (
                    <TableRow key={product.id} hover sx={{ cursor: "pointer" }} onClick={() => openEdit(product)}>
                      <TableCell>
                        <Avatar variant="rounded" src={imgSrc} sx={{ width: 48, height: 48, bgcolor: "#e2e8f0" }}>
                          <InventoryIcon fontSize="small" />
                        </Avatar>
                      </TableCell>
                      <TableCell>
                        <Typography fontWeight={500}>{product.name || "Sin nombre"}</Typography>
                        {product.sku && (
                          <Typography variant="caption" color="text.secondary">SKU: {product.sku}</Typography>
                        )}
                      </TableCell>
                      <TableCell>
                        <Typography fontWeight={500}>
                          ${typeof product.price === "number" ? product.price.toFixed(2) : product.price || "0.00"}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Typography color={product.stock <= 0 ? "error.main" : "text.primary"}>
                          {product.stock ?? "-"}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Chip label={chip.label} color={chip.color} size="small" />
                      </TableCell>
                      <TableCell align="right" onClick={(e) => e.stopPropagation()}>
                        <IconButton size="small" onClick={() => openEdit(product)} title="Editar">
                          <EditIcon fontSize="small" />
                        </IconButton>
                        <IconButton size="small" onClick={() => setDeleteId(product.id)} title="Eliminar" color="error">
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
        <TablePagination
          component="div"
          count={totalCount}
          page={page}
          onPageChange={(_, p) => setPage(p)}
          rowsPerPage={rowsPerPage}
          onRowsPerPageChange={(e) => { setRowsPerPage(parseInt(e.target.value, 10)); setPage(0); }}
          rowsPerPageOptions={[5, 10, 25]}
          labelRowsPerPage="Filas por pagina"
        />
      </Paper>

      {/* Edit/Create Dialog */}
      <Dialog open={editOpen} onClose={() => setEditOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>{editProduct ? "Editar Producto" : "Nuevo Producto"}</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 0.5 }}>
            <Grid item xs={12}>
              <TextField fullWidth label="Nombre" value={form.name} onChange={(e) => updateField("name", e.target.value)} />
            </Grid>
            <Grid item xs={6}>
              <TextField fullWidth label="Precio" type="number" value={form.price} onChange={(e) => updateField("price", e.target.value)} />
            </Grid>
            <Grid item xs={6}>
              <TextField fullWidth label="Precio comparacion" type="number" value={form.compareAtPrice} onChange={(e) => updateField("compareAtPrice", e.target.value)} />
            </Grid>
            <Grid item xs={12}>
              <TextField fullWidth label="Descripcion" multiline rows={3} value={form.description} onChange={(e) => updateField("description", e.target.value)} />
            </Grid>
            <Grid item xs={12}>
              <TextField fullWidth label="URLs de imagenes (separadas por coma)" value={form.images} onChange={(e) => updateField("images", e.target.value)} helperText="Ej: https://example.com/img1.jpg, https://example.com/img2.jpg" />
            </Grid>
            <Grid item xs={4}>
              <TextField fullWidth label="Stock" type="number" value={form.stock} onChange={(e) => updateField("stock", e.target.value)} />
            </Grid>
            <Grid item xs={4}>
              <TextField fullWidth label="SKU" value={form.sku} onChange={(e) => updateField("sku", e.target.value)} />
            </Grid>
            <Grid item xs={4}>
              <TextField
                fullWidth
                label="Estado"
                select
                value={form.status}
                onChange={(e) => updateField("status", e.target.value)}
                SelectProps={{ native: true }}
              >
                <option value="draft">Borrador</option>
                <option value="active">Activo</option>
                <option value="archived">Archivado</option>
              </TextField>
            </Grid>
            <Grid item xs={12}>
              <TextField fullWidth label="Variantes (JSON)" multiline rows={2} value={form.variants} onChange={(e) => updateField("variants", e.target.value)} helperText='Ej: [{"size":"M","color":"rojo"}]' />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEditOpen(false)}>Cancelar</Button>
          <Button onClick={handleSave} variant="contained" disabled={saving || !form.name}>
            {saving ? "Guardando..." : "Guardar"}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Delete dialog */}
      <Dialog open={!!deleteId} onClose={() => setDeleteId(null)}>
        <DialogTitle>Eliminar producto</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Esta accion no se puede deshacer. El producto sera eliminado permanentemente.
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
