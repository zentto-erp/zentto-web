"use client";

import { useState } from "react";
import { Box, Button, TextField, Alert, Stack, Typography, Paper, Divider, Checkbox, FormControlLabel } from "@mui/material";
import AssignmentReturnIcon from "@mui/icons-material/AssignmentReturn";
import { useCreateReturn } from "../hooks/useReturns";

interface OrderLine {
  lineNumber?: number;
  productCode: string;
  productName: string;
  quantity: number;
  unitPrice: number;
}

interface Props {
  orderNumber: string;
  lines: OrderLine[];
  onCreated?: (returnId: number) => void;
  onCancel?: () => void;
}

export default function ReturnRequestForm({ orderNumber, lines, onCreated, onCancel }: Props) {
  const [reason, setReason] = useState("");
  const [selected, setSelected] = useState<Record<string, { checked: boolean; quantity: number; reason: string }>>(
    () => Object.fromEntries(lines.map((l) => [l.productCode, { checked: true, quantity: l.quantity, reason: "" }]))
  );
  const [error, setError] = useState("");
  const create = useCreateReturn();

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    if (!reason.trim()) {
      setError("Por favor describe el motivo de la devolución");
      return;
    }
    const picked = lines
      .filter((l) => selected[l.productCode]?.checked)
      .map((l) => ({
        lineNumber: l.lineNumber,
        productCode: l.productCode,
        productName: l.productName,
        quantity: selected[l.productCode]?.quantity || l.quantity,
        unitPrice: l.unitPrice,
        reason: selected[l.productCode]?.reason || undefined,
      }));
    if (!picked.length) {
      setError("Selecciona al menos un producto a devolver");
      return;
    }
    try {
      const result = await create.mutateAsync({ orderNumber, reason: reason.trim(), items: picked });
      if (result.ok && result.returnId) {
        onCreated?.(result.returnId);
      } else {
        setError(result.message || "No se pudo crear la devolución");
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  return (
    <Paper component="form" onSubmit={submit} sx={{ p: 3, maxWidth: 720 }}>
      <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 2 }}>
        <AssignmentReturnIcon color="primary" />
        <Typography variant="h6" fontWeight={700}>
          Solicitar devolución — Pedido {orderNumber}
        </Typography>
      </Box>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      <TextField
        label="Motivo general de la devolución"
        value={reason}
        onChange={(e) => setReason(e.target.value)}
        fullWidth
        multiline
        rows={2}
        required
        sx={{ mb: 2 }}
        placeholder="Ej: Producto defectuoso, talla incorrecta, no era lo esperado…"
      />

      <Typography variant="subtitle2" sx={{ mb: 1 }}>
        Productos a devolver
      </Typography>
      <Divider sx={{ mb: 1 }} />

      <Stack spacing={1.5}>
        {lines.map((line) => {
          const sel = selected[line.productCode];
          return (
            <Box key={line.productCode} sx={{ display: "flex", alignItems: "center", gap: 2, py: 1, borderBottom: "1px solid #f0f0f0" }}>
              <FormControlLabel
                control={
                  <Checkbox
                    checked={!!sel?.checked}
                    onChange={(e) => setSelected({ ...selected, [line.productCode]: { ...sel, checked: e.target.checked, quantity: sel?.quantity ?? line.quantity, reason: sel?.reason ?? "" } })}
                  />
                }
                label={
                  <Box>
                    <Typography variant="body2" fontWeight={600}>{line.productName}</Typography>
                    <Typography variant="caption" color="text.secondary">
                      {line.productCode} — Comprado: {line.quantity}
                    </Typography>
                  </Box>
                }
                sx={{ flex: 1, m: 0 }}
              />
              <TextField
                size="small"
                type="number"
                label="Cant."
                value={sel?.quantity ?? line.quantity}
                onChange={(e) => setSelected({ ...selected, [line.productCode]: { ...sel, checked: !!sel?.checked, quantity: Number(e.target.value), reason: sel?.reason ?? "" } })}
                inputProps={{ min: 1, max: line.quantity }}
                sx={{ width: 80 }}
                disabled={!sel?.checked}
              />
              <TextField
                size="small"
                label="Motivo (opcional)"
                value={sel?.reason ?? ""}
                onChange={(e) => setSelected({ ...selected, [line.productCode]: { ...sel, checked: !!sel?.checked, quantity: sel?.quantity ?? line.quantity, reason: e.target.value } })}
                sx={{ flex: "0 1 240px" }}
                disabled={!sel?.checked}
              />
            </Box>
          );
        })}
      </Stack>

      <Box sx={{ mt: 3, display: "flex", gap: 1, justifyContent: "flex-end" }}>
        {onCancel && (
          <Button onClick={onCancel} disabled={create.isPending}>
            Cancelar
          </Button>
        )}
        <Button type="submit" variant="contained" disabled={create.isPending}>
          {create.isPending ? "Enviando…" : "Enviar solicitud"}
        </Button>
      </Box>
    </Paper>
  );
}
