"use client";

import { Drawer, Box, Typography, Button, Divider, IconButton, List } from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import ShoppingCartCheckoutIcon from "@mui/icons-material/ShoppingCartCheckout";
import DeleteSweepIcon from "@mui/icons-material/DeleteSweep";
import LocalShippingIcon from "@mui/icons-material/LocalShipping";
import ShieldIcon from "@mui/icons-material/Shield";
import CartItem from "./CartItem";
import { useCartStore } from "../store/useCartStore";

interface Props {
  open: boolean;
  onClose: () => void;
  onCheckout: () => void;
}

export default function CartDrawer({ open, onClose, onCheckout }: Props) {
  const items = useCartStore((s) => s.items);
  const clearCart = useCartStore((s) => s.clearCart);
  const getSubtotal = useCartStore((s) => s.getSubtotal);
  const getTaxTotal = useCartStore((s) => s.getTaxTotal);
  const getTotal = useCartStore((s) => s.getTotal);
  const getItemCount = useCartStore((s) => s.getItemCount);

  return (
    <Drawer anchor="right" open={open} onClose={onClose} PaperProps={{ sx: { width: { xs: "100%", sm: 420 }, bgcolor: "#f5f5f5" } }}>
      {/* Header */}
      <Box sx={{ p: 2, display: "flex", justifyContent: "space-between", alignItems: "center", bgcolor: "#131921", color: "#fff" }}>
        <Typography variant="h6" fontWeight="bold">
          Carrito ({getItemCount()})
        </Typography>
        <IconButton onClick={onClose} sx={{ color: "#fff" }}>
          <CloseIcon />
        </IconButton>
      </Box>

      {items.length === 0 ? (
        <Box sx={{ p: 4, textAlign: "center" }}>
          <Typography variant="h6" color="text.secondary" gutterBottom sx={{ mt: 4 }}>
            Tu carrito esta vacio
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Agrega productos para comenzar tu compra
          </Typography>
        </Box>
      ) : (
        <>
          <List sx={{ flexGrow: 1, overflow: "auto", bgcolor: "#fff", mx: 0 }}>
            {items.map((item) => (
              <CartItem key={item.productCode} item={item} />
            ))}
          </List>

          <Box sx={{ bgcolor: "#fff", borderTop: "1px solid #e3e6e6" }}>
            <Box sx={{ bgcolor: "#f0faf0", px: 2, py: 1, display: "flex", alignItems: "center", gap: 1 }}>
              <LocalShippingIcon sx={{ fontSize: 18, color: "#067D62" }} />
              <Typography variant="caption" sx={{ color: "#067D62", fontWeight: 500 }}>
                Envio gratis en pedidos mayores a $25
              </Typography>
            </Box>

            <Box sx={{ p: 2 }}>
              <Box sx={{ display: "flex", justifyContent: "space-between", mb: 0.5 }}>
                <Typography variant="body2" color="text.secondary">Subtotal:</Typography>
                <Typography variant="body2">${getSubtotal().toFixed(2)}</Typography>
              </Box>
              <Box sx={{ display: "flex", justifyContent: "space-between", mb: 0.5 }}>
                <Typography variant="body2" color="text.secondary">IVA:</Typography>
                <Typography variant="body2">${getTaxTotal().toFixed(2)}</Typography>
              </Box>
              <Divider sx={{ my: 1 }} />
              <Box sx={{ display: "flex", justifyContent: "space-between", mb: 2 }}>
                <Typography variant="h6" fontWeight="bold">Total:</Typography>
                <Typography variant="h6" fontWeight="bold" sx={{ color: "#b12704" }}>
                  ${getTotal().toFixed(2)}
                </Typography>
              </Box>

              <Button
                variant="contained"
                fullWidth
                startIcon={<ShoppingCartCheckoutIcon />}
                onClick={onCheckout}
                sx={{
                  bgcolor: "#ffd814",
                  color: "#0f1111",
                  fontWeight: "bold",
                  fontSize: 15,
                  textTransform: "none",
                  borderRadius: "20px",
                  py: 1.2,
                  boxShadow: "none",
                  border: "1px solid #fcd200",
                  "&:hover": { bgcolor: "#f7ca00", boxShadow: "none" },
                  mb: 1,
                }}
              >
                Proceder al pago
              </Button>

              <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 0.5, mb: 1.5 }}>
                <ShieldIcon sx={{ fontSize: 14, color: "#067D62" }} />
                <Typography variant="caption" sx={{ color: "#067D62" }}>
                  Compra 100% segura
                </Typography>
              </Box>

              <Button
                variant="text"
                fullWidth
                startIcon={<DeleteSweepIcon />}
                onClick={clearCart}
                size="small"
                sx={{ color: "#565959", textTransform: "none", fontSize: 12 }}
              >
                Vaciar carrito
              </Button>
            </Box>
          </Box>
        </>
      )}
    </Drawer>
  );
}
