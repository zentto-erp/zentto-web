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
  MenuItem,
  Select,
  FormControl,
  InputLabel,
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import AddIcon from "@mui/icons-material/Add";
import { useConceptosList, useSaveConcepto, type ConceptoFilter, type ConceptoInput } from "../hooks/useNomina";

export default function ConceptosPage() {
  const [filter, setFilter] = useState<ConceptoFilter>({ page: 1, limit: 50 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [form, setForm] = useState<ConceptoInput>({
    codigo: "",
    codigoNomina: "",
    nombre: "",
    tipo: "ASIGNACION",
  });

  const { data, isLoading } = useConceptosList(filter);
  const saveMutation = useSaveConcepto();

  const rows = data?.data ?? data?.rows ?? [];

  const columns: GridColDef[] = [
    { field: "codigo", headerName: "Código", width: 100 },
    { field: "codigoNomina", headerName: "Cód. Nómina", width: 120 },
    { field: "nombre", headerName: "Nombre", flex: 1, minWidth: 200 },
    { field: "tipo", headerName: "Tipo", width: 120 },
    { field: "clase", headerName: "Clase", width: 100 },
    { field: "formula", headerName: "Fórmula", width: 150 },
    { field: "valorDefecto", headerName: "Valor Def.", width: 110, type: "number" },
  ];

  const handleSave = async () => {
    await saveMutation.mutateAsync(form);
    setDialogOpen(false);
    setForm({ codigo: "", codigoNomina: "", nombre: "", tipo: "ASIGNACION" });
  };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Stack direction="row" justifyContent="flex-end" alignItems="center" mb={2}>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => setDialogOpen(true)}>
          Nuevo Concepto
        </Button>
      </Stack>

      <Stack direction="row" spacing={2} mb={2}>
        <TextField
          label="Buscar"
          size="small"
          value={filter.search || ""}
          onChange={(e) => setFilter((f) => ({ ...f, search: e.target.value }))}
        />
        <FormControl size="small" sx={{ minWidth: 150 }}>
          <InputLabel>Tipo</InputLabel>
          <Select
            value={filter.tipo || ""}
            label="Tipo"
            onChange={(e) => setFilter((f) => ({ ...f, tipo: e.target.value || undefined }))}
          >
            <MenuItem value="">Todos</MenuItem>
            <MenuItem value="ASIGNACION">Asignación</MenuItem>
            <MenuItem value="DEDUCCION">Deducción</MenuItem>
            <MenuItem value="BONO">Bono</MenuItem>
          </Select>
        </FormControl>
      </Stack>

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%" }}>
        <DataGrid
          rows={rows}
          columns={columns}
          loading={isLoading}
          pageSizeOptions={[25, 50]}
          disableRowSelectionOnClick
          getRowId={(r) => r.codigo ?? r.Codigo ?? Math.random()}
        />
      </Paper>

      {/* New Concept Dialog */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Nuevo Concepto</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <TextField
              label="Código"
              fullWidth
              value={form.codigo}
              onChange={(e) => setForm((f) => ({ ...f, codigo: e.target.value }))}
            />
            <TextField
              label="Código Nómina"
              fullWidth
              value={form.codigoNomina}
              onChange={(e) => setForm((f) => ({ ...f, codigoNomina: e.target.value }))}
            />
            <TextField
              label="Nombre"
              fullWidth
              value={form.nombre}
              onChange={(e) => setForm((f) => ({ ...f, nombre: e.target.value }))}
            />
            <FormControl fullWidth>
              <InputLabel>Tipo</InputLabel>
              <Select
                value={form.tipo || "ASIGNACION"}
                label="Tipo"
                onChange={(e) => setForm((f) => ({ ...f, tipo: e.target.value as any }))}
              >
                <MenuItem value="ASIGNACION">Asignación</MenuItem>
                <MenuItem value="DEDUCCION">Deducción</MenuItem>
                <MenuItem value="BONO">Bono</MenuItem>
              </Select>
            </FormControl>
            <TextField
              label="Fórmula"
              fullWidth
              value={form.formula || ""}
              onChange={(e) => setForm((f) => ({ ...f, formula: e.target.value }))}
            />
            <TextField
              label="Valor por defecto"
              type="number"
              fullWidth
              value={form.valorDefecto || ""}
              onChange={(e) => setForm((f) => ({ ...f, valorDefecto: Number(e.target.value) || undefined }))}
            />
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
