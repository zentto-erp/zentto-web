"use client";

import { Box, Typography, CircularProgress, Chip } from "@mui/material";
import { formatDate, formatCurrency } from "@zentto/shared-api";
import { ZenttoDataGrid, type ZenttoColDef } from "@zentto/shared-ui";

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

export default function OrderHistory({ orders, loading, onViewOrder }: Props) {
  const timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";

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

  const columns: ZenttoColDef[] = [
    { field: "orderNumber", headerName: "Pedido", flex: 1 },
    {
      field: "orderDate",
      headerName: "Fecha",
      flex: 1,
      renderCell: (params) => formatDate(params.value, { timeZone }),
    },
    {
      field: "totalAmount",
      headerName: "Total",
      flex: 1,
      type: "number",
      renderCell: (params) => `$${(params.value as number)?.toFixed(2)}`,
    },
    {
      field: "isPaid",
      headerName: "Estado",
      flex: 1,
      renderCell: (params) => (
        <Chip
          size="small"
          label={params.value === "S" ? "Pagado" : "Pendiente"}
          color={params.value === "S" ? "success" : "warning"}
        />
      ),
    },
  ];

  return (
    <ZenttoDataGrid
      rows={orders}
      columns={columns}
      getRowId={(row) => row.orderNumber}
      hideToolbar
      autoHeight
      onRowClick={onViewOrder ? (params) => onViewOrder(params.row.orderNumber) : undefined}
      sx={{ cursor: onViewOrder ? "pointer" : "default" }}
    />
  );
}
