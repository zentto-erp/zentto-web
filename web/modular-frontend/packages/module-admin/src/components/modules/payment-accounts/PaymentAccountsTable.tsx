"use client";

import * as React from "react";
import {
  Box, Button, Chip, IconButton, Stack, Typography, Tooltip, CircularProgress,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import DeleteIcon from "@mui/icons-material/Delete";
import VisibilityIcon from "@mui/icons-material/Visibility";
import StarIcon from "@mui/icons-material/Star";
import {
  usePaymentAccounts,
  useDeletePaymentAccount,
  type PaymentAccount,
} from "../../../hooks/usePaymentAccounts";
import PaymentAccountFormDialog from "./PaymentAccountFormDialog";
import PaymentAccountPreviewDialog from "./PaymentAccountPreviewDialog";

const PROVIDER_COLORS: Record<string, string> = {
  paddle: "#FFC857",
  stripe: "#635BFF",
  manual: "#94A3B8",
  binance: "#F0B90B",
  mercantil: "#0066B3",
  pago_movil: "#10B981",
  bank_transfer: "#3B82F6",
  redsys: "#FF6B35",
};

export default function PaymentAccountsTable() {
  const { data, isLoading, error } = usePaymentAccounts();
  const deleteMut = useDeletePaymentAccount();
  const [formOpen, setFormOpen] = React.useState(false);
  const [previewId, setPreviewId] = React.useState<number | null>(null);

  const accounts = data?.accounts ?? [];

  async function handleDelete(account: PaymentAccount) {
    if (!confirm(`¿Desactivar account "${account.displayName ?? account.providerCode}"?`)) return;
    await deleteMut.mutateAsync(account.accountId);
  }

  return (
    <Box sx={{ p: 3 }}>
      <Stack direction="row" alignItems="center" justifyContent="space-between" sx={{ mb: 3 }}>
        <Box>
          <Typography variant="body2" color="text.secondary">
            Configura los providers (Paddle, Stripe, Mercantil, Binance, etc.) que usará tu empresa para cobrar.
          </Typography>
        </Box>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => setFormOpen(true)}>
          Agregar cuenta
        </Button>
      </Stack>

      {error ? (
        <Box sx={{ p: 3, bgcolor: "error.light", borderRadius: 2, mb: 2 }}>
          <Typography color="error.dark">
            No se pudo conectar al servicio de pagos. Verifica que el servidor esté disponible.
          </Typography>
        </Box>
      ) : null}

      {isLoading ? (
        <Box sx={{ display: "flex", justifyContent: "center", py: 6 }}>
          <CircularProgress />
        </Box>
      ) : accounts.length === 0 ? (
        <Box sx={{ p: 6, textAlign: "center", border: "1px dashed", borderColor: "divider", borderRadius: 2 }}>
          <Typography variant="body1" sx={{ mb: 1, fontWeight: 600 }}>
            Aún no tienes cuentas de pago configuradas
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Agrega al menos una para que tus clientes puedan pagar online en tu tienda, hotel, sistema de tickets, etc.
          </Typography>
          <Button variant="contained" onClick={() => setFormOpen(true)}>Configurar primera cuenta</Button>
        </Box>
      ) : (
        <Box sx={{ display: "grid", gap: 1.5 }}>
          {accounts.map((acc) => (
            <Box
              key={acc.accountId}
              sx={{
                p: 2,
                borderRadius: 2,
                border: "1px solid",
                borderColor: "divider",
                display: "grid",
                gridTemplateColumns: "auto 1fr auto",
                alignItems: "center",
                gap: 2,
              }}
            >
              <Box
                sx={{
                  width: 48, height: 48, borderRadius: 2,
                  bgcolor: PROVIDER_COLORS[acc.providerCode] ?? "#64748B",
                  color: "#fff",
                  display: "flex", alignItems: "center", justifyContent: "center",
                  fontWeight: 800, fontSize: "0.85rem",
                  textTransform: "uppercase",
                }}
              >
                {acc.providerCode.slice(0, 3)}
              </Box>
              <Box>
                <Stack direction="row" alignItems="center" spacing={1}>
                  <Typography fontWeight={700}>
                    {acc.displayName ?? acc.providerCode}
                  </Typography>
                  {acc.isDefault ? (
                    <Tooltip title="Cuenta por defecto">
                      <StarIcon sx={{ fontSize: 16, color: "warning.main" }} />
                    </Tooltip>
                  ) : null}
                  <Chip label={acc.environment} size="small" color={acc.environment === "production" ? "success" : "default"} />
                  {acc.countryCode ? <Chip label={acc.countryCode} size="small" variant="outlined" /> : null}
                </Stack>
                <Typography variant="caption" color="text.secondary">
                  {acc.providerCode} · creada {new Date(acc.createdAt).toLocaleDateString("es")}
                  {acc.hasCredentials ? "" : " · sin credenciales"}
                </Typography>
              </Box>
              <Stack direction="row" spacing={0.5}>
                <Tooltip title="Ver credenciales (enmascaradas)">
                  <IconButton size="small" onClick={() => setPreviewId(acc.accountId)}>
                    <VisibilityIcon fontSize="small" />
                  </IconButton>
                </Tooltip>
                <Tooltip title="Desactivar cuenta">
                  <IconButton size="small" color="error" onClick={() => handleDelete(acc)}>
                    <DeleteIcon fontSize="small" />
                  </IconButton>
                </Tooltip>
              </Stack>
            </Box>
          ))}
        </Box>
      )}

      <PaymentAccountFormDialog open={formOpen} onClose={() => setFormOpen(false)} />
      <PaymentAccountPreviewDialog
        accountId={previewId}
        onClose={() => setPreviewId(null)}
      />
    </Box>
  );
}
