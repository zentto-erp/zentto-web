"use client";

import React from "react";
import { Alert, Box, Typography } from "@mui/material";
import { BarChart } from "@mui/x-charts/BarChart";
import { LineChart } from "@mui/x-charts/LineChart";
import Grid from "@mui/material/Grid2";

interface SalesByPeriodRow {
  Period: string;
  WonCount: number;
  WonValue: number;
  CumulativeValue: number;
  AvgDealSize: number;
}

interface Props {
  data: SalesByPeriodRow[];
}

export default function SalesByPeriodChart({ data }: Props) {
  if (!data || data.length === 0) {
    return <Alert severity="info">Sin datos de ventas para el periodo seleccionado</Alert>;
  }

  const periods = data.map((d) => d.Period);
  const wonValues = data.map((d) => d.WonValue);
  const cumulativeValues = data.map((d) => d.CumulativeValue);

  return (
    <Grid container spacing={3}>
      <Grid size={{ xs: 12, md: 7 }}>
        <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 600 }}>
          Valor de ventas cerradas por periodo
        </Typography>
        <Box sx={{ width: "100%", height: 350 }}>
          <BarChart
            height={330}
            xAxis={[{ data: periods, scaleType: "band", label: "Periodo" }]}
            yAxis={[{ label: "Valor ($)" }]}
            series={[
              {
                data: wonValues,
                label: "Valor ganado",
                color: "#4caf50",
              },
            ]}
          />
        </Box>
      </Grid>

      <Grid size={{ xs: 12, md: 5 }}>
        <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 600 }}>
          Valor acumulado
        </Typography>
        <Box sx={{ width: "100%", height: 350 }}>
          <LineChart
            height={330}
            xAxis={[{ data: periods, scaleType: "band", label: "Periodo" }]}
            yAxis={[{ label: "Acumulado ($)" }]}
            series={[
              {
                data: cumulativeValues,
                label: "Acumulado",
                color: "#1976d2",
                area: true,
              },
            ]}
          />
        </Box>
      </Grid>
    </Grid>
  );
}
