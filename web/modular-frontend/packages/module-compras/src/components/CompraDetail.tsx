"use client";

import { useState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  Button,
  Chip,
  CircularProgress,
  Divider,
  Grid,
  IconButton,
  Paper,
  Stack,
  Step,
  StepLabel,
  Stepper,
  Tooltip,
  Typography,
} from "@mui/material";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import PrintIcon from "@mui/icons-material/Print";
import BlockIcon from "@mui/icons-material/Block";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import InventoryIcon from "@mui/icons-material/Inventory";
import AccountBalanceWalletIcon from "@mui/icons-material/AccountBalanceWallet";
import LocalShippingIcon from "@mui/icons-material/LocalShipping";
import { ConfirmDialog } from "@zentto/shared-ui";
import type { ColumnDef, GridRow } from "@zentto/datagrid-core";
import { useCompraById, useDetalleCompra, useIndicadoresCompra } from "../hooks/useCompras";
import { useTimezone } from "@zentto/shared-auth";
import { formatDate } from "@zentto/shared-api";

interface CompraDetailProps {
  numFact: string;
}

type CompraDetalleRow = Record<string, any>;

const STEPS = ["Emitida", "Recibida", "Pagada"];

function getActiveStep(row: Record<string, any> | null, ind: Record<string, any> | null): number {
  if (!row) return 0;
  if (ind?.cxp?.generado && Number(ind?.cxp?.pendienteTotal || 0) === 0) return 2;
  if (ind?.recepcion?.recibida) return 1;
  return 0;
}

function isAnulada(row: Record<string, any> | null): boolean {
  if (!row) return false;
  const status = String(row.ESTATUS || row.STATUS || row.Estado || "").toUpperCase();
  return status === "ANULADA" || status === "ANULADO" || status === "VOID";
}

const COLUMNS: ColumnDef[] = [
  { field: "CODIGO", header: "Codigo", width: 120, sortable: true },
  { field: "DESCRIPCION", header: "Descripcion", flex: 1, minWidth: 200, sortable: true },
  { field: "CANTIDAD", header: "Cant.", width: 100, type: "number", aggregation: "sum" },
  { field: "PRECIO_COSTO", header: "P. Unit.", width: 120, type: "number", currency: "VES" },
  { field: "ALICUOTA", header: "IVA %", width: 90, type: "number" },
  { field: "SUBTOTAL", header: "Total", width: 130, type: "number", currency: "VES", aggregation: "sum" },
];

export default function CompraDetail({ numFact }: CompraDetailProps) {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const compra = useCompraById(numFact);
  const detalle = useDetalleCompra(numFact);
  const indicadores = useIndicadoresCompra(numFact);

  const [anularOpen, setAnularOpen] = useState(false);
  const [registered, setRegistered] = useState(false);
  const gridRef = useRef<any>(null);

  const row = (compra.data ?? null) as Record<string, any> | null;
  const detRows = (detalle.data ?? []) as CompraDetalleRow[];
  const ind = (indicadores.data ?? null) as Record<string, any> | null;

  const anulada = isAnulada(row);
  const activeStep = getActiveStep(row, ind);

  // Calcular totales
  const subtotal = detRows.reduce((acc, d) => {
    return acc + Number(d.CANTIDAD || 0) * Number(d.PRECIO_COSTO || 0);
  }, 0);
  const totalIva = detRows.reduce((acc, d) => {
    const base = Number(d.CANTIDAD || 0) * Number(d.PRECIO_COSTO || 0);
    const alicuota = Number(d.Alicuota ?? d.ALICUOTA ?? 0);
    return acc + base * (alicuota / 100);
  }, 0);
  const total = Number(row?.TOTAL || 0) || subtotal + totalIva;

  // Rows con id y campos calculados
  const gridRows: GridRow[] = detRows.map((d, idx) => {
    const c = Number(d.CANTIDAD || 0);
    const p = Number(d.PRECIO_COSTO || 0);
    const alicuota = Number(d.Alicuota ?? d.ALICUOTA ?? 0);
    return {
      id: d.ID || d.CODIGO ? `${d.CODIGO}_${idx}` : idx,
      ...d,
      CANTIDAD: c,
      PRECIO_COSTO: p,
      ALICUOTA: alicuota,
      SUBTOTAL: c * p * (1 + alicuota / 100),
    };
  });

  // Register web component
  useEffect(() => {
    import("@zentto/datagrid").then(() => setRegistered(true));
  }, []);

  // Bind data to grid
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = gridRows;
    el.loading = detalle.isLoading;
  }, [gridRows, detalle.isLoading, registered]);

  const handleAnular = async () => {
    // TODO: integrar con API de anulacion
    setAnularOpen(false);
  };

  return (
    <Box sx={{ maxWidth: 1100, mx: "auto" }}>
      {/* -- Header -- */}
      <Paper sx={{ px: 3, py: 2, mb: 2 }}>
        <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <Stack direction="row" alignItems="center" spacing={1.5}>
            <Tooltip title="Volver a compras">
              <IconButton onClick={() => router.push("/compras")} size="small">
                <ArrowBackIcon />
              </IconButton>
            </Tooltip>
            <Typography variant="h5" sx={{ fontWeight: 700, letterSpacing: -0.5 }}>
              COMPRA #{numFact}
            </Typography>
            {row?.TIPO && (
              <Chip
                label={String(row.TIPO).toUpperCase()}
                size="small"
                color="primary"
                variant="outlined"
              />
            )}
            {row?.MONEDA && (
              <Chip label={String(row.MONEDA)} size="small" variant="outlined" />
            )}
          </Stack>
          <Stack direction="row" spacing={1}>
            {!anulada && (
              <Tooltip title="Anular compra">
                <Button
                  variant="outlined"
                  color="error"
                  size="small"
                  startIcon={<BlockIcon />}
                  onClick={() => setAnularOpen(true)}
                >
                  Anular
                </Button>
              </Tooltip>
            )}
            <Tooltip title="Imprimir">
              <IconButton size="small" onClick={() => window.print()}>
                <PrintIcon />
              </IconButton>
            </Tooltip>
          </Stack>
        </Box>
      </Paper>

      {/* -- Status Stepper / Anulada -- */}
      <Paper sx={{ px: 3, py: 2, mb: 2 }}>
        {anulada ? (
          <Box sx={{ textAlign: "center", py: 1 }}>
            <Chip
              label="ANULADA"
              color="error"
              size="medium"
              icon={<BlockIcon />}
              sx={{ fontSize: "0.95rem", fontWeight: 700, px: 2, py: 0.5 }}
            />
          </Box>
        ) : (
          <Stepper activeStep={activeStep} alternativeLabel>
            {STEPS.map((label) => (
              <Step key={label}>
                <StepLabel>{label}</StepLabel>
              </Step>
            ))}
          </Stepper>
        )}
      </Paper>

      {/* -- Proveedor + Documento -- */}
      <Grid container spacing={2} sx={{ mb: 2 }}>
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2.5, height: "100%" }}>
            <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 1.5, textTransform: "uppercase", letterSpacing: 0.5, fontSize: "0.75rem" }}>
              Proveedor
            </Typography>
            <Typography variant="body1" sx={{ fontWeight: 600, mb: 0.5 }}>
              {row?.NOMBRE || row?.COD_PROVEEDOR || "\u2014"}
            </Typography>
            {row?.RIF && (
              <Typography variant="body2" color="text.secondary">
                RIF: {String(row.RIF)}
              </Typography>
            )}
            {row?.EMAIL && (
              <Typography variant="body2" color="text.secondary">
                Email: {String(row.EMAIL)}
              </Typography>
            )}
            {row?.TELEFONO && (
              <Typography variant="body2" color="text.secondary">
                Tel: {String(row.TELEFONO)}
              </Typography>
            )}
            {row?.DIRECCION && (
              <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
                {String(row.DIRECCION)}
              </Typography>
            )}
          </Paper>
        </Grid>
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2.5, height: "100%" }}>
            <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 1.5, textTransform: "uppercase", letterSpacing: 0.5, fontSize: "0.75rem" }}>
              Documento
            </Typography>
            <Grid container spacing={1}>
              <Grid item xs={6}>
                <Typography variant="body2" color="text.secondary">Fecha</Typography>
                <Typography variant="body1" sx={{ fontWeight: 500 }}>
                  {row?.FECHA ? formatDate(row.FECHA, { timeZone }) : "\u2014"}
                </Typography>
              </Grid>
              <Grid item xs={6}>
                <Typography variant="body2" color="text.secondary">Tipo</Typography>
                <Typography variant="body1" sx={{ fontWeight: 500 }}>
                  {row?.TIPO || "\u2014"}
                </Typography>
              </Grid>
              <Grid item xs={6}>
                <Typography variant="body2" color="text.secondary">Vencimiento</Typography>
                <Typography variant="body1" sx={{ fontWeight: 500 }}>
                  {row?.FECHA_VENCIMIENTO ? formatDate(row.FECHA_VENCIMIENTO, { timeZone }) : "\u2014"}
                </Typography>
              </Grid>
              <Grid item xs={6}>
                <Typography variant="body2" color="text.secondary">Moneda</Typography>
                <Typography variant="body1" sx={{ fontWeight: 500 }}>
                  {row?.MONEDA || "VES"}
                </Typography>
              </Grid>
            </Grid>
            {row?.CONCEPTO && (
              <>
                <Divider sx={{ my: 1.5 }} />
                <Typography variant="body2" color="text.secondary">Concepto</Typography>
                <Typography variant="body2">{String(row.CONCEPTO)}</Typography>
              </>
            )}
          </Paper>
        </Grid>
      </Grid>

      {/* -- Lineas de detalle -- */}
      <Paper sx={{ p: 2.5, mb: 2 }}>
        <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 1.5, textTransform: "uppercase", letterSpacing: 0.5, fontSize: "0.75rem" }}>
          Lineas de compra
        </Typography>

        {!registered ? (
          <Box sx={{ display: "flex", justifyContent: "center", py: 4 }}>
            <CircularProgress />
          </Box>
        ) : (
          <zentto-grid
            ref={gridRef}
            default-currency="VES"
            export-filename="compra-detalle"
            height="350px"
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

        {/* -- Totales -- */}
        <Divider sx={{ my: 2 }} />
        <Box sx={{ display: "flex", justifyContent: "flex-end" }}>
          <Box sx={{ minWidth: 260 }}>
            <Stack direction="row" justifyContent="space-between" sx={{ mb: 0.5 }}>
              <Typography variant="body2" color="text.secondary">Subtotal</Typography>
              <Typography variant="body2">{subtotal.toFixed(2)}</Typography>
            </Stack>
            <Stack direction="row" justifyContent="space-between" sx={{ mb: 0.5 }}>
              <Typography variant="body2" color="text.secondary">IVA</Typography>
              <Typography variant="body2">{totalIva.toFixed(2)}</Typography>
            </Stack>
            <Divider sx={{ my: 1 }} />
            <Stack direction="row" justifyContent="space-between">
              <Typography variant="h6" sx={{ fontWeight: 700 }}>TOTAL</Typography>
              <Typography variant="h6" sx={{ fontWeight: 700 }}>
                {total.toFixed(2)}
              </Typography>
            </Stack>
          </Box>
        </Box>
      </Paper>

      {/* -- Indicadores de proceso -- */}
      <Paper sx={{ p: 2.5 }}>
        <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 1.5, textTransform: "uppercase", letterSpacing: 0.5, fontSize: "0.75rem" }}>
          Indicadores de proceso
        </Typography>
        <Stack spacing={1.5}>
          {/* Inventario */}
          <Stack direction="row" alignItems="center" spacing={1.5}>
            <InventoryIcon
              color={ind?.inventario?.impactado ? "success" : "disabled"}
              fontSize="small"
            />
            <Typography variant="body2" sx={{ fontWeight: 500 }}>
              {ind?.inventario?.impactado
                ? `Inventario impactado (${Number(ind?.inventario?.movimientos || 0)} movimientos)`
                : "Inventario sin impactar"}
            </Typography>
            <Chip
              size="small"
              label={ind?.inventario?.impactado ? "Completado" : "Pendiente"}
              color={ind?.inventario?.impactado ? "success" : "default"}
              variant="outlined"
            />
          </Stack>

          {/* CxP */}
          <Stack direction="row" alignItems="center" spacing={1.5}>
            <AccountBalanceWalletIcon
              color={ind?.cxp?.generado ? "success" : "disabled"}
              fontSize="small"
            />
            <Typography variant="body2" sx={{ fontWeight: 500 }}>
              {ind?.cxp?.generado
                ? `CxP generado (Pendiente: ${Number(ind?.cxp?.pendienteTotal || 0).toFixed(2)})`
                : "CxP no generado"}
            </Typography>
            <Chip
              size="small"
              label={ind?.cxp?.generado ? (Number(ind?.cxp?.pendienteTotal || 0) === 0 ? "Pagado" : "Pendiente") : "Sin generar"}
              color={ind?.cxp?.generado ? (Number(ind?.cxp?.pendienteTotal || 0) === 0 ? "success" : "warning") : "default"}
              variant="outlined"
            />
          </Stack>

          {/* Recepcion */}
          <Stack direction="row" alignItems="center" spacing={1.5}>
            <LocalShippingIcon
              color={ind?.recepcion?.recibida ? "success" : "disabled"}
              fontSize="small"
            />
            <Typography variant="body2" sx={{ fontWeight: 500 }}>
              {ind?.recepcion?.recibida
                ? "Recepcion completada"
                : "Recepcion pendiente"}
            </Typography>
            <Chip
              size="small"
              label={ind?.recepcion?.recibida ? "Completado" : "Pendiente"}
              color={ind?.recepcion?.recibida ? "success" : "default"}
              variant="outlined"
            />
          </Stack>
        </Stack>
      </Paper>

      {/* -- Dialogo de anulacion -- */}
      <ConfirmDialog
        open={anularOpen}
        onClose={() => setAnularOpen(false)}
        onConfirm={handleAnular}
        title="Anular compra"
        message={`\u00bfEstas seguro de anular la compra ${numFact}? Esta accion revertira el impacto en inventario y CxP.`}
        confirmLabel="Anular"
        variant="danger"
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
