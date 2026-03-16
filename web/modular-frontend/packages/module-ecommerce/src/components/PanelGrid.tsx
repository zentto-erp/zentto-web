"use client";

import { Box, Paper, Typography, Grid } from "@mui/material";

interface PanelProduct {
  code: string;
  name: string;
  price: number;
  imageUrl?: string | null;
}

interface PanelGridProps {
  title: string;
  products: PanelProduct[];
  actionLabel?: string;
  onAction?: () => void;
  onViewProduct: (code: string) => void;
}

export default function PanelGrid({ title, products, actionLabel, onAction, onViewProduct }: PanelGridProps) {
  const items = products.slice(0, 4);
  if (items.length === 0) return null;

  return (
    <Paper
      elevation={0}
      sx={{
        p: 2.5,
        height: "100%",
        minHeight: 380,
        display: "flex",
        flexDirection: "column",
        border: "1px solid #e3e6e6",
        borderRadius: "8px",
        bgcolor: "#fff",
      }}
    >
      <Typography variant="h6" sx={{ fontWeight: 700, color: "#0f1111", mb: 2, fontSize: 18, lineHeight: 1.3 }}>
        {title}
      </Typography>

      <Grid container spacing={1.5} sx={{ flex: 1 }}>
        {items.map((p) => (
          <Grid key={p.code} xs={6}>
            <Box
              onClick={() => onViewProduct(p.code)}
              sx={{
                cursor: "pointer",
                borderRadius: "4px",
                overflow: "hidden",
                transition: "opacity 0.2s",
                "&:hover": { opacity: 0.85 },
              }}
            >
              <Box
                sx={{
                  width: "100%",
                  aspectRatio: "1",
                  bgcolor: "#f7f7f7",
                  borderRadius: "4px",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  overflow: "hidden",
                  mb: 0.5,
                }}
              >
                <Box
                  component="img"
                  src={p.imageUrl || "/placeholder-product.png"}
                  alt={p.name}
                  sx={{ maxWidth: "90%", maxHeight: "90%", objectFit: "contain" }}
                  onError={(e: any) => {
                    e.target.src =
                      "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='120' height='120'%3E%3Crect fill='%23f0f0f0' width='120' height='120'/%3E%3Ctext fill='%23999' x='50%25' y='50%25' text-anchor='middle' dy='.3em' font-size='12'%3ESin imagen%3C/text%3E%3C/svg%3E";
                  }}
                />
              </Box>
              <Typography
                variant="caption"
                sx={{
                  color: "#0f1111",
                  display: "-webkit-box",
                  WebkitLineClamp: 2,
                  WebkitBoxOrient: "vertical",
                  overflow: "hidden",
                  lineHeight: 1.3,
                  fontSize: 12,
                }}
              >
                {p.name}
              </Typography>
              <Typography variant="caption" sx={{ color: "#b12704", fontWeight: 600, fontSize: 12 }}>
                ${p.price.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
              </Typography>
            </Box>
          </Grid>
        ))}
      </Grid>

      {actionLabel && onAction && (
        <Typography
          onClick={onAction}
          variant="body2"
          sx={{
            color: "#007185",
            cursor: "pointer",
            mt: 1.5,
            fontSize: 13,
            "&:hover": { color: "#c45500", textDecoration: "underline" },
          }}
        >
          {actionLabel}
        </Typography>
      )}
    </Paper>
  );
}
