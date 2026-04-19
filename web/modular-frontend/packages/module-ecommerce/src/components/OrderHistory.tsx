"use client";

import { useEffect, useRef } from "react";
import { Box, Typography, CircularProgress } from "@mui/material";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useGridLayoutSync } from "@zentto/shared-api";
import { useEcommerceGridRegistration } from "./zenttoGridPersistence";


interface OrderRow {
  orderNumber: string;
  orderDate: string;
  customerName: string;
  subtotal: number;
  taxAmount: number;
  totalAmount: number;
  isPaid: string;
  isDelivered: string;
}

interface Props {
  orders: OrderRow[];
  loading?: boolean;
  onViewOrder?: (orderNumber: string) => void;
  onRequestReturn?: (orderNumber: string) => void;
}

const COLUMNS: ColumnDef[] = [
  { field: "orderNumber", header: "Pedido", flex: 1, sortable: true },
  { field: "orderDate", header: "Fecha", flex: 1, type: "date", sortable: true },
  { field: "totalAmount", header: "Total", flex: 1, type: "number", currency: "USD", aggregation: "sum" },
  {
    field: "isPaid",
    header: "Pago",
    flex: 1,
    sortable: true,
    groupable: true,
    statusColors: { S: "success", N: "warning" },
    statusVariant: "outlined",
  },
  {
    field: "isDelivered",
    header: "Entrega",
    flex: 1,
    sortable: true,
    groupable: true,
    statusColors: { S: "success", N: "default" },
    statusVariant: "outlined",
  },
  {
    field: "actions",
    header: "Acciones",
    type: "actions",
    width: 120,
    pin: "right",
    actions: [
      { icon: "view", label: "Ver pedido", action: "view", color: "#6b7280" },
      { icon: "assignment_return", label: "Solicitar devolución", action: "return", color: "#f59e0b" },
    ],
  },
];

const GRID_ID = "module-ecommerce:order-history:list";

export default function OrderHistory({ orders, loading, onViewOrder, onRequestReturn }: Props) {
  const gridRef = useRef<any>(null);
  const { ready: gridLayoutReady } = useGridLayoutSync(GRID_ID);
  const { registered } = useEcommerceGridRegistration(gridLayoutReady);

  const rows = orders.map((o) => ({
    ...o,
    id: o.orderNumber,
  }));

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows;
    el.loading = !!loading;
  }, [rows, loading, registered]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "view" && onViewOrder) onViewOrder(row.orderNumber);
      if (action === "return" && onRequestReturn && row.isDelivered === "S") {
        onRequestReturn(row.orderNumber);
      }
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, rows, onViewOrder, onRequestReturn]);

  if (loading) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", py: 4 }}>
        <CircularProgress />
      </Box>
    );
  }

  if (!orders.length) {
    return (
      <Box sx={{ textAlign: "center", py: 4 }}>
        <Typography color="text.secondary">No tienes pedidos aun</Typography>
      </Box>
    );
  }

  if (!gridLayoutReady || !registered) {
    return <Box sx={{ display: "flex", justifyContent: "center", py: 4 }}><CircularProgress /></Box>;
  }

  return (
    <zentto-grid
      ref={gridRef}
      grid-id={GRID_ID}
      default-currency="USD"
      export-filename="order-history"
      height="400px"
      enable-toolbar
      enable-header-menu
      enable-header-filters
      enable-clipboard
      enable-quick-search
      enable-context-menu
      enable-status-bar
      enable-configurator
    ></zentto-grid>
  );
}

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
