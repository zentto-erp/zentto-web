"use client";

import React from "react";
import { Box, Paper, Typography } from "@mui/material";

export interface DashboardSectionProps {
  title?: string;
  headerAction?: React.ReactNode;
  children: React.ReactNode;
  padded?: boolean;
  fullHeight?: boolean;
}

export default function DashboardSection({
  title,
  headerAction,
  children,
  padded = true,
  fullHeight = true,
}: DashboardSectionProps) {
  return (
    <Paper
      elevation={0}
      sx={(t) => ({
        ...(fullHeight ? { height: "100%" } : {}),
        borderRadius: 2,
        overflow: "hidden",
        display: "flex",
        flexDirection: "column",
        border: `1px solid ${t.palette.divider}`,
        backgroundImage: "none",
      })}
    >
      {title && (
        <Box
          sx={(t) => ({
            px: 2,
            py: 2,
            borderBottom: `1px solid ${t.palette.divider}`,
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            gap: 2,
            flexShrink: 0,
          })}
        >
          <Typography variant="h6" fontWeight={600}>
            {title}
          </Typography>
          {headerAction}
        </Box>
      )}
      <Box sx={{ flex: 1, p: padded ? 3 : 0, minHeight: 0, overflow: "auto" }}>
        {children}
      </Box>
    </Paper>
  );
}
