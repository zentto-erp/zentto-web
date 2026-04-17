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
      sx={{
        borderRadius: 2,
        overflow: "hidden",
        boxShadow: "0 2px 4px rgba(0,0,0,0.05)",
        height: "100%",
      }}
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
            height: 80,
          })}
        >
          {icon}
        </Box>
        <CardContent
          sx={{
            textAlign: "center",
            py: 2,
            flex: 1,
            minHeight: 96,
            display: "flex",
            flexDirection: "column",
            justifyContent: "center",
          }}
        >
          <Typography
            variant="h6"
            sx={{
              fontWeight: 700,
              color: "text.primary",
              mb: 0,
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
            variant="body2"
            color="text.secondary"
            sx={{
              textTransform: "uppercase",
              fontWeight: 600,
              fontSize: "0.75rem",
              letterSpacing: 1,
            }}
          >
            {description}
          </Typography>
        </CardContent>
      </CardActionArea>
    </Card>
  );
}
