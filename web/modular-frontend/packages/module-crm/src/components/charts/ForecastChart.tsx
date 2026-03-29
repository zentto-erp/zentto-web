"use client";

import React from "react";
import { Alert, Box } from "@mui/material";
import { BarChart } from "@mui/x-charts/BarChart";
import { formatCurrency } from "@zentto/shared-api";

interface ForecastRow {
  Month: string;
  WeightedValue: number;
  TotalValue: number;
  LeadCount: number;
}

interface Props {
  data: ForecastRow[];
}

export default function ForecastChart({ data }: Props) {
  if (!data || data.length === 0) {
    return <Alert severity="info">Sin datos de forecast</Alert>;
  }

  return (
    <Box sx={{ width: "100%", height: 380 }}>
      <BarChart
        height={360}
        xAxis={[{ data: data.map((d) => d.Month), scaleType: "band" }]}
        yAxis={[{ valueFormatter: (v: number) => formatCurrency(v) }]}
        series={[
          {
            data: data.map((d) => d.WeightedValue),
            label: "Ponderado",
            color: "#1976d2",
            valueFormatter: (v) => formatCurrency(v ?? 0),
          },
          {
            data: data.map((d) => d.TotalValue),
            label: "Total",
            color: "rgba(158,158,158,0.3)",
            valueFormatter: (v) => formatCurrency(v ?? 0),
          },
        ]}
      />
    </Box>
  );
}
