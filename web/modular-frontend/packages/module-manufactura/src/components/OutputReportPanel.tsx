"use client";

import React, { useState } from "react";
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  Grid,
  LinearProgress,
  TextField,
  Typography,
} from "@mui/material";
import { alpha } from "@mui/material/styles";
import { useWorkOrderDetail, useReportOutput } from "../hooks/useManufactura";

/* ─── Props ──────────────────────────────────────────────── */

interface OutputReportPanelProps {
  workOrderId: number;
}

/* ─── Component ──────────────────────────────────────────── */

export default function OutputReportPanel({ workOrderId }: OutputReportPanelProps) {
  const { data: detail, isLoading } = useWorkOrderDetail(workOrderId);
  const reportOutput = useReportOutput(workOrderId);

  const [quantity, setQuantity] = useState("");
  const [lotNumber, setLotNumber] = useState("");
  const [warehouseId, setWarehouseId] = useState("");
  const [notes, setNotes] = useState("");
  const [error, setError] = useState("");
  const [successMsg, setSuccessMsg] = useState("");

  const order = (detail ?? {}) as Record<string, unknown>;
  const status = String(order.Status ?? "DRAFT");
  const canReport = status === "DRAFT" || status === "IN_PROGRESS";

  const productName = String(order.ProductName ?? order.ProductCode ?? "-");
  const plannedQty = Number(order.PlannedQuantity ?? 0);
  const producedQty = Number(order.ProducedQuantity ?? 0);
  const remainingQty = Math.max(plannedQty - producedQty, 0);
  const progressPct = plannedQty > 0 ? Math.min((producedQty / plannedQty) * 100, 100) : 0;

  /* ─── Handle submit ────────────────────────────────────── */

  const handleSubmit = () => {
    setError("");
    setSuccessMsg("");

    if (!quantity || Number(quantity) <= 0) {
      setError("Ingrese una cantidad valida");
      return;
    }

    reportOutput.mutate(
      {
        quantity: Number(quantity),
        lotNumber: lotNumber || null,
        warehouseId: warehouseId ? Number(warehouseId) : null,
      },
      {
        onSuccess: (res: any) => {
          if (res?.success === false) {
            setError(res.message || "Error al reportar salida");
            return;
          }
          setQuantity("");
          setLotNumber("");
          setWarehouseId("");
          setNotes("");
          setSuccessMsg("Salida de produccion reportada exitosamente");
          setTimeout(() => setSuccessMsg(""), 4000);
        },
        onError: (err: any) => setError(String(err?.message ?? "Error al reportar salida")),
      },
    );
  };

  if (isLoading) return <LinearProgress />;

  return (
    <Box sx={{ p: 1 }}>
      <Typography variant="subtitle1" fontWeight={600} sx={{ mb: 2 }}>
        Reporte de Salida de Produccion
      </Typography>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
      {successMsg && <Alert severity="success" sx={{ mb: 2 }}>{successMsg}</Alert>}

      {/* Product info cards */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={4}>
          <Card sx={{ border: `1px solid ${alpha("#1976d2", 0.2)}`, borderRadius: 2 }}>
            <CardContent sx={{ pb: "12px !important" }}>
              <Typography variant="caption" color="text.secondary" sx={{ textTransform: "uppercase", fontWeight: 600 }}>
                Producto Final
              </Typography>
              <Typography variant="h6" fontWeight={600} sx={{ mt: 0.5 }}>
                {productName}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={6} sm={4}>
          <Card sx={{ border: `1px solid ${alpha("#ff9800", 0.2)}`, borderRadius: 2 }}>
            <CardContent sx={{ pb: "12px !important" }}>
              <Typography variant="caption" color="text.secondary" sx={{ textTransform: "uppercase", fontWeight: 600 }}>
                Planificada
              </Typography>
              <Typography variant="h6" fontWeight={600} sx={{ mt: 0.5, color: "#ff9800" }}>
                {plannedQty.toLocaleString("es")} uds
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={6} sm={4}>
          <Card sx={{ border: `1px solid ${alpha("#4caf50", 0.2)}`, borderRadius: 2 }}>
            <CardContent sx={{ pb: "12px !important" }}>
              <Typography variant="caption" color="text.secondary" sx={{ textTransform: "uppercase", fontWeight: 600 }}>
                Producida
              </Typography>
              <Typography variant="h6" fontWeight={600} sx={{ mt: 0.5, color: "#4caf50" }}>
                {producedQty.toLocaleString("es")} uds
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Progress bar */}
      <Box sx={{ mb: 3 }}>
        <Box sx={{ display: "flex", justifyContent: "space-between", mb: 0.5 }}>
          <Typography variant="caption" color="text.secondary">
            Progreso de produccion
          </Typography>
          <Typography variant="caption" fontWeight={600}>
            {progressPct.toFixed(1)}% ({remainingQty.toLocaleString("es")} pendientes)
          </Typography>
        </Box>
        <LinearProgress
          variant="determinate"
          value={progressPct}
          sx={{
            height: 10,
            borderRadius: 5,
            bgcolor: "grey.200",
            "& .MuiLinearProgress-bar": {
              borderRadius: 5,
              bgcolor: progressPct >= 100 ? "#4caf50" : progressPct >= 50 ? "#ff9800" : "#1976d2",
            },
          }}
        />
      </Box>

      {/* Form */}
      {canReport && (
        <Grid container spacing={2}>
          <Grid item xs={12} sm={4}>
            <TextField
              label="Cantidad Producida"
              value={quantity}
              onChange={(e) => setQuantity(e.target.value)}
              type="number"
              fullWidth
              size="small"
              required
              inputProps={{ min: 1 }}
            />
          </Grid>
          <Grid item xs={12} sm={4}>
            <TextField
              label="Lote (opcional)"
              value={lotNumber}
              onChange={(e) => setLotNumber(e.target.value)}
              fullWidth
              size="small"
            />
          </Grid>
          <Grid item xs={12} sm={4}>
            <TextField
              label="Almacen ID (opcional)"
              value={warehouseId}
              onChange={(e) => setWarehouseId(e.target.value)}
              type="number"
              fullWidth
              size="small"
            />
          </Grid>
          <Grid item xs={12}>
            <TextField
              label="Notas"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              multiline
              rows={2}
              fullWidth
              size="small"
            />
          </Grid>
          <Grid item xs={12}>
            <Box sx={{ display: "flex", justifyContent: "flex-end" }}>
              <Button
                variant="contained"
                onClick={handleSubmit}
                disabled={reportOutput.isPending || !quantity}
              >
                {reportOutput.isPending ? "Reportando..." : "Reportar Salida"}
              </Button>
            </Box>
          </Grid>
        </Grid>
      )}

      {!canReport && (
        <Alert severity="info">
          Esta orden esta en estado {status}. No se pueden reportar salidas.
        </Alert>
      )}
    </Box>
  );
}
