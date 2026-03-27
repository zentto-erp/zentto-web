"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Alert,
  Box,
  Button,
  LinearProgress,
  TextField,
  Typography,
  CircularProgress,
} from "@mui/material";
import {
  useWorkOrderDetail,
  useConsumeMaterial,
} from "../hooks/useManufactura";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useGridLayoutSync } from "@zentto/shared-api";

/* ─── Props ──────────────────────────────────────────────── */

interface MaterialConsumptionPanelProps {
  workOrderId: number;
}

const GRID_ID = "module-manufactura:material-consumption:list";

/* ─── Component ──────────────────────────────────────────── */

export default function MaterialConsumptionPanel({ workOrderId }: MaterialConsumptionPanelProps) {
  const { data: detail, isLoading } = useWorkOrderDetail(workOrderId);
  const consumeMaterial = useConsumeMaterial(workOrderId);

  const [quantities, setQuantities] = useState<Record<number, string>>({});
  const [error, setError] = useState("");
  const [successMsg, setSuccessMsg] = useState("");
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const { ready: layoutReady } = useGridLayoutSync(GRID_ID);

  useEffect(() => {
    if (!layoutReady) return;
    import("@zentto/datagrid").then(() => setRegistered(true));
  }, [layoutReady]);

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

  const columns: ColumnDef[] = [
    { field: "ProductCode", header: "Codigo", flex: 0.7, minWidth: 90 },
    { field: "ProductName", header: "Material", flex: 1.3, minWidth: 140 },
    {
      field: "PlannedQuantity",
      header: "Requerida",
      width: 100,
      type: "number",
      aggregation: "sum",
    },
    {
      field: "ConsumedQuantity",
      header: "Consumida",
      width: 100,
      type: "number",
      aggregation: "sum",
    },
    {
      field: "Pending",
      header: "Pendiente",
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
      header: "A Consumir",
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
    }] : []),
  ];

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = columns;
    el.rows = rows;
    el.loading = isLoading;
  }, [rows, isLoading, registered, columns]);

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

      <zentto-grid
        ref={gridRef}
        grid-id={GRID_ID}
        height="400px"
        enable-toolbar
        enable-header-menu
        enable-clipboard
        enable-quick-search
        enable-context-menu
        enable-status-bar
        enable-configurator
      ></zentto-grid>

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

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
