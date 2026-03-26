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
  MenuItem,
  Select,
  FormControl,
  InputLabel,
  FormControlLabel,
  Switch,
  Divider,
  Typography,
  Collapse,
} from "@mui/material";

import type { ColumnDef } from "@zentto/datagrid-core";
import { useLookup } from "@zentto/shared-api";
import AddIcon from "@mui/icons-material/Add";
import ExpandMoreIcon from "@mui/icons-material/ExpandMore";
import ExpandLessIcon from "@mui/icons-material/ExpandLess";
import { useConceptosList, useSaveConcepto, useDeleteConcepto, type ConceptoFilter, type ConceptoInput } from "../hooks/useNomina";
import FormulaEditor from "./FormulaEditor";

const COLUMNS: ColumnDef[] = [
  { field: "codigo", header: "Código", width: 100, sortable: true },
  { field: "codigoNomina", header: "Cód. Nómina", width: 120, sortable: true },
  { field: "nombre", header: "Nombre", flex: 1, minWidth: 200, sortable: true },
  { field: "tipo", header: "Tipo", width: 120, sortable: true, groupable: true },
  { field: "clase", header: "Clase", width: 100, sortable: true, groupable: true },
  { field: "formula", header: "Fórmula", width: 150 },
  { field: "valorDefecto", header: "Valor Def.", width: 110, type: "number" },
];

const emptyForm: ConceptoInput = {
  codigo: "",
  codigoNomina: "",
  nombre: "",
  tipo: "ASIGNACION",
};


const SVG_EDIT = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>';
const SVG_DELETE = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>';

export default function ConceptosPage() {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
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

  useEffect(() => {
    import("@zentto/datagrid").then(() => setRegistered(true));
  }, []);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows;
    el.loading = isLoading;
    el.getRowId = (r: any) => `${r.codigo ?? r.Codigo}_${r.codigoNomina ?? r.CodigoNomina ?? ""}`;
    el.actionButtons = [
      { icon: SVG_EDIT, label: "Editar", action: "edit", color: "#1976d2" },
      { icon: SVG_DELETE, label: "Eliminar", action: "delete", color: "#dc2626" },
    ];
  }, [rows, isLoading, registered]);

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

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "edit") handleEdit(row);
      if (action === "delete") handleDelete(row);
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, rows]);

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
        />
      </Box>

      {/* Create/Edit Dialog */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>{editMode ? "Editar Concepto" : "Nuevo Concepto"}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
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

            <Divider>
              <Typography variant="caption" color="text.secondary">Cálculo</Typography>
            </Divider>

            <FormulaEditor
              value={form.formula || ""}
              onChange={(v) => setForm((f) => ({ ...f, formula: v }))}
              conceptCodes={rows.map((r: any) => r.codigo ?? r.Codigo).filter(Boolean)}
            />

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

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
