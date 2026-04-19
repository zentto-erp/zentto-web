"use client";

import React from "react";
import { Chip } from "@mui/material";
import PhoneIcon from "@mui/icons-material/Phone";
import EmailIcon from "@mui/icons-material/Email";
import PeopleIcon from "@mui/icons-material/People";
import NoteIcon from "@mui/icons-material/Note";
import TaskIcon from "@mui/icons-material/Task";
import {
  ACTIVITY_TYPE_COLORS,
  ACTIVITY_TYPE_LABELS,
  isActivityType,
  type ActivityType,
} from "../../types";

/**
 * Chip visual para tipos de actividad CRM (CALL/EMAIL/MEETING/NOTE/TASK).
 *
 * ChipType consistente con `LeadActivityTimeline` — mismos colores/labels,
 * centralizados en `types.ts` para evitar drift.
 */
export interface ActivityTypeChipProps {
  /** Tipo crudo (puede venir del backend). Si no es válido → renderiza chip default. */
  type: string | ActivityType | null | undefined;
  /** Tamaño del chip (default "small"). */
  size?: "small" | "medium";
  /** Variante visual (default "outlined"). */
  variant?: "filled" | "outlined";
}

const iconMap: Record<ActivityType, React.ReactNode> = {
  CALL: <PhoneIcon sx={{ fontSize: 14 }} />,
  EMAIL: <EmailIcon sx={{ fontSize: 14 }} />,
  MEETING: <PeopleIcon sx={{ fontSize: 14 }} />,
  NOTE: <NoteIcon sx={{ fontSize: 14 }} />,
  TASK: <TaskIcon sx={{ fontSize: 14 }} />,
};

export function ActivityTypeChip({ type, size = "small", variant = "outlined" }: ActivityTypeChipProps) {
  if (!isActivityType(type)) {
    return <Chip label={String(type ?? "—")} size={size} variant={variant} />;
  }
  return (
    <Chip
      icon={iconMap[type] as React.ReactElement}
      label={ACTIVITY_TYPE_LABELS[type]}
      size={size}
      color={ACTIVITY_TYPE_COLORS[type]}
      variant={variant}
    />
  );
}

export default ActivityTypeChip;
