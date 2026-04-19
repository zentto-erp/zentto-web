"use client";

import { Box, Typography, Button, Paper, IconButton } from "@mui/material";
import ShoppingCartIcon from "@mui/icons-material/ShoppingCart";
import LocalShippingIcon from "@mui/icons-material/LocalShipping";
import FavoriteBorderIcon from "@mui/icons-material/FavoriteBorder";
import FavoriteIcon from "@mui/icons-material/Favorite";
import { useCartStore } from "../store/useCartStore";
import { useFavoritesStore } from "../store/useFavoritesStore";
import ReviewStars from "./ReviewStars";
import { formatPrice } from "../utils/formatCurrency";

interface Props {
  code: string;
  name: string;
  fullDescription?: string;
  category?: string;
  brand?: string;
  price: number;
  originalPrice?: number;
  stock: number;
  taxRate: number;
  imageUrl?: string | null;
  avgRating?: number;
  reviewCount?: number;
  onViewDetail?: (code: string) => void;
}

export default function ProductCard({
  code, name, fullDescription, category, brand, price, originalPrice, stock, taxRate, imageUrl, avgRating, reviewCount, onViewDetail,
}: Props) {
  const addItem = useCartStore((s) => s.addItem);
  const currency = useCartStore((s) => s.currency);
  const toggleFavorite = useFavoritesStore((s) => s.toggleFavorite);
  const isFav = useFavoritesStore((s) => s.isFavorite(code));

  const handleFav = (e: React.MouseEvent) => {
    e.stopPropagation();
    toggleFavorite({ productCode: code, productName: name, price, imageUrl: imageUrl ?? null });
  };

  const handleAdd = (e: React.MouseEvent) => {
    e.stopPropagation();
    addItem({
      productCode: code,
      productName: name,
      quantity: 1,
      unitPrice: price,
      taxRate: taxRate > 1 ? taxRate / 100 : taxRate,
      imageUrl: imageUrl ?? null,
    });
  };

  const discount = originalPrice && originalPrice > price
    ? Math.round(((originalPrice - price) / originalPrice) * 100)
    : null;

  return (
    <Paper
      elevation={0}
      onClick={() => onViewDetail?.(code)}
      sx={{
        height: "100%",
        display: "flex",
        flexDirection: "column",
        cursor: "pointer",
        border: "1px solid #e3e6e6",
        borderRadius: "8px",
        overflow: "hidden",
        transition: "all 0.2s ease",
        bgcolor: "#fff",
        "&:hover": {
          boxShadow: "0 4px 12px rgba(0,0,0,0.15)",
          transform: "translateY(-2px)",
        },
      }}
    >
      {/* Image */}
      <Box
        sx={{
          position: "relative",
          height: 220,
          bgcolor: "#f7f7f7",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          overflow: "hidden",
          p: 2,
        }}
      >
        {discount && (
          <Box
            sx={{
              position: "absolute",
              top: 8,
              left: 8,
              bgcolor: "#cc0c39",
              color: "#fff",
              px: 1,
              py: 0.3,
              borderRadius: "4px",
              fontSize: 12,
              fontWeight: "bold",
              zIndex: 1,
            }}
          >
            -{discount}%
          </Box>
        )}
        <IconButton
          onClick={handleFav}
          size="small"
          sx={{
            position: "absolute",
            top: 6,
            right: 6,
            zIndex: 1,
            bgcolor: "rgba(255,255,255,0.85)",
            "&:hover": { bgcolor: "#fff" },
          }}
        >
          {isFav ? <FavoriteIcon sx={{ fontSize: 20, color: "#cc0c39" }} /> : <FavoriteBorderIcon sx={{ fontSize: 20, color: "#565959" }} />}
        </IconButton>
        <Box
          component="img"
          src={imageUrl || "/placeholder-product.png"}
          alt={name}
          sx={{
            maxWidth: "100%",
            maxHeight: "100%",
            objectFit: "contain",
            transition: "transform 0.3s ease",
            "&:hover": { transform: "scale(1.08)" },
          }}
          onError={(e: any) => { e.target.src = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='200' height='200'%3E%3Crect fill='%23f0f0f0' width='200' height='200'/%3E%3Ctext fill='%23999' x='50%25' y='50%25' text-anchor='middle' dy='.3em' font-size='14'%3ESin imagen%3C/text%3E%3C/svg%3E"; }}
        />
      </Box>

      {/* Content */}
      <Box sx={{ p: 1.5, flexGrow: 1, display: "flex", flexDirection: "column" }}>
        {/* Title */}
        <Typography
          variant="body2"
          sx={{
            fontWeight: 400,
            color: "#0f1111",
            display: "-webkit-box",
            WebkitLineClamp: 2,
            WebkitBoxOrient: "vertical",
            overflow: "hidden",
            lineHeight: 1.35,
            mb: 0.5,
            fontSize: 14,
            "&:hover": { color: "#c45500" },
          }}
        >
          {fullDescription || name}
        </Typography>

        {/* Brand */}
        {brand && (
          <Typography variant="caption" sx={{ color: "#565959", fontSize: 11, mb: 0.3 }}>
            {brand}
          </Typography>
        )}

        {/* Rating */}
        {avgRating != null && avgRating > 0 && (
          <Box sx={{ mb: 0.3 }}>
            <ReviewStars rating={avgRating} count={reviewCount} size="small" />
          </Box>
        )}

        {/* Price (display currency aware) */}
        <Box sx={{ mt: "auto", pt: 0.5 }}>
          <Typography sx={{ fontSize: 22, fontWeight: 500, color: "#0f1111", lineHeight: 1 }}>
            {formatPrice(price, currency)}
          </Typography>
          {originalPrice && originalPrice > price && (
            <Typography variant="caption" sx={{ color: "#565959", textDecoration: "line-through", fontSize: 12 }}>
              {formatPrice(originalPrice, currency)}
            </Typography>
          )}
        </Box>

        {/* Shipping */}
        {price >= 25 && (
          <Box sx={{ display: "flex", alignItems: "center", gap: 0.3, mt: 0.3 }}>
            <LocalShippingIcon sx={{ fontSize: 14, color: "#067D62" }} />
            <Typography variant="caption" sx={{ color: "#067D62", fontSize: 11 }}>
              Envio gratis
            </Typography>
          </Box>
        )}

        {/* Stock */}
        <Typography
          variant="caption"
          sx={{
            color: stock > 10 ? "#067D62" : stock > 0 ? "#b12704" : "#cc0c39",
            fontSize: 11,
            mt: 0.3,
          }}
        >
          {stock > 10 ? "En stock" : stock > 0 ? `Solo quedan ${stock}` : "Agotado"}
        </Typography>
      </Box>

      {/* Add to cart button */}
      <Box sx={{ px: 1.5, pb: 1.5 }}>
        <Button
          size="small"
          variant="contained"
          startIcon={<ShoppingCartIcon sx={{ fontSize: 16 }} />}
          onClick={handleAdd}
          disabled={stock <= 0}
          fullWidth
          sx={{
            bgcolor: "#ffd814",
            color: "#0f1111",
            fontWeight: 500,
            fontSize: 13,
            textTransform: "none",
            borderRadius: "20px",
            boxShadow: "none",
            border: "1px solid #fcd200",
            "&:hover": { bgcolor: "#f7ca00", boxShadow: "none" },
            "&:disabled": { bgcolor: "#e3e6e6", color: "#999" },
          }}
        >
          Agregar
        </Button>
      </Box>
    </Paper>
  );
}
