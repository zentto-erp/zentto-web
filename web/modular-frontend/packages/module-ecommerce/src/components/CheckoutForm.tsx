"use client";

import { useState } from "react";
import { Box, TextField, Button, Typography, Alert, CircularProgress, Paper, Divider, FormControlLabel, Checkbox, MenuItem } from "@mui/material";
import Grid from "@mui/material/Grid2";
import { FormGrid, FormField } from "@zentto/shared-ui";
import LockIcon from "@mui/icons-material/Lock";
import ShieldIcon from "@mui/icons-material/Shield";
import LocalShippingIcon from "@mui/icons-material/LocalShipping";
import ReceiptIcon from "@mui/icons-material/Receipt";
import { useCountries } from "@zentto/shared-api";
import { useCartStore } from "../store/useCartStore";
import { useCheckout } from "../hooks/useStoreOrders";
import OrderSummary from "./OrderSummary";
import AddressSelector from "./AddressSelector";
import PaymentMethodSelector from "./PaymentMethodSelector";
import type { CustomerAddress, CustomerPaymentMethod } from "../hooks/useStoreAccount";

interface Props {
  onSuccess: (orderToken: string) => void;
  onBack: () => void;
}

export default function CheckoutForm({ onSuccess, onBack }: Props) {
  const items = useCartStore((s) => s.items);
  const customerInfo = useCartStore((s) => s.customerInfo);
  const customerToken = useCartStore((s) => s.customerToken);
  const getSubtotal = useCartStore((s) => s.getSubtotal);
  const getTaxTotal = useCartStore((s) => s.getTaxTotal);
  const getTotal = useCartStore((s) => s.getTotal);

  const isLoggedIn = !!customerToken;

  const [name, setName] = useState(customerInfo?.name ?? "");
  const [email, setEmail] = useState(customerInfo?.email ?? "");
  const [phone, setPhone] = useState(customerInfo?.phone ?? "");
  const [address, setAddress] = useState(customerInfo?.address ?? "");
  const [fiscalId, setFiscalId] = useState(customerInfo?.fiscalId ?? "");
  const [notes, setNotes] = useState("");
  const [error, setError] = useState("");

  // Saved address & payment selection (logged in)
  const [selectedAddressId, setSelectedAddressId] = useState<number | null>(null);
  const [selectedAddress, setSelectedAddress] = useState<CustomerAddress | null>(null);
  const [selectedPaymentId, setSelectedPaymentId] = useState<number | null>(null);
  const [selectedPayment, setSelectedPayment] = useState<CustomerPaymentMethod | null>(null);

  // Billing address
  const [sameAsBilling, setSameAsBilling] = useState(true);
  const [billingAddressId, setBillingAddressId] = useState<number | null>(null);
  const [billingAddress, setBillingAddress] = useState<CustomerAddress | null>(null);

  // Structured address for guests
  const [guestAddress, setGuestAddress] = useState({ addressLine: "", city: "", state: "", zipCode: "", country: "VE" });

  const { data: countries = [] } = useCountries();
  const checkoutMutation = useCheckout();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");

    if (!name.trim() || !email.trim()) {
      setError("Nombre y email son obligatorios");
      return;
    }
    if (items.length === 0) {
      setError("El carrito esta vacio");
      return;
    }

    // Build shipping address
    const shippingAddr = isLoggedIn && selectedAddress
      ? [selectedAddress.AddressLine, selectedAddress.City, selectedAddress.State].filter(Boolean).join(", ")
      : [guestAddress.addressLine, guestAddress.city, guestAddress.state].filter(Boolean).join(", ") || address.trim();

    // Build billing address
    const billingAddr = sameAsBilling
      ? shippingAddr
      : isLoggedIn && billingAddress
        ? [billingAddress.AddressLine, billingAddress.City, billingAddress.State].filter(Boolean).join(", ")
        : shippingAddr;

    try {
      const result = await checkoutMutation.mutateAsync({
        customer: {
          name: name.trim(),
          email: email.trim().toLowerCase(),
          phone: phone.trim() || undefined,
          address: shippingAddr || undefined,
          billingAddress: billingAddr || undefined,
          fiscalId: fiscalId.trim() || undefined,
        },
        items: items.map((item) => ({
          productCode: item.productCode,
          productName: item.productName,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          taxRate: item.taxRate,
          subtotal: item.subtotal,
          taxAmount: item.taxAmount,
        })),
        notes: notes.trim() || undefined,
        addressId: selectedAddressId ?? undefined,
        billingAddressId: sameAsBilling ? selectedAddressId ?? undefined : billingAddressId ?? undefined,
        paymentMethodId: selectedPaymentId ?? undefined,
        paymentMethodType: selectedPayment?.MethodType ?? undefined,
      });

      if (result.orderToken) {
        onSuccess(result.orderToken);
      }
    } catch (err: any) {
      setError(err.message || "Error al crear el pedido");
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 3 }}>
        <LockIcon sx={{ color: "#ff9900" }} />
        <Typography variant="h5" fontWeight="bold" sx={{ color: "#0f1111" }}>
          Finalizar compra
        </Typography>
      </Box>

      <Grid container spacing={3}>
        <Grid size={{ xs: 12, md: 7 }}>
          <Paper elevation={0} sx={{ border: "1px solid #e3e6e6", borderRadius: "8px", overflow: "hidden" }}>
            {/* 1. Datos de contacto */}
            <Box sx={{ bgcolor: "#f0f2f2", px: 3, py: 1.5 }}>
              <Typography variant="subtitle1" fontWeight="bold" sx={{ color: "#0f1111" }}>
                1. Datos de contacto
              </Typography>
            </Box>
            <Box sx={{ p: 3 }}>
              {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
              <FormGrid spacing={2}>
                <FormField xs={12} sm={6}>
                  <TextField label="Nombre completo" value={name} onChange={(e) => setName(e.target.value)} required />
                </FormField>
                <FormField xs={12} sm={6}>
                  <TextField label="Email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
                </FormField>
                <FormField xs={12} sm={6}>
                  <TextField label="Telefono" value={phone} onChange={(e) => setPhone(e.target.value)} />
                </FormField>
                <FormField xs={12} sm={6}>
                  <TextField label="RIF / Cedula" value={fiscalId} onChange={(e) => setFiscalId(e.target.value)} />
                </FormField>
              </FormGrid>
            </Box>

            {/* 2. Dirección de envío */}
            <Divider />
            <Box sx={{ bgcolor: "#f0f2f2", px: 3, py: 1.5, display: "flex", alignItems: "center", gap: 1 }}>
              <LocalShippingIcon sx={{ fontSize: 18, color: "#555" }} />
              <Typography variant="subtitle1" fontWeight="bold" sx={{ color: "#0f1111" }}>
                2. Direccion de envio
              </Typography>
            </Box>
            <Box sx={{ p: 3 }}>
              {isLoggedIn ? (
                <AddressSelector
                  selectedId={selectedAddressId}
                  onSelect={(id, addr) => {
                    setSelectedAddressId(id);
                    setSelectedAddress(addr);
                  }}
                />
              ) : (
                <FormGrid spacing={2}>
                  <FormField xs={12}>
                    <TextField label="Direccion" value={guestAddress.addressLine} onChange={(e) => setGuestAddress({ ...guestAddress, addressLine: e.target.value })} required />
                  </FormField>
                  <FormField xs={12} sm={4}>
                    <TextField label="Ciudad" value={guestAddress.city} onChange={(e) => setGuestAddress({ ...guestAddress, city: e.target.value })} />
                  </FormField>
                  <FormField xs={12} sm={4}>
                    <TextField select label="Pais" value={guestAddress.country} onChange={(e) => setGuestAddress({ ...guestAddress, country: e.target.value, state: "" })}>
                      {countries.map((c) => (
                        <MenuItem key={c.CountryCode} value={c.CountryCode}>{c.CountryName}</MenuItem>
                      ))}
                    </TextField>
                  </FormField>
                  <FormField xs={12} sm={4}>
                    <TextField label="Estado / Provincia" value={guestAddress.state} onChange={(e) => setGuestAddress({ ...guestAddress, state: e.target.value })} />
                  </FormField>
                </FormGrid>
              )}
            </Box>

            {/* 2b. Dirección de facturación */}
            <Divider />
            <Box sx={{ bgcolor: "#f0f2f2", px: 3, py: 1.5, display: "flex", alignItems: "center", gap: 1 }}>
              <ReceiptIcon sx={{ fontSize: 18, color: "#555" }} />
              <Typography variant="subtitle1" fontWeight="bold" sx={{ color: "#0f1111" }}>
                Direccion de facturacion
              </Typography>
            </Box>
            <Box sx={{ px: 3, py: 2 }}>
              <FormControlLabel
                control={<Checkbox checked={sameAsBilling} onChange={(e) => setSameAsBilling(e.target.checked)} size="small" />}
                label={<Typography variant="body2">Misma que la direccion de envio</Typography>}
              />
              {!sameAsBilling && isLoggedIn && (
                <Box sx={{ mt: 2 }}>
                  <AddressSelector
                    selectedId={billingAddressId}
                    onSelect={(id, addr) => {
                      setBillingAddressId(id);
                      setBillingAddress(addr);
                    }}
                  />
                </Box>
              )}
              {!sameAsBilling && !isLoggedIn && (
                <Box sx={{ mt: 2 }}>
                  <TextField label="Direccion de facturacion" value={address} onChange={(e) => setAddress(e.target.value)} fullWidth placeholder="Si es diferente a la de envio" />
                </Box>
              )}
            </Box>

            {/* 3. Método de pago */}
            <Divider />
            <Box sx={{ bgcolor: "#f0f2f2", px: 3, py: 1.5 }}>
              <Typography variant="subtitle1" fontWeight="bold" sx={{ color: "#0f1111" }}>
                3. Metodo de pago
              </Typography>
            </Box>
            <Box sx={{ p: 3 }}>
              {isLoggedIn ? (
                <PaymentMethodSelector
                  selectedId={selectedPaymentId}
                  onSelect={(id, method) => {
                    setSelectedPaymentId(id);
                    setSelectedPayment(method);
                  }}
                />
              ) : (
                <Typography variant="body2" color="text.secondary">
                  Inicia sesion para guardar y seleccionar metodos de pago.
                  El pago se coordina despues de confirmar el pedido.
                </Typography>
              )}
            </Box>

            {/* 4. Notas adicionales */}
            <Divider />
            <Box sx={{ bgcolor: "#f0f2f2", px: 3, py: 1.5 }}>
              <Typography variant="subtitle1" fontWeight="bold" sx={{ color: "#0f1111" }}>
                4. Notas adicionales
              </Typography>
            </Box>
            <Box sx={{ p: 3 }}>
              <TextField label="Instrucciones especiales (opcional)" value={notes} onChange={(e) => setNotes(e.target.value)} fullWidth multiline rows={2} placeholder="Ej: Entregar en horario de oficina" />
            </Box>
          </Paper>
        </Grid>

        {/* Resumen del pedido */}
        <Grid size={{ xs: 12, md: 5 }}>
          <Paper elevation={0} sx={{ border: "1px solid #e3e6e6", borderRadius: "8px", p: 3, position: "sticky", top: 80 }}>
            <Typography variant="h6" fontWeight="bold" sx={{ color: "#0f1111", mb: 2 }}>
              Resumen del pedido
            </Typography>
            <OrderSummary items={items} subtotal={getSubtotal()} tax={getTaxTotal()} total={getTotal()} />

            <Box sx={{ mt: 3 }}>
              <Button
                type="submit"
                variant="contained"
                size="large"
                fullWidth
                disabled={checkoutMutation.isPending || items.length === 0}
                sx={{
                  bgcolor: "#ffd814",
                  color: "#0f1111",
                  fontWeight: "bold",
                  fontSize: 16,
                  textTransform: "none",
                  borderRadius: "20px",
                  py: 1.3,
                  boxShadow: "none",
                  border: "1px solid #fcd200",
                  "&:hover": { bgcolor: "#f7ca00", boxShadow: "none" },
                  mb: 1.5,
                }}
              >
                {checkoutMutation.isPending ? <CircularProgress size={24} /> : `Confirmar pedido — $${getTotal().toFixed(2)}`}
              </Button>

              <Box sx={{ display: "flex", flexDirection: "column", gap: 0.5, mt: 1 }}>
                <Box sx={{ display: "flex", alignItems: "center", gap: 0.5, justifyContent: "center" }}>
                  <ShieldIcon sx={{ fontSize: 14, color: "#067D62" }} />
                  <Typography variant="caption" sx={{ color: "#067D62" }}>Compra protegida</Typography>
                </Box>
                <Box sx={{ display: "flex", alignItems: "center", gap: 0.5, justifyContent: "center" }}>
                  <LocalShippingIcon sx={{ fontSize: 14, color: "#067D62" }} />
                  <Typography variant="caption" sx={{ color: "#067D62" }}>Envio a todo el pais</Typography>
                </Box>
              </Box>
            </Box>

            <Button variant="text" fullWidth onClick={onBack} sx={{ mt: 2, color: "#007185", textTransform: "none", fontSize: 13 }}>
              Volver al carrito
            </Button>
          </Paper>
        </Grid>
      </Grid>
    </form>
  );
}
