"use client";

import React, { useState } from "react";
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
import { ZenttoDataGrid, type ZenttoColDef, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import { useConstantesList, useSaveConstante, useDeleteConstante, type ConstanteInput } from "../hooks/useNomina";

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
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [form, setForm] = useState<ConstanteInput>({ codigo: "", nombre: "", valor: 0 });

  const { data, isLoading } = useConstantesList();
  const saveMutation = useSaveConstante();
  const deleteMutation = useDeleteConstante();

  const rows = data?.data ?? data?.rows ?? [];

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

  const columns: ZenttoColDef[] = [
    { field: "codigo", headerName: "Código", width: 150 },
    { field: "nombre", headerName: "Nombre", flex: 1, minWidth: 200 },
    { field: "valor", headerName: "Valor", width: 150, type: "number" },
    { field: "origen", headerName: "Origen", width: 120 },
    {
      field: "actions",
      headerName: "Acciones",
      width: 110,
      sortable: false,
      filterable: false,
      renderCell: (params) => (
        <Stack direction="row" spacing={0.5}>
          <Tooltip title="Editar">
            <IconButton size="small" color="primary" onClick={() => handleEdit(params.row)}>
              <EditIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          <Tooltip title="Eliminar">
            <IconButton size="small" color="error" onClick={() => handleDelete(params.row)}>
              <DeleteIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Stack>
      ),
    },
  ];

  const handleSave = async () => {
    await saveMutation.mutateAsync(form);
    setDialogOpen(false);
    setForm({ codigo: "", nombre: "", valor: 0 });
  };

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
        <ZenttoDataGrid
            gridId="nomina-constantes-list"
          rows={rows}
          columns={columns}
          loading={isLoading}
          enableHeaderFilters
          pageSizeOptions={[25, 50]}
          disableRowSelectionOnClick
          getRowId={(r) => r.codigo ?? Math.random()}
          mobileVisibleFields={['codigo', 'nombre']}
          smExtraFields={['valor']}
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
