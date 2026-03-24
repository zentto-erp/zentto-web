"use client";

import React from "react";
import { Alert, Box } from "@mui/material";
import { BarChart } from "@mui/x-charts/BarChart";
import { formatCurrency } from "@zentto/shared-api";

interface FunnelRow {
  StageName: string;
  LeadCount: number;
  TotalValue: number;
  Color: string;
  ConversionToNext: number;
  StageOrder?: number;
}

interface Props {
  data: FunnelRow[];
}

export default function FunnelChart({ data }: Props) {
  if (!data || data.length === 0) {
    return <Alert severity="info">Sin datos del embudo</Alert>;
  }

  const sorted = [...data].sort(
    (a, b) => (a.StageOrder ?? 0) - (b.StageOrder ?? 0),
  );

  return (
    <Box sx={{ width: "100%", height: 380 }}>
      <BarChart
        height={360}
        layout="horizontal"
        yAxis={[
          {
            data: sorted.map((d) => d.StageName),
            scaleType: "band",
          },
        ]}
        xAxis={[
          {
            valueFormatter: (v: number) => formatCurrency(v),
          },
        ]}
        series={[
          {
            data: sorted.map((d) => d.TotalValue),
            label: "Valor",
            valueFormatter: (v, ctx) => {
              const idx = ctx.dataIndex;
              const row = sorted[idx];
              if (!row) return formatCurrency(v ?? 0);
              return `${row.LeadCount} leads — ${formatCurrency(row.TotalValue)} — ${row.ConversionToNext.toFixed(0)}%`;
            },
            color: "#1976d2",
          },
        ]}
        colors={sorted.map((d) => d.Color || "#1976d2")}
      />
    </Box>
  );
}
