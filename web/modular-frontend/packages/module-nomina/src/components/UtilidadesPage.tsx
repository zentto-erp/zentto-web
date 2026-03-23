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
  Chip,
  CircularProgress,
  IconButton,
  Tooltip,
} from "@mui/material";
import { type GridColDef } from "@mui/x-data-grid";
import { ZenttoDataGrid } from "@zentto/shared-ui";
import AddIcon from "@mui/icons-material/Add";
import VisibilityIcon from "@mui/icons-material/Visibility";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import { formatCurrency } from "@zentto/shared-api";
import {
  useProfitSharingList,
  useGenerateProfitSharing,
  useProfitSharingSummary,
  useApproveProfitSharing,
  type ProfitSharingFilter,
} from "../hooks/useRRHH";

export default function UtilidadesPage() {
  const [filter, setFilter] = useState<ProfitSharingFilter>({ page: 1, limit: 25 });
  const [generateOpen, setGenerateOpen] = useState(false);
  const [summaryId, setSummaryId] = useState<number | null>(null);
  const [generateForm, setGenerateForm] = useState({ fiscalYear: new Date().getFullYear(), daysGranted: 15 });

  const { data, isLoading } = useProfitSharingList(filter);
  const generateMutation = useGenerateProfitSharing();
  const approveMutation = useApproveProfitSharing();
  const summary = useProfitSharingSummary(summaryId);

  const rows = data?.data ?? data?.rows ?? [];
  const summaryRows = summary.data?.employees ?? summary.data?.data ?? [];

  const columns: GridColDef[] = [
    { field: "fiscalYear", headerName: "Año Fiscal", width: 120 },
    { field: "daysGranted", headerName: "Días Otorgados", width: 140 },
    { field: "totalEmployees", headerName: "Total Empleados", width: 140 },
    {
      field: "totalAmount",
      headerName: "Monto Total",
      width: 150,
      renderCell: (p) => formatCurrency(p.value ?? 0),
    },
    {
      field: "status",
      headerName: "Estado",
      width: 120,
      renderCell: (p) => (
        <Chip
          label={p.value || "PENDIENTE"}
          size="small"
          color={
            p.value === "APROBADO" ? "success" :
            p.value === "PROCESADO" ? "info" : "warning"
          }
        />
      ),
    },
    {
      field: "actions",
      headerName: "",
      width: 120,
      sortable: false,
      renderCell: (p) => (
        <Stack direction="row" spacing={0.5}>
          <Tooltip title="Ver resumen">
            <IconButton size="small" onClick={() => setSummaryId(p.row.id)}>
              <VisibilityIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          {p.row.status !== "APROBADO" && p.row.status !== "PROCESADO" && (
            <Tooltip title="Aprobar calculo">
              <IconButton
                size="small"
                color="success"
                onClick={() => approveMutation.mutate({ id: p.row.id })}
              >
                <CheckCircleIcon fontSize="small" />
              </IconButton>
            </Tooltip>
          )}
        </Stack>
      ),
    },
  ];

  const summaryColumns: GridColDef[] = [
    { field: "employeeCode", headerName: "Código", width: 100 },
    { field: "employeeName", headerName: "Empleado", flex: 1, minWidth: 200 },
    { field: "daysWorked", headerName: "Días Trabajados", width: 140 },
    { field: "salary", headerName: "Salario", width: 130, renderCell: (p) => formatCurrency(p.value ?? 0) },
    { field: "amount", headerName: "Utilidades", width: 130, renderCell: (p) => formatCurrency(p.value ?? 0) },
  ];

  const handleGenerate = async () => {
    await generateMutation.mutateAsync(generateForm);
    setGenerateOpen(false);
  };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h6">Utilidades (Reparto de Beneficios)</Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => setGenerateOpen(true)}>
          Generar Utilidades
        </Button>
      </Stack>

      <Stack direction="row" spacing={2} mb={2}>
        <TextField
          label="Año Fiscal"
          type="number"
          size="small"
          value={filter.fiscalYear || ""}
          onChange={(e) => setFilter((f) => ({ ...f, fiscalYear: Number(e.target.value) || undefined }))}
        />
      </Stack>

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", border: "1px solid #E5E7EB" }}>
        <ZenttoDataGrid
          rows={rows}
          columns={columns}
          loading={isLoading}
          pageSizeOptions={[25, 50]}
          disableRowSelectionOnClick
          getRowId={(r) => r.id ?? r.fiscalYear}
          mobileVisibleFields={['fiscalYear', 'totalAmount']}
          smExtraFields={['status', 'totalEmployees']}
        />
      </Paper>

      {/* Generate Dialog */}
      <Dialog open={generateOpen} onClose={() => setGenerateOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Generar Utilidades</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <TextField
              label="Año Fiscal"
              type="number"
              fullWidth
              value={generateForm.fiscalYear}
              onChange={(e) => setGenerateForm((f) => ({ ...f, fiscalYear: Number(e.target.value) }))}
            />
            <TextField
              label="Días Otorgados"
              type="number"
              fullWidth
              value={generateForm.daysGranted}
              onChange={(e) => setGenerateForm((f) => ({ ...f, daysGranted: Number(e.target.value) }))}
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setGenerateOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleGenerate} disabled={generateMutation.isPending}>
            Generar
          </Button>
        </DialogActions>
      </Dialog>

      {/* Summary Dialog */}
      <Dialog open={summaryId != null} onClose={() => setSummaryId(null)} maxWidth="md" fullWidth>
        <DialogTitle>Resumen de Utilidades</DialogTitle>
        <DialogContent>
          {summary.isLoading ? (
            <CircularProgress />
          ) : (
            <Box>
              <Stack direction="row" spacing={3} mb={2}>
                <Typography variant="body2">
                  <strong>Año:</strong> {summary.data?.fiscalYear}
                </Typography>
                <Typography variant="body2">
                  <strong>Total:</strong> {formatCurrency(summary.data?.totalAmount ?? 0)}
                </Typography>
                <Typography variant="body2">
                  <strong>Empleados:</strong> {summary.data?.totalEmployees ?? summaryRows.length}
                </Typography>
              </Stack>
              <ZenttoDataGrid
                rows={summaryRows.map((r: Record<string, unknown>, i: number) => ({ ...r, _id: i }))}
                columns={summaryColumns}
                autoHeight
                getRowId={(r) => r._id}
                disableRowSelectionOnClick
                pageSizeOptions={[25, 50]}
                hideToolbar
                mobileDetailDrawer={false}
                density="compact"
                mobileVisibleFields={['employeeName', 'amount']}
              />
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setSummaryId(null)}>Cerrar</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
