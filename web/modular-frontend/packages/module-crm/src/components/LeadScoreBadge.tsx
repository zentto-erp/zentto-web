"use client";

import React from "react";
import { Box, CircularProgress, Typography } from "@mui/material";

interface LeadScoreBadgeProps {
  score: number;
  size?: "small" | "medium" | "large";
}

const sizeMap = {
  small: { circle: 36, font: "0.65rem", thickness: 4 },
  medium: { circle: 52, font: "0.85rem", thickness: 4.5 },
  large: { circle: 72, font: "1.1rem", thickness: 5 },
} as const;

function getScoreColor(score: number): string {
  if (score < 30) return "#ef5350"; // rojo
  if (score < 60) return "#ff9800"; // naranja
  return "#4caf50"; // verde
}

export function LeadScoreBadge({ score, size = "medium" }: LeadScoreBadgeProps) {
  const s = sizeMap[size];
  const color = getScoreColor(score);
  const clampedScore = Math.min(100, Math.max(0, score));

  return (
    <Box sx={{ position: "relative", display: "inline-flex", width: s.circle, height: s.circle }}>
      {/* Background track */}
      <CircularProgress
        variant="determinate"
        value={100}
        size={s.circle}
        thickness={s.thickness}
        sx={{ color: "action.disabledBackground", position: "absolute" }}
      />
      {/* Score arc */}
      <CircularProgress
        variant="determinate"
        value={clampedScore}
        size={s.circle}
        thickness={s.thickness}
        sx={{ color }}
      />
      {/* Centered number */}
      <Box
        sx={{
          top: 0,
          left: 0,
          bottom: 0,
          right: 0,
          position: "absolute",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <Typography
          variant="caption"
          component="span"
          sx={{ fontWeight: 700, fontSize: s.font, color }}
        >
          {Math.round(clampedScore)}
        </Typography>
      </Box>
    </Box>
  );
}

export default LeadScoreBadge;
