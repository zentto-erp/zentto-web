"use client";

import React from "react";
import { Box, Card, CardActionArea, CardContent, Typography } from "@mui/material";
import { useRouter } from "next/navigation";
import { brandColors } from "../theme";

export interface DashboardShortcutCardProps {
  title: string;
  description: string;
  icon: React.ReactNode;
  href: string;
  color?: string;
  index?: number;
}

const PALETTE = [
  brandColors.shortcutDark,
  brandColors.shortcutTeal,
  brandColors.shortcutViolet,
  brandColors.statRed,
];

export default function DashboardShortcutCard({
  title,
  description,
  icon,
  href,
  color,
  index = 0,
}: DashboardShortcutCardProps) {
  const router = useRouter();
  const bg = color ?? PALETTE[index % PALETTE.length];

  return (
    <Card
      elevation={0}
      sx={(t) => ({
        borderRadius: 2,
        overflow: "hidden",
        bgcolor: "background.paper",
        backgroundImage: "none",
        border: `1px solid ${t.palette.divider}`,
        boxShadow: "none",
        height: "100%",
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
      <CardActionArea
        onClick={() => router.push(href)}
        sx={{ height: "100%", display: "flex", flexDirection: "column", alignItems: "stretch" }}
      >
        <Box
          sx={(t) => ({
            bgcolor: bg,
            backgroundImage:
              t.palette.mode === "dark"
                ? "linear-gradient(rgba(255,255,255,0.05), rgba(255,255,255,0.05))"
                : "none",
            color: "white",
            display: "flex",
            justifyContent: "center",
            alignItems: "center",
            height: 60,
            "& .MuiSvgIcon-root": { fontSize: 26 },
          })}
        >
          {icon}
        </Box>
        <CardContent
          sx={{
            textAlign: "center",
            py: 1.5,
            flex: 1,
            minHeight: 80,
            display: "flex",
            flexDirection: "column",
            justifyContent: "center",
          }}
        >
          <Typography
            sx={{
              fontWeight: 700,
              color: "text.primary",
              mb: 0,
              fontSize: "0.95rem",
              display: "-webkit-box",
              WebkitLineClamp: 2,
              WebkitBoxOrient: "vertical",
              overflow: "hidden",
              lineHeight: 1.3,
            }}
          >
            {title}
          </Typography>
          <Typography
            color="text.secondary"
            sx={{
              textTransform: "uppercase",
              fontWeight: 600,
              fontSize: "0.68rem",
              letterSpacing: 0.8,
            }}
          >
            {description}
          </Typography>
        </CardContent>
      </CardActionArea>
    </Card>
  );
}
