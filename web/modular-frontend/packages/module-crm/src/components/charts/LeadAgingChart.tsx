"use client";

import React from "react";
import { Alert, Box, Typography, Stack, Chip } from "@mui/material";
import { BarChart } from "@mui/x-charts/BarChart";

interface LeadAgingRow {
  Bucket: string;
  BucketOrder: number;
  LeadCount: number;
  Percentage: number;
  TotalValue: number;
}

interface Props {
  data: LeadAgingRow[];
}

const BUCKET_COLORS: Record<string, string> = {
  "0-7 dias": "#4caf50",
  "8-14 dias": "#ffeb3b",
  "15-30 dias": "#ff9800",
  "31-60 dias": "#f44336",
  "60+ dias": "#b71c1c",
};

function getBucketColor(bucket: string): string {
  for (const [key, color] of Object.entries(BUCKET_COLORS)) {
    if (bucket.toLowerCase().includes(key.replace(" dias", "").replace("+", ""))) {
      return color;
    }
  }
  // Fallback by order
  return "#9e9e9e";
}

export default function LeadAgingChart({ data }: Props) {
  if (!data || data.length === 0) {
    return <Alert severity="info">Sin datos de aging de leads</Alert>;
  }

  const sorted = [...data].sort((a, b) => a.BucketOrder - b.BucketOrder);
  const buckets = sorted.map((d) => d.Bucket);
  const counts = sorted.map((d) => d.LeadCount);
  const colors = sorted.map((d) => getBucketColor(d.Bucket));

  return (
    <Box>
      <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 600 }}>
        Aging de leads abiertos
      </Typography>

      <Stack direction="row" spacing={1} sx={{ mb: 2 }} flexWrap="wrap">
        {sorted.map((d) => (
          <Chip
            key={d.Bucket}
            label={`${d.Bucket}: ${d.LeadCount} (${Number(d.Percentage ?? 0).toFixed(1)}%)`}
            size="small"
            sx={{
              bgcolor: getBucketColor(d.Bucket),
              color: ["#ffeb3b", "#4caf50"].includes(getBucketColor(d.Bucket))
                ? "#000"
                : "#fff",
              fontWeight: 600,
            }}
          />
        ))}
      </Stack>

      <Box sx={{ width: "100%", height: 350 }}>
        <BarChart
          height={330}
          layout="horizontal"
          yAxis={[{ data: buckets, scaleType: "band" }]}
          xAxis={[{ label: "Cantidad de leads" }]}
          series={[
            {
              data: counts,
              label: "Leads",
              color: "#1976d2",
              valueFormatter: (v) => `${v} leads`,
            },
          ]}
          colors={colors}
        />
      </Box>
    </Box>
  );
}
