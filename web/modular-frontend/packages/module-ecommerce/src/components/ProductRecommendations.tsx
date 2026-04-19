"use client";

import { Box, Typography, Paper, Skeleton, Chip, Stack } from "@mui/material";
import { useProductRecommendations } from "../hooks/useStoreSearch";
import { useCartStore } from "../store/useCartStore";
import { formatPrice } from "../utils/formatCurrency";
import ReviewStars from "./ReviewStars";

interface Props {
  productCode: string;
  title?: string;
  limit?: number;
  onProductClick?: (code: string) => void;
}

export default function ProductRecommendations({
  productCode, title = "También te puede interesar", limit = 8, onProductClick,
}: Props) {
  const { data, isLoading } = useProductRecommendations(productCode, limit);
  const currency = useCartStore((s) => s.currency);

  if (isLoading) {
    return (
      <Box sx={{ my: 3 }}>
        <Typography variant="h6" fontWeight={700} sx={{ mb: 2 }}>{title}</Typography>
        <Stack direction="row" spacing={1.5} sx={{ overflowX: "auto" }}>
          {Array.from({ length: 4 }).map((_, i) => (
            <Skeleton key={i} variant="rectangular" width={180} height={240} sx={{ borderRadius: 2, flexShrink: 0 }} />
          ))}
        </Stack>
      </Box>
    );
  }

  if (!data || data.length === 0) return null;

  return (
    <Box sx={{ my: 3 }}>
      <Typography variant="h6" fontWeight={700} sx={{ mb: 2 }}>
        {title}
      </Typography>
      <Box
        sx={{
          display: "flex",
          gap: 1.5,
          overflowX: "auto",
          pb: 1,
          "&::-webkit-scrollbar": { display: "none" },
          msOverflowStyle: "none",
          scrollbarWidth: "none",
        }}
      >
        {data.map((item) => (
          <Paper
            key={item.code}
            elevation={0}
            onClick={() => onProductClick?.(item.code)}
            sx={{
              flex: "0 0 auto",
              width: 200,
              p: 1.5,
              border: "1px solid #e3e6e6",
              borderRadius: 2,
              cursor: "pointer",
              transition: "all 0.15s ease",
              "&:hover": { boxShadow: "0 4px 12px rgba(0,0,0,0.12)", transform: "translateY(-2px)" },
            }}
          >
            <Box
              component="img"
              src={item.imageUrl}
              alt={item.name}
              sx={{ width: "100%", height: 140, objectFit: "contain", borderRadius: 1, bgcolor: "#fafafa", mb: 1 }}
            />
            <Typography variant="body2" sx={{ fontSize: 13, lineHeight: 1.3, display: "-webkit-box", WebkitLineClamp: 2, WebkitBoxOrient: "vertical", overflow: "hidden", mb: 0.5, minHeight: 34 }}>
              {item.name}
            </Typography>
            {item.avgRating > 0 && (
              <Box sx={{ mb: 0.5 }}>
                <ReviewStars rating={item.avgRating} count={item.reviewCount} size="small" />
              </Box>
            )}
            <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <Typography variant="body2" fontWeight={700} sx={{ color: "#0f1111" }}>
                {formatPrice(item.price, currency)}
              </Typography>
              {item.matchScore >= 3 && (
                <Chip size="small" color="success" label="Match" sx={{ height: 18, fontSize: 10 }} />
              )}
            </Box>
          </Paper>
        ))}
      </Box>
    </Box>
  );
}
