"use client";

import { useEffect, useRef, useState } from "react";
import { Box, Typography, CircularProgress } from "@mui/material";
import type { ColumnDef } from "@zentto/datagrid-core";

const SVG_VIEW = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>';

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
}

const COLUMNS: ColumnDef[] = [
  { field: "orderNumber", header: "Pedido", flex: 1, sortable: true },
  { field: "orderDate", header: "Fecha", flex: 1, type: "date", sortable: true },
  { field: "totalAmount", header: "Total", flex: 1, type: "number", currency: "USD", aggregation: "sum" },
  {
    field: "isPaid",
    header: "Estado",
    flex: 1,
    sortable: true,
    groupable: true,
    statusColors: { S: "success", N: "warning" },
    statusVariant: "outlined",
  },
];

export default function OrderHistory({ orders, loading, onViewOrder }: Props) {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);

  useEffect(() => {
    import("@zentto/datagrid").then(() => setRegistered(true));
  }, []);

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
    el.actionButtons = [
      { icon: SVG_VIEW, label: "Ver pedido", action: "view", color: "#6b7280" },
    ];
  }, [rows, loading, registered]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "view" && onViewOrder) onViewOrder(row.orderNumber);
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, rows, onViewOrder]);

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

  if (!registered) {
    return <Box sx={{ display: "flex", justifyContent: "center", py: 4 }}><CircularProgress /></Box>;
  }

  return (
    <zentto-grid
      ref={gridRef}
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
