"use client";

import React, { useState, useEffect, useRef } from "react";
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
import { ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import type { ColumnDef } from "@zentto/datagrid-core";
import CalculateIcon from "@mui/icons-material/Calculate";
import { formatCurrency } from "@zentto/shared-api";
import {
  useTrustList,
  useCalculateTrust,
  useTrustSummary,
  type TrustFilter,
} from "../hooks/useRRHH";

const COLUMNS: ColumnDef[] = [
  { field: "employeeCode", header: "Código", width: 100, sortable: true },
  { field: "employeeName", header: "Empleado", flex: 1, minWidth: 200, sortable: true },
  { field: "quarter", header: "Trimestre", width: 100, sortable: true },
  { field: "deposit", header: "Depósito", width: 130, type: "number", aggregation: "sum" },
  { field: "interest", header: "Intereses", width: 130, type: "number", aggregation: "sum" },
  { field: "balance", header: "Saldo", width: 130, type: "number", aggregation: "sum" },
];

const FIDEICOMISO_FILTERS: FilterFieldDef[] = [
  {
    field: "quarter", label: "Trimestre", type: "select",
    options: [
      { value: "1", label: "Q1" },
      { value: "2", label: "Q2" },
      { value: "3", label: "Q3" },
      { value: "4", label: "Q4" },
    ],
  },
];

export default function FideicomisoPage() {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const currentYear = new Date().getFullYear();
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const [filter, setFilter] = useState<TrustFilter>({ year: currentYear, page: 1, limit: 25 });
  const [calcOpen, setCalcOpen] = useState(false);
  const [calcForm, setCalcForm] = useState({ year: currentYear, quarter: 1 });

  const { data, isLoading } = useTrustList(filter);
  const calculateMutation = useCalculateTrust();
  const summaryQuery = useTrustSummary(filter.year ?? null, filter.quarter ?? null);

  const rows = data?.data ?? data?.rows ?? [];
  const summaryData = summaryQuery.data;

  useEffect(() => {
    import("@zentto/datagrid").then(() => setRegistered(true));
  }, []);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows;
    el.loading = isLoading;
    el.getRowId = (r: any) => r.id ?? `${r.employeeCode}-${r.quarter}`;
  }, [rows, isLoading, registered]);

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
      <ZenttoFilterPanel
        filters={FIDEICOMISO_FILTERS}
        values={filterValues}
        onChange={(v) => {
          setFilterValues(v);
          setFilter((f) => ({ ...f, quarter: v.quarter ? Number(v.quarter) : undefined }));
        }}
        searchPlaceholder="Buscar empleados..."
        searchValue={search}
        onSearchChange={setSearch}
      />

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", border: "1px solid #E5E7EB" }}>
        <zentto-grid
          ref={gridRef}
          height="100%"
          show-totals
          enable-toolbar
          enable-header-menu
          enable-header-filters
          enable-clipboard
          enable-quick-search
          enable-context-menu
          enable-status-bar
          enable-configurator
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

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
