"use client";

import { Box, Typography, Divider } from "@mui/material";
import type { CartItem } from "../store/useCartStore";

interface Props {
  items: CartItem[];
  subtotal: number;
  tax: number;
  total: number;
}

export default function OrderSummary({ items, subtotal, tax, total }: Props) {
  return (
    <Box>
      {items.map((item) => (
        <Box key={item.productCode} sx={{ display: "flex", gap: 1.5, mb: 1.5, pb: 1.5, borderBottom: "1px solid #f0f0f0" }}>
          <Box
            component="img"
            src={item.imageUrl || "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='48' height='48'%3E%3Crect fill='%23f0f0f0' width='48' height='48'/%3E%3C/svg%3E"}
            alt={item.productName}
            sx={{ width: 48, height: 48, objectFit: "contain", borderRadius: "4px", border: "1px solid #e3e6e6", flexShrink: 0 }}
          />
          <Box sx={{ flexGrow: 1, minWidth: 0 }}>
            <Typography variant="body2" sx={{ fontSize: 13, display: "-webkit-box", WebkitLineClamp: 1, WebkitBoxOrient: "vertical", overflow: "hidden" }}>
              {item.productName}
            </Typography>
            <Typography variant="caption" color="text.secondary">
              {item.quantity} x ${item.unitPrice.toFixed(2)}
            </Typography>
          </Box>
          <Typography variant="body2" fontWeight="bold" sx={{ whiteSpace: "nowrap" }}>
            ${item.total.toFixed(2)}
          </Typography>
        </Box>
      ))}

      <Box sx={{ display: "flex", justifyContent: "space-between", mb: 0.5 }}>
        <Typography variant="body2" color="text.secondary">Subtotal:</Typography>
        <Typography variant="body2">${subtotal.toFixed(2)}</Typography>
      </Box>
      <Box sx={{ display: "flex", justifyContent: "space-between", mb: 0.5 }}>
        <Typography variant="body2" color="text.secondary">IVA:</Typography>
        <Typography variant="body2">${tax.toFixed(2)}</Typography>
      </Box>
      <Divider sx={{ my: 1 }} />
      <Box sx={{ display: "flex", justifyContent: "space-between" }}>
        <Typography variant="h6" fontWeight="bold">Total:</Typography>
        <Typography variant="h6" fontWeight="bold" sx={{ color: "#b12704" }}>
          ${total.toFixed(2)}
        </Typography>
      </Box>
    </Box>
  );
}
