"use client";

import React from "react";
import {
  Box,
  Paper,
  Typography,
  Alert,
  Button,
  List,
  ListItem,
  ListItemText,
  Chip,
  CircularProgress,
} from "@mui/material";
import WarningAmberIcon from "@mui/icons-material/WarningAmber";
import PlayArrowIcon from "@mui/icons-material/PlayArrow";
import OpenInNewIcon from "@mui/icons-material/OpenInNew";
import { useRouter } from "next/navigation";
import { useStaleLeads, useEvaluateRules } from "../hooks/useCRMAutomation";

interface StaleLeadsAlertProps {
  pipelineId?: number;
  days?: number;
  maxDisplay?: number;
}

export function StaleLeadsAlert({
  pipelineId,
  days = 7,
  maxDisplay = 5,
}: StaleLeadsAlertProps) {
  const router = useRouter();
  const { data: staleRaw, isLoading } = useStaleLeads(days, pipelineId);
  const evaluateMutation = useEvaluateRules();

  const staleLeads = React.useMemo(() => {
    if (!staleRaw) return [];
    return Array.isArray(staleRaw) ? staleRaw : (staleRaw as any)?.data ?? [];
  }, [staleRaw]);

  // No renderizar si no hay leads estancados o cargando
  if (isLoading || staleLeads.length === 0) return null;

  const displayed = staleLeads.slice(0, maxDisplay);
  const remaining = staleLeads.length - displayed.length;

  return (
    <Paper
      sx={{
        mb: 3,
        borderRadius: 2,
        overflow: "hidden",
        border: "1px solid",
        borderColor: "warning.light",
      }}
    >
      <Alert
        severity="warning"
        icon={<WarningAmberIcon />}
        sx={{
          borderRadius: 0,
          "& .MuiAlert-message": { width: "100%" },
        }}
        action={
          <Box sx={{ display: "flex", gap: 1, flexShrink: 0 }}>
            <Button
              size="small"
              variant="outlined"
              color="warning"
              startIcon={
                evaluateMutation.isPending ? (
                  <CircularProgress size={14} color="inherit" />
                ) : (
                  <PlayArrowIcon />
                )
              }
              onClick={() => evaluateMutation.mutate()}
              disabled={evaluateMutation.isPending}
            >
              Evaluar reglas
            </Button>
            <Button
              size="small"
              variant="text"
              color="warning"
              endIcon={<OpenInNewIcon sx={{ fontSize: 14 }} />}
              onClick={() => router.push("/leads?status=OPEN")}
            >
              Ver todos
            </Button>
          </Box>
        }
      >
        <Typography variant="subtitle2" sx={{ fontWeight: 700 }}>
          {staleLeads.length} lead{staleLeads.length !== 1 ? "s" : ""} estancado
          {staleLeads.length !== 1 ? "s" : ""} (sin actividad en {days}+ dias)
        </Typography>
      </Alert>

      <List dense sx={{ py: 0 }}>
        {displayed.map((lead: any) => (
          <ListItem
            key={lead.LeadId}
            sx={{
              borderBottom: "1px solid",
              borderColor: "divider",
              "&:last-child": { borderBottom: "none" },
              py: 0.75,
            }}
          >
            <ListItemText
              primary={
                <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                  <Typography
                    variant="body2"
                    sx={{ fontWeight: 600, fontFamily: "monospace" }}
                  >
                    {lead.LeadCode}
                  </Typography>
                  <Typography variant="body2">{lead.ContactName}</Typography>
                </Box>
              }
              secondary={lead.StageName}
            />
            <Chip
              label={`${lead.DaysSinceLastActivity}d`}
              size="small"
              color="warning"
              variant="outlined"
              sx={{ ml: 1, fontWeight: 600 }}
            />
          </ListItem>
        ))}
      </List>

      {remaining > 0 && (
        <Box sx={{ px: 2, py: 1, bgcolor: "action.hover" }}>
          <Typography variant="caption" color="text.secondary">
            y {remaining} mas...
          </Typography>
        </Box>
      )}
    </Paper>
  );
}
