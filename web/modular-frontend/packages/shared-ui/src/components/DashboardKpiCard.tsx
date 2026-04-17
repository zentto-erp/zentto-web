"use client";

import React from "react";
import { Box, Card, CardContent, Chip, Skeleton, Typography } from "@mui/material";
import { alpha } from "@mui/material/styles";
import TrendingUpIcon from "@mui/icons-material/TrendingUp";
import TrendingDownIcon from "@mui/icons-material/TrendingDown";

export interface DashboardKpiCardProps {
  title: string;
  value: string | number;
  color: string;
  icon?: React.ReactNode;
  subtitle?: string;
  trend?: { value: number; positive: boolean } | null;
  change?: number | null;
  loading?: boolean;
  isPercent?: boolean;
  footer?: React.ReactNode;
}

export default function DashboardKpiCard({
  title,
  value,
  color,
  icon,
  subtitle,
  trend,
  change,
  loading,
  isPercent,
  footer,
}: DashboardKpiCardProps) {
  const displayValue =
    typeof value === "number" && isPercent
      ? `${value.toFixed(1)}%`
      : String(value);

  return (
    <Card
      elevation={0}
      sx={(t) => ({
        height: "100%",
        borderRadius: 2,
        border: `1px solid ${t.palette.divider}`,
        transition: "transform 0.2s, box-shadow 0.2s, border-color 0.2s",
        "&:hover": {
          transform: "translateY(-2px)",
          boxShadow: t.palette.mode === "dark"
            ? "0 4px 20px rgba(0,0,0,0.25)"
            : "0 4px 20px rgba(0,0,0,0.08)",
          borderColor: t.palette.mode === "dark" ? "rgba(255,255,255,0.2)" : t.palette.divider,
        },
      })}
    >
      <CardContent sx={{ p: 2.5, "&:last-child": { pb: 2.5 } }}>
        <Typography
          variant="body2"
          color="text.secondary"
          sx={{
            fontWeight: 500,
            fontSize: "0.8rem",
            mb: 1,
            display: "-webkit-box",
            WebkitLineClamp: 2,
            WebkitBoxOrient: "vertical",
            overflow: "hidden",
            lineHeight: 1.3,
          }}
        >
          {title}
        </Typography>
        {loading ? (
          <Skeleton variant="text" width={100} sx={{ fontSize: "1.8rem" }} />
        ) : (
          <Typography variant="h5" sx={{ fontWeight: 700, lineHeight: 1.2, mb: 0.5 }}>
            {displayValue}
          </Typography>
        )}
        {!loading && (trend || subtitle || (change !== undefined && change !== null)) && (
          <Box sx={{ display: "flex", alignItems: "center", gap: 0.5, flexWrap: "wrap" }}>
            {trend && trend.value > 0 && (
              <Chip
                size="small"
                icon={
                  trend.positive ? (
                    <TrendingUpIcon sx={{ fontSize: 14 }} />
                  ) : (
                    <TrendingDownIcon sx={{ fontSize: 14 }} />
                  )
                }
                label={`${trend.value}%`}
                sx={{
                  height: 22,
                  fontSize: "0.7rem",
                  fontWeight: 600,
                  bgcolor: alpha(trend.positive ? "#4caf50" : "#f44336", 0.1),
                  color: trend.positive ? "#2e7d32" : "#d32f2f",
                  "& .MuiChip-icon": { color: "inherit" },
                }}
              />
            )}
            {change !== undefined && change !== null && (
              <Chip
                size="small"
                icon={
                  change >= 0 ? (
                    <TrendingUpIcon sx={{ fontSize: 14 }} />
                  ) : (
                    <TrendingDownIcon sx={{ fontSize: 14 }} />
                  )
                }
                label={`${change >= 0 ? "+" : ""}${change.toFixed(1)}%`}
                sx={{
                  height: 22,
                  fontSize: "0.7rem",
                  fontWeight: 600,
                  bgcolor: alpha(change >= 0 ? "#4caf50" : "#f44336", 0.1),
                  color: change >= 0 ? "#2e7d32" : "#d32f2f",
                  "& .MuiChip-icon": { color: "inherit" },
                }}
              />
            )}
            {subtitle && (
              <Typography variant="caption" color="text.secondary">
                {subtitle}
              </Typography>
            )}
          </Box>
        )}
        {footer && <Box sx={{ mt: 1.5 }}>{footer}</Box>}
      </CardContent>
    </Card>
  );
}
