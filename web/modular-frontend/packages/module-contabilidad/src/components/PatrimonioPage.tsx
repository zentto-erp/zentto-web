"use client";

import React, { useState } from "react";
import {
  Box,
  Paper,
  Typography,
  Button,
  TextField,
  Chip,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Stack,
  Tab,
  Tabs,
  CircularProgress,
  Alert,
  MenuItem,
  Select,
  FormControl,
  InputLabel,
  type SelectChangeEvent,
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import AddIcon from "@mui/icons-material/Add";
import { formatCurrency } from "@zentto/shared-api";
import { ContextActionHeader, ZenttoDataGrid } from "@zentto/shared-ui";
import {
  useEquityMovements,
  useInsertEquityMovement,
  useUpdateEquityMovement,
  useDeleteEquityMovement,
  useEquityChangesReport,
  type EquityMovementInput,
  type EquityMovement,
} from "../hooks/useContabilidadLegal";

// ─── Movement Types ──────────────────────────────────────────

const MOVEMENT_TYPES = [
  "CAPITAL_INCREASE",
  "CAPITAL_DECREASE",
  "RESERVE_LEGAL",
  "RESERVE_STATUTORY",
  "RESERVE_VOLUNTARY",
  "NET_INCOME",
  "RETAINED_EARNINGS",
  "DIVIDEND_CASH",
  "DIVIDEND_STOCK",
  "INFLATION_ADJUST",
  "REVALUATION_SURPLUS",
  "OTHER",
] as const;

type MovementType = (typeof MOVEMENT_TYPES)[number];

const MOVEMENT_TYPE_LABELS: Record<MovementType, string> = {
  CAPITAL_INCREASE: "Aumento de Capital",
  CAPITAL_DECREASE: "Disminución de Capital",
  RESERVE_LEGAL: "Reserva legal",
  RESERVE_STATUTORY: "Reserva estatutaria",
  RESERVE_VOLUNTARY: "Reserva voluntaria",
  NET_INCOME: "Resultado del Ejercicio",
  RETAINED_EARNINGS: "Resultados acumulados",
  DIVIDEND_CASH: "Dividendo en Efectivo",
  DIVIDEND_STOCK: "Dividendo en Acciones",
  INFLATION_ADJUST: "Ajuste por Inflación",
  REVALUATION_SURPLUS: "Superávit por Revaluación",
  OTHER: "Otro",
};

function getMovementChipColor(
  type: string
): "primary" | "info" | "success" | "warning" | "secondary" | "default" {
  switch (type) {
    case "CAPITAL_INCREASE":
    case "CAPITAL_DECREASE":
      return "primary";
    case "RESERVE_LEGAL":
    case "RESERVE_STATUTORY":
    case "RESERVE_VOLUNTARY":
      return "info";
    case "NET_INCOME":
    case "RETAINED_EARNINGS":
      return "success";
    case "DIVIDEND_CASH":
    case "DIVIDEND_STOCK":
      return "warning";
    case "INFLATION_ADJUST":
    case "REVALUATION_SURPLUS":
      return "secondary";
    default:
      return "default";
  }
}

// ─── Empty Form ──────────────────────────────────────────────

const EMPTY_FORM: EquityMovementInput = {
  fiscalYear: new Date().getFullYear(),
  accountCode: "",
  movementType: "CAPITAL_INCREASE",
  movementDate: "",
  amount: 0,
  description: "",
};

// ─── Matricial Columns ──────────────────────────────────────

const MATRIX_COLUMNS = [
  "Saldo inicial",
  "Capital",
  "Reservas",
  "Resultados",
  "Dividendos",
  "Ajuste inflación",
  "Otros",
  "Saldo final",
];

// ─── Component ──────────────────────────────────────────────

export default function PatrimonioPage() {
  const currentYear = new Date().getFullYear();
  const [fiscalYear, setFiscalYear] = useState<number>(currentYear);
  const [tab, setTab] = useState(0);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [deleteId, setDeleteId] = useState<number | null>(null);
  const [form, setForm] = useState<EquityMovementInput>({ ...EMPTY_FORM, fiscalYear });

  // ─── Hooks ────────────────────────────────────────────────
  const { data, isLoading } = useEquityMovements(fiscalYear);
  const reportQuery = useEquityChangesReport(fiscalYear, tab === 1);
  const insertMutation = useInsertEquityMovement();
  const updateMutation = useUpdateEquityMovement();
  const deleteMutation = useDeleteEquityMovement();

  const rows: EquityMovement[] = data?.data ?? data?.rows ?? [];

  // ─── Fiscal Year Options ──────────────────────────────────
  const yearOptions: number[] = [];
  for (let y = currentYear; y >= currentYear - 10; y--) {
    yearOptions.push(y);
  }

  // ─── Handlers ─────────────────────────────────────────────

  const openCreate = () => {
    setEditingId(null);
    setForm({ ...EMPTY_FORM, fiscalYear });
    setDialogOpen(true);
  };

  const openEdit = (row: EquityMovement) => {
    setEditingId(row.EquityMovementId);
    setForm({
      fiscalYear,
      accountCode: row.AccountCode,
      movementType: row.MovementType,
      movementDate: row.MovementDate?.split("T")[0] ?? "",
      amount: row.Amount,
      description: row.Description ?? "",
    });
    setDialogOpen(true);
  };

  const handleSave = async () => {
    if (editingId) {
      await updateMutation.mutateAsync({ id: editingId, ...form });
    } else {
      await insertMutation.mutateAsync(form);
    }
    setDialogOpen(false);
  };

  const handleDelete = async () => {
    if (!deleteId) return;
    await deleteMutation.mutateAsync(deleteId);
    setDeleteId(null);
  };

  // ─── DataGrid Columns ────────────────────────────────────

  const columns: GridColDef[] = [
    { field: "AccountCode", headerName: "Código cuenta", width: 130 },
    { field: "AccountName", headerName: "Nombre cuenta", flex: 1, minWidth: 180 },
    {
      field: "MovementType",
      headerName: "Tipo movimiento",
      width: 190,
      renderCell: (p) => (
        <Chip
          label={MOVEMENT_TYPE_LABELS[p.value as MovementType] ?? p.value}
          size="small"
          color={getMovementChipColor(p.value)}
        />
      ),
    },
    {
      field: "MovementDate",
      headerName: "Fecha",
      width: 120,
      valueFormatter: (value: string) => (value ? value.split("T")[0] : ""),
    },
    {
      field: "Amount",
      headerName: "Monto",
      width: 150,
      align: "right",
      headerAlign: "right",
      renderCell: (p) => formatCurrency(p.value),
    },
    { field: "Description", headerName: "Descripción", flex: 1, minWidth: 150 },
    {
      field: "acciones",
      headerName: "",
      width: 100,
      sortable: false,
      renderCell: (p) => (
        <Stack direction="row" spacing={0.5}>
          <IconButton size="small" onClick={() => openEdit(p.row)}>
            <EditIcon fontSize="small" />
          </IconButton>
          <IconButton size="small" color="error" onClick={() => setDeleteId(p.row.EquityMovementId)}>
            <DeleteIcon fontSize="small" />
          </IconButton>
        </Stack>
      ),
    },
  ];

  // ─── Matricial Data ──────────────────────────────────────

  const reportData = reportQuery.data?.data ?? reportQuery.data?.rows ?? [];

  // ─── Render ──────────────────────────────────────────────

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader
        title="Estado de Cambios en el Patrimonio"
        primaryAction={{
          label: "Nuevo movimiento",
          onClick: openCreate,
        }}
      />

      <Box sx={{ p: { xs: 2, md: 3 }, flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
        {/* Fiscal Year Selector + Legal Reference */}
        <Stack direction="row" spacing={2} mb={2} alignItems="center">
          <FormControl size="small" sx={{ minWidth: 160 }}>
            <InputLabel>Año fiscal</InputLabel>
            <Select
              value={fiscalYear}
              label="Año fiscal"
              onChange={(e: SelectChangeEvent<number>) => setFiscalYear(Number(e.target.value))}
            >
              {yearOptions.map((y) => (
                <MenuItem key={y} value={y}>
                  {y}
                </MenuItem>
              ))}
            </Select>
          </FormControl>
          <Typography variant="caption" color="text.secondary">
            VE: BA VEN-NIF 1, párrafos 106-110 &nbsp;|&nbsp; ES: PGC 3a parte - ECPN
          </Typography>
        </Stack>

        {/* Tabs */}
        <Tabs value={tab} onChange={(_, v) => setTab(v)} sx={{ mb: 2 }}>
          <Tab label="Movimientos" />
          <Tab label="Vista matricial" />
        </Tabs>

        {/* Tab: Movimientos */}
        {tab === 0 && (
          <Paper
            sx={{
              flex: 1,
              display: "flex",
              flexDirection: "column",
              minHeight: 0,
              width: "100%",
              elevation: 0,
              border: "1px solid #E5E7EB",
            }}
          >
            <ZenttoDataGrid
              rows={rows}
              columns={columns}
              loading={isLoading}
              pageSizeOptions={[25, 50]}
              paginationModel={{ page: 0, pageSize: 25 }}
              disableRowSelectionOnClick
              getRowId={(row) => row.EquityMovementId ?? row.id ?? row.Id}
              sx={{ border: "none" }}
              mobileVisibleFields={['MovementDate', 'MovementType']}
              smExtraFields={['Amount', 'AccountCode']}
            />
          </Paper>
        )}

        {/* Tab: Vista Matricial */}
        {tab === 1 && (
          <Paper
            sx={{
              flex: 1,
              overflow: "auto",
              border: "1px solid #E5E7EB",
              elevation: 0,
            }}
          >
            {reportQuery.isLoading ? (
              <Box sx={{ display: "flex", justifyContent: "center", p: 4 }}>
                <CircularProgress />
              </Box>
            ) : reportData.length === 0 ? (
              <Alert severity="info" sx={{ m: 2 }}>
                No hay datos para el año fiscal {fiscalYear}.
              </Alert>
            ) : (
              <Box sx={{ overflowX: "auto" }}>
                <table
                  style={{
                    width: "100%",
                    borderCollapse: "collapse",
                    fontSize: "0.875rem",
                  }}
                >
                  <thead>
                    <tr style={{ backgroundColor: "#F9FAFB" }}>
                      <th
                        style={{
                          textAlign: "left",
                          padding: "12px 16px",
                          borderBottom: "2px solid #E5E7EB",
                          fontWeight: 600,
                        }}
                      >
                        Cuenta
                      </th>
                      {MATRIX_COLUMNS.map((col) => (
                        <th
                          key={col}
                          style={{
                            textAlign: "right",
                            padding: "12px 16px",
                            borderBottom: "2px solid #E5E7EB",
                            fontWeight: 600,
                            whiteSpace: "nowrap",
                          }}
                        >
                          {col}
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {reportData.map((row: any, idx: number) => (
                      <tr
                        key={row.AccountCode ?? idx}
                        style={{
                          backgroundColor: idx % 2 === 0 ? "#FFFFFF" : "#F9FAFB",
                        }}
                      >
                        <td
                          style={{
                            padding: "10px 16px",
                            borderBottom: "1px solid #E5E7EB",
                            fontWeight: row._isTotal ? 700 : 400,
                          }}
                        >
                          {row.AccountCode ? `${row.AccountCode} - ${row.AccountName}` : row.AccountName}
                        </td>
                        <td style={{ textAlign: "right", padding: "10px 16px", borderBottom: "1px solid #E5E7EB" }}>
                          {formatCurrency(row.SaldoInicial ?? 0)}
                        </td>
                        <td style={{ textAlign: "right", padding: "10px 16px", borderBottom: "1px solid #E5E7EB" }}>
                          {formatCurrency(row.Capital ?? 0)}
                        </td>
                        <td style={{ textAlign: "right", padding: "10px 16px", borderBottom: "1px solid #E5E7EB" }}>
                          {formatCurrency(row.Reservas ?? 0)}
                        </td>
                        <td style={{ textAlign: "right", padding: "10px 16px", borderBottom: "1px solid #E5E7EB" }}>
                          {formatCurrency(row.Resultados ?? 0)}
                        </td>
                        <td style={{ textAlign: "right", padding: "10px 16px", borderBottom: "1px solid #E5E7EB" }}>
                          {formatCurrency(row.Dividendos ?? 0)}
                        </td>
                        <td style={{ textAlign: "right", padding: "10px 16px", borderBottom: "1px solid #E5E7EB" }}>
                          {formatCurrency(row.AjusteInflacion ?? 0)}
                        </td>
                        <td style={{ textAlign: "right", padding: "10px 16px", borderBottom: "1px solid #E5E7EB" }}>
                          {formatCurrency(row.Otros ?? 0)}
                        </td>
                        <td
                          style={{
                            textAlign: "right",
                            padding: "10px 16px",
                            borderBottom: "1px solid #E5E7EB",
                            fontWeight: 600,
                          }}
                        >
                          {formatCurrency(row.SaldoFinal ?? 0)}
                        </td>
                      </tr>
                    ))}
                    {/* Totals Row */}
                    {reportData.length > 0 && !reportData[reportData.length - 1]?._isTotal && (
                      <tr style={{ backgroundColor: "#F3F4F6" }}>
                        <td
                          style={{
                            padding: "10px 16px",
                            borderTop: "2px solid #D1D5DB",
                            fontWeight: 700,
                          }}
                        >
                          TOTAL
                        </td>
                        {["SaldoInicial", "Capital", "Reservas", "Resultados", "Dividendos", "AjusteInflacion", "Otros", "SaldoFinal"].map(
                          (field) => (
                            <td
                              key={field}
                              style={{
                                textAlign: "right",
                                padding: "10px 16px",
                                borderTop: "2px solid #D1D5DB",
                                fontWeight: 700,
                              }}
                            >
                              {formatCurrency(
                                reportData.reduce((sum: number, r: any) => sum + (r[field] ?? 0), 0)
                              )}
                            </td>
                          )
                        )}
                      </tr>
                    )}
                  </tbody>
                </table>
              </Box>
            )}
          </Paper>
        )}
      </Box>

      {/* Create / Edit Dialog */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editingId ? "Editar movimiento" : "Nuevo movimiento de patrimonio"}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField
              label="Código de Cuenta"
              fullWidth
              size="small"
              value={form.accountCode}
              onChange={(e) => setForm((f) => ({ ...f, accountCode: e.target.value }))}
            />
            <FormControl fullWidth size="small">
              <InputLabel>Tipo de Movimiento</InputLabel>
              <Select
                value={form.movementType}
                label="Tipo de Movimiento"
                onChange={(e: SelectChangeEvent) =>
                  setForm((f) => ({ ...f, movementType: e.target.value }))
                }
              >
                {MOVEMENT_TYPES.map((mt) => (
                  <MenuItem key={mt} value={mt}>
                    {MOVEMENT_TYPE_LABELS[mt]}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            <TextField
              label="Fecha"
              type="date"
              fullWidth
              size="small"
              InputLabelProps={{ shrink: true }}
              value={form.movementDate}
              onChange={(e) => setForm((f) => ({ ...f, movementDate: e.target.value }))}
            />
            <TextField
              label="Monto"
              type="number"
              fullWidth
              size="small"
              value={form.amount}
              onChange={(e) => setForm((f) => ({ ...f, amount: Number(e.target.value) }))}
            />
            <TextField
              label="Descripción"
              fullWidth
              size="small"
              multiline
              rows={2}
              value={form.description}
              onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))}
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleSave}
            disabled={
              !form.accountCode ||
              !form.movementDate ||
              !form.amount ||
              insertMutation.isPending ||
              updateMutation.isPending
            }
          >
            {editingId ? "Guardar cambios" : "Crear movimiento"}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <Dialog open={deleteId != null} onClose={() => setDeleteId(null)}>
        <DialogTitle>Eliminar Movimiento</DialogTitle>
        <DialogContent>
          <Typography>
            ¿Está seguro de que desea eliminar este movimiento de patrimonio? Esta acción no se puede deshacer.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteId(null)}>Cancelar</Button>
          <Button
            variant="contained"
            color="error"
            onClick={handleDelete}
            disabled={deleteMutation.isPending}
          >
            Eliminar
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
