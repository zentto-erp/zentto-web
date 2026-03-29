"use client";

import React from "react";
import { Alert, Box, Typography } from "@mui/material";
import Grid from "@mui/material/Grid2";
import { BarChart } from "@mui/x-charts/BarChart";
import { PieChart } from "@mui/x-charts/PieChart";

interface PeriodRow {
  Period: string;
  WonCount: number;
  LostCount: number;
  WinRate: number;
}

interface SourceRow {
  Source: string;
  WonCount: number;
  LostCount: number;
  WinRate: number;
}

interface Props {
  byPeriod: PeriodRow[];
  bySource: SourceRow[];
}

export default function WinLossChart({ byPeriod, bySource }: Props) {
  const hasPeriod = byPeriod && byPeriod.length > 0;
  const hasSource = bySource && bySource.length > 0;

  if (!hasPeriod && !hasSource) {
    return <Alert severity="info">Sin datos de ganados/perdidos</Alert>;
  }

  const pieData = hasSource
    ? bySource.map((s, idx) => ({
        id: idx,
        value: s.WonCount + s.LostCount,
        label: s.Source || "Sin fuente",
      }))
    : [];

  return (
    <Grid container spacing={3}>
      {hasPeriod && (
        <Grid size={{ xs: 12, md: hasSource ? 7 : 12 }}>
          <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 600 }}>
            Ganados vs Perdidos por periodo
          </Typography>
          <Box sx={{ width: "100%", height: 320 }}>
            <BarChart
              height={300}
              xAxis={[
                {
                  data: byPeriod.map((d) => d.Period),
                  scaleType: "band",
                },
              ]}
              series={[
                {
                  data: byPeriod.map((d) => d.WonCount),
                  label: "Ganados",
                  color: "#4caf50",
                },
                {
                  data: byPeriod.map((d) => d.LostCount),
                  label: "Perdidos",
                  color: "#f44336",
                },
              ]}
            />
          </Box>
        </Grid>
      )}

      {hasSource && (
        <Grid size={{ xs: 12, md: hasPeriod ? 5 : 12 }}>
          <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 600 }}>
            Distribución por fuente
          </Typography>
          <Box sx={{ width: "100%", height: 320 }}>
            <PieChart
              height={300}
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
      )}
    </Grid>
  );
}
