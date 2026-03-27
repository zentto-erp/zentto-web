"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box,
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

import type { ColumnDef } from "@zentto/datagrid-core";
import CalculateIcon from "@mui/icons-material/Calculate";
import { formatCurrency, useGridLayoutSync } from "@zentto/shared-api";

import {
  useTrustList,
  useCalculateTrust,
  useTrustSummary,
  type TrustFilter,
} from "../hooks/useRRHH";
import { buildNominaGridId, useNominaGridId, useNominaGridRegistration } from "./zenttoGridPersistence";

const COLUMNS: ColumnDef[] = [
  { field: "employeeCode", header: "Código", width: 100, sortable: true },
  { field: "employeeName", header: "Empleado", flex: 1, minWidth: 200, sortable: true },
  { field: "quarter", header: "Trimestre", width: 100, sortable: true },
  { field: "deposit", header: "Depósito", width: 130, type: "number", aggregation: "sum" },
  { field: "interest", header: "Intereses", width: 130, type: "number", aggregation: "sum" },
  { field: "balance", header: "Saldo", width: 130, type: "number", aggregation: "sum" },
  {
    field: "actions", header: "Acciones", type: "actions", width: 100, pin: "right",
    actions: [
      { icon: "view", label: "Ver", action: "view", color: "#1976d2" },
      { icon: "edit", label: "Editar", action: "edit", color: "#ed6c02" },
    ],
  },
];

const GRID_ID = buildNominaGridId("fideicomiso");


export default function FideicomisoPage() {
  const gridRef = useRef<any>(null);
  const currentYear = new Date().getFullYear();
  const [filter, setFilter] = useState<TrustFilter>({ year: currentYear, page: 1, limit: 25 });
  const [calcOpen, setCalcOpen] = useState(false);
  const [calcForm, setCalcForm] = useState({ year: currentYear, quarter: 1 });

  const { data, isLoading } = useTrustList(filter);
  const calculateMutation = useCalculateTrust();
  const summaryQuery = useTrustSummary(filter.year ?? null, filter.quarter ?? null);
  const { ready: layoutReady } = useGridLayoutSync(GRID_ID);
  useNominaGridId(gridRef, GRID_ID);
  const { registered } = useNominaGridRegistration(layoutReady);

  const rows = data?.data ?? data?.rows ?? [];
  const summaryData = summaryQuery.data;

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows;
    el.loading = isLoading;
    el.getRowId = (r: any) => r.id ?? `${r.employeeCode}-${r.quarter}`;
  }, [rows, isLoading, registered]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "view") {
        console.log("Ver fideicomiso:", row);
      } else if (action === "edit") {
        console.log("Editar fideicomiso:", row);
      }
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered]);

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

      <Box sx={{ flex: 1, minHeight: 0 }}>
        <zentto-grid
          ref={gridRef}
          height="calc(100vh - 200px)"
          show-totals
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
