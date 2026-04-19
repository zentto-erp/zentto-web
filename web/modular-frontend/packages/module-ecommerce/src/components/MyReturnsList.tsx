"use client";

import { Box, Paper, Typography, Chip, Stack, CircularProgress, Button, Divider } from "@mui/material";
import { useMyReturns, type MyReturn } from "../hooks/useReturns";

const STATUS_COLOR: Record<MyReturn["status"], { color: "default" | "primary" | "success" | "warning" | "error" | "info"; label: string }> = {
  requested:  { color: "info",    label: "Solicitada" },
  approved:   { color: "primary", label: "Aprobada" },
  rejected:   { color: "error",   label: "Rechazada" },
  in_transit: { color: "warning", label: "En tránsito" },
  received:   { color: "primary", label: "Recibida" },
  refunded:   { color: "success", label: "Reembolsada" },
};

interface Props {
  onSelect?: (returnId: number) => void;
  emptyAction?: React.ReactNode;
}

export default function MyReturnsList({ onSelect, emptyAction }: Props) {
  const { data, isLoading } = useMyReturns();

  if (isLoading) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", py: 4 }}>
        <CircularProgress size={28} />
      </Box>
    );
  }

  const rows = data?.rows || [];
  if (!rows.length) {
    return (
      <Paper sx={{ p: 4, textAlign: "center" }}>
        <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
          Aún no tienes devoluciones solicitadas.
        </Typography>
        {emptyAction}
      </Paper>
    );
  }

  return (
    <Stack spacing={1.5}>
      {rows.map((r) => {
        const meta = STATUS_COLOR[r.status] ?? { color: "default" as const, label: r.status };
        return (
          <Paper key={r.returnId} sx={{ p: 2.5 }}>
            <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", flexWrap: "wrap", gap: 2 }}>
              <Box>
                <Typography variant="subtitle1" fontWeight={700}>
                  Pedido {r.orderNumber}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  Solicitada el {new Date(r.requestedAt).toLocaleString()}
                </Typography>
              </Box>
              <Chip color={meta.color} label={meta.label} size="small" />
            </Box>

            <Divider sx={{ my: 1.5 }} />

            <Typography variant="body2" sx={{ mb: 1 }}>
              {r.reason}
            </Typography>
            <Typography variant="caption" color="text.secondary" sx={{ display: "block" }}>
              Productos: {r.itemCount} · Reembolso estimado: {r.refundCurrency} {Number(r.refundAmount).toFixed(2)}
            </Typography>

            {onSelect && (
              <Box sx={{ mt: 1.5, textAlign: "right" }}>
                <Button size="small" onClick={() => onSelect(r.returnId)}>
                  Ver detalle
                </Button>
              </Box>
            )}
          </Paper>
        );
      })}
    </Stack>
  );
}
