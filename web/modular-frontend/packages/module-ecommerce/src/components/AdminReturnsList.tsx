"use client";

import { useState } from "react";
import {
  Box, Paper, Typography, Chip, Stack, CircularProgress, Button, Dialog, DialogTitle,
  DialogContent, DialogActions, TextField, MenuItem, Alert, Divider, Tabs, Tab,
} from "@mui/material";
import AssignmentReturnIcon from "@mui/icons-material/AssignmentReturn";
import {
  useAdminReturns, useAdminReturnDetail, useAdminSetReturnStatus,
  type ReturnSummary,
} from "../hooks/useAdminEcommerce";

const STATUS_COLOR: Record<ReturnSummary["status"], { color: "default" | "primary" | "success" | "warning" | "error" | "info"; label: string }> = {
  requested:  { color: "info",    label: "Solicitada" },
  approved:   { color: "primary", label: "Aprobada" },
  rejected:   { color: "error",   label: "Rechazada" },
  in_transit: { color: "warning", label: "En tránsito" },
  received:   { color: "primary", label: "Recibida" },
  refunded:   { color: "success", label: "Reembolsada" },
};

const TAB_STATUS = ["all", "requested", "approved", "in_transit", "received", "refunded", "rejected"];

function ReturnDetailDialog({ returnId, onClose }: { returnId: number; onClose: () => void }) {
  const { data, isLoading } = useAdminReturnDetail(returnId);
  const set = useAdminSetReturnStatus();
  const [adminNotes, setAdminNotes] = useState("");
  const [refundMethod, setRefundMethod] = useState("");
  const [refundReference, setRefundReference] = useState("");
  const [error, setError] = useState("");

  const apply = async (status: string) => {
    setError("");
    try {
      const r = await set.mutateAsync({
        returnId,
        status,
        adminNotes: adminNotes || undefined,
        refundMethod: refundMethod || undefined,
        refundReference: refundReference || undefined,
      });
      if (!r.ok) setError(r.message || "Error");
      else onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  return (
    <Dialog open onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>Devolución #{returnId}</DialogTitle>
      <DialogContent dividers>
        {isLoading || !data ? (
          <Box sx={{ display: "flex", justifyContent: "center", py: 4 }}>
            <CircularProgress />
          </Box>
        ) : (
          <Stack spacing={2}>
            <Box>
              <Typography variant="subtitle2">Pedido</Typography>
              <Typography>{data.orderNumber} — Cliente: {data.customerCode}</Typography>
            </Box>
            <Box>
              <Typography variant="subtitle2">Estado actual</Typography>
              <Chip
                size="small"
                color={STATUS_COLOR[data.status as ReturnSummary["status"]]?.color || "default"}
                label={STATUS_COLOR[data.status as ReturnSummary["status"]]?.label || data.status}
              />
            </Box>
            <Box>
              <Typography variant="subtitle2">Motivo del cliente</Typography>
              <Typography>{data.reason}</Typography>
            </Box>
            <Divider />
            <Box>
              <Typography variant="subtitle2" gutterBottom>Productos</Typography>
              <Stack spacing={0.5}>
                {(data.items || []).map((it: any, i: number) => (
                  <Typography key={i} variant="body2">
                    {it.quantity} × {it.productName} ({it.productCode})
                    {it.reason && <Typography variant="caption" color="text.secondary"> — {it.reason}</Typography>}
                  </Typography>
                ))}
              </Stack>
            </Box>
            <Divider />
            <Typography variant="subtitle2">Procesar</Typography>
            <TextField
              label="Notas del admin"
              value={adminNotes}
              onChange={(e) => setAdminNotes(e.target.value)}
              fullWidth
              multiline
              rows={2}
            />
            <TextField
              select label="Método de reembolso (si aplica)"
              value={refundMethod}
              onChange={(e) => setRefundMethod(e.target.value)}
              fullWidth
            >
              <MenuItem value="">—</MenuItem>
              <MenuItem value="paddle_refund">Paddle refund</MenuItem>
              <MenuItem value="stripe_refund">Stripe refund</MenuItem>
              <MenuItem value="bank_transfer">Transferencia bancaria</MenuItem>
              <MenuItem value="store_credit">Crédito en tienda</MenuItem>
            </TextField>
            <TextField
              label="Referencia / nro. operación"
              value={refundReference}
              onChange={(e) => setRefundReference(e.target.value)}
              fullWidth
            />
            {error && <Alert severity="error">{error}</Alert>}
          </Stack>
        )}
      </DialogContent>
      <DialogActions sx={{ px: 3, pb: 2, flexWrap: "wrap", gap: 1 }}>
        <Button onClick={onClose}>Cerrar</Button>
        <Button color="error" onClick={() => apply("rejected")} disabled={set.isPending}>Rechazar</Button>
        <Button onClick={() => apply("approved")} disabled={set.isPending}>Aprobar</Button>
        <Button onClick={() => apply("in_transit")} disabled={set.isPending}>En tránsito</Button>
        <Button onClick={() => apply("received")} disabled={set.isPending}>Recibida</Button>
        <Button color="success" variant="contained" onClick={() => apply("refunded")} disabled={set.isPending}>
          Marcar reembolsada
        </Button>
      </DialogActions>
    </Dialog>
  );
}

export default function AdminReturnsList() {
  const [tab, setTab] = useState(0);
  const status = TAB_STATUS[tab] === "all" ? undefined : TAB_STATUS[tab];
  const { data, isLoading } = useAdminReturns({ status });
  const [openId, setOpenId] = useState<number | null>(null);

  return (
    <Box>
      <Tabs value={tab} onChange={(_, v) => setTab(v)} variant="scrollable" sx={{ mb: 2 }}>
        <Tab label="Todas" />
        <Tab label="Solicitadas" />
        <Tab label="Aprobadas" />
        <Tab label="En tránsito" />
        <Tab label="Recibidas" />
        <Tab label="Reembolsadas" />
        <Tab label="Rechazadas" />
      </Tabs>

      {isLoading ? (
        <Box sx={{ display: "flex", justifyContent: "center", py: 4 }}>
          <CircularProgress />
        </Box>
      ) : (
        <Stack spacing={1.5}>
          {(data?.rows || []).map((r) => {
            const meta = STATUS_COLOR[r.status] ?? { color: "default" as const, label: r.status };
            return (
              <Paper key={r.returnId} sx={{ p: 2 }}>
                <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: 2 }}>
                  <Box>
                    <Typography variant="subtitle1" fontWeight={700}>
                      #{r.returnId} — Pedido {r.orderNumber}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      Cliente {r.customerCode} · {new Date(r.requestedAt).toLocaleString()} · {r.itemCount} producto(s)
                    </Typography>
                    <Typography variant="body2" sx={{ mt: 0.5 }}>{r.reason}</Typography>
                  </Box>
                  <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                    <Chip color={meta.color} label={meta.label} size="small" />
                    <Button size="small" variant="outlined" onClick={() => setOpenId(r.returnId)}>Procesar</Button>
                  </Box>
                </Box>
              </Paper>
            );
          })}
          {(data?.rows || []).length === 0 && (
            <Paper sx={{ p: 4, textAlign: "center" }}>
              <Typography variant="body2" color="text.secondary">
                No hay devoluciones en este estado.
              </Typography>
            </Paper>
          )}
        </Stack>
      )}

      {openId && <ReturnDetailDialog returnId={openId} onClose={() => setOpenId(null)} />}
    </Box>
  );
}
