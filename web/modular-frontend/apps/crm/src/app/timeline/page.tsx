"use client";

import { useState } from "react";
import {
  Box,
  Typography,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  ToggleButtonGroup,
  ToggleButton,
  Paper,
  Stack,
} from "@mui/material";
import { LeadTimeline } from "@zentto/module-crm";
import { useLeadTimeline, usePipelinesList } from "@zentto/module-crm";

export default function TimelinePage() {
  const [pipelineId, setPipelineId] = useState<number | undefined>();
  const [status, setStatus] = useState<string>("all");

  const { data: pipelinesData } = usePipelinesList();
  const pipelines = pipelinesData?.data ?? pipelinesData?.rows ?? pipelinesData ?? [];

  const { data, isLoading } = useLeadTimeline(
    pipelineId,
    status === "all" ? undefined : status,
  );
  const leads = (data as any)?.data ?? (data as any)?.rows ?? data ?? [];

  return (
    <Box>
      <Typography variant="h5" fontWeight={700} sx={{ mb: 2 }}>
        Timeline de Leads
      </Typography>

      <Paper sx={{ p: 2, mb: 2, borderRadius: 2 }}>
        <Stack direction="row" spacing={2} alignItems="center" flexWrap="wrap">
          <FormControl sx={{ minWidth: 160 }}>
            <InputLabel>Pipeline</InputLabel>
            <Select
              value={pipelineId ?? ""}
              label="Pipeline"
              onChange={(e) =>
                setPipelineId(e.target.value ? Number(e.target.value) : undefined)
              }
            >
              <MenuItem value="">Todos</MenuItem>
              {pipelines.map((p: any) => (
                <MenuItem key={p.PipelineId} value={p.PipelineId}>
                  {p.Name}
                </MenuItem>
              ))}
            </Select>
          </FormControl>

          <ToggleButtonGroup
            value={status}
            exclusive
            onChange={(_, v) => v && setStatus(v)}
            size="small"
          >
            <ToggleButton value="all">Todos</ToggleButton>
            <ToggleButton value="OPEN">Abiertos</ToggleButton>
            <ToggleButton value="WON">Ganados</ToggleButton>
            <ToggleButton value="LOST">Perdidos</ToggleButton>
          </ToggleButtonGroup>
        </Stack>
      </Paper>

      <Paper sx={{ p: 2, borderRadius: 2 }}>
        {isLoading ? (
          <Typography variant="body2" color="text.secondary" sx={{ textAlign: "center", py: 4 }}>
            Cargando timeline...
          </Typography>
        ) : (
          <LeadTimeline leads={leads} />
        )}
      </Paper>
    </Box>
  );
}
