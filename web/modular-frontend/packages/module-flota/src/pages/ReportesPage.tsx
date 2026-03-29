"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box,
  Card,
  CardContent,
  MenuItem,
  TextField,
  Typography,
  CircularProgress,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import { formatCurrency, useGridLayoutSync } from "@zentto/shared-api";
import { useFuelMonthlyReport } from "../hooks/useFlota";
import type { ColumnDef } from "@zentto/datagrid-core";

const MONTHS = [
  { value: 1, label: "Enero" },
  { value: 2, label: "Febrero" },
  { value: 3, label: "Marzo" },
  { value: 4, label: "Abril" },
  { value: 5, label: "Mayo" },
  { value: 6, label: "Junio" },
  { value: 7, label: "Julio" },
  { value: 8, label: "Agosto" },
  { value: 9, label: "Septiembre" },
  { value: 10, label: "Octubre" },
  { value: 11, label: "Noviembre" },
  { value: 12, label: "Diciembre" },
];

const currentYear = new Date().getFullYear();
const YEARS = Array.from({ length: 5 }, (_, i) => currentYear - i);
const GRID_ID = "module-flota:reportes:fuel-monthly";

const columns: ColumnDef[] = [
  { field: "LicensePlate", header: "Placa", flex: 1, minWidth: 100 },
  { field: "Brand", header: "Marca", flex: 1, minWidth: 100, mobileHide: true },
  { field: "Model", header: "Modelo", flex: 1, minWidth: 100, mobileHide: true },
  {
    field: "TotalLiters",
    header: "Total Litros",
    flex: 1,
    minWidth: 120,
    type: "number",
    aggregation: "sum",
    renderCell: (value: unknown) => Number(value ?? 0).toFixed(2),
  },
  {
    field: "TotalCost",
    header: "Costo Total",
    flex: 1,
    minWidth: 130,
    type: "number",
    aggregation: "sum",
    renderCell: (value: unknown) => formatCurrency(Number(value ?? 0)),
  },
  {
    field: "AvgCostPerLiter",
    header: "Costo/Litro Prom.",
    flex: 1,
    minWidth: 140,
    type: "number",
    aggregation: "avg",
    renderCell: (value: unknown) => formatCurrency(Number(value ?? 0)),
  },
];

export default function ReportesPage() {
  const [year, setYear] = useState(currentYear);
  const [month, setMonth] = useState(new Date().getMonth() + 1);
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const { ready: layoutReady } = useGridLayoutSync(GRID_ID);

  useEffect(() => {
    if (!layoutReady) return;
    import("@zentto/datagrid").then(() => setRegistered(true));
  }, [layoutReady]);

  const { data, isLoading } = useFuelMonthlyReport(year, month);

  const rows = (data?.rows ?? []).map((r, idx) => ({ id: r.VehicleId ?? idx, ...r }));

  // Bind data to zentto-grid web component

  useEffect(() => {

    const el = gridRef.current;

    if (!el || !registered) return;

    el.columns = columns;

    el.rows = rows;

    el.loading = isLoading;

  }, [rows, isLoading, registered, columns]);


  return (
    <Box>
      <Typography variant="h5" sx={{ mb: 3, fontWeight: 700, color: "text.primary" }}>
        Reportes de Flota
      </Typography>

      {/* Filtros */}
      <Card sx={{ mb: 3, borderRadius: 2 }}>
        <CardContent>
          <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>
            Consumo de Combustible Mensual
          </Typography>
          <Grid container spacing={2}>
            <Grid size={{ xs: 6, sm: 3 }}>
              <TextField
                select
                fullWidth
                size="small"
                label="Anio"
                value={year}
                onChange={(e) => setYear(Number(e.target.value))}
              >
                {YEARS.map((y) => (
                  <MenuItem key={y} value={y}>{y}</MenuItem>
                ))}
              </TextField>
            </Grid>
            <Grid size={{ xs: 6, sm: 3 }}>
              <TextField
                select
                fullWidth
                size="small"
                label="Mes"
                value={month}
                onChange={(e) => setMonth(Number(e.target.value))}
              >
                {MONTHS.map((m) => (
                  <MenuItem key={m.value} value={m.value}>{m.label}</MenuItem>
                ))}
              </TextField>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      {/* Grid de resultados */}
      <Card sx={{ borderRadius: 2 }}>
        <CardContent>
          <zentto-grid
        ref={gridRef}
        grid-id={GRID_ID}
        export-filename="flota-reportes-list"
        height="400px"
        enable-toolbar
        enable-header-menu
        enable-header-filters
        enable-clipboard
        enable-quick-search
        enable-context-menu
        enable-status-bar
        enable-configurator
      ></zentto-grid>
        </CardContent>
      </Card>
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
