"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box,
  Button,
  TextField,
  Stack,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
} from "@mui/material";

import type { ColumnDef } from "@zentto/datagrid-core";
import { useConstantesList, useSaveConstante, useDeleteConstante, type ConstanteInput } from "../hooks/useNomina";

const COLUMNS: ColumnDef[] = [
  { field: "codigo", header: "Código", width: 150, sortable: true },
  { field: "nombre", header: "Nombre", flex: 1, minWidth: 200, sortable: true },
  { field: "valor", header: "Valor", width: 150, type: "number", sortable: true },
  { field: "origen", header: "Origen", width: 120, sortable: true },
  {
    field: "actions", header: "Acciones", type: "actions", width: 100, pin: "right",
    actions: [
      { icon: "edit", label: "Editar", action: "edit", color: "#1976d2" },
      { icon: "delete", label: "Eliminar", action: "delete", color: "#dc2626" },
    ],
  },
];


export default function ConstantesPage() {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
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

    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "edit") handleEdit(row);
      if (action === "delete") handleDelete(row);
    };
    el.addEventListener("action-click", handler);
    const createHandler = () => handleNew();
    el.addEventListener("create-click", createHandler);
    return () => { el.removeEventListener("action-click", handler); el.removeEventListener("create-click", createHandler); };
  }, [registered, rows]);

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Box sx={{ flex: 1, minHeight: 0 }}>
        <zentto-grid
          ref={gridRef}
          height="calc(100vh - 200px)"
          enable-toolbar
          enable-header-menu
          enable-header-filters
          enable-clipboard
          enable-quick-search
          enable-context-menu
          enable-status-bar
          enable-configurator
          enable-grouping
          enable-pivot
          enable-create
          create-label="Nueva Constante"
        />
      </Box>

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
