"use client";

import { Box, Typography } from "@mui/material";
import StarIcon from "@mui/icons-material/Star";
import StarHalfIcon from "@mui/icons-material/StarHalf";
import StarOutlineIcon from "@mui/icons-material/StarOutline";

interface Props {
  rating: number;
  count?: number;
  size?: "small" | "medium";
  showCount?: boolean;
}

export default function ReviewStars({ rating, count, size = "small", showCount = true }: Props) {
  const sz = size === "small" ? 16 : 20;
  const stars: React.ReactNode[] = [];
  const r = Math.round(rating * 2) / 2;
  for (let i = 1; i <= 5; i++) {
    if (i <= r) stars.push(<StarIcon key={i} sx={{ fontSize: sz, color: "#f5a623" }} />);
    else if (i - 0.5 === r) stars.push(<StarHalfIcon key={i} sx={{ fontSize: sz, color: "#f5a623" }} />);
    else stars.push(<StarOutlineIcon key={i} sx={{ fontSize: sz, color: "#f5a623" }} />);
  }

  return (
    <Box sx={{ display: "inline-flex", alignItems: "center", gap: 0.3 }}>
      {stars}
      {showCount && count != null && (
        <Typography variant="caption" sx={{ color: "#007185", ml: 0.3, fontSize: size === "small" ? 12 : 14 }}>
          ({count.toLocaleString()})
        </Typography>
      )}
    </Box>
  );
}
