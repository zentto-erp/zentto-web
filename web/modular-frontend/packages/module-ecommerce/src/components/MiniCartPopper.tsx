"use client";

import {
  Box,
  Button,
  ClickAwayListener,
  Divider,
  IconButton,
  Paper,
  Popper,
  Stack,
  Typography,
} from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import ShoppingCartCheckoutIcon from "@mui/icons-material/ShoppingCartCheckout";
import RemoveShoppingCartIcon from "@mui/icons-material/RemoveShoppingCart";
import { useCartStore } from "../store/useCartStore";
import { formatPrice } from "../utils/formatCurrency";

interface Props {
  /** Ancla al que se posiciona el popper (icono del carrito). */
  anchorEl: HTMLElement | null;
  /** Controla visibilidad. */
  open: boolean;
  /** Cierra el popper. */
  onClose: () => void;
  /** Navegar a la página completa de carrito. */
  onViewCart: () => void;
  /** Navegar a checkout. */
  onCheckout: () => void;
}

/**
 * Mini-cart estilo popper para desktop. Muestra los últimos 3 items y CTAs
 * para "Ver carrito" y "Checkout". En mobile el layout sigue usando `CartDrawer`.
 */
export default function MiniCartPopper({ anchorEl, open, onClose, onViewCart, onCheckout }: Props) {
  const items = useCartStore((s) => s.items);
  const getSubtotal = useCartStore((s) => s.getSubtotal);
  const getTaxTotal = useCartStore((s) => s.getTaxTotal);
  const getTotal = useCartStore((s) => s.getTotal);
  const getItemCount = useCartStore((s) => s.getItemCount);
  const currency = useCartStore((s) => s.currency);

  const itemCount = getItemCount();
  const subtotal = getSubtotal();
  const taxTotal = getTaxTotal();
  const total = getTotal();
  const preview = items.slice(0, 3);
  const remaining = Math.max(0, items.length - preview.length);
  const taxPct = Math.round((currency.taxRate ?? 0) * 100);

  return (
    <Popper
      open={open}
      anchorEl={anchorEl}
      placement="bottom-end"
      disablePortal={false}
      modifiers={[{ name: "offset", options: { offset: [0, 8] } }]}
      sx={{ zIndex: 1400 }}
    >
      <ClickAwayListener onClickAway={onClose}>
        <Paper
          elevation={8}
          sx={{
            width: { xs: 320, sm: 360 },
            maxWidth: "96vw",
            borderRadius: 2,
            overflow: "hidden",
            border: "1px solid #e3e6e6",
          }}
        >
          {/* Header */}
          <Box
            sx={{
              bgcolor: "#131921",
              color: "#fff",
              px: 2,
              py: 1.2,
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",
            }}
          >
            <Typography variant="subtitle2" fontWeight={700} sx={{ fontSize: 14 }}>
              Carrito ({itemCount})
            </Typography>
            <IconButton size="small" onClick={onClose} sx={{ color: "#fff", p: 0.5 }}>
              <CloseIcon sx={{ fontSize: 18 }} />
            </IconButton>
          </Box>

          {items.length === 0 ? (
            <Box sx={{ p: 3, textAlign: "center" }}>
              <RemoveShoppingCartIcon sx={{ fontSize: 36, color: "#ccc", mb: 1 }} />
              <Typography variant="body2" color="text.secondary">
                Tu carrito está vacío
              </Typography>
            </Box>
          ) : (
            <>
              {/* Lista de los últimos items */}
              <Stack divider={<Divider />} sx={{ maxHeight: 260, overflow: "auto" }}>
                {preview.map((item) => (
                  <Box
                    key={item.productCode}
                    sx={{
                      display: "flex",
                      gap: 1.2,
                      alignItems: "center",
                      px: 1.5,
                      py: 1,
                    }}
                  >
                    <Box
                      sx={{
                        width: 50,
                        height: 50,
                        flexShrink: 0,
                        borderRadius: 1,
                        overflow: "hidden",
                        bgcolor: "#f5f5f5",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                      }}
                    >
                      {item.imageUrl ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img
                          src={item.imageUrl}
                          alt={item.productName}
                          style={{ width: "100%", height: "100%", objectFit: "cover" }}
                        />
                      ) : (
                        <Typography variant="caption" color="text.secondary">
                          Sin foto
                        </Typography>
                      )}
                    </Box>
                    <Box sx={{ flex: 1, minWidth: 0 }}>
                      <Typography
                        variant="body2"
                        sx={{
                          fontWeight: 500,
                          fontSize: 13,
                          overflow: "hidden",
                          textOverflow: "ellipsis",
                          display: "-webkit-box",
                          WebkitLineClamp: 2,
                          WebkitBoxOrient: "vertical",
                        }}
                      >
                        {item.productName}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        x{item.quantity}
                      </Typography>
                    </Box>
                    <Typography variant="body2" sx={{ fontWeight: 600, fontSize: 13 }}>
                      {formatPrice(item.subtotal, currency)}
                    </Typography>
                  </Box>
                ))}
              </Stack>

              {remaining > 0 && (
                <Box sx={{ px: 2, py: 0.8, bgcolor: "#fafafa" }}>
                  <Typography variant="caption" color="text.secondary">
                    +{remaining} producto{remaining > 1 ? "s" : ""} más en el carrito
                  </Typography>
                </Box>
              )}

              <Divider />

              {/* Subtotal + IVA + Total + CTAs */}
              <Box sx={{ p: 2 }}>
                <Box sx={{ display: "flex", justifyContent: "space-between", mb: 0.5 }}>
                  <Typography variant="body2" color="text.secondary">
                    Subtotal
                  </Typography>
                  <Typography variant="body2" fontWeight={500}>
                    {formatPrice(subtotal, currency)}
                  </Typography>
                </Box>
                {taxTotal > 0 && (
                  <Box sx={{ display: "flex", justifyContent: "space-between", mb: 0.5 }}>
                    <Typography variant="body2" color="text.secondary">
                      {currency.taxName || "IVA"}{taxPct ? ` (${taxPct}%)` : ""}
                    </Typography>
                    <Typography variant="body2" fontWeight={500}>
                      {formatPrice(taxTotal, currency)}
                    </Typography>
                  </Box>
                )}
                <Divider sx={{ my: 1 }} />
                <Box sx={{ display: "flex", justifyContent: "space-between", mb: 1.2 }}>
                  <Typography variant="body2" fontWeight={700}>
                    Total
                  </Typography>
                  <Typography variant="body1" fontWeight={700} sx={{ color: "#b12704" }}>
                    {formatPrice(total, currency)}
                  </Typography>
                </Box>

                <Stack direction="row" spacing={1}>
                  <Button
                    variant="outlined"
                    fullWidth
                    onClick={() => {
                      onClose();
                      onViewCart();
                    }}
                    sx={{ textTransform: "none", fontWeight: 600 }}
                  >
                    Ver carrito
                  </Button>
                  <Button
                    variant="contained"
                    fullWidth
                    startIcon={<ShoppingCartCheckoutIcon />}
                    onClick={() => {
                      onClose();
                      onCheckout();
                    }}
                    sx={{
                      bgcolor: "#ffd814",
                      color: "#0f1111",
                      textTransform: "none",
                      fontWeight: 700,
                      boxShadow: "none",
                      border: "1px solid #fcd200",
                      "&:hover": { bgcolor: "#f7ca00", boxShadow: "none" },
                    }}
                  >
                    Checkout
                  </Button>
                </Stack>
              </Box>
            </>
          )}
        </Paper>
      </ClickAwayListener>
    </Popper>
  );
}
