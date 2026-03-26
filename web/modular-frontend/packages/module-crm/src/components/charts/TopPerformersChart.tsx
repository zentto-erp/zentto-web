"use client";

import React from "react";
import { Alert, Box, Typography, Stack, Chip } from "@mui/material";
import { BarChart } from "@mui/x-charts/BarChart";

interface TopPerformerRow {
  UserId: number;
  UserName: string;
  WonCount: number;
  TotalDeals: number;
  WinRate: number;
  Revenue: number;
  AvgDealSize: number;
}

interface Props {
  data: TopPerformerRow[];
}

export default function TopPerformersChart({ data }: Props) {
  if (!data || data.length === 0) {
    return <Alert severity="info">Sin datos de rendimiento de vendedores</Alert>;
  }

  const sorted = [...data].sort((a, b) => b.Revenue - a.Revenue);
  const names = sorted.map((d) => d.UserName);
  const revenues = sorted.map((d) => d.Revenue);

  return (
    <Box>
      <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 600 }}>
        Top vendedores por ingreso
      </Typography>

      <Stack direction="row" spacing={1} sx={{ mb: 2 }} flexWrap="wrap">
        {sorted.slice(0, 10).map((d) => (
          <Chip
            key={d.UserId}
            label={`${d.UserName}: ${Number(d.WinRate ?? 0).toFixed(0)}% win`}
            size="small"
            color={d.WinRate >= 50 ? "success" : d.WinRate >= 30 ? "warning" : "error"}
            variant="outlined"
            sx={{ fontWeight: 600 }}
          />
        ))}
      </Stack>

      <Box sx={{ width: "100%", height: Math.max(300, sorted.length * 45) }}>
        <BarChart
          height={Math.max(280, sorted.length * 45)}
          layout="horizontal"
          yAxis={[{ data: names, scaleType: "band" }]}
          xAxis={[{ label: "Ingreso ($)" }]}
          series={[
            {
              data: revenues,
              label: "Ingreso",
              color: "#1976d2",
              valueFormatter: (v) =>
                `$${(v ?? 0).toLocaleString("es-VE", { minimumFractionDigits: 2 })}`,
            },
          ]}
        />
      </Box>
    </Box>
  );
}
