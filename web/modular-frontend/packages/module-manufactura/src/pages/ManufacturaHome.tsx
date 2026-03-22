"use client";

import React from "react";
import {
  Box,
  Card,
  CardActionArea,
  CardContent,
  IconButton,
  Skeleton,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Chip,
  Typography,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import MoreVertIcon from "@mui/icons-material/MoreVert";
import PrecisionManufacturingIcon from "@mui/icons-material/PrecisionManufacturing";
import FactoryIcon from "@mui/icons-material/Factory";
import AssignmentIcon from "@mui/icons-material/Assignment";
import AccountTreeIcon from "@mui/icons-material/AccountTree";
import { useRouter } from "next/navigation";
import {
  useManufacturaDashboard,
  useBOMList,
  useWorkOrdersList,
} from "../hooks/useManufactura";
import { brandColors } from "@zentto/shared-ui";

const orderStatusLabels: Record<string, string> = {
  DRAFT: "Borrador",
  IN_PROGRESS: "En Proceso",
  COMPLETED: "Completada",
  CANCELLED: "Cancelada",
};

const orderStatusColors: Record<string, "default" | "info" | "success" | "error"> = {
  DRAFT: "default",
  IN_PROGRESS: "info",
  COMPLETED: "success",
  CANCELLED: "error",
};

const bomStatusLabels: Record<string, string> = {
  DRAFT: "Borrador",
  ACTIVE: "Activa",
  OBSOLETE: "Obsoleta",
};

const bomStatusColors: Record<string, "default" | "success" | "error"> = {
  DRAFT: "default",
  ACTIVE: "success",
  OBSOLETE: "error",
};

export default function ManufacturaHome({ basePath = "" }: { basePath?: string }) {
  const router = useRouter();
  const bp = basePath.replace(/\/+$/, "");
  const { data: dashboard, isLoading: dashLoading } = useManufacturaDashboard();
  const { data: lastBOMs } = useBOMList({ limit: 5 });
  const { data: lastOrders } = useWorkOrdersList({ limit: 5 });

  const statsCards = [
    {
      title: "BOMs Activos",
      value: dashboard ? String(dashboard.BOMsActivos) : "\u2014",
      subtitle: "Listas de materiales",
      loading: dashLoading,
      color: brandColors.statBlue,
      chartType: "bar" as const,
    },
    {
      title: "Centros de Trabajo",
      value: dashboard ? String(dashboard.CentrosTrabajo) : "\u2014",
      subtitle: "Registrados",
      loading: dashLoading,
      color: brandColors.statTeal,
      chartType: "line" as const,
    },
    {
      title: "Ordenes en Proceso",
      value: dashboard ? String(dashboard.OrdenesEnProceso) : "\u2014",
      subtitle: "En produccion",
      loading: dashLoading,
      color: brandColors.statOrange,
      chartType: "bar" as const,
    },
    {
      title: "Ordenes Completadas",
      value: dashboard ? String(dashboard.OrdenesCompletadas) : "\u2014",
      subtitle: "Finalizadas",
      loading: dashLoading,
      color: brandColors.statRed,
      chartType: "line" as const,
    },
  ];

  const shortcuts = [
    { title: "BOM", description: "Lista de materiales", icon: <AccountTreeIcon sx={{ fontSize: 32 }} />, href: `${bp}/bom`, bg: brandColors.shortcutGreen },
    { title: "Centros de Trabajo", description: "Configuracion", icon: <FactoryIcon sx={{ fontSize: 32 }} />, href: `${bp}/centros-trabajo`, bg: brandColors.shortcutDark },
    { title: "Ordenes", description: "Produccion", icon: <AssignmentIcon sx={{ fontSize: 32 }} />, href: `${bp}/ordenes`, bg: brandColors.shortcutNavy },
  ];

  const bomRows = (lastBOMs?.rows ?? []) as Record<string, unknown>[];
  const orderRows = (lastOrders?.rows ?? []) as Record<string, unknown>[];

  return (
    <Box>
      <Typography variant="h5" sx={{ mb: 3, fontWeight: 700, color: "text.primary" }}>
        Dashboard de Manufactura
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

      {/* ULTIMAS BOMs + ULTIMAS ORDENES */}
      <Grid container spacing={3}>
        <Grid size={{ xs: 12, md: 6 }}>
          <Card sx={{ borderRadius: 2, boxShadow: "0 2px 8px rgba(0,0,0,0.08)", height: "100%" }}>
            <CardContent>
              <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>Ultimas BOMs</Typography>
              {bomRows.length > 0 ? (
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell sx={{ fontWeight: 600 }}>Codigo</TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>Nombre</TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>Producto</TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>Estado</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {bomRows.map((r, i) => (
                      <TableRow key={i}>
                        <TableCell>{String(r.BOMCode ?? "")}</TableCell>
                        <TableCell>{String(r.BOMName ?? "")}</TableCell>
                        <TableCell>{String(r.ProductName ?? "")}</TableCell>
                        <TableCell>
                          <Chip
                            label={bomStatusLabels[String(r.Status)] ?? String(r.Status)}
                            size="small"
                            color={bomStatusColors[String(r.Status)] ?? "default"}
                            variant="outlined"
                          />
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              ) : (
                <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", minHeight: 150, bgcolor: "#f8f9fa", borderRadius: 2 }}>
                  <Typography variant="body2" color="text.secondary" sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                    <AccountTreeIcon /> No hay BOMs registradas aun
                  </Typography>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 12, md: 6 }}>
          <Card sx={{ borderRadius: 2, boxShadow: "0 2px 8px rgba(0,0,0,0.08)", height: "100%" }}>
            <CardContent>
              <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>Ultimas Ordenes de Produccion</Typography>
              {orderRows.length > 0 ? (
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell sx={{ fontWeight: 600 }}>N. Orden</TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>Producto</TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>Cantidad</TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>Estado</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {orderRows.map((d, i) => (
                      <TableRow key={i}>
                        <TableCell>{String(d.WorkOrderNumber ?? "")}</TableCell>
                        <TableCell>{String(d.ProductName ?? "")}</TableCell>
                        <TableCell>{String(d.PlannedQuantity ?? "")}</TableCell>
                        <TableCell>
                          <Chip
                            label={orderStatusLabels[String(d.Status)] ?? String(d.Status)}
                            size="small"
                            color={orderStatusColors[String(d.Status)] ?? "default"}
                            variant="outlined"
                          />
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              ) : (
                <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", minHeight: 150, bgcolor: "#f8f9fa", borderRadius: 2 }}>
                  <Typography variant="body2" color="text.secondary" sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                    <PrecisionManufacturingIcon /> No hay ordenes registradas aun
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
