"use client";

import { Box, Typography, IconButton, Select, MenuItem, ListItem } from "@mui/material";
import DeleteOutlineIcon from "@mui/icons-material/DeleteOutline";
import { useCartStore, type CartItem as CartItemType } from "../store/useCartStore";

interface Props {
  item: CartItemType;
}

export default function CartItem({ item }: Props) {
  const updateQuantity = useCartStore((s) => s.updateQuantity);
  const removeItem = useCartStore((s) => s.removeItem);

  return (
    <ListItem
      sx={{
        py: 1.5,
        px: 2,
        borderBottom: "1px solid #f0f0f0",
        alignItems: "flex-start",
      }}
    >
      {/* Image */}
      <Box
        component="img"
        src={item.imageUrl || "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='80' height='80'%3E%3Crect fill='%23f0f0f0' width='80' height='80'/%3E%3C/svg%3E"}
        alt={item.productName}
        sx={{
          width: 72,
          height: 72,
          objectFit: "contain",
          borderRadius: "4px",
          border: "1px solid #e3e6e6",
          bgcolor: "#f7f7f7",
          mr: 1.5,
          flexShrink: 0,
        }}
      />

      {/* Details */}
      <Box sx={{ flexGrow: 1, minWidth: 0 }}>
        <Typography
          variant="body2"
          sx={{
            fontWeight: 400,
            color: "#0f1111",
            display: "-webkit-box",
            WebkitLineClamp: 2,
            WebkitBoxOrient: "vertical",
            overflow: "hidden",
            fontSize: 13,
            lineHeight: 1.3,
            mb: 0.5,
          }}
        >
          {item.productName}
        </Typography>

        <Typography variant="body2" sx={{ fontWeight: "bold", color: "#0f1111", mb: 0.5 }}>
          ${item.total.toFixed(2)}
        </Typography>

        <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
          <Select
           
            value={item.quantity}
            onChange={(e) => updateQuantity(item.productCode, Number(e.target.value))}
            sx={{
              fontSize: 12,
              height: 28,
              bgcolor: "#f0f2f2",
              borderRadius: "7px",
              "& .MuiOutlinedInput-notchedOutline": { border: "1px solid #d5d9d9" },
              minWidth: 60,
            }}
          >
            {Array.from({ length: 10 }, (_, i) => i + 1).map((v) => (
              <MenuItem key={v} value={v} sx={{ fontSize: 12 }}>
                Cant: {v}
              </MenuItem>
            ))}
          </Select>

          <IconButton
            size="small"
            onClick={() => removeItem(item.productCode)}
            sx={{ color: "#007185", fontSize: 12, p: 0.5 }}
          >
            <DeleteOutlineIcon sx={{ fontSize: 18 }} />
          </IconButton>

          <Typography
            variant="caption"
            onClick={() => removeItem(item.productCode)}
            sx={{ color: "#007185", cursor: "pointer", fontSize: 12, "&:hover": { textDecoration: "underline" } }}
          >
            Eliminar
          </Typography>
        </Box>
      </Box>
    </ListItem>
  );
}
