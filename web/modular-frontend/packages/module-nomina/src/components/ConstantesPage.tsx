"use client";

import React, { useState } from "react";
import {
  Box,
  Paper,
  Typography,
  Button,
  TextField,
  Stack,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import AddIcon from "@mui/icons-material/Add";
import { useConstantesList, useSaveConstante, type ConstanteInput } from "../hooks/useNomina";

export default function ConstantesPage() {
  const [dialogOpen, setDialogOpen] = useState(false);
  const [form, setForm] = useState<ConstanteInput>({ codigo: "", nombre: "", valor: 0 });

  const { data, isLoading } = useConstantesList();
  const saveMutation = useSaveConstante();

  const rows = data?.data ?? data?.rows ?? [];

  const columns: GridColDef[] = [
    { field: "codigo", headerName: "Código", width: 150 },
    { field: "nombre", headerName: "Nombre", flex: 1, minWidth: 200 },
    { field: "valor", headerName: "Valor", width: 150, type: "number" },
    { field: "origen", headerName: "Origen", width: 120 },
  ];

  const handleSave = async () => {
    await saveMutation.mutateAsync(form);
    setDialogOpen(false);
    setForm({ codigo: "", nombre: "", valor: 0 });
  };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Stack direction="row" justifyContent="flex-end" alignItems="center" mb={2}>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => setDialogOpen(true)}>
          Nueva Constante
        </Button>
      </Stack>

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%" }}>
        <DataGrid
          rows={rows}
          columns={columns}
          loading={isLoading}
          pageSizeOptions={[25, 50]}
          disableRowSelectionOnClick
          getRowId={(r) => r.codigo ?? Math.random()}
        />
      </Paper>

      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Nueva Constante</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <TextField label="Código" fullWidth value={form.codigo} onChange={(e) => setForm((f) => ({ ...f, codigo: e.target.value }))} />
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
