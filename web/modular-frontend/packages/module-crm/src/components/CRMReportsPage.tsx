"use client";

import React, { useState } from "react";
import {
  Box,
  Paper,
  Tabs,
  Tab,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Stack,
  Skeleton,
  ToggleButtonGroup,
  ToggleButton,
} from "@mui/material";
import AssessmentIcon from "@mui/icons-material/Assessment";
import HourglassTopIcon from "@mui/icons-material/HourglassTop";
import CompareArrowsIcon from "@mui/icons-material/CompareArrows";
import EmojiEventsIcon from "@mui/icons-material/EmojiEvents";
import { usePipelinesList } from "../hooks/useCRM";
import {
  useSalesByPeriod,
  useLeadAging,
  useConversionBySource,
  useTopPerformers,
} from "../hooks/useCRMReports";
import { SalesByPeriodChart } from "./charts";
import { LeadAgingChart } from "./charts";
import { ConversionBySourceChart } from "./charts";
import { TopPerformersChart } from "./charts";

/* ─── Tab panel helper ──────────────────────────────────────── */

function TabPanel({ children, value, index }: { children: React.ReactNode; value: number; index: number }) {
  return value === index ? <Box sx={{ pt: 2 }}>{children}</Box> : null;
}

/* ─── Loading skeleton ──────────────────────────────────────── */

function ChartSkeleton() {
  return (
    <Box>
      <Skeleton variant="rectangular" height={350} sx={{ borderRadius: 2 }} />
    </Box>
  );
}

/* ─── Main Component ────────────────────────────────────────── */

export default function CRMReportsPage() {
  const [tab, setTab] = useState(0);
  const [pipelineId, setPipelineId] = useState<number | undefined>();
  const [groupBy, setGroupBy] = useState<string>("month");

  // Pipeline selector
  const { data: pipelinesData } = usePipelinesList();
  const pipelines = (pipelinesData as any)?.data ?? (pipelinesData as any)?.rows ?? pipelinesData ?? [];

  // Data hooks
  const { data: salesRaw, isLoading: salesLoading } = useSalesByPeriod(pipelineId, groupBy);
  const salesData = (salesRaw as any)?.data ?? (salesRaw as any)?.rows ?? salesRaw ?? [];

  const { data: agingRaw, isLoading: agingLoading } = useLeadAging(pipelineId);
  const agingData = (agingRaw as any)?.data ?? (agingRaw as any)?.rows ?? agingRaw ?? [];

  const { data: conversionRaw, isLoading: conversionLoading } = useConversionBySource(pipelineId);
  const conversionData = (conversionRaw as any)?.data ?? (conversionRaw as any)?.rows ?? conversionRaw ?? [];

  const { data: performersRaw, isLoading: performersLoading } = useTopPerformers(pipelineId);
  const performersData = (performersRaw as any)?.data ?? (performersRaw as any)?.rows ?? performersRaw ?? [];

  return (
    <Box>
      {/* ── Filtros globales ─────────────────────────────────────── */}
      <Paper sx={{ p: 2, mb: 2, borderRadius: 2 }}>
        <Stack direction="row" spacing={2} alignItems="center" flexWrap="wrap">
          <FormControl sx={{ minWidth: 180 }}>
            <InputLabel>Pipeline</InputLabel>
            <Select
              value={pipelineId ?? ""}
              label="Pipeline"
              onChange={(e) =>
                setPipelineId(e.target.value ? Number(e.target.value) : undefined)
              }
            >
              <MenuItem value="">Todos</MenuItem>
              {Array.isArray(pipelines) &&
                pipelines.map((p: any) => (
                  <MenuItem key={p.PipelineId} value={p.PipelineId}>
                    {p.Name}
                  </MenuItem>
                ))}
            </Select>
          </FormControl>

          {tab === 0 && (
            <ToggleButtonGroup
              value={groupBy}
              exclusive
              onChange={(_, v) => v && setGroupBy(v)}
              size="small"
            >
              <ToggleButton value="day">Dia</ToggleButton>
              <ToggleButton value="week">Semana</ToggleButton>
              <ToggleButton value="month">Mes</ToggleButton>
            </ToggleButtonGroup>
          )}
        </Stack>
      </Paper>

      {/* ── Tabs ─────────────────────────────────────────────────── */}
      <Paper sx={{ borderRadius: 2 }}>
        <Tabs
          value={tab}
          onChange={(_, v) => setTab(v)}
          variant="scrollable"
          scrollButtons="auto"
        >
          <Tab icon={<AssessmentIcon />} iconPosition="start" label="Ventas" />
          <Tab icon={<HourglassTopIcon />} iconPosition="start" label="Aging" />
          <Tab icon={<CompareArrowsIcon />} iconPosition="start" label="Conversion" />
          <Tab icon={<EmojiEventsIcon />} iconPosition="start" label="Top Performers" />
        </Tabs>

        <Box sx={{ p: 2 }}>
          <TabPanel value={tab} index={0}>
            {salesLoading ? <ChartSkeleton /> : <SalesByPeriodChart data={salesData} />}
          </TabPanel>

          <TabPanel value={tab} index={1}>
            {agingLoading ? <ChartSkeleton /> : <LeadAgingChart data={agingData} />}
          </TabPanel>

          <TabPanel value={tab} index={2}>
            {conversionLoading ? <ChartSkeleton /> : <ConversionBySourceChart data={conversionData} />}
          </TabPanel>

          <TabPanel value={tab} index={3}>
            {performersLoading ? <ChartSkeleton /> : <TopPerformersChart data={performersData} />}
          </TabPanel>
        </Box>
      </Paper>
    </Box>
  );
}
