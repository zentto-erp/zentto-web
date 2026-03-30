"use client";

import React from "react";
import { Alert, Box } from "@mui/material";
import { BarChart } from "@mui/x-charts/BarChart";

interface VelocityRow {
  StageName: string;
  AvgDaysInStage: number;
  MedianDaysInStage: number;
  Color: string;
}

interface Props {
  data: VelocityRow[];
}

export default function VelocityChart({ data }: Props) {
  if (!data || data.length === 0) {
    return <Alert severity="info">Sin datos de velocidad</Alert>;
  }

  return (
    <Box sx={{ width: "100%", height: 380 }}>
      <BarChart
        height={360}
        xAxis={[
          {
            data: data.map((d) => d.StageName),
            scaleType: "band",
          },
        ]}
        yAxis={[
          {
            label: "Días",
          },
        ]}
        series={[
          {
            data: data.map((d) => d.AvgDaysInStage),
            label: "Promedio",
            color: "#1976d2",
            valueFormatter: (v) => `${Number(v ?? 0).toFixed(1)} días`,
          },
          {
            data: data.map((d) => d.MedianDaysInStage),
            label: "Mediana",
            color: "#ff9800",
            valueFormatter: (v) => `${Number(v ?? 0).toFixed(1)} días`,
          },
        ]}
        colors={data.map((d) => d.Color || "#1976d2")}
      />
    </Box>
  );
}
