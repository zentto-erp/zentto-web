"use client";

import React, { useEffect, useRef, useMemo } from "react";
import {
  Box,
  Card,
  CardContent,
  CardActionArea,
  Typography,
  IconButton,
  Skeleton,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import InventoryIcon from "@mui/icons-material/Inventory";
import WarningAmberIcon from "@mui/icons-material/WarningAmber";
import CategoryIcon from "@mui/icons-material/Category";
import AttachMoneyIcon from "@mui/icons-material/AttachMoney";
import MoreVertIcon from "@mui/icons-material/MoreVert";
import TrendingUpIcon from "@mui/icons-material/TrendingUp";
import TuneIcon from "@mui/icons-material/Tune";
import BrandingWatermarkIcon from "@mui/icons-material/BrandingWatermark";
import LinearScaleIcon from "@mui/icons-material/LinearScale";
import StraightenIcon from "@mui/icons-material/Straighten";
import SwapHorizIcon from "@mui/icons-material/SwapHoriz";
import HistoryIcon from "@mui/icons-material/History";
import MenuBookIcon from "@mui/icons-material/MenuBook";
import LocalOfferIcon from "@mui/icons-material/LocalOffer";
import WarehouseIcon from "@mui/icons-material/Warehouse";
import { useRouter } from "next/navigation";
import { useInventarioDashboard, useMovimientosList } from "../hooks/useInventario";
import { formatCurrency, useGridLayoutSync } from "@zentto/shared-api";
import { brandColors } from "@zentto/shared-ui";
import { useInventarioGridRegistration } from "../components/zenttoGridPersistence";
import type { ColumnDef } from "@zentto/datagrid-core";

const MOVS_GRID_ID = "module-inventario:home:ultimos-movimientos";

const MOVS_COLUMNS: ColumnDef[] = [
  { field: "fecha", header: "Fecha", width: 100 },
  { field: "articulo", header: "Articulo", flex: 1, minWidth: 140, sortable: true },
  {
    field: "tipo", header: "Tipo", width: 100,
    statusColors: { ENTRADA: "success", SALIDA: "error", AJUSTE: "info", TRASLADO: "warning" },
    statusVariant: "outlined",
  },
  { field: "cantidad", header: "Cantidad", width: 90, type: "number" },
  { field: "referencia", header: "Referencia", width: 130 },
];

export default function InventarioHome({ basePath = "" }: { basePath?: string }) {
  const router = useRouter();
  const gridRef = useRef<any>(null);
  const bp = basePath.replace(/\/+$/, "");
  const { data: dashboard, isLoading: dashLoading } = useInventarioDashboard();
  const { data: ultMovs } = useMovimientosList({ limit: 5 });

  const { ready } = useGridLayoutSync(MOVS_GRID_ID);
  const { registered } = useInventarioGridRegistration(ready);

  const statsCards = [
    {
      title: "Total Articulos",
      value: dashboard ? String(dashboard.TotalArticulos) : "\u2014",
      subtitle: "En sistema",
      loading: dashLoading,
      color: brandColors.statBlue,
      chartType: "bar" as const,
    },
    {
      title: "Bajo Stock",
      value: dashboard ? String(dashboard.BajoStock) : "\u2014",
      subtitle: "Requieren atencion",
      loading: dashLoading,
      color: brandColors.statRed,
      chartType: "line" as const,
    },
    {
      title: "Categorias",
      value: dashboard ? String(dashboard.TotalCategorias) : "\u2014",
      subtitle: "Catalogos",
      loading: dashLoading,
      color: brandColors.statTeal,
      chartType: "bar" as const,
    },
    {
      title: "Valor Inventario",
      value: dashboard ? formatCurrency(dashboard.ValorInventario) : "\u2014",
      subtitle: "Costo total",
      loading: dashLoading,
      color: brandColors.statOrange,
      chartType: "line" as const,
    },
  ];

  const shortcuts = [
    { title: "Articulos", description: "Gestion de productos", icon: <InventoryIcon sx={{ fontSize: 32 }} />, href: `${bp}/articulos`, bg: brandColors.shortcutGreen },
    { title: "Ajuste Inventario", description: "Entradas y salidas", icon: <TuneIcon sx={{ fontSize: 32 }} />, href: `${bp}/ajuste`, bg: brandColors.shortcutDark },
    { title: "Movimientos", description: "Historial completo", icon: <HistoryIcon sx={{ fontSize: 32 }} />, href: `${bp}/movimientos`, bg: brandColors.shortcutNavy },
    { title: "Traslados", description: "Entre almacenes", icon: <SwapHorizIcon sx={{ fontSize: 32 }} />, href: `${bp}/traslados`, bg: brandColors.danger },
    { title: "Libro Inventario", description: "Reporte mensual", icon: <MenuBookIcon sx={{ fontSize: 32 }} />, href: `${bp}/reportes/libro`, bg: brandColors.success },
    { title: "Etiquetas", description: "Generador", icon: <LocalOfferIcon sx={{ fontSize: 32 }} />, href: `${bp}/etiquetas`, bg: brandColors.shortcutSlate },
    { title: "Categorias", description: "Catalogo", icon: <CategoryIcon sx={{ fontSize: 32 }} />, href: `${bp}/catalogos/categorias`, bg: brandColors.shortcutTeal },
    { title: "Almacenes", description: "Catalogo", icon: <WarehouseIcon sx={{ fontSize: 32 }} />, href: `${bp}/catalogos/almacenes`, bg: brandColors.shortcutSlate },
  ];

  const movRows = (ultMovs?.rows ?? []) as Record<string, unknown>[];

  const gridRows = useMemo(() => movRows.map((m, i) => ({
    id: i,
    fecha: String(m.MovementDate ?? "").slice(0, 10),
    articulo: String(m.ProductName ?? m.ProductCode ?? ""),
    tipo: String(m.MovementType ?? ""),
    cantidad: Number(m.Quantity ?? 0),
    referencia: String(m.DocumentRef ?? ""),
  })), [movRows]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = MOVS_COLUMNS;
    el.rows = gridRows;
    el.loading = false;
    el.getRowId = (r: any) => r.id;
  }, [gridRows, registered]);

  return (
    <Box>
      <Typography variant="h5" sx={{ mb: 3, fontWeight: 700, color: "text.primary" }}>
        Dashboard de Inventario
      </Typography>

      {/* STATS CARDS */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        {statsCards.map((s, idx) => (
          <Grid size={{ xs: 12, sm: 6, md: 3 }} key={idx}>
            <Card
              sx={{
                height: "100%", bgcolor: s.color, color: "white", borderRadius: 2,
                position: "relative", overflow: "hidden", boxShadow: "0 4px 6px rgba(0,0,0,0.1)",
              }}
            >
              <CardContent sx={{ pb: "16px !important" }}>
                <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
                  <Box>
                    {s.loading ? (
                      <Skeleton variant="text" width={80} sx={{ bgcolor: "rgba(255,255,255,0.3)", fontSize: "2rem" }} />
                    ) : (
                      <Typography variant="h4" sx={{ fontWeight: 700, lineHeight: 1 }}>{s.value}</Typography>
                    )}
                    <Typography variant="body1" sx={{ mt: 1, opacity: 0.9, fontWeight: 500 }}>{s.title}</Typography>
                  </Box>
                  <IconButton size="small" sx={{ color: "white", opacity: 0.8, p: 0 }}>
                    <MoreVertIcon />
                  </IconButton>
                </Box>
                <Box sx={{ mt: 3, height: 40, width: "100%" }}>
                  {s.chartType === "line" ? (
                    <svg viewBox="0 0 100 30" width="100%" height="100%" preserveAspectRatio="none">
                      <path d="M0,20 Q10,10 20,25 T40,15 T60,20 T80,5 T100,10 L100,30 L0,30 Z" fill="rgba(255,255,255,0.1)" />
                      <path d="M0,20 Q10,10 20,25 T40,15 T60,20 T80,5 T100,10" fill="none" stroke="rgba(255,255,255,0.6)" strokeWidth="2" />
                    </svg>
                  ) : (
                    <svg viewBox="0 0 100 30" width="100%" height="100%" preserveAspectRatio="none">
                      <rect x="5" y="10" width="15" height="20" fill="rgba(255,255,255,0.4)" rx="2" />
                      <rect x="30" y="5" width="15" height="25" fill="rgba(255,255,255,0.6)" rx="2" />
                      <rect x="55" y="15" width="15" height="15" fill="rgba(255,255,255,0.3)" rx="2" />
                      <rect x="80" y="8" width="15" height="22" fill="rgba(255,255,255,0.5)" rx="2" />
                    </svg>
                  )}
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* SHORTCUTS */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        {shortcuts.map((sc, idx) => (
          <Grid size={{ xs: 6, sm: 4, md: 3 }} key={idx}>
            <Card sx={{ borderRadius: 2, overflow: "hidden", boxShadow: "0 2px 4px rgba(0,0,0,0.05)" }}>
              <CardActionArea onClick={() => router.push(sc.href)}>
                <Box sx={{ bgcolor: sc.bg, color: "white", display: "flex", justifyContent: "center", py: 3, position: "relative" }}>
                  {sc.icon}
                  <svg preserveAspectRatio="none" style={{ position: "absolute", bottom: 0, left: 0, width: "100%", height: "30px" }} viewBox="0 0 100 100">
                    <path d="M0,100 C20,0 50,0 100,100 Z" fill="rgba(255,255,255,0.15)" />
                  </svg>
                </Box>
                <CardContent sx={{ textAlign: "center", py: 1.5 }}>
                  <Typography variant="subtitle1" sx={{ fontWeight: 700, color: "text.primary", mb: 0, lineHeight: 1.3 }}>{sc.title}</Typography>
                  <Typography variant="caption" color="text.secondary" sx={{ textTransform: "uppercase", fontWeight: 600, letterSpacing: 1 }}>{sc.description}</Typography>
                </CardContent>
              </CardActionArea>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* INDICADORES + ULTIMOS MOVIMIENTOS */}
      <Grid container spacing={3}>
        <Grid size={{ xs: 12, md: 4 }}>
          <Card sx={{ borderRadius: 2, boxShadow: "0 2px 8px rgba(0,0,0,0.08)", height: "100%" }}>
            <CardContent>
              <Typography variant="h6" sx={{ fontWeight: 600, mb: 3 }}>Indicadores</Typography>
              <Box sx={{ borderLeft: `4px solid ${brandColors.statBlue}`, pl: 2, mb: 3 }}>
                <Typography variant="body2" color="text.secondary">Valor Total en Stock</Typography>
                <Typography variant="h5" sx={{ fontWeight: 700 }}>
                  {dashLoading ? <Skeleton width={120} /> : formatCurrency(dashboard?.ValorInventario ?? 0)}
                </Typography>
              </Box>
              <Box sx={{ borderLeft: `4px solid ${brandColors.statRed}`, pl: 2, mb: 3 }}>
                <Typography variant="body2" color="text.secondary">Articulos Bajo Minimo</Typography>
                <Typography variant="h5" sx={{ fontWeight: 700 }}>
                  {dashLoading ? <Skeleton width={60} /> : dashboard?.BajoStock ?? 0}
                </Typography>
              </Box>
              <Box sx={{ borderLeft: `4px solid ${brandColors.statOrange}`, pl: 2 }}>
                <Typography variant="body2" color="text.secondary">Movimientos del Mes</Typography>
                <Typography variant="h5" sx={{ fontWeight: 700 }}>
                  {dashLoading ? <Skeleton width={60} /> : dashboard?.MovimientosMes ?? 0}
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 12, md: 8 }}>
          <Card sx={{ borderRadius: 2, boxShadow: "0 2px 8px rgba(0,0,0,0.08)", height: "100%" }}>
            <CardContent>
              <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>Ultimos Movimientos</Typography>
              {movRows.length > 0 ? (
                <zentto-grid
                  ref={gridRef}
                  grid-id={MOVS_GRID_ID}
                  height="250px"
                  enable-status-bar
                  enable-quick-search
                  enable-header-filters
                  enable-configurator
                  enable-toolbar
                  enable-header-menu
                  enable-clipboard
                  enable-context-menu
                />
              ) : (
                <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", minHeight: 150, bgcolor: "#f8f9fa", borderRadius: 2 }}>
                  <Typography variant="body2" color="text.secondary" sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                    <TrendingUpIcon /> No hay movimientos registrados aun
                  </Typography>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>
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
