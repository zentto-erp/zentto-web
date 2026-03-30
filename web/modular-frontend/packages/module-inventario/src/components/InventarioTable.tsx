// components/InventarioTable.tsx
"use client";

import { useState, useCallback, useEffect, useRef, useMemo } from "react";
import { useRouter } from "next/navigation";
import { Box, Button, Typography } from "@mui/material";
import { Add as AddIcon } from "@mui/icons-material";
import { useInventarioList } from "../hooks/useInventario";
import { formatCurrency, useGridLayoutSync } from "@zentto/shared-api";
import { useInventarioGridRegistration } from "./zenttoGridPersistence";
import type { ColumnDef } from "@zentto/datagrid-core";

const GRID_ID = "module-inventario:articulos:list";

const COLUMNS: ColumnDef[] = [
  { field: "codigo", header: "Codigo", width: 120, sortable: true },
  { field: "nombre", header: "Articulo", flex: 1, minWidth: 200, sortable: true },
  { field: "categoria", header: "Categoria", width: 140, sortable: true },
  { field: "stock", header: "Stock", width: 90, type: "number", sortable: true },
  { field: "minimo", header: "Minimo", width: 90, type: "number" },
  { field: "costo", header: "Costo", width: 120, type: "number", currency: "VES" },
  { field: "precio", header: "Precio", width: 120, type: "number", currency: "VES" },
  {
    field: "estado", header: "Estado", width: 100,
    statusColors: { Bajo: "error", Normal: "success" },
    statusVariant: "outlined",
  },
  {
    field: "actions", header: "Acciones", type: "actions", width: 80, pin: "right",
    actions: [
      { icon: "view", label: "Ver detalle", action: "view", color: "#6b7280" },
    ],
  },
];

export default function InventarioTable() {
  const router = useRouter();
  const gridRef = useRef<any>(null);
  const [search, setSearch] = useState("");

  const { data: inventario, isLoading } = useInventarioList({
    search,
    limit: 200,
  });

  const rows = (inventario?.rows ?? []) as Record<string, unknown>[];

  const { ready } = useGridLayoutSync(GRID_ID);
  const { registered } = useInventarioGridRegistration(ready);

  const gridRows = useMemo(() => rows.map((item, i) => {
    const codigo = String(item.CODIGO ?? item.ProductCode ?? "");
    const stock = Number(item.EXISTENCIA ?? item.StockQty ?? 0);
    const minimo = Number(item.MINIMO ?? item.StockMin ?? 0);
    return {
      id: i,
      codigo,
      nombre: String(item.DescripcionCompleta ?? item.DESCRIPCION ?? item.ProductName ?? ""),
      categoria: String(item.Categoria ?? ""),
      stock,
      minimo,
      costo: Number(item.PRECIO_COMPRA ?? item.CostPrice ?? 0),
      precio: Number(item.PRECIO_VENTA ?? item.SalesPrice ?? 0),
      estado: minimo > 0 && stock < minimo ? "Bajo" : "Normal",
    };
  }), [rows]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = gridRows;
    el.loading = isLoading;
    el.getRowId = (r: any) => r.id;
  }, [gridRows, isLoading, registered]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "view" && row?.codigo) {
        router.push(`/articulos/${row.codigo}`);
      }
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, router]);

  return (
    <Box sx={{ p: 2 }}>
      {/* Header */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
        <Typography variant="h5" fontWeight={600}>Inventario</Typography>
        <Box sx={{ display: "flex", gap: 1 }}>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => router.push("/articulos/new")}
          >
            Nuevo Articulo
          </Button>
          <Button
            variant="outlined"
            onClick={() => router.push("/ajuste")}
          >
            Ajuste de Inventario
          </Button>
        </Box>
      </Box>

      <zentto-grid
        ref={gridRef}
        grid-id={GRID_ID}
        height="calc(100vh - 200px)"
        default-currency="VES"
        export-filename="inventario"
        enable-toolbar
        enable-header-menu
        enable-header-filters
        enable-clipboard
        enable-quick-search
        enable-context-menu
        enable-status-bar
        enable-configurator
      />
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
