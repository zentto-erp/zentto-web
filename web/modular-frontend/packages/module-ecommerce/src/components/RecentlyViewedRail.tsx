"use client";

import { Box, Typography, Paper, IconButton } from "@mui/material";
import ChevronLeftIcon from "@mui/icons-material/ChevronLeft";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import { useRef } from "react";
import { useRecentlyViewed } from "../hooks/useRecentlyViewed";
import { useCartStore } from "../store/useCartStore";
import { formatPrice } from "../utils/formatCurrency";

interface Props {
  title?: string;
  limit?: number;
  onProductClick?: (productCode: string) => void;
}

export default function RecentlyViewedRail({ title = "Vistos recientemente", limit = 12, onProductClick }: Props) {
  const { data: items = [] } = useRecentlyViewed(limit);
  const currency = useCartStore((s) => s.currency);
  const railRef = useRef<HTMLDivElement>(null);

  if (!items.length) return null;

  const scroll = (dir: 1 | -1) => {
    railRef.current?.scrollBy({ left: dir * 320, behavior: "smooth" });
  };

  return (
    <Box sx={{ my: 4 }}>
      <Box sx={{ display: "flex", alignItems: "center", justifyContent: "space-between", mb: 1.5, px: { xs: 1, md: 0 } }}>
        <Typography variant="h6" fontWeight={700}>
          {title}
        </Typography>
        <Box>
          <IconButton size="small" onClick={() => scroll(-1)}><ChevronLeftIcon /></IconButton>
          <IconButton size="small" onClick={() => scroll(1)}><ChevronRightIcon /></IconButton>
        </Box>
      </Box>
      <Box
        ref={railRef}
        sx={{
          display: "flex",
          gap: 1.5,
          overflowX: "auto",
          scrollSnapType: "x mandatory",
          pb: 1,
          "&::-webkit-scrollbar": { display: "none" },
          msOverflowStyle: "none",
          scrollbarWidth: "none",
        }}
      >
        {items.map((item) => (
          <Paper
            key={item.productCode}
            elevation={0}
            onClick={() => onProductClick?.(item.productCode)}
            sx={{
              flex: "0 0 auto",
              width: 180,
              p: 1.5,
              border: "1px solid #e3e6e6",
              borderRadius: 2,
              cursor: "pointer",
              scrollSnapAlign: "start",
              transition: "all 0.15s ease",
              "&:hover": { boxShadow: "0 4px 12px rgba(0,0,0,0.12)", transform: "translateY(-2px)" },
            }}
          >
            <Box
              component="img"
              src={item.imageUrl || "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='160' height='130'%3E%3Crect fill='%23f0f0f0' width='160' height='130'/%3E%3C/svg%3E"}
              alt={item.productName}
              sx={{ width: "100%", height: 130, objectFit: "contain", borderRadius: 1, bgcolor: "#fafafa", mb: 1 }}
            />
            <Typography
              variant="body2"
              sx={{ fontSize: 13, lineHeight: 1.3, display: "-webkit-box", WebkitLineClamp: 2, WebkitBoxOrient: "vertical", overflow: "hidden", mb: 0.5, minHeight: 34 }}
            >
              {item.productName}
            </Typography>
            <Typography variant="body2" fontWeight={700} sx={{ color: "#0f1111" }}>
              {formatPrice(Number(item.price), currency)}
            </Typography>
          </Paper>
        ))}
      </Box>
    </Box>
  );
}
