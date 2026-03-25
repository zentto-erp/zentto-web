// Articulos — migrado de MUI DataGrid a @zentto/datagrid nativo
"use client";

import { useEffect, useRef, useState, useMemo } from "react";
import { useRouter } from "next/navigation";
import { Box, Button, Typography, Dialog, DialogTitle, DialogContent, DialogActions, CircularProgress } from "@mui/material";
import { Add as AddIcon } from "@mui/icons-material";
import type { ColumnDef, GridRow } from "@zentto/datagrid-core";
import { useArticulosList, useDeleteArticulo } from "../../hooks/useArticulos";

// ─── SVG Icons ───────────────────────────────────────
const SVG_VIEW = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>';
const SVG_EDIT = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>';
const SVG_DELETE = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>';

// ─── Columns ─────────────────────────────────────────
const COLUMNS: ColumnDef[] = [
  { field: 'codigo', header: 'Codigo', width: 120, sortable: true },
  { field: 'descripcion', header: 'Articulo', flex: 1, minWidth: 200, sortable: true },
  { field: 'categoria', header: 'Categoria', width: 120, sortable: true, groupable: true },
  { field: 'marca', header: 'Marca', width: 110, sortable: true, groupable: true },
  { field: 'precioCompra', header: 'Costo', width: 110, type: 'number', currency: 'VES', aggregation: 'sum' },
  { field: 'precioVenta', header: 'Precio', width: 110, type: 'number', currency: 'VES', aggregation: 'sum' },
  { field: 'stock', header: 'Stock', width: 90, type: 'number' },
  { field: 'unidad', header: 'Unid.', width: 70, sortable: true, mobileHide: true },
  { field: 'estado', header: 'Estado', width: 100, sortable: true, groupable: true,
    statusColors: { Activo: 'success', Inactivo: 'error' }, statusVariant: 'outlined' },
];

const FILTER_PANEL = [
  { field: 'categoria', type: 'select', label: 'Categoria' },
  { field: 'marca', type: 'select', label: 'Marca' },
  { field: 'estado', type: 'select', label: 'Estado' },
  { field: 'precioVenta', type: 'range', label: 'Precio' },
  { field: 'stock', type: 'range', label: 'Stock' },
  { field: 'descripcion', type: 'text', label: 'Buscar', placeholder: 'Nombre, codigo, referencia...' },
];

const DETAIL_RENDERER = (row: any) => `
  <div style="display:grid;grid-template-columns:1fr 1fr 1fr 1fr;gap:10px;padding:8px 0;font-size:13px">
    <div><strong>Codigo:</strong> ${row.codigo}</div>
    <div><strong>Categoria:</strong> ${row.categoria || '-'}</div>
    <div><strong>Marca:</strong> ${row.marca || '-'}</div>
    <div><strong>Linea:</strong> ${row.linea || '-'}</div>
    <div><strong>Tipo:</strong> ${row.tipo || '-'}</div>
    <div><strong>Unidad:</strong> ${row.unidad || '-'}</div>
    <div><strong>Referencia:</strong> ${row.referencia || '-'}</div>
    <div><strong>Barra:</strong> ${row.barra || '-'}</div>
    <div><strong>Costo:</strong> ${row.precioCompra}</div>
    <div><strong>Precio:</strong> ${row.precioVenta}</div>
    <div><strong>Stock:</strong> ${row.stock}</div>
    <div><strong>Estado:</strong> ${row.estado}</div>
  </div>
`;

export default function ArticulosTable() {
  const router = useRouter();
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedArticulo, setSelectedArticulo] = useState<string | null>(null);

  // Register web component
  useEffect(() => {
    import('@zentto/datagrid').then(() => setRegistered(true));
  }, []);

  // Fetch data (page 1, large limit since grid handles client-side pagination)
  const { data: articulosData, isLoading } = useArticulosList({ page: 1, limit: 200 });
  const { mutate: deleteArticulo, isPending: isDeleting } = useDeleteArticulo();

  // Map API data to grid rows
  const rows = useMemo(() => {
    return (articulosData?.data || []).map((a: any) => ({
      id: a.codigo,
      codigo: a.codigo,
      descripcion: a.descripcion || a.descripcionCompleta || a.nombre || '',
      categoria: a.categoria || '',
      marca: a.marca || '',
      linea: a.linea || '',
      tipo: a.tipo || '',
      unidad: a.unidad || '',
      referencia: a.referencia || '',
      barra: a.barra || '',
      precioCompra: Number(a.precioCompra || 0),
      precioVenta: Number(a.precioVenta || a.precio || 0),
      stock: Number(a.stock || 0),
      estado: a.estado || 'Activo',
    }));
  }, [articulosData?.data]);

  // Action handlers
  const handleAction = (e: CustomEvent) => {
    const { action, row } = e.detail;
    if (action === 'view') router.push(`/articulos/${row.codigo}`);
    if (action === 'edit') router.push(`/articulos/${row.codigo}/edit`);
    if (action === 'delete') {
      setSelectedArticulo(row.codigo);
      setDeleteDialogOpen(true);
    }
  };

  const handleConfirmDelete = () => {
    if (selectedArticulo) {
      deleteArticulo(selectedArticulo, {
        onSuccess: () => { setDeleteDialogOpen(false); setSelectedArticulo(null); },
        onError: (err) => console.error("Error eliminando:", err),
      });
    }
  };

  // Bind props to web component
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows;
    el.loading = isLoading;
    el.filterPanel = FILTER_PANEL;
    el.detailRenderer = DETAIL_RENDERER;
    el.actionButtons = [
      { icon: SVG_VIEW, label: 'Ver', action: 'view' },
      { icon: SVG_EDIT, label: 'Editar', action: 'edit', color: '#e67e22' },
      { icon: SVG_DELETE, label: 'Eliminar', action: 'delete', color: '#dc2626' },
    ];
  }, [rows, isLoading, registered]);

  // Listen for action clicks
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.addEventListener('action-click', handleAction);
    return () => el.removeEventListener('action-click', handleAction);
  }, [registered, router]);

  if (!registered) {
    return <Box sx={{ display: 'flex', justifyContent: 'center', mt: 10 }}><CircularProgress /></Box>;
  }

  return (
    <Box sx={{ p: 2, display: "flex", flexDirection: "column", height: "100%" }}>
      {/* Header */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 2 }}>
        <Typography variant="h5" fontWeight={600}>Articulos</Typography>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Button variant="contained" startIcon={<AddIcon />} onClick={() => router.push("/articulos/new")}>
            Nuevo Articulo
          </Button>
        </Box>
      </Box>

      {/* Grid nativo */}
      <zentto-grid
        ref={gridRef}
        default-currency="VES"
        export-filename="articulos"
        height="calc(100vh - 180px)"
        show-totals
        enable-toolbar
        enable-header-menu
        enable-header-filters
        enable-clipboard
        enable-find
        enable-quick-search
        enable-context-menu
        enable-status-bar
        enable-row-selection
        enable-filter-panel
        enable-master-detail
      ></zentto-grid>

      {/* Delete Confirmation Dialog */}
      <Dialog open={deleteDialogOpen} onClose={() => { setDeleteDialogOpen(false); setSelectedArticulo(null); }}>
        <DialogTitle>Eliminar Articulo</DialogTitle>
        <DialogContent>
          <Typography>
            Esta seguro de que desea eliminar el articulo <strong>{selectedArticulo}</strong>?
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => { setDeleteDialogOpen(false); setSelectedArticulo(null); }}>Cancelar</Button>
          <Button variant="contained" color="error" onClick={handleConfirmDelete} disabled={isDeleting}>
            {isDeleting ? 'Eliminando...' : 'Eliminar'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
