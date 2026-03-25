"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box,
  Paper,
  Button,
  TextField,
  Stack,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  IconButton,
  Tooltip,
} from "@mui/material";
import { ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import type { ColumnDef } from "@zentto/datagrid-core";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import { useConstantesList, useSaveConstante, useDeleteConstante, type ConstanteInput } from "../hooks/useNomina";

const COLUMNS: ColumnDef[] = [
  { field: "codigo", header: "Código", width: 150, sortable: true },
  { field: "nombre", header: "Nombre", flex: 1, minWidth: 200, sortable: true },
  { field: "valor", header: "Valor", width: 150, type: "number", sortable: true },
  { field: "origen", header: "Origen", width: 120, sortable: true },
];

const CONSTANTES_FILTERS: FilterFieldDef[] = [
  {
    field: "tipo", label: "Tipo", type: "select",
    options: [
      { value: "SISTEMA", label: "Sistema" },
      { value: "USUARIO", label: "Usuario" },
      { value: "LEGAL", label: "Legal" },
    ],
  },
];

export default function ConstantesPage() {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [form, setForm] = useState<ConstanteInput>({ codigo: "", nombre: "", valor: 0 });

  const { data, isLoading } = useConstantesList();
  const saveMutation = useSaveConstante();
  const deleteMutation = useDeleteConstante();

  const rows = data?.data ?? data?.rows ?? [];

  useEffect(() => {
    import("@zentto/datagrid").then(() => setRegistered(true));
  }, []);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows;
    el.loading = isLoading;
    el.getRowId = (r: any) => r.codigo ?? Math.random();
  }, [rows, isLoading, registered]);

  const handleNew = () => {
    setForm({ codigo: "", nombre: "", valor: 0 });
    setEditMode(false);
    setDialogOpen(true);
  };

  const handleEdit = (row: Record<string, any>) => {
    setForm({
      codigo: row.codigo ?? row.Codigo ?? "",
      nombre: row.nombre ?? row.Nombre ?? "",
      valor: row.valor ?? row.Valor ?? 0,
      origen: row.origen ?? row.Origen ?? "",
    });
    setEditMode(true);
    setDialogOpen(true);
  };

  const handleDelete = async (row: Record<string, any>) => {
    const codigo = row.codigo ?? row.Codigo;
    if (!codigo) return;
    if (!window.confirm(`¿Eliminar la constante "${row.nombre ?? row.Nombre}"?`)) return;
    await deleteMutation.mutateAsync(codigo);
  };

  const handleSave = async () => {
    await saveMutation.mutateAsync(form);
    setDialogOpen(false);
    setForm({ codigo: "", nombre: "", valor: 0 });
  };

  // Listen for row action events
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;

    const SVG_EDIT = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>';
    const SVG_DELETE = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>';

    el.actionButtons = [
      { icon: SVG_EDIT, label: "Editar", action: "edit", color: "#1976d2" },
      { icon: SVG_DELETE, label: "Eliminar", action: "delete", color: "#dc2626" },
    ];

    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "edit") handleEdit(row);
      if (action === "delete") handleDelete(row);
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, rows]);

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Stack direction="row" justifyContent="flex-end" alignItems="center" mb={2}>
        <Button variant="contained" startIcon={<AddIcon />} onClick={handleNew}>
          Nueva Constante
        </Button>
      </Stack>

      <ZenttoFilterPanel
        filters={CONSTANTES_FILTERS}
        values={filterValues}
        onChange={setFilterValues}
        searchPlaceholder="Buscar constantes..."
        searchValue={search}
        onSearchChange={setSearch}
      />

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%" }}>
        <zentto-grid
          ref={gridRef}
          height="100%"
          enable-toolbar
          enable-header-menu
          enable-header-filters
          enable-clipboard
          enable-quick-search
          enable-context-menu
          enable-status-bar
          enable-configurator
        />
      </Paper>

      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editMode ? "Editar Constante" : "Nueva Constante"}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <TextField
              label="Código"
              fullWidth
              value={form.codigo}
              onChange={(e) => setForm((f) => ({ ...f, codigo: e.target.value }))}
              disabled={editMode}
            />
            <TextField label="Nombre" fullWidth value={form.nombre || ""} onChange={(e) => setForm((f) => ({ ...f, nombre: e.target.value }))} />
            <TextField label="Valor" type="number" fullWidth value={form.valor || ""} onChange={(e) => setForm((f) => ({ ...f, valor: Number(e.target.value) }))} />
            <TextField label="Origen" fullWidth value={form.origen || ""} onChange={(e) => setForm((f) => ({ ...f, origen: e.target.value }))} />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleSave} disabled={saveMutation.isPending}>
            Guardar
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
