"use client";

import React, { useState } from "react";
import {
  Box,
  Card,
  CardContent,
  MenuItem,
  TextField,
  Typography,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import { ZenttoDataGrid } from "@zentto/shared-ui";
import type { ZenttoColDef } from "@zentto/shared-ui";
import { formatCurrency } from "@zentto/shared-api";
import { useFuelMonthlyReport } from "../hooks/useFlota";

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

const columns: ZenttoColDef[] = [
  { field: "LicensePlate", headerName: "Placa", flex: 1, minWidth: 100 },
  { field: "Brand", headerName: "Marca", flex: 1, minWidth: 100, mobileHide: true },
  { field: "Model", headerName: "Modelo", flex: 1, minWidth: 100, mobileHide: true },
  {
    field: "TotalLiters",
    headerName: "Total Litros",
    flex: 1,
    minWidth: 120,
    type: "number",
    aggregation: "sum",
    valueFormatter: (value: unknown) => Number(value ?? 0).toFixed(2),
  },
  {
    field: "TotalCost",
    headerName: "Costo Total",
    flex: 1,
    minWidth: 130,
    type: "number",
    aggregation: "sum",
    valueFormatter: (value: unknown) => formatCurrency(Number(value ?? 0)),
  },
  {
    field: "AvgCostPerLiter",
    headerName: "Costo/Litro Prom.",
    flex: 1,
    minWidth: 140,
    type: "number",
    aggregation: "avg",
    valueFormatter: (value: unknown) => formatCurrency(Number(value ?? 0)),
  },
];

export default function ReportesPage() {
  const [year, setYear] = useState(currentYear);
  const [month, setMonth] = useState(new Date().getMonth() + 1);
  const { data, isLoading } = useFuelMonthlyReport(year, month);

  const rows = (data?.rows ?? []).map((r, idx) => ({ id: r.VehicleId ?? idx, ...r }));

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
          <ZenttoDataGrid
            gridId="flota-reportes-list"
            rows={rows}
            columns={columns}
            loading={isLoading}
            serverRowCount={rows.length}
            autoHeight
            disableRowSelectionOnClick
          />
        </CardContent>
      </Card>
    </Box>
  );
}
