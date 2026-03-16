"use client";

import { Box, Typography, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper, Chip, CircularProgress } from "@mui/material";
import { formatDate } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";

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
  const { timeZone } = useTimezone();
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

  return (
    <TableContainer component={Paper}>
      <Table size="small">
        <TableHead>
          <TableRow>
            <TableCell>Pedido</TableCell>
            <TableCell>Fecha</TableCell>
            <TableCell align="right">Total</TableCell>
            <TableCell>Estado</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {orders.map((o) => (
            <TableRow
              key={o.orderNumber}
              hover
              sx={{ cursor: onViewOrder ? "pointer" : "default" }}
              onClick={() => onViewOrder?.(o.orderNumber)}
            >
              <TableCell>{o.orderNumber}</TableCell>
              <TableCell>{formatDate(o.orderDate, { timeZone })}</TableCell>
              <TableCell align="right">${o.totalAmount?.toFixed(2)}</TableCell>
              <TableCell>
                <Chip
                  size="small"
                  label={o.isPaid === "S" ? "Pagado" : "Pendiente"}
                  color={o.isPaid === "S" ? "success" : "warning"}
                />
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </TableContainer>
  );
}
