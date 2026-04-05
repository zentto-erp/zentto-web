"use client";

import { useParams, useRouter } from "next/navigation";
import { useEffect, useState, useCallback } from "react";
import {
  Box,
  Typography,
  Paper,
  Button,
  Chip,
  Skeleton,
  Alert,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  Tabs,
  Tab,
  IconButton,
  Collapse,
  Breadcrumbs,
  Link,
  Divider,
} from "@mui/material";
import ShoppingCartIcon from "@mui/icons-material/ShoppingCart";
import ExpandMoreIcon from "@mui/icons-material/ExpandMore";
import ExpandLessIcon from "@mui/icons-material/ExpandLess";
import PaidIcon from "@mui/icons-material/Paid";
import LocalShippingIcon from "@mui/icons-material/LocalShipping";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import { ordersApi } from "@/lib/api";

const PAYMENT_TABS = [
  { label: "Todos", value: "" },
  { label: "Pendiente", value: "pending" },
  { label: "Pagado", value: "paid" },
  { label: "Reembolsado", value: "refunded" },
];

const paymentChipProps: Record<string, { label: string; color: "default" | "warning" | "success" | "error" | "info" }> = {
  pending: { label: "Pendiente", color: "warning" },
  paid: { label: "Pagado", color: "success" },
  refunded: { label: "Reembolsado", color: "error" },
  failed: { label: "Fallido", color: "error" },
};

const fulfillmentChipProps: Record<string, { label: string; color: "default" | "warning" | "success" | "info" }> = {
  unfulfilled: { label: "Sin enviar", color: "default" },
  shipped: { label: "Enviado", color: "info" },
  delivered: { label: "Entregado", color: "success" },
  completed: { label: "Completado", color: "success" },
};

export default function OrdersPage() {
  const params = useParams<{ siteId: string }>();
  const router = useRouter();
  const siteId = params.siteId;

  const [orders, setOrders] = useState<any[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [paymentFilter, setPaymentFilter] = useState("");
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);

  const [expandedId, setExpandedId] = useState<string | null>(null);

  const fetchOrders = useCallback(async () => {
    if (!siteId) return;
    setLoading(true);
    setError(null);
    try {
      const result = await ordersApi.list(siteId, {
        paymentStatus: paymentFilter || undefined,
        limit: rowsPerPage,
        offset: page * rowsPerPage,
      });
      const items = Array.isArray(result) ? result : result?.data ?? result?.orders ?? [];
      const total = result?.totalCount ?? result?.total ?? items.length;
      setOrders(items);
      setTotalCount(total);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, [siteId, paymentFilter, page, rowsPerPage]);

  useEffect(() => {
    fetchOrders();
  }, [fetchOrders]);

  const updateOrderStatus = async (orderId: string, data: any) => {
    setError(null);
    try {
      await ordersApi.update(siteId, orderId, data);
      fetchOrders();
    } catch (err: any) {
      setError(err.message);
    }
  };

  const toggleExpand = (id: string) => {
    setExpandedId((prev) => (prev === id ? null : id));
  };

  return (
    <Box sx={{ p: 3, maxWidth: 1200, mx: "auto" }}>
      {/* Breadcrumbs */}
      <Breadcrumbs sx={{ mb: 2 }}>
        <Link underline="hover" color="inherit" sx={{ cursor: "pointer" }} onClick={() => router.push("/sites")}>
          Mis Sitios
        </Link>
        <Link underline="hover" color="inherit" sx={{ cursor: "pointer" }} onClick={() => router.push(`/sites/${siteId}`)}>
          Sitio
        </Link>
        <Typography color="text.primary">Pedidos</Typography>
      </Breadcrumbs>

      {/* Header */}
      <Box sx={{ display: "flex", alignItems: "center", justifyContent: "space-between", mb: 3, flexWrap: "wrap", gap: 2 }}>
        <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
          <ShoppingCartIcon color="primary" sx={{ fontSize: 32 }} />
          <Typography variant="h4" fontWeight={700}>
            Pedidos
          </Typography>
        </Box>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {/* Filters */}
      <Paper sx={{ mb: 3 }}>
        <Tabs
          value={paymentFilter}
          onChange={(_, v) => { setPaymentFilter(v); setPage(0); }}
          sx={{ borderBottom: 1, borderColor: "divider", px: 2 }}
        >
          {PAYMENT_TABS.map((tab) => (
            <Tab key={tab.value} label={tab.label} value={tab.value} />
          ))}
        </Tabs>
      </Paper>

      {/* Table */}
      <Paper>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell sx={{ width: 40 }} />
                <TableCell sx={{ fontWeight: 600 }}># Pedido</TableCell>
                <TableCell sx={{ fontWeight: 600 }}>Cliente</TableCell>
                <TableCell sx={{ fontWeight: 600 }}>Total</TableCell>
                <TableCell sx={{ fontWeight: 600 }}>Pago</TableCell>
                <TableCell sx={{ fontWeight: 600 }}>Envio</TableCell>
                <TableCell sx={{ fontWeight: 600 }}>Fecha</TableCell>
                <TableCell sx={{ fontWeight: 600 }} align="right">Acciones</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {loading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <TableRow key={i}>
                    {Array.from({ length: 8 }).map((_, j) => (
                      <TableCell key={j}><Skeleton /></TableCell>
                    ))}
                  </TableRow>
                ))
              ) : orders.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={8} align="center" sx={{ py: 6 }}>
                    <Typography color="text.secondary">No hay pedidos.</Typography>
                  </TableCell>
                </TableRow>
              ) : (
                orders.map((order) => {
                  const payChip = paymentChipProps[order.paymentStatus] || { label: order.paymentStatus || "?", color: "default" as const };
                  const fulChip = fulfillmentChipProps[order.fulfillmentStatus] || { label: order.fulfillmentStatus || "?", color: "default" as const };
                  const isExpanded = expandedId === order.id;

                  return (
                    <>
                      <TableRow key={order.id} hover>
                        <TableCell>
                          <IconButton size="small" onClick={() => toggleExpand(order.id)}>
                            {isExpanded ? <ExpandLessIcon /> : <ExpandMoreIcon />}
                          </IconButton>
                        </TableCell>
                        <TableCell>
                          <Typography fontWeight={500}>#{order.orderNumber || order.id?.slice(0, 8)}</Typography>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">
                            {order.customer?.name || order.customerName || order.customerEmail || "-"}
                          </Typography>
                          {order.customer?.email && (
                            <Typography variant="caption" color="text.secondary">{order.customer.email}</Typography>
                          )}
                        </TableCell>
                        <TableCell>
                          <Typography fontWeight={500}>
                            ${typeof order.total === "number" ? order.total.toFixed(2) : order.total || "0.00"}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Chip label={payChip.label} color={payChip.color} size="small" />
                        </TableCell>
                        <TableCell>
                          <Chip label={fulChip.label} color={fulChip.color} size="small" variant="outlined" />
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2" color="text.secondary">
                            {order.createdAt ? new Date(order.createdAt).toLocaleDateString("es") : "-"}
                          </Typography>
                        </TableCell>
                        <TableCell align="right" onClick={(e) => e.stopPropagation()}>
                          {order.paymentStatus !== "paid" && (
                            <IconButton
                              size="small"
                              onClick={() => updateOrderStatus(order.id, { paymentStatus: "paid" })}
                              title="Marcar como pagado"
                              color="success"
                            >
                              <PaidIcon fontSize="small" />
                            </IconButton>
                          )}
                          {order.fulfillmentStatus !== "shipped" && order.fulfillmentStatus !== "delivered" && order.fulfillmentStatus !== "completed" && (
                            <IconButton
                              size="small"
                              onClick={() => updateOrderStatus(order.id, { fulfillmentStatus: "shipped" })}
                              title="Marcar como enviado"
                              color="info"
                            >
                              <LocalShippingIcon fontSize="small" />
                            </IconButton>
                          )}
                          {order.fulfillmentStatus !== "completed" && (
                            <IconButton
                              size="small"
                              onClick={() => updateOrderStatus(order.id, { fulfillmentStatus: "completed" })}
                              title="Marcar como completado"
                              color="primary"
                            >
                              <CheckCircleIcon fontSize="small" />
                            </IconButton>
                          )}
                        </TableCell>
                      </TableRow>
                      <TableRow key={`${order.id}-detail`}>
                        <TableCell colSpan={8} sx={{ py: 0, borderBottom: isExpanded ? undefined : "none" }}>
                          <Collapse in={isExpanded} timeout="auto" unmountOnExit>
                            <Box sx={{ py: 2, px: 2 }}>
                              {/* Items */}
                              {order.items && order.items.length > 0 && (
                                <Box sx={{ mb: 2 }}>
                                  <Typography variant="subtitle2" gutterBottom>Articulos</Typography>
                                  <Table size="small">
                                    <TableHead>
                                      <TableRow>
                                        <TableCell>Producto</TableCell>
                                        <TableCell>Cantidad</TableCell>
                                        <TableCell>Precio</TableCell>
                                        <TableCell>Subtotal</TableCell>
                                      </TableRow>
                                    </TableHead>
                                    <TableBody>
                                      {order.items.map((item: any, idx: number) => (
                                        <TableRow key={idx}>
                                          <TableCell>{item.name || item.productName || "-"}</TableCell>
                                          <TableCell>{item.quantity ?? 1}</TableCell>
                                          <TableCell>${typeof item.price === "number" ? item.price.toFixed(2) : item.price}</TableCell>
                                          <TableCell>${typeof item.subtotal === "number" ? item.subtotal.toFixed(2) : ((item.price || 0) * (item.quantity || 1)).toFixed(2)}</TableCell>
                                        </TableRow>
                                      ))}
                                    </TableBody>
                                  </Table>
                                </Box>
                              )}

                              {/* Addresses */}
                              <Box sx={{ display: "flex", gap: 4, flexWrap: "wrap", mb: 2 }}>
                                {order.shippingAddress && (
                                  <Box>
                                    <Typography variant="subtitle2" gutterBottom>Direccion de envio</Typography>
                                    <Typography variant="body2" color="text.secondary">
                                      {order.shippingAddress.line1 || order.shippingAddress.address}
                                      {order.shippingAddress.city && `, ${order.shippingAddress.city}`}
                                      {order.shippingAddress.state && `, ${order.shippingAddress.state}`}
                                      {order.shippingAddress.zip && ` ${order.shippingAddress.zip}`}
                                    </Typography>
                                  </Box>
                                )}
                                {order.billingAddress && (
                                  <Box>
                                    <Typography variant="subtitle2" gutterBottom>Direccion de facturacion</Typography>
                                    <Typography variant="body2" color="text.secondary">
                                      {order.billingAddress.line1 || order.billingAddress.address}
                                      {order.billingAddress.city && `, ${order.billingAddress.city}`}
                                      {order.billingAddress.state && `, ${order.billingAddress.state}`}
                                      {order.billingAddress.zip && ` ${order.billingAddress.zip}`}
                                    </Typography>
                                  </Box>
                                )}
                              </Box>

                              {/* Notes */}
                              {order.notes && (
                                <Box>
                                  <Typography variant="subtitle2" gutterBottom>Notas</Typography>
                                  <Typography variant="body2" color="text.secondary">{order.notes}</Typography>
                                </Box>
                              )}
                            </Box>
                          </Collapse>
                        </TableCell>
                      </TableRow>
                    </>
                  );
                })
              )}
            </TableBody>
          </Table>
        </TableContainer>
        <TablePagination
          component="div"
          count={totalCount}
          page={page}
          onPageChange={(_, p) => setPage(p)}
          rowsPerPage={rowsPerPage}
          onRowsPerPageChange={(e) => { setRowsPerPage(parseInt(e.target.value, 10)); setPage(0); }}
          rowsPerPageOptions={[5, 10, 25]}
          labelRowsPerPage="Filas por pagina"
        />
      </Paper>
    </Box>
  );
}
