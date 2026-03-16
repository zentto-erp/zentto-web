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
  Card,
  CardContent,
  MenuItem,
  Select,
  FormControl,
  InputLabel,
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import CalculateIcon from "@mui/icons-material/Calculate";
import { formatCurrency } from "@zentto/shared-api";
import {
  useTrustList,
  useCalculateTrust,
  useTrustSummary,
  type TrustFilter,
} from "../hooks/useRRHH";

export default function FideicomisoPage() {
  const currentYear = new Date().getFullYear();
  const [filter, setFilter] = useState<TrustFilter>({ year: currentYear, page: 1, limit: 25 });
  const [calcOpen, setCalcOpen] = useState(false);
  const [calcForm, setCalcForm] = useState({ year: currentYear, quarter: 1 });

  const { data, isLoading } = useTrustList(filter);
  const calculateMutation = useCalculateTrust();
  const summaryQuery = useTrustSummary(filter.year ?? null, filter.quarter ?? null);

  const rows = data?.data ?? data?.rows ?? [];
  const summaryData = summaryQuery.data;

  const columns: GridColDef[] = [
    { field: "employeeCode", headerName: "Código", width: 100 },
    { field: "employeeName", headerName: "Empleado", flex: 1, minWidth: 200 },
    { field: "quarter", headerName: "Trimestre", width: 100 },
    {
      field: "deposit",
      headerName: "Depósito",
      width: 130,
      renderCell: (p) => formatCurrency(p.value ?? 0),
    },
    {
      field: "interest",
      headerName: "Intereses",
      width: 130,
      renderCell: (p) => formatCurrency(p.value ?? 0),
    },
    {
      field: "balance",
      headerName: "Saldo",
      width: 130,
      renderCell: (p) => formatCurrency(p.value ?? 0),
    },
  ];

  const handleCalculate = async () => {
    await calculateMutation.mutateAsync(calcForm);
    setCalcOpen(false);
  };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h6">Fideicomiso</Typography>
        <Button variant="contained" startIcon={<CalculateIcon />} onClick={() => setCalcOpen(true)}>
          Calcular Trimestre
        </Button>
      </Stack>

      {/* Summary Cards */}
      <Stack direction="row" spacing={2} mb={2}>
        <Card sx={{ minWidth: 180 }}>
          <CardContent>
            <Typography variant="caption" color="text.secondary">Saldo Total</Typography>
            <Typography variant="h6">{formatCurrency(summaryData?.totalBalance ?? 0)}</Typography>
          </CardContent>
        </Card>
        <Card sx={{ minWidth: 180 }}>
          <CardContent>
            <Typography variant="caption" color="text.secondary">Total Intereses</Typography>
            <Typography variant="h6">{formatCurrency(summaryData?.totalInterest ?? 0)}</Typography>
          </CardContent>
        </Card>
        <Card sx={{ minWidth: 180 }}>
          <CardContent>
            <Typography variant="caption" color="text.secondary">Empleados</Typography>
            <Typography variant="h6">{summaryData?.employeeCount ?? 0}</Typography>
          </CardContent>
        </Card>
      </Stack>

      {/* Filters */}
      <Stack direction="row" spacing={2} mb={2}>
        <TextField
          label="Año"
          type="number"
          size="small"
          value={filter.year || ""}
          onChange={(e) => setFilter((f) => ({ ...f, year: Number(e.target.value) || undefined }))}
        />
        <FormControl size="small" sx={{ minWidth: 140 }}>
          <InputLabel>Trimestre</InputLabel>
          <Select
            value={filter.quarter || ""}
            label="Trimestre"
            onChange={(e) => setFilter((f) => ({ ...f, quarter: Number(e.target.value) || undefined }))}
          >
            <MenuItem value="">Todos</MenuItem>
            <MenuItem value={1}>Q1</MenuItem>
            <MenuItem value={2}>Q2</MenuItem>
            <MenuItem value={3}>Q3</MenuItem>
            <MenuItem value={4}>Q4</MenuItem>
          </Select>
        </FormControl>
      </Stack>

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", border: "1px solid #E5E7EB" }}>
        <DataGrid
          rows={rows}
          columns={columns}
          loading={isLoading}
          pageSizeOptions={[25, 50]}
          disableRowSelectionOnClick
          getRowId={(r) => r.id ?? `${r.employeeCode}-${r.quarter}`}
        />
      </Paper>

      {/* Calculate Dialog */}
      <Dialog open={calcOpen} onClose={() => setCalcOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Calcular Fideicomiso Trimestral</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <TextField
              label="Año"
              type="number"
              fullWidth
              value={calcForm.year}
              onChange={(e) => setCalcForm((f) => ({ ...f, year: Number(e.target.value) }))}
            />
            <FormControl fullWidth>
              <InputLabel>Trimestre</InputLabel>
              <Select
                value={calcForm.quarter}
                label="Trimestre"
                onChange={(e) => setCalcForm((f) => ({ ...f, quarter: Number(e.target.value) }))}
              >
                <MenuItem value={1}>Q1 (Ene-Mar)</MenuItem>
                <MenuItem value={2}>Q2 (Abr-Jun)</MenuItem>
                <MenuItem value={3}>Q3 (Jul-Sep)</MenuItem>
                <MenuItem value={4}>Q4 (Oct-Dic)</MenuItem>
              </Select>
            </FormControl>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCalcOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleCalculate} disabled={calculateMutation.isPending}>
            Calcular
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
