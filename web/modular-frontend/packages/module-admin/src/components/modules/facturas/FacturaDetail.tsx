"use client";

import { useEffect, useRef, useState, useMemo } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  Button,
  Chip,
  CircularProgress,
  Divider,
  Paper,
  Step,
  StepLabel,
  Stepper,
  Typography,
  Alert,
  alpha,
} from "@mui/material";
import {
  ArrowBack as ArrowBackIcon,
  Block as BlockIcon,
  PictureAsPdf as PdfIcon,
  CheckCircle as CheckCircleIcon,
  HourglassEmpty as HourglassIcon,
} from "@mui/icons-material";
import { ConfirmDialog } from "@zentto/shared-ui";
import { formatCurrency, toDateOnly, useGridLayoutSync } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { useFacturaById, useDetalleFactura, useDeleteFactura } from "../../../hooks/useFacturas";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useScopedGridId } from "../../../lib/zentto-grid";

// ── Types ───────────────────────────────────────────────────────────────────
interface FacturaDetailProps {
  numeroFactura: string;
}

type DetalleRow = Record<string, unknown>;

// ── Status helpers ──────────────────────────────────────────────────────────
const STEPS = ["Emitida", "Cobrada"];

function getActiveStep(estado: string): number {
  if (estado === "Anulada") return -1;
  if (estado === "CONTADO" || estado === "Cobrada") return 1;
  return 0;
}

function isPaid(estado: string): boolean {
  return estado === "CONTADO" || estado === "Cobrada";
}

// ── Columns for zentto-grid ──────────────────────────────────────────────
const COLUMNS: ColumnDef[] = [
  { field: "codigo", header: "Codigo", flex: 0.8, minWidth: 100 },
  { field: "descripcion", header: "Descripcion", flex: 2, minWidth: 200 },
  { field: "cantidad", header: "Cant.", flex: 0.5, minWidth: 70, type: "number" },
  { field: "precio", header: "Precio", flex: 0.7, minWidth: 90, type: "number", currency: "VES" },
  { field: "alicuota", header: "IVA %", flex: 0.5, minWidth: 70, type: "number" },
  { field: "total", header: "Total", flex: 0.8, minWidth: 100, type: "number", currency: "VES", aggregation: "sum" },
];

// ── Component ───────────────────────────────────────────────────────────────
export default function FacturaDetail({ numeroFactura }: FacturaDetailProps) {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const [anularOpen, setAnularOpen] = useState(false);
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const gridId = useScopedGridId('factura-detail-lineas');
  const { ready: layoutReady } = useGridLayoutSync(gridId);

  useEffect(() => {
    if (!layoutReady) return;
    import("@zentto/datagrid").then(() => setRegistered(true));
  }, [layoutReady]);

  // Queries
  const {
    data: factura,
    isLoading: loadingFactura,
    error: errorFactura,
  } = useFacturaById(numeroFactura);
  const {
    data: detalleRaw,
    isLoading: loadingDetalle,
  } = useDetalleFactura(numeroFactura);
  const { mutateAsync: anularFactura, isPending: isAnulando } = useDeleteFactura();

  const detRows = (Array.isArray(detalleRaw) ? detalleRaw : []) as DetalleRow[];
  const estado = factura?.estado ?? "Emitida";
  const isAnulada = estado === "Anulada";
  const activeStep = getActiveStep(estado);
  const pagada = isPaid(estado);

  // Map rows for the grid
  const gridRows = useMemo(
    () =>
      detRows.map((d, idx) => ({
        id: idx,
        codigo: d.COD_SERV ?? d.CODIGO ?? d.codigo ?? "",
        descripcion: d.DESCRIPCION ?? d.descripcion ?? d.NOMBRE ?? "",
        cantidad: Number(d.CANTIDAD ?? d.cantidad ?? 0),
        precio: Number(d.PRECIO ?? d.precio ?? d.PRECIO_VENTA ?? 0),
        alicuota: Number(d.ALICUOTA ?? d.alicuota ?? 0),
        total: (() => {
          const cant = Number(d.CANTIDAD ?? d.cantidad ?? 0);
          const precio = Number(d.PRECIO ?? d.precio ?? d.PRECIO_VENTA ?? 0);
          const desc = Number(d.DESCUENTO ?? d.descuento ?? 0);
          return cant * precio - desc;
        })(),
      })),
    [detRows]
  );

  // Totals
  const subtotal = detRows.reduce((acc, d) => {
    const cant = Number(d.CANTIDAD ?? d.cantidad ?? 0);
    const precio = Number(d.PRECIO ?? d.precio ?? d.PRECIO_VENTA ?? 0);
    return acc + cant * precio;
  }, 0);
  const totalDescuentos = detRows.reduce(
    (acc, d) => acc + Number(d.DESCUENTO ?? d.descuento ?? 0),
    0
  );
  const baseImponible = subtotal - totalDescuentos;
  const totalIva = detRows.reduce((acc, d) => {
    const cant = Number(d.CANTIDAD ?? d.cantidad ?? 0);
    const precio = Number(d.PRECIO ?? d.precio ?? d.PRECIO_VENTA ?? 0);
    const desc = Number(d.DESCUENTO ?? d.descuento ?? 0);
    const alic = Number(d.ALICUOTA ?? d.alicuota ?? 0);
    return acc + (cant * precio - desc) * (alic / 100);
  }, 0);
  const totalFactura = factura?.totalFactura ?? baseImponible + totalIva;

  // Bind data to web component
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = gridRows;
    el.loading = loadingDetalle;
    // No actionButtons needed — read-only invoice detail line items
  }, [gridRows, loadingDetalle, registered]);

  // Anular handler
  const handleAnular = async () => {
    await anularFactura(numeroFactura);
    setAnularOpen(false);
    router.push("/facturas");
  };

  // ── Loading / Error ─────────────────────────────────────────────────────
  if (loadingFactura || loadingDetalle) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", alignItems: "center", height: 400 }}>
        <CircularProgress />
      </Box>
    );
  }

  if (errorFactura) {
    return (
      <Box sx={{ p: 3 }}>
        <Alert severity="error">
          Error al cargar la factura: {errorFactura instanceof Error ? errorFactura.message : "Error desconocido"}
        </Alert>
        <Button sx={{ mt: 2 }} variant="outlined" startIcon={<ArrowBackIcon />} onClick={() => router.push("/facturas")}>
          Volver
        </Button>
      </Box>
    );
  }

  // ── Render ────────────────────────────────────────────────────────────────
  return (
    <Box sx={{ p: { xs: 1, md: 3 }, maxWidth: 1100, mx: "auto" }}>
      {/* ── Header ─────────────────────────────────────────────────────────── */}
      <Box
        sx={{
          display: "flex",
          flexWrap: "wrap",
          justifyContent: "space-between",
          alignItems: "center",
          mb: 3,
          gap: 1,
        }}
      >
        <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
          <Button
            variant="text"
            startIcon={<ArrowBackIcon />}
            onClick={() => router.push("/facturas")}
            sx={{ minWidth: 0, color: "text.secondary" }}
          >
            Volver
          </Button>
          <Typography variant="h5" sx={{ fontWeight: 700 }}>
            FACTURA #{numeroFactura}
          </Typography>
          {isAnulada && (
            <Chip label="ANULADA" color="error" size="small" sx={{ fontWeight: 700 }} />
          )}
        </Box>
        <Box sx={{ display: "flex", gap: 1 }}>
          {!isAnulada && (
            <Button
              variant="outlined"
              color="error"
              size="small"
              startIcon={<BlockIcon />}
              onClick={() => setAnularOpen(true)}
            >
              Anular
            </Button>
          )}
          <Button variant="outlined" size="small" startIcon={<PdfIcon />} disabled>
            PDF
          </Button>
        </Box>
      </Box>

      {/* ── Status Stepper ─────────────────────────────────────────────────── */}
      {!isAnulada && (
        <Paper sx={{ p: 2, mb: 3 }}>
          <Stepper activeStep={activeStep} alternativeLabel>
            {STEPS.map((label, idx) => (
              <Step key={label} completed={idx <= activeStep}>
                <StepLabel>{label}</StepLabel>
              </Step>
            ))}
          </Stepper>
        </Paper>
      )}

      {/* ── Info Cards ─────────────────────────────────────────────────────── */}
      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: { xs: "1fr", md: "1fr 1fr" },
          gap: 2,
          mb: 3,
        }}
      >
        {/* Cliente */}
        <Paper sx={{ p: 2.5 }}>
          <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 1.5, textTransform: "uppercase", fontSize: "0.7rem", letterSpacing: 1 }}>
            Cliente
          </Typography>
          <Typography variant="body1" sx={{ fontWeight: 600, mb: 0.5 }}>
            {factura?.nombreCliente || "—"}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Codigo: {factura?.codigoCliente || "—"}
          </Typography>
          {factura?.referencia && (
            <Typography variant="body2" color="text.secondary">
              Referencia: {factura.referencia}
            </Typography>
          )}
        </Paper>

        {/* Documento */}
        <Paper sx={{ p: 2.5 }}>
          <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 1.5, textTransform: "uppercase", fontSize: "0.7rem", letterSpacing: 1 }}>
            Documento
          </Typography>
          <Box sx={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 0.5 }}>
            <Typography variant="body2" color="text.secondary">Fecha:</Typography>
            <Typography variant="body2" sx={{ fontWeight: 500 }}>
              {factura?.fecha ? toDateOnly(factura.fecha, timeZone) : "—"}
            </Typography>

            <Typography variant="body2" color="text.secondary">Tipo:</Typography>
            <Typography variant="body2" sx={{ fontWeight: 500 }}>
              {estado === "CONTADO" || estado === "Cobrada" ? "CONTADO" : "CREDITO"}
            </Typography>

            <Typography variant="body2" color="text.secondary">Estado:</Typography>
            <Typography variant="body2" sx={{ fontWeight: 500 }}>
              {estado}
            </Typography>
          </Box>
          {factura?.observaciones && (
            <>
              <Divider sx={{ my: 1 }} />
              <Typography variant="body2" color="text.secondary">
                Obs: {factura.observaciones}
              </Typography>
            </>
          )}
        </Paper>
      </Box>

      {/* ── Lineas (zentto-grid) ────────────────────────────────────────── */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 1.5, textTransform: "uppercase", fontSize: "0.7rem", letterSpacing: 1 }}>
          Lineas de la Factura
        </Typography>
        <Box sx={{ minHeight: 200 }}>
          {registered && (
            <zentto-grid
              ref={gridRef}
              grid-id={gridId}
              default-currency="VES"
              height="300px"
              show-totals
              enable-toolbar
              enable-header-menu
              enable-header-filters
              enable-clipboard
              enable-quick-search
              enable-context-menu
              enable-status-bar
              enable-configurator
            ></zentto-grid>
          )}
        </Box>

        {/* Totales */}
        {detRows.length > 0 && (
          <Box sx={{ mt: 2, display: "flex", justifyContent: "flex-end" }}>
            <Box sx={{ minWidth: 280 }}>
              <Box sx={{ display: "flex", justifyContent: "space-between", mb: 0.5 }}>
                <Typography variant="body2" color="text.secondary">Subtotal:</Typography>
                <Typography variant="body2">{formatCurrency(subtotal)}</Typography>
              </Box>
              {totalDescuentos > 0 && (
                <Box sx={{ display: "flex", justifyContent: "space-between", mb: 0.5 }}>
                  <Typography variant="body2" color="text.secondary">Descuentos:</Typography>
                  <Typography variant="body2" color="error.main">-{formatCurrency(totalDescuentos)}</Typography>
                </Box>
              )}
              <Box sx={{ display: "flex", justifyContent: "space-between", mb: 0.5 }}>
                <Typography variant="body2" color="text.secondary">IVA:</Typography>
                <Typography variant="body2">{formatCurrency(totalIva)}</Typography>
              </Box>
              <Divider sx={{ my: 1 }} />
              <Box sx={{ display: "flex", justifyContent: "space-between" }}>
                <Typography variant="h6" sx={{ fontWeight: 700 }}>TOTAL:</Typography>
                <Typography variant="h6" sx={{ fontWeight: 700, color: "primary.main" }}>
                  {formatCurrency(totalFactura)}
                </Typography>
              </Box>
            </Box>
          </Box>
        )}
      </Paper>

      {/* ── Estado de Pago ─────────────────────────────────────────────────── */}
      <Paper
        sx={{
          p: 2.5,
          display: "flex",
          alignItems: "center",
          gap: 2,
          bgcolor: (t) =>
            isAnulada
              ? alpha(t.palette.error.main, 0.06)
              : pagada
                ? alpha(t.palette.success.main, 0.06)
                : alpha(t.palette.warning.main, 0.06),
          border: 1,
          borderColor: isAnulada
            ? "error.light"
            : pagada
              ? "success.light"
              : "warning.light",
        }}
      >
        {isAnulada ? (
          <BlockIcon color="error" />
        ) : pagada ? (
          <CheckCircleIcon color="success" />
        ) : (
          <HourglassIcon color="warning" />
        )}
        <Box>
          <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
            {isAnulada ? "Factura Anulada" : pagada ? "Pagada" : "Pendiente de Cobro"}
          </Typography>
          {!isAnulada && (
            <Typography variant="body2" color="text.secondary">
              Saldo: {formatCurrency(pagada ? 0 : totalFactura)}
            </Typography>
          )}
        </Box>
      </Paper>

      {/* ── Confirm Anular Dialog ──────────────────────────────────────────── */}
      <ConfirmDialog
        open={anularOpen}
        onClose={() => setAnularOpen(false)}
        onConfirm={handleAnular}
        title="Anular Factura"
        message={`Estas seguro de anular la factura ${numeroFactura}? Esta accion no se puede deshacer.`}
        confirmLabel="Anular"
        variant="danger"
        loading={isAnulando}
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
