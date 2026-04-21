"use client";

import * as React from "react";
import {
  Box, Card, CardContent, Chip, CircularProgress, IconButton,
  MenuItem, Stack, TextField, Tooltip, Typography, LinearProgress,
} from "@mui/material";
import RefreshIcon from "@mui/icons-material/Refresh";
import TrendingUpIcon from "@mui/icons-material/TrendingUp";
import HourglassEmptyIcon from "@mui/icons-material/HourglassEmpty";
import ErrorOutlineIcon from "@mui/icons-material/ErrorOutline";
import ReceiptLongIcon from "@mui/icons-material/ReceiptLong";
import {
  usePaymentTransactions,
  usePaymentsDashboard,
  type PaymentTransaction,
} from "../../../hooks/usePaymentAccounts";

const STATUS_COLOR: Record<string, "success" | "warning" | "error" | "default" | "info"> = {
  paid: "success", pending: "warning", processing: "info",
  failed: "error", cancelled: "default", refunded: "info", expired: "default",
};
const STATUS_LABEL: Record<string, string> = {
  paid: "Pagado", pending: "Pendiente", processing: "Procesando",
  failed: "Fallido", cancelled: "Cancelado", refunded: "Reembolsado", expired: "Expirado",
};
const PROVIDER_COLORS: Record<string, string> = {
  paddle: "#FFC857", stripe: "#635BFF", manual: "#94A3B8",
  binance: "#F0B90B", mercantil: "#0066B3", pago_movil: "#10B981",
  bank_transfer: "#3B82F6", redsys: "#FF6B35",
};
const APP_LABEL: Record<string, string> = {
  tickets: "Tickets", hotel: "Hotel", rental: "Rental", medical: "Medical",
  ecommerce: "Ecommerce", erp: "ERP / SaaS", restaurante: "Restaurante",
  pos: "POS", education: "Education",
};

function formatMoney(amount: number, currency = "USD"): string {
  try { return new Intl.NumberFormat("es-VE", { style: "currency", currency, maximumFractionDigits: 2 }).format(amount); }
  catch { return `$${amount.toFixed(2)}`; }
}
function formatDate(iso: string): string {
  return new Date(iso).toLocaleString("es-VE", { day: "2-digit", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit" });
}

export default function CobrosOnlineDashboard() {
  const today = new Date();
  const monthStart = new Date(today.getFullYear(), today.getMonth(), 1).toISOString().slice(0, 10);
  const todayStr = today.toISOString().slice(0, 10);

  const [from, setFrom] = React.useState<string>(monthStart);
  const [to, setTo] = React.useState<string>(todayStr);
  const [statusFilter, setStatusFilter] = React.useState<string>("");
  const [providerFilter, setProviderFilter] = React.useState<string>("");

  const { data: dashboard, isLoading: dashLoading, refetch: refetchDash } = usePaymentsDashboard({ from, to });
  const { data: txData, isLoading: txLoading, refetch: refetchTx } = usePaymentTransactions({
    from, to,
    status: statusFilter || undefined,
    provider: providerFilter || undefined,
    limit: 100,
  });

  const transactions = txData?.rows ?? [];
  const total = txData?.total ?? 0;
  const handleRefresh = () => { refetchDash(); refetchTx(); };

  return (
    <Box sx={{ p: 3 }}>
      <Stack direction="row" alignItems="center" justifyContent="space-between" sx={{ mb: 3 }}>
        <Box>
          <Typography variant="body2" color="text.secondary">
            Todas las transacciones de tus apps (tickets, hotel, ecommerce, etc.) en un solo lugar — sin entrar a Paddle/Stripe.
          </Typography>
        </Box>
        <Tooltip title="Actualizar"><IconButton onClick={handleRefresh}><RefreshIcon /></IconButton></Tooltip>
      </Stack>

      <Stack direction={{ xs: "column", md: "row" }} spacing={2} sx={{ mb: 3 }}>
        <TextField label="Desde" type="date" value={from} onChange={(e) => setFrom(e.target.value)} size="small" sx={{ minWidth: 160 }} InputLabelProps={{ shrink: true }} />
        <TextField label="Hasta" type="date" value={to} onChange={(e) => setTo(e.target.value)} size="small" sx={{ minWidth: 160 }} InputLabelProps={{ shrink: true }} />
        <TextField select label="Estado" value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} size="small" sx={{ minWidth: 180 }}>
          <MenuItem value="">Todos</MenuItem>
          {Object.entries(STATUS_LABEL).map(([k, v]) => <MenuItem key={k} value={k}>{v}</MenuItem>)}
        </TextField>
        <TextField select label="Proveedor" value={providerFilter} onChange={(e) => setProviderFilter(e.target.value)} size="small" sx={{ minWidth: 180 }}>
          <MenuItem value="">Todos</MenuItem>
          {Object.keys(PROVIDER_COLORS).map((p) => <MenuItem key={p} value={p}>{p}</MenuItem>)}
        </TextField>
      </Stack>

      {dashLoading ? <LinearProgress sx={{ mb: 3 }} /> : (
        <Box sx={{ display: "grid", gridTemplateColumns: { xs: "1fr", sm: "repeat(2, 1fr)", md: "repeat(4, 1fr)" }, gap: 2, mb: 3 }}>
          <SummaryCard icon={<TrendingUpIcon sx={{ color: "#10B981" }} />} title="Cobrado" value={formatMoney(dashboard?.totalPaid ?? 0)} subtitle={`${dashboard?.totalTransactions ?? 0} transacciones totales`} color="#10B981" />
          <SummaryCard icon={<HourglassEmptyIcon sx={{ color: "#F59E0B" }} />} title="Pendiente" value={formatMoney(dashboard?.totalPending ?? 0)} subtitle="Esperando pago del cliente" color="#F59E0B" />
          <SummaryCard icon={<ErrorOutlineIcon sx={{ color: "#EF4444" }} />} title="Fallidos" value={formatMoney(dashboard?.totalFailed ?? 0)} subtitle="Cancelados / expirados / rechazados" color="#EF4444" />
          <SummaryCard icon={<ReceiptLongIcon sx={{ color: "#6366F1" }} />} title="Total" value={String(dashboard?.totalTransactions ?? 0)} subtitle="Operaciones en el período" color="#6366F1" />
        </Box>
      )}

      {!dashLoading && dashboard && (
        <Box sx={{ display: "grid", gridTemplateColumns: { xs: "1fr", md: "1fr 1fr" }, gap: 2, mb: 3 }}>
          <BreakdownCard title="Por proveedor de pago" rows={dashboard.amountByProvider.map((p) => ({ label: p.provider, amount: p.amount, count: p.count, color: PROVIDER_COLORS[p.provider] ?? "#94A3B8" }))} />
          <BreakdownCard title="Por app del ecosistema" rows={dashboard.amountByApp.map((a) => ({ label: APP_LABEL[a.ownerApp] ?? a.ownerApp, amount: a.amount, count: a.count, color: "#6366F1" }))} />
        </Box>
      )}

      <Card variant="outlined">
        <CardContent>
          <Stack direction="row" alignItems="center" justifyContent="space-between" sx={{ mb: 2 }}>
            <Typography variant="subtitle1" fontWeight={700}>Últimas transacciones {total > 0 ? `(${total} en total)` : ""}</Typography>
            {txLoading ? <CircularProgress size={18} /> : null}
          </Stack>
          {transactions.length === 0 && !txLoading ? (
            <Box sx={{ p: 4, textAlign: "center", color: "text.secondary" }}>
              <Typography variant="body2">No hay transacciones en el período seleccionado.</Typography>
            </Box>
          ) : (
            <Box sx={{ display: "grid", gap: 1 }}>
              {transactions.map((t) => <TxRow key={t.TransactionId} tx={t} />)}
            </Box>
          )}
        </CardContent>
      </Card>
    </Box>
  );
}

function SummaryCard({ icon, title, value, subtitle, color }: { icon: React.ReactNode; title: string; value: string; subtitle: string; color: string }) {
  return (
    <Card variant="outlined" sx={{ borderLeft: `4px solid ${color}` }}>
      <CardContent>
        <Stack direction="row" alignItems="center" spacing={1} sx={{ mb: 1 }}>
          {icon}
          <Typography variant="subtitle2" color="text.secondary" sx={{ textTransform: "uppercase", letterSpacing: 0.5 }}>{title}</Typography>
        </Stack>
        <Typography variant="h5" fontWeight={800} sx={{ mb: 0.5 }}>{value}</Typography>
        <Typography variant="caption" color="text.secondary">{subtitle}</Typography>
      </CardContent>
    </Card>
  );
}

function BreakdownCard({ title, rows }: { title: string; rows: Array<{ label: string; amount: number; count: number; color: string }> }) {
  const max = Math.max(1, ...rows.map((r) => r.amount));
  return (
    <Card variant="outlined">
      <CardContent>
        <Typography variant="subtitle2" fontWeight={700} sx={{ mb: 2, textTransform: "uppercase", letterSpacing: 0.5, color: "text.secondary" }}>{title}</Typography>
        {rows.length === 0 ? (
          <Typography variant="body2" color="text.secondary">Sin datos.</Typography>
        ) : (
          <Stack spacing={1.2}>
            {rows.map((r) => (
              <Box key={r.label}>
                <Stack direction="row" alignItems="center" justifyContent="space-between" sx={{ mb: 0.5 }}>
                  <Typography variant="body2" sx={{ textTransform: "capitalize", fontWeight: 600 }}>{r.label}</Typography>
                  <Typography variant="body2" fontWeight={700}>{formatMoney(r.amount)} <Typography component="span" variant="caption" color="text.secondary">· {r.count}</Typography></Typography>
                </Stack>
                <LinearProgress variant="determinate" value={(r.amount / max) * 100} sx={{ height: 6, borderRadius: 3, bgcolor: "grey.200", "& .MuiLinearProgress-bar": { bgcolor: r.color } }} />
              </Box>
            ))}
          </Stack>
        )}
      </CardContent>
    </Card>
  );
}

function TxRow({ tx }: { tx: PaymentTransaction }) {
  const orderId = (tx.Metadata as Record<string, unknown> | null)?.["orderId"] as string | undefined;
  return (
    <Box sx={{ display: "grid", gridTemplateColumns: { xs: "1fr", md: "1fr 100px 110px 130px 110px 140px 90px" }, alignItems: "center", gap: 2, p: 1.5, borderRadius: 1, bgcolor: "grey.50", "&:hover": { bgcolor: "grey.100" } }}>
      <Box sx={{ minWidth: 0 }}>
        <Typography variant="body2" fontWeight={600} noWrap>{tx.CustomerName ?? tx.CustomerEmail ?? "—"}</Typography>
        <Typography variant="caption" color="text.secondary" noWrap>{tx.CustomerEmail ?? "—"}{orderId ? ` · orden ${orderId}` : ""}</Typography>
      </Box>
      <Box sx={{ textAlign: { xs: "left", md: "center" } }}>
        <Chip label={APP_LABEL[tx.OwnerApp] ?? tx.OwnerApp} size="small" variant="outlined" />
      </Box>
      <Box sx={{ textAlign: { xs: "left", md: "center" } }}>
        <Box sx={{ display: "inline-flex", alignItems: "center", gap: 0.5, px: 1, py: 0.3, borderRadius: 1, bgcolor: PROVIDER_COLORS[tx.Provider] ?? "#94A3B8", color: "#fff", fontSize: "0.72rem", fontWeight: 700, textTransform: "uppercase" }}>
          {tx.Provider}
        </Box>
      </Box>
      <Typography variant="body2" sx={{ textAlign: { xs: "left", md: "right" }, fontWeight: 700, fontVariantNumeric: "tabular-nums" }}>{formatMoney(tx.Amount, tx.Currency)}</Typography>
      <Box sx={{ textAlign: { xs: "left", md: "center" } }}>
        <Chip label={STATUS_LABEL[tx.Status] ?? tx.Status} size="small" color={STATUS_COLOR[tx.Status] ?? "default"} />
      </Box>
      <Typography variant="caption" color="text.secondary" sx={{ textAlign: { xs: "left", md: "right" } }}>{formatDate(tx.CreatedAt)}</Typography>
      <Typography variant="caption" sx={{ fontFamily: "monospace", color: "text.secondary", textAlign: { xs: "left", md: "right" }, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{tx.ProviderTxnId.slice(-10)}</Typography>
    </Box>
  );
}
