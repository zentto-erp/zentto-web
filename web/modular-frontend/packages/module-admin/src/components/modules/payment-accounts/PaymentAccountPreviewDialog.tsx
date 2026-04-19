"use client";

import * as React from "react";
import {
  Dialog, DialogTitle, DialogContent, DialogActions, Button, Box,
  Typography, CircularProgress, Stack,
} from "@mui/material";
import { usePaymentAccountPreview } from "../../../hooks/usePaymentAccounts";

export default function PaymentAccountPreviewDialog({
  accountId,
  onClose,
}: {
  accountId: number | null;
  onClose: () => void;
}) {
  const { data, isLoading } = usePaymentAccountPreview(accountId);
  const open = accountId !== null;

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>Credenciales (enmascaradas)</DialogTitle>
      <DialogContent dividers>
        {isLoading ? (
          <Box sx={{ display: "flex", justifyContent: "center", py: 4 }}>
            <CircularProgress />
          </Box>
        ) : !data || Object.keys(data.preview ?? {}).length === 0 ? (
          <Typography color="text.secondary">No hay credenciales registradas.</Typography>
        ) : (
          <Stack spacing={1.5}>
            {Object.entries(data.preview).map(([k, v]) => (
              <Box key={k} sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", p: 1.5, bgcolor: "grey.100", borderRadius: 1 }}>
                <Typography variant="body2" fontWeight={600}>{k}</Typography>
                <Typography variant="body2" sx={{ fontFamily: "monospace", color: "text.secondary" }}>{v}</Typography>
              </Box>
            ))}
            <Typography variant="caption" color="text.secondary" sx={{ mt: 1 }}>
              Por seguridad solo mostramos prefijo y sufijo. Para cambiar las credenciales, crea una nueva cuenta.
            </Typography>
          </Stack>
        )}
      </DialogContent>
      <DialogActions sx={{ px: 3, py: 2 }}>
        <Button onClick={onClose}>Cerrar</Button>
      </DialogActions>
    </Dialog>
  );
}
