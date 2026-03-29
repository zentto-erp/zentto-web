"use client";

import React, { useMemo } from "react";
import { Box, Typography, Chip, alpha, useTheme } from "@mui/material";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import type { Activity } from "../hooks/useCRM";
import type { HistoryEntry } from "../hooks/useCRMScoring";

interface LeadActivityTimelineProps {
  activities: Activity[];
  history: HistoryEntry[];
  onComplete?: (activityId: number) => void;
}

/* ─── Helpers ──────────────────────────────────────────────── */

interface TimelineItem {
  id: string;
  type: "activity" | "history";
  date: string;
  activityType?: string;
  changeType?: string;
  subject: string;
  description: string;
  fromStage?: string | null;
  toStage?: string | null;
  fromStageColor?: string | null;
  toStageColor?: string | null;
  isCompleted?: boolean;
  isOverdue?: boolean;
  activityId?: number;
  createdBy?: string;
}

const typeIcons: Record<string, string> = {
  CALL: "\u260E\uFE0F",      // phone
  EMAIL: "\u2709\uFE0F",     // email
  MEETING: "\uD83E\uDD1D",   // handshake
  NOTE: "\uD83D\uDCDD",      // note
  TASK: "\u2705",             // task
  STAGE_CHANGE: "\uD83D\uDD04", // stage change
};

function getIcon(item: TimelineItem): string {
  if (item.type === "history") return typeIcons.STAGE_CHANGE;
  return typeIcons[item.activityType ?? ""] ?? "\uD83D\uDCCB";
}

function getTypeLabel(item: TimelineItem): string {
  if (item.type === "history") {
    if (item.changeType === "STAGE_CHANGE") return "Cambio de etapa";
    return item.changeType ?? "Historial";
  }
  const map: Record<string, string> = {
    CALL: "Llamada",
    EMAIL: "Email",
    MEETING: "Reunión",
    NOTE: "Nota",
    TASK: "Tarea",
  };
  return map[item.activityType ?? ""] ?? item.activityType ?? "Actividad";
}

function formatDateShort(d: string): string {
  try {
    const dt = new Date(d);
    return dt.toLocaleDateString("es", { day: "2-digit", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit" });
  } catch {
    return d;
  }
}

export function LeadActivityTimeline({ activities, history, onComplete }: LeadActivityTimelineProps) {
  const theme = useTheme();
  const now = new Date();

  const items = useMemo<TimelineItem[]>(() => {
    const actItems: TimelineItem[] = (activities ?? []).map((a) => ({
      id: `act-${a.ActivityId}`,
      type: "activity" as const,
      date: a.DueDate ?? a.CreatedAt,
      activityType: a.ActivityType,
      subject: a.Subject,
      description: a.Description ?? "",
      isCompleted: a.IsCompleted,
      isOverdue: !a.IsCompleted && a.DueDate ? new Date(a.DueDate) < now : false,
      activityId: a.ActivityId,
    }));

    const histItems: TimelineItem[] = (history ?? []).map((h) => ({
      id: `hist-${h.HistoryId}`,
      type: "history" as const,
      date: h.CreatedAt,
      changeType: h.ChangeType,
      subject: h.ChangeType === "STAGE_CHANGE"
        ? `De ${h.FromStage ?? "?"} \u2192 ${h.ToStage ?? "?"}`
        : h.Description,
      description: h.Description ?? "",
      fromStage: h.FromStage,
      toStage: h.ToStage,
      fromStageColor: h.FromStageColor,
      toStageColor: h.ToStageColor,
      createdBy: h.CreatedBy,
    }));

    return [...actItems, ...histItems].sort(
      (a, b) => new Date(b.date).getTime() - new Date(a.date).getTime(),
    );
  }, [activities, history]);

  if (!items.length) {
    return (
      <Typography variant="body2" color="text.secondary" sx={{ py: 2, textAlign: "center" }}>
        Sin actividades ni historial
      </Typography>
    );
  }

  return (
    <Box sx={{ position: "relative", pl: 4 }}>
      {/* Vertical line */}
      <Box
        sx={{
          position: "absolute",
          left: 14,
          top: 8,
          bottom: 8,
          width: 2,
          bgcolor: "divider",
          borderRadius: 1,
        }}
      />

      {items.map((item) => {
        const icon = getIcon(item);
        const isStageChange = item.type === "history" && item.changeType === "STAGE_CHANGE";

        return (
          <Box
            key={item.id}
            sx={{
              position: "relative",
              mb: 2,
              p: 1.5,
              borderRadius: 1.5,
              border: `1px solid ${item.isOverdue ? theme.palette.error.main : theme.palette.divider}`,
              bgcolor: item.isOverdue
                ? alpha(theme.palette.error.main, 0.04)
                : "background.paper",
              "&:hover": { bgcolor: alpha(theme.palette.primary.main, 0.03) },
            }}
          >
            {/* Icon circle */}
            <Box
              sx={{
                position: "absolute",
                left: -30,
                top: 12,
                width: 28,
                height: 28,
                borderRadius: "50%",
                bgcolor: "background.paper",
                border: `2px solid ${theme.palette.divider}`,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                fontSize: 14,
                zIndex: 1,
              }}
            >
              {icon}
            </Box>

            {/* Content */}
            <Box sx={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", gap: 1 }}>
              <Box sx={{ flex: 1, minWidth: 0 }}>
                <Typography
                  variant="body2"
                  fontWeight={600}
                  sx={{
                    textDecoration: item.isCompleted ? "line-through" : "none",
                    opacity: item.isCompleted ? 0.7 : 1,
                  }}
                >
                  {item.subject}
                  {item.isCompleted && (
                    <CheckCircleIcon sx={{ ml: 0.5, fontSize: 14, color: "success.main", verticalAlign: "middle" }} />
                  )}
                </Typography>

                {isStageChange && item.fromStage && item.toStage && (
                  <Box sx={{ display: "flex", alignItems: "center", gap: 0.5, mt: 0.5 }}>
                    <Chip
                      label={item.fromStage}
                      size="small"
                      sx={{
                        bgcolor: item.fromStageColor ? alpha(item.fromStageColor, 0.15) : undefined,
                        color: item.fromStageColor ?? undefined,
                        fontWeight: 600,
                        height: 22,
                      }}
                    />
                    <Typography variant="caption" color="text.secondary">{"\u2192"}</Typography>
                    <Chip
                      label={item.toStage}
                      size="small"
                      sx={{
                        bgcolor: item.toStageColor ? alpha(item.toStageColor, 0.15) : undefined,
                        color: item.toStageColor ?? undefined,
                        fontWeight: 600,
                        height: 22,
                      }}
                    />
                  </Box>
                )}

                {!isStageChange && item.description && (
                  <Typography variant="caption" color="text.secondary" sx={{ display: "block", mt: 0.3 }}>
                    {item.description}
                  </Typography>
                )}

                <Typography variant="caption" color="text.secondary" sx={{ mt: 0.5, display: "block" }}>
                  {formatDateShort(item.date)}
                  {item.createdBy && ` \u2014 ${item.createdBy}`}
                </Typography>
              </Box>

              <Box sx={{ display: "flex", alignItems: "center", gap: 0.5, flexShrink: 0 }}>
                <Chip label={getTypeLabel(item)} size="small" variant="outlined" sx={{ height: 22, fontSize: "0.7rem" }} />
                {item.isOverdue && (
                  <Chip label="Vencida" size="small" color="error" sx={{ height: 22, fontSize: "0.7rem" }} />
                )}
                {item.type === "activity" && !item.isCompleted && onComplete && item.activityId && (
                  <Chip
                    label="Completar"
                    size="small"
                    color="primary"
                    clickable
                    onClick={() => onComplete(item.activityId!)}
                    sx={{ height: 22, fontSize: "0.7rem" }}
                  />
                )}
              </Box>
            </Box>
          </Box>
        );
      })}
    </Box>
  );
}

export default LeadActivityTimeline;
