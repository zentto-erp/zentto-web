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
import { brandColors, DashboardShortcutCard, DashboardKpiCard } from "@zentto/shared-ui";
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
      color: brandColors.shortcutDark,
      icon: <InventoryIcon />,
    },
    {
      title: "Categorias",
      value: dashboard ? String(dashboard.TotalCategorias) : "\u2014",
      subtitle: "Catalogos",
      loading: dashLoading,
      color: brandColors.shortcutTeal,
      icon: <CategoryIcon />,
    },
    {
      title: "Valor Inventario",
      value: dashboard ? formatCurrency(dashboard.ValorInventario) : "\u2014",
      subtitle: "Costo total",
      loading: dashLoading,
      color: brandColors.shortcutViolet,
      icon: <AttachMoneyIcon />,
    },
    {
      title: "Bajo Stock",
      value: dashboard ? String(dashboard.BajoStock) : "\u2014",
      subtitle: "Requieren atencion",
      loading: dashLoading,
      color: brandColors.statRed,
      icon: <WarningAmberIcon />,
    },
  ];

  const PALETTE = [brandColors.shortcutDark, brandColors.shortcutTeal, brandColors.shortcutViolet, brandColors.statRed];
  const shortcutItems = [
    { title: "Articulos", description: "Gestion de productos", icon: <InventoryIcon sx={{ fontSize: 32 }} />, href: `${bp}/articulos` },
    { title: "Ajuste Inventario", description: "Entradas y salidas", icon: <TuneIcon sx={{ fontSize: 32 }} />, href: `${bp}/ajuste` },
    { title: "Movimientos", description: "Historial completo", icon: <HistoryIcon sx={{ fontSize: 32 }} />, href: `${bp}/movimientos` },
    { title: "Traslados", description: "Entre almacenes", icon: <SwapHorizIcon sx={{ fontSize: 32 }} />, href: `${bp}/traslados` },
    { title: "Libro Inventario", description: "Reporte mensual", icon: <MenuBookIcon sx={{ fontSize: 32 }} />, href: `${bp}/reportes/libro` },
    { title: "Etiquetas", description: "Generador", icon: <LocalOfferIcon sx={{ fontSize: 32 }} />, href: `${bp}/etiquetas` },
    { title: "Categorias", description: "Catalogo", icon: <CategoryIcon sx={{ fontSize: 32 }} />, href: `${bp}/catalogos/categorias` },
    { title: "Almacenes", description: "Catalogo", icon: <WarehouseIcon sx={{ fontSize: 32 }} />, href: `${bp}/catalogos/almacenes` },
  ];
  const shortcuts = shortcutItems.map((sc, i) => ({ ...sc, bg: PALETTE[i % PALETTE.length] }));

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
      {/* STATS CARDS */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        {statsCards.map((s, idx) => (
          <Grid size={{ xs: 12, sm: 6, md: 3 }} key={idx}>
            <DashboardKpiCard
              title={s.title}
              value={s.value}
              color={s.color}
              icon={s.icon}
              subtitle={s.subtitle}
              loading={s.loading}
            />
          </Grid>
        ))}
      </Grid>

      {/* SHORTCUTS */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        {shortcuts.map((sc, idx) => (
          <Grid size={{ xs: 12, sm: 6, md: 3 }} key={idx}>
            <DashboardShortcutCard
              title={sc.title}
              description={sc.description}
              icon={sc.icon}
              href={sc.href}
              color={sc.bg}
            />
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
