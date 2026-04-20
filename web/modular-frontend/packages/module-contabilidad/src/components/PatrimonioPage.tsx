"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box, Paper, Typography, Button, TextField, Chip, IconButton, Dialog, DialogTitle,
  DialogContent, DialogActions, Stack, Tab, Tabs, CircularProgress, Alert, MenuItem,
  Select, FormControl, InputLabel, type SelectChangeEvent, Tooltip,
} from "@mui/material";
import type { ColumnDef } from "@zentto/datagrid-core";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import { useGridLayoutSync, formatCurrency } from "@zentto/shared-api";
import { ModulePageShell, DatePicker } from "@zentto/shared-ui";
import dayjs from "dayjs";
import {
  useEquityMovements, useInsertEquityMovement, useUpdateEquityMovement, useDeleteEquityMovement,
  useEquityChangesReport, type EquityMovementInput, type EquityMovement,
} from "../hooks/useContabilidadLegal";

import { buildContabilidadGridId, useContabilidadGridId, useContabilidadGridRegistration } from "./zenttoGridPersistence";
const MOVEMENT_TYPES = [
  "CAPITAL_INCREASE", "CAPITAL_DECREASE", "RESERVE_LEGAL", "RESERVE_STATUTORY",
  "RESERVE_VOLUNTARY", "NET_INCOME", "RETAINED_EARNINGS", "DIVIDEND_CASH",
  "DIVIDEND_STOCK", "INFLATION_ADJUST", "REVALUATION_SURPLUS", "OTHER",
] as const;
type MovementType = (typeof MOVEMENT_TYPES)[number];
const MOVEMENT_TYPE_LABELS: Record<MovementType, string> = {
  CAPITAL_INCREASE: "Aumento de Capital", CAPITAL_DECREASE: "Disminucion de Capital",
  RESERVE_LEGAL: "Reserva legal", RESERVE_STATUTORY: "Reserva estatutaria",
  RESERVE_VOLUNTARY: "Reserva voluntaria", NET_INCOME: "Resultado del Ejercicio",
  RETAINED_EARNINGS: "Resultados acumulados", DIVIDEND_CASH: "Dividendo en Efectivo",
  DIVIDEND_STOCK: "Dividendo en Acciones", INFLATION_ADJUST: "Ajuste por Inflacion",
  REVALUATION_SURPLUS: "Superavit por Revaluacion", OTHER: "Otro",
};

const EMPTY_FORM: EquityMovementInput = { fiscalYear: new Date().getFullYear(), accountCode: "", movementType: "CAPITAL_INCREASE", movementDate: "", amount: 0, description: "" };

const MATRIX_COLUMNS = ["Saldo inicial", "Capital", "Reservas", "Resultados", "Dividendos", "Ajuste inflacion", "Otros", "Saldo final"];

const COLUMNS: ColumnDef[] = [
  { field: "AccountCode", header: "Codigo cuenta", width: 130, sortable: true },
  { field: "AccountName", header: "Nombre cuenta", flex: 1, minWidth: 180, sortable: true },
  { field: "MovementType", header: "Tipo movimiento", width: 190, sortable: true, groupable: true },
  { field: "MovementDate", header: "Fecha", width: 120, type: "date", sortable: true },
  { field: "Amount", header: "Monto", width: 150, type: "number", currency: "VES" },
  { field: "Description", header: "Descripcion", flex: 1, minWidth: 150 },
];

const GRID_IDS = {
  gridRef: buildContabilidadGridId("patrimonio", "main"),
} as const;

export default function PatrimonioPage() {
  const gridRef = useRef<any>(null);
    const { ready: gridLayoutReady } = useGridLayoutSync(GRID_IDS.gridRef);
  useContabilidadGridId(gridRef, GRID_IDS.gridRef);
  const layoutReady = gridLayoutReady;
  const { registered } = useContabilidadGridRegistration(layoutReady);
  const currentYear = new Date().getFullYear();
  const [fiscalYear, setFiscalYear] = useState<number>(currentYear);
  const [tab, setTab] = useState(0);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [deleteId, setDeleteId] = useState<number | null>(null);
  const [form, setForm] = useState<EquityMovementInput>({ ...EMPTY_FORM, fiscalYear });

  const { data, isLoading } = useEquityMovements(fiscalYear);
  const reportQuery = useEquityChangesReport(fiscalYear, tab === 1);
  const insertMutation = useInsertEquityMovement();
  const updateMutation = useUpdateEquityMovement();
  const deleteMutation = useDeleteEquityMovement();
  const rows: EquityMovement[] = data?.data ?? data?.rows ?? [];

  const yearOptions: number[] = [];
  for (let y = currentYear; y >= currentYear - 10; y--) yearOptions.push(y);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered || tab !== 0) return;
    el.columns = COLUMNS;
    el.rows = rows.map((r: any) => ({ ...r, id: r.EquityMovementId ?? r.id ?? r.Id, MovementDate: r.MovementDate?.split("T")[0] ?? "" }));
    el.loading = isLoading;
  }, [rows, isLoading, registered, tab]);

  const openCreate = () => { setEditingId(null); setForm({ ...EMPTY_FORM, fiscalYear }); setDialogOpen(true); };
  const openEdit = (row: EquityMovement) => {
    setEditingId(row.EquityMovementId);
    setForm({ fiscalYear, accountCode: row.AccountCode, movementType: row.MovementType, movementDate: row.MovementDate?.split("T")[0] ?? "", amount: row.Amount, description: row.Description ?? "" });
    setDialogOpen(true);
  };
  const handleSave = async () => {
    if (editingId) await updateMutation.mutateAsync({ id: editingId, ...form }); else await insertMutation.mutateAsync(form);
    setDialogOpen(false);
  };
  const handleDelete = async () => { if (!deleteId) return; await deleteMutation.mutateAsync(deleteId); setDeleteId(null); };

  const reportData = reportQuery.data?.data ?? reportQuery.data?.rows ?? [];

  if (!registered) { return <Box sx={{ display: "flex", justifyContent: "center", mt: 10 }}><CircularProgress /></Box>; }

  return (
    <>
      <ModulePageShell
        actions={<Button variant="contained" onClick={openCreate}>Nuevo movimiento</Button>}
        sx={{ display: "flex", flexDirection: "column", minHeight: 500 }}
      >
        <Stack direction="row" spacing={2} mb={2} alignItems="center">
          <FormControl sx={{ minWidth: 160 }}><InputLabel>Ano fiscal</InputLabel>
            <Select value={fiscalYear} label="Ano fiscal" onChange={(e: SelectChangeEvent<number>) => setFiscalYear(Number(e.target.value))}>
              {yearOptions.map((y) => (<MenuItem key={y} value={y}>{y}</MenuItem>))}
            </Select>
          </FormControl>
          <Typography variant="caption" color="text.secondary">VE: BA VEN-NIF 1, parrafos 106-110 | ES: PGC 3a parte - ECPN</Typography>
        </Stack>
        <Tabs value={tab} onChange={(_, v) => setTab(v)} sx={{ mb: 2 }}><Tab label="Movimientos" /><Tab label="Vista matricial" /></Tabs>

        {tab === 0 && (
          <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", elevation: 0, border: (t) => `1px solid ${t.palette.divider}` }}>
            <zentto-grid ref={gridRef} default-currency="VES" export-filename="patrimonio" height="100%"
              enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator></zentto-grid>
          </Paper>
        )}

        {tab === 1 && (
          <Paper sx={{ flex: 1, overflow: "auto", border: (t) => `1px solid ${t.palette.divider}`, elevation: 0 }}>
            {reportQuery.isLoading ? <Box sx={{ display: "flex", justifyContent: "center", p: 4 }}><CircularProgress /></Box>
            : reportData.length === 0 ? <Alert severity="info" sx={{ m: 2 }}>No hay datos para el ano fiscal {fiscalYear}.</Alert>
            : (
              <Box sx={{ overflowX: "auto" }}>
                <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "0.875rem" }}>
                  <thead>
                    <tr style={{ backgroundColor: "#F9FAFB" }}>
                      <th style={{ textAlign: "left", padding: "12px 16px", borderBottom: "2px solid #E5E7EB", fontWeight: 600 }}>Cuenta</th>
                      {MATRIX_COLUMNS.map((col) => (<th key={col} style={{ textAlign: "right", padding: "12px 16px", borderBottom: "2px solid #E5E7EB", fontWeight: 600, whiteSpace: "nowrap" }}>{col}</th>))}
                    </tr>
                  </thead>
                  <tbody>
                    {reportData.map((row: any, idx: number) => (
                      <tr key={row.AccountCode ?? idx} style={{ backgroundColor: idx % 2 === 0 ? "#FFFFFF" : "#F9FAFB" }}>
                        <td style={{ padding: "10px 16px", borderBottom: "1px solid #E5E7EB", fontWeight: row._isTotal ? 700 : 400 }}>
                          {row.AccountCode ? `${row.AccountCode} - ${row.AccountName}` : row.AccountName}
                        </td>
                        {["SaldoInicial","Capital","Reservas","Resultados","Dividendos","AjusteInflacion","Otros","SaldoFinal"].map((f) => (
                          <td key={f} style={{ textAlign: "right", padding: "10px 16px", borderBottom: "1px solid #E5E7EB", fontWeight: f === "SaldoFinal" ? 600 : 400 }}>{formatCurrency(row[f] ?? 0)}</td>
                        ))}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </Box>
            )}
          </Paper>
        )}
      </ModulePageShell>

      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editingId ? "Editar movimiento" : "Nuevo movimiento de patrimonio"}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField label="Codigo de Cuenta" fullWidth value={form.accountCode} onChange={(e) => setForm((f) => ({ ...f, accountCode: e.target.value }))} />
            <FormControl fullWidth><InputLabel>Tipo de Movimiento</InputLabel>
              <Select value={form.movementType} label="Tipo de Movimiento" onChange={(e: SelectChangeEvent) => setForm((f) => ({ ...f, movementType: e.target.value }))}>
                {MOVEMENT_TYPES.map((mt) => (<MenuItem key={mt} value={mt}>{MOVEMENT_TYPE_LABELS[mt]}</MenuItem>))}
              </Select>
            </FormControl>
            <DatePicker label="Fecha" value={form.movementDate ? dayjs(form.movementDate) : null} onChange={(v) => setForm((f) => ({ ...f, movementDate: v ? v.format('YYYY-MM-DD') : '' }))} slotProps={{ textField: { size: 'small', fullWidth: true } }} />
            <TextField label="Monto" type="number" fullWidth value={form.amount} onChange={(e) => setForm((f) => ({ ...f, amount: Number(e.target.value) }))} />
            <TextField label="Descripcion" fullWidth multiline rows={2} value={form.description} onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))} />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleSave} disabled={!form.accountCode || !form.movementDate || !form.amount || insertMutation.isPending || updateMutation.isPending}>
            {editingId ? "Guardar cambios" : "Crear movimiento"}
          </Button>
        </DialogActions>
      </Dialog>

      <Dialog open={deleteId != null} onClose={() => setDeleteId(null)}>
        <DialogTitle>Eliminar Movimiento</DialogTitle>
        <DialogContent><Typography>Esta seguro de que desea eliminar este movimiento? Esta accion no se puede deshacer.</Typography></DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteId(null)}>Cancelar</Button>
          <Button variant="contained" color="error" onClick={handleDelete} disabled={deleteMutation.isPending}>Eliminar</Button>
        </DialogActions>
      </Dialog>
    </>
  );
}

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
