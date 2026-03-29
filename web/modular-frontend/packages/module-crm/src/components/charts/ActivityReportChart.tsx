"use client";

import React, { useMemo } from "react";
import { Alert, Box } from "@mui/material";
import { BarChart } from "@mui/x-charts/BarChart";

interface ActivityReportRow {
  AssignedToName: string;
  ActivityType: string;
  TotalCount: number;
  CompletedCount: number;
  PendingCount: number;
  OverdueCount: number;
}

interface Props {
  data: ActivityReportRow[];
}

export default function ActivityReportChart({ data }: Props) {
  if (!data || data.length === 0) {
    return <Alert severity="info">Sin datos de actividades</Alert>;
  }

  // Agrupar por vendedor (sumar todas las filas de activity types)
  const grouped = useMemo(() => {
    const map = new Map<
      string,
      { completed: number; pending: number; overdue: number }
    >();
    for (const row of data) {
      const key = row.AssignedToName || "Sin asignar";
      const prev = map.get(key) ?? { completed: 0, pending: 0, overdue: 0 };
      prev.completed += row.CompletedCount;
      prev.pending += row.PendingCount;
      prev.overdue += row.OverdueCount;
      map.set(key, prev);
    }
    return Array.from(map.entries()).map(([name, vals]) => ({
      name,
      ...vals,
    }));
  }, [data]);

  return (
    <Box sx={{ width: "100%", height: 380 }}>
      <BarChart
        height={360}
        xAxis={[
          {
            data: grouped.map((d) => d.name),
            scaleType: "band",
          },
        ]}
        series={[
          {
            data: grouped.map((d) => d.completed),
            label: "Completadas",
            color: "#4caf50",
            stack: "activities",
          },
          {
            data: grouped.map((d) => d.pending),
            label: "Pendientes",
            color: "#ff9800",
            stack: "activities",
          },
          {
            data: grouped.map((d) => d.overdue),
            label: "Vencidas",
            color: "#f44336",
            stack: "activities",
          },
        ]}
      />
    </Box>
  );
}
