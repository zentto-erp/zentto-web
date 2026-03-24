"use client";

import React, { useState } from "react";
import {
  Alert,
  Box,
  Button,
  LinearProgress,
  TextField,
  Typography,
} from "@mui/material";
import { ZenttoDataGrid, type ZenttoColDef } from "@zentto/shared-ui";
import {
  useWorkOrderDetail,
  useConsumeMaterial,
} from "../hooks/useManufactura";

/* ─── Props ──────────────────────────────────────────────── */

interface MaterialConsumptionPanelProps {
  workOrderId: number;
}

/* ─── Component ──────────────────────────────────────────── */

export default function MaterialConsumptionPanel({ workOrderId }: MaterialConsumptionPanelProps) {
  const { data: detail, isLoading } = useWorkOrderDetail(workOrderId);
  const consumeMaterial = useConsumeMaterial(workOrderId);

  const [quantities, setQuantities] = useState<Record<number, string>>({});
  const [error, setError] = useState("");
  const [successMsg, setSuccessMsg] = useState("");

  const order = (detail ?? {}) as Record<string, unknown>;
  const materials = (Array.isArray(order.Materials) ? order.Materials : []) as Record<string, unknown>[];
  const status = String(order.Status ?? "DRAFT");
  const canConsume = status === "DRAFT" || status === "IN_PROGRESS";

  /* ─── Build rows with pending calculation ─────────────── */

  const rows = materials.map((m, i) => {
    const planned = Number(m.PlannedQuantity ?? m.Quantity ?? 0);
    const consumed = Number(m.ConsumedQuantity ?? 0);
    const pending = Math.max(planned - consumed, 0);
    return {
      id: m.MaterialConsumptionId ?? m.ProductId ?? i,
      ProductId: m.ProductId,
      ProductCode: m.ProductCode ?? "",
      ProductName: m.ProductName ?? "",
      PlannedQuantity: planned,
      ConsumedQuantity: consumed,
      Pending: pending,
    };
  });

  /* ─── Columns ──────────────────────────────────────────── */

  const columns: ZenttoColDef[] = [
    { field: "ProductCode", headerName: "Codigo", flex: 0.7, minWidth: 90 },
    { field: "ProductName", headerName: "Material", flex: 1.3, minWidth: 140 },
    {
      field: "PlannedQuantity",
      headerName: "Requerida",
      width: 100,
      type: "number",
      aggregation: "sum",
    },
    {
      field: "ConsumedQuantity",
      headerName: "Consumida",
      width: 100,
      type: "number",
      aggregation: "sum",
    },
    {
      field: "Pending",
      headerName: "Pendiente",
      width: 100,
      type: "number",
      aggregation: "sum",
      renderCell: (params) => {
        const val = Number(params.value ?? 0);
        return (
          <Typography
            variant="body2"
            sx={{ fontWeight: 600, color: val > 0 ? "warning.main" : "success.main" }}
          >
            {val.toLocaleString("es")}
          </Typography>
        );
      },
    },
    ...(canConsume ? [{
      field: "consumeInput",
      headerName: "A Consumir",
      width: 120,
      sortable: false,
      filterable: false,
      renderCell: (params: any) => {
        const productId = Number(params.row.ProductId);
        return (
          <TextField
            size="small"
            type="number"
            value={quantities[productId] ?? ""}
            onChange={(e) =>
              setQuantities((prev) => ({ ...prev, [productId]: e.target.value }))
            }
            placeholder="0"
            sx={{ width: 100 }}
            inputProps={{ min: 0, step: 1 }}
          />
        );
      },
    } as ZenttoColDef] : []),
  ];

  /* ─── Handle consume ──────────────────────────────────── */

  const handleConsume = async () => {
    setError("");
    setSuccessMsg("");

    const toConsume = Object.entries(quantities)
      .filter(([, qty]) => Number(qty) > 0)
      .map(([productId, qty]) => ({
        productId: Number(productId),
        quantity: Number(qty),
      }));

    if (toConsume.length === 0) {
      setError("Ingrese al menos una cantidad a consumir");
      return;
    }

    try {
      for (const item of toConsume) {
        await consumeMaterial.mutateAsync(item);
      }
      setQuantities({});
      setSuccessMsg(`Se registraron ${toConsume.length} consumo(s) exitosamente`);
      setTimeout(() => setSuccessMsg(""), 4000);
    } catch (err: any) {
      setError(String(err?.message ?? "Error al registrar consumo"));
    }
  };

  if (isLoading) return <LinearProgress />;

  return (
    <Box sx={{ p: 1 }}>
      <Typography variant="subtitle1" fontWeight={600} sx={{ mb: 2 }}>
        Consumo de Materiales
      </Typography>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
      {successMsg && <Alert severity="success" sx={{ mb: 2 }}>{successMsg}</Alert>}

      <ZenttoDataGrid
        rows={rows}
        columns={columns}
        getRowId={(row) => row.id}
        autoHeight
        disableRowSelectionOnClick
        hideFooter={rows.length <= 10}
        pageSizeOptions={[10, 25]}
        enableClipboard
        sx={{ bgcolor: "background.paper", borderRadius: 1 }}
        mobileVisibleFields={["ProductCode", "Pending"]}
        smExtraFields={["ProductName", "ConsumedQuantity"]}
      />

      {rows.length === 0 && (
        <Typography variant="body2" color="text.secondary" sx={{ textAlign: "center", py: 3 }}>
          No hay materiales definidos en la BOM de esta orden.
        </Typography>
      )}

      {canConsume && rows.length > 0 && (
        <Box sx={{ display: "flex", justifyContent: "flex-end", mt: 2 }}>
          <Button
            variant="contained"
            onClick={handleConsume}
            disabled={consumeMaterial.isPending}
          >
            {consumeMaterial.isPending ? "Registrando..." : "Registrar Consumo"}
          </Button>
        </Box>
      )}
    </Box>
  );
}
