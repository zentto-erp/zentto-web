"use client";

import React from "react";
import { Alert, Box, Typography } from "@mui/material";
import Grid from "@mui/material/Grid2";
import { BarChart } from "@mui/x-charts/BarChart";
import { PieChart } from "@mui/x-charts/PieChart";

interface ConversionBySourceRow {
  Source: string;
  TotalLeads: number;
  WonCount: number;
  LostCount: number;
  OpenCount: number;
  ConversionRate: number;
  TotalValue: number;
  WonValue: number;
}

interface Props {
  data: ConversionBySourceRow[];
}

export default function ConversionBySourceChart({ data }: Props) {
  if (!data || data.length === 0) {
    return <Alert severity="info">Sin datos de conversion por fuente</Alert>;
  }

  const sources = data.map((d) => d.Source || "Sin fuente");
  const wonCounts = data.map((d) => d.WonCount);
  const lostCounts = data.map((d) => d.LostCount);

  const pieData = data.map((d, idx) => ({
    id: idx,
    value: d.TotalLeads,
    label: d.Source || "Sin fuente",
  }));

  return (
    <Grid container spacing={3}>
      <Grid size={{ xs: 12, md: 7 }}>
        <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 600 }}>
          Ganados vs Perdidos por fuente
        </Typography>
        <Box sx={{ width: "100%", height: 350 }}>
          <BarChart
            height={330}
            xAxis={[{ data: sources, scaleType: "band", label: "Fuente" }]}
            yAxis={[{ label: "Cantidad" }]}
            series={[
              {
                data: wonCounts,
                label: "Ganados",
                color: "#4caf50",
              },
              {
                data: lostCounts,
                label: "Perdidos",
                color: "#f44336",
              },
            ]}
          />
        </Box>
      </Grid>

      <Grid size={{ xs: 12, md: 5 }}>
        <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 600 }}>
          Distribucion de leads por fuente
        </Typography>
        <Box sx={{ width: "100%", height: 350 }}>
          <PieChart
            height={330}
            series={[
              {
                data: pieData,
                highlightScope: { fade: "global", highlight: "item" },
                innerRadius: 30,
                paddingAngle: 2,
                cornerRadius: 4,
              },
            ]}
          />
        </Box>
      </Grid>
    </Grid>
  );
}
