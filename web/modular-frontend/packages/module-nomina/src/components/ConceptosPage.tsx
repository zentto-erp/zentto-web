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
  MenuItem,
  Select,
  FormControl,
  InputLabel,
  IconButton,
  Tooltip,
  FormControlLabel,
  Switch,
  Divider,
  Typography,
  Collapse,
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import { ZenttoDataGrid } from "@zentto/shared-ui";
import { useLookup } from "@zentto/shared-api";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import ExpandMoreIcon from "@mui/icons-material/ExpandMore";
import ExpandLessIcon from "@mui/icons-material/ExpandLess";
import { useConceptosList, useSaveConcepto, useDeleteConcepto, type ConceptoFilter, type ConceptoInput } from "../hooks/useNomina";
import FormulaEditor from "./FormulaEditor";

const emptyForm: ConceptoInput = {
  codigo: "",
  codigoNomina: "",
  nombre: "",
  tipo: "ASIGNACION",
};

export default function ConceptosPage() {
  const [filter, setFilter] = useState<ConceptoFilter>({ page: 1, limit: 50 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [form, setForm] = useState<ConceptoInput>({ ...emptyForm });
  const [showAdvanced, setShowAdvanced] = useState(false);

  const { data, isLoading } = useConceptosList(filter);
  const saveMutation = useSaveConcepto();
  const deleteMutation = useDeleteConcepto();
  const { data: frequencies = [] } = useLookup('PAYROLL_FREQUENCY');

  const rows = data?.data ?? data?.rows ?? [];

  const handleNew = () => {
    setForm({ ...emptyForm });
    setEditMode(false);
    setDialogOpen(true);
  };

  const handleEdit = (row: Record<string, any>) => {
    setForm({
      codigo: row.codigo ?? row.Codigo ?? "",
      codigoNomina: row.codigoNomina ?? row.CodigoNomina ?? "",
      nombre: row.nombre ?? row.Nombre ?? "",
      tipo: row.tipo ?? row.Tipo ?? "ASIGNACION",
      clase: row.clase ?? row.Clase,
      formula: row.formula ?? row.Formula,
      sobre: row.sobre ?? row.Sobre,
      uso: row.uso ?? row.Uso,
      bonificable: row.bonificable ?? row.Bonificable,
      esAntiguedad: row.esAntiguedad ?? row.EsAntiguedad,
      cuentaContable: row.cuentaContable ?? row.CuentaContable,
      aplica: row.aplica ?? row.Aplica,
      valorDefecto: row.valorDefecto ?? row.ValorDefecto,
    });
    setEditMode(true);
    setShowAdvanced(false);
    setDialogOpen(true);
  };

  const handleDelete = async (row: Record<string, any>) => {
    const codigo = row.codigo ?? row.Codigo;
    if (!codigo) return;
    if (!window.confirm(`¿Eliminar el concepto "${row.nombre ?? row.Nombre}"?`)) return;
    await deleteMutation.mutateAsync(codigo);
  };

  const columns: GridColDef[] = [
    { field: "codigo", headerName: "Código", width: 100 },
    { field: "codigoNomina", headerName: "Cód. Nómina", width: 120 },
    { field: "nombre", headerName: "Nombre", flex: 1, minWidth: 200 },
    { field: "tipo", headerName: "Tipo", width: 120 },
    { field: "clase", headerName: "Clase", width: 100 },
    { field: "formula", headerName: "Fórmula", width: 150 },
    { field: "valorDefecto", headerName: "Valor Def.", width: 110, type: "number" },
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
    setForm({ ...emptyForm });
  };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Stack direction="row" justifyContent="flex-end" alignItems="center" mb={2}>
        <Button variant="contained" startIcon={<AddIcon />} onClick={handleNew}>
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
        <ZenttoDataGrid
          rows={rows}
          columns={columns}
          loading={isLoading}
          pageSizeOptions={[25, 50]}
          disableRowSelectionOnClick
          getRowId={(r) => `${r.codigo ?? r.Codigo}_${r.codigoNomina ?? r.CodigoNomina ?? ""}`}
          mobileVisibleFields={['codigo', 'nombre']}
          smExtraFields={['tipo', 'clase']}
        />
      </Paper>

      {/* Create/Edit Dialog */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>{editMode ? "Editar Concepto" : "Nuevo Concepto"}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            {/* Row 1: Código + Código Nómina */}
            <Stack direction="row" spacing={2}>
              <TextField
                label="Código"
                fullWidth
                value={form.codigo}
                onChange={(e) => setForm((f) => ({ ...f, codigo: e.target.value.toUpperCase() }))}
                disabled={editMode}
                helperText={!editMode ? "Ej: SUELDO, SSO, HE_DIURNAS" : undefined}
              />
              <TextField
                label="Código Nómina"
                fullWidth
                value={form.codigoNomina}
                onChange={(e) => setForm((f) => ({ ...f, codigoNomina: e.target.value.toUpperCase() }))}
              />
            </Stack>

            <TextField
              label="Nombre"
              fullWidth
              value={form.nombre}
              onChange={(e) => setForm((f) => ({ ...f, nombre: e.target.value }))}
            />

            {/* Row 2: Tipo + Clase */}
            <Stack direction="row" spacing={2}>
              <FormControl fullWidth>
                <InputLabel>Tipo</InputLabel>
                <Select
                  value={form.tipo || "ASIGNACION"}
                  label="Tipo"
                  onChange={(e) => setForm((f) => ({ ...f, tipo: e.target.value as "ASIGNACION" | "DEDUCCION" | "BONO" }))}
                >
                  <MenuItem value="ASIGNACION">Asignación</MenuItem>
                  <MenuItem value="DEDUCCION">Deducción</MenuItem>
                  <MenuItem value="BONO">Bono</MenuItem>
                </Select>
              </FormControl>
              <FormControl fullWidth>
                <InputLabel>Clase</InputLabel>
                <Select
                  value={form.clase || ""}
                  label="Clase"
                  onChange={(e) => setForm((f) => ({ ...f, clase: e.target.value || undefined }))}
                >
                  <MenuItem value="">Sin clase</MenuItem>
                  <MenuItem value="SALARIO">Salario</MenuItem>
                  <MenuItem value="BONO">Bono</MenuItem>
                  <MenuItem value="LEGAL">Legal</MenuItem>
                  <MenuItem value="COMISION">Comisión</MenuItem>
                  <MenuItem value="HORA_EXTRA">Hora Extra</MenuItem>
                  <MenuItem value="VACACION">Vacación</MenuItem>
                  <MenuItem value="LIQUIDACION">Liquidación</MenuItem>
                  <MenuItem value="PRESTACION">Prestación</MenuItem>
                </Select>
              </FormControl>
            </Stack>

            {/* Formula editor */}
            <Divider>
              <Typography variant="caption" color="text.secondary">Cálculo</Typography>
            </Divider>

            <FormulaEditor
              value={form.formula || ""}
              onChange={(v) => setForm((f) => ({ ...f, formula: v }))}
              conceptCodes={rows.map((r: any) => r.codigo ?? r.Codigo).filter(Boolean)}
            />

            {/* Row: Base + Valor por defecto */}
            <Stack direction="row" spacing={2}>
              <TextField
                label="Base de cálculo (sobre)"
                fullWidth
                value={form.sobre || ""}
                onChange={(e) => setForm((f) => ({ ...f, sobre: e.target.value }))}
                placeholder="Ej: SUELDO, SALARIO_DIARIO"
                helperText="Variable base para el cálculo (referencia)"
              />
              <TextField
                label="Valor por defecto"
                type="number"
                fullWidth
                value={form.valorDefecto ?? ""}
                onChange={(e) => setForm((f) => ({ ...f, valorDefecto: Number(e.target.value) || undefined }))}
                helperText="Valor fijo si no hay fórmula"
              />
            </Stack>

            {/* Advanced fields */}
            <Box>
              <Button
                size="small"
                onClick={() => setShowAdvanced((v) => !v)}
                endIcon={showAdvanced ? <ExpandLessIcon /> : <ExpandMoreIcon />}
                sx={{ textTransform: "none", color: "text.secondary" }}
              >
                Opciones avanzadas
              </Button>
              <Collapse in={showAdvanced}>
                <Stack spacing={2} mt={1}>
                  <Stack direction="row" spacing={2}>
                    <TextField
                      label="Cuenta contable"
                      fullWidth
                      value={form.cuentaContable || ""}
                      onChange={(e) => setForm((f) => ({ ...f, cuentaContable: e.target.value }))}
                      placeholder="Ej: 5.1.01.001"
                    />
                    <FormControl fullWidth>
                      <InputLabel>Uso</InputLabel>
                      <Select
                        value={form.uso || ""}
                        label="Uso"
                        onChange={(e) => setForm((f) => ({ ...f, uso: e.target.value || undefined }))}
                      >
                        <MenuItem value="">General</MenuItem>
                        {frequencies.map(f => (
                          <MenuItem key={f.Code} value={f.Code}>{f.Label}</MenuItem>
                        ))}
                      </Select>
                    </FormControl>
                  </Stack>
                  <Stack direction="row" spacing={3}>
                    <FormControlLabel
                      control={
                        <Switch
                          checked={form.bonificable === "S"}
                          onChange={(e) => setForm((f) => ({ ...f, bonificable: e.target.checked ? "S" : "N" }))}
                        />
                      }
                      label="Bonificable (suma para utilidades)"
                    />
                    <FormControlLabel
                      control={
                        <Switch
                          checked={form.esAntiguedad === "S"}
                          onChange={(e) => setForm((f) => ({ ...f, esAntiguedad: e.target.checked ? "S" : "N" }))}
                        />
                      }
                      label="Por antigüedad"
                    />
                    <FormControlLabel
                      control={
                        <Switch
                          checked={form.aplica !== "N"}
                          onChange={(e) => setForm((f) => ({ ...f, aplica: e.target.checked ? "S" : "N" }))}
                        />
                      }
                      label="Aplica al empleado"
                    />
                  </Stack>
                </Stack>
              </Collapse>
            </Box>
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
