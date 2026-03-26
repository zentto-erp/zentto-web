"use client";
import { useEffect, useMemo, useRef, useState } from "react";
import {
  Box, Button, Dialog, DialogActions, DialogContent, DialogTitle, Stack, TextField, Typography,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import SearchIcon from "@mui/icons-material/Search";
import InputAdornment from "@mui/material/InputAdornment";
import { useToast } from "@zentto/shared-ui";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useBancosList, useCreateBanco, useUpdateBanco, useDeleteBanco } from "../../hooks/useBancosAuxiliares";

const EMPTY_FORM = { Nombre: "", Contacto: "", Direccion: "", Telefonos: "", Co_Usuario: "SUP" };

const COLUMNS: ColumnDef[] = [
  { field: "Nombre", header: "Nombre", flex: 1, minWidth: 180, sortable: true },
  { field: "Contacto", header: "Contacto", width: 160 },
  { field: "Direccion", header: "Dirección", flex: 1, minWidth: 200 },
  { field: "Telefonos", header: "Teléfonos", width: 150 },
  {
    field: "actions", header: "Acciones", type: "actions" as any, width: 100, pin: "right",
    actions: [
      { icon: "edit", label: "Editar", action: "edit", color: "#1976d2" },
      { icon: "delete", label: "Eliminar", action: "delete", color: "#dc2626" },
    ],
  } as ColumnDef,
];


export default function BancosPage() {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(50);
  const [formOpen, setFormOpen] = useState(false);
  const [editNombre, setEditNombre] = useState<string | null>(null);
  const [form, setForm] = useState({ ...EMPTY_FORM });
  const [deleteTarget, setDeleteTarget] = useState<string | null>(null);

  const { data, isLoading } = useBancosList({ search, page, limit });
  const crear = useCreateBanco();
  const actualizar = useUpdateBanco();
  const eliminar = useDeleteBanco();
  const { showToast } = useToast();
  const saving = crear.isPending || actualizar.isPending;
  const rows = (data?.rows ?? data?.items ?? []) as Record<string, any>[];

  useEffect(() => { import("@zentto/datagrid").then(() => setRegistered(true)); }, []);

  useEffect(() => {
    const el = gridRef.current; if (!el || !registered) return;
    el.columns = COLUMNS; el.rows = rows; el.loading = isLoading;
    el.getRowId = (r: any) => r.Nombre ?? r.NOMBRE ?? Math.random();
  }, [rows, isLoading, registered]);

  const handleEdit = (row: Record<string, any>) => {
    setForm({ Nombre: row.Nombre ?? "", Contacto: row.Contacto ?? "", Direccion: row.Direccion ?? "", Telefonos: row.Telefonos ?? "", Co_Usuario: "SUP" });
    setEditNombre(row.Nombre); setFormOpen(true);
  };

  useEffect(() => {
    const el = gridRef.current; if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "edit") handleEdit(row);
      if (action === "delete") setDeleteTarget(row.Nombre);
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, rows]);

  const handleNew = () => { setForm({ ...EMPTY_FORM }); setEditNombre(null); setFormOpen(true); };
  const handleSave = async () => {
    try {
      if (editNombre) { await actualizar.mutateAsync({ nombre: editNombre, data: form }); showToast("Banco actualizado correctamente", "success"); }
      else { await crear.mutateAsync(form); showToast("Banco creado correctamente", "success"); }
      setFormOpen(false);
    } catch (err: any) { showToast(err?.message ?? "Error al guardar", "error"); }
  };
  const handleDelete = async () => {
    if (!deleteTarget) return;
    try { await eliminar.mutateAsync(deleteTarget); showToast("Banco eliminado correctamente", "success"); setDeleteTarget(null); }
    catch (err: any) { showToast(err?.message ?? "Error al eliminar", "error"); }
  };

  return (
    <Box>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h5" fontWeight={600}>Entidades</Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={handleNew}>Nuevo Banco</Button>
      </Stack>

      <TextField placeholder="Buscar banco..." size="small" value={search}
        onChange={(e) => { setSearch(e.target.value); setPage(1); }}
        sx={{ mb: 2, maxWidth: 360 }}
        InputProps={{ startAdornment: <InputAdornment position="start"><SearchIcon fontSize="small" /></InputAdornment> }}
      />

      <Box sx={{ minHeight: 400 }}>
        <zentto-grid ref={gridRef} height="400px" enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator />
      </Box>

      <Dialog open={formOpen} onClose={() => setFormOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editNombre ? "Editar Banco" : "Nuevo Banco"}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <TextField label="Nombre" fullWidth value={form.Nombre} disabled={!!editNombre} onChange={(e) => setForm((f) => ({ ...f, Nombre: e.target.value }))} />
            <TextField label="Contacto" fullWidth value={form.Contacto} onChange={(e) => setForm((f) => ({ ...f, Contacto: e.target.value }))} />
            <TextField label="Dirección" fullWidth value={form.Direccion} onChange={(e) => setForm((f) => ({ ...f, Direccion: e.target.value }))} />
            <TextField label="Teléfonos" fullWidth value={form.Telefonos} onChange={(e) => setForm((f) => ({ ...f, Telefonos: e.target.value }))} />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setFormOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleSave} disabled={saving}>{editNombre ? "Actualizar" : "Guardar"}</Button>
        </DialogActions>
      </Dialog>

      <Dialog open={deleteTarget != null} onClose={() => setDeleteTarget(null)}>
        <DialogTitle>Confirmar Eliminación</DialogTitle>
        <DialogContent><Typography>¿Está seguro de eliminar el banco &quot;{deleteTarget}&quot;?</Typography></DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteTarget(null)}>Cancelar</Button>
          <Button variant="contained" color="error" onClick={handleDelete} disabled={eliminar.isPending}>Eliminar</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

declare global { namespace JSX { interface IntrinsicElements { 'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>; } } }
