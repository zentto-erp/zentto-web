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
import ReceiptLongIcon from "@mui/icons-material/ReceiptLong";
import AssignmentReturnIcon from "@mui/icons-material/AssignmentReturn";
import LocalShippingIcon from "@mui/icons-material/LocalShipping";
import PeopleIcon from "@mui/icons-material/People";
import DescriptionIcon from "@mui/icons-material/Description";
import SwapHorizIcon from "@mui/icons-material/SwapHoriz";
import { useRouter } from "next/navigation";
import { useLogisticaDashboard, useReceiptsList, useDeliveryNotesList } from "../hooks/useLogistica";
import { brandColors } from "@zentto/shared-ui";

const receiptStatusLabels: Record<string, string> = {
  DRAFT: "Borrador",
  PARTIAL: "Parcial",
  COMPLETE: "Completa",
  VOIDED: "Anulada",
};

const receiptStatusColors: Record<string, "default" | "warning" | "success" | "error"> = {
  DRAFT: "default",
  PARTIAL: "warning",
  COMPLETE: "success",
  VOIDED: "error",
};

const deliveryStatusLabels: Record<string, string> = {
  DRAFT: "Borrador",
  CONFIRMED: "Confirmado",
  PICKING: "En Picking",
  PACKED: "Empacado",
  DISPATCHED: "Despachado",
  DELIVERED: "Entregado",
  VOIDED: "Anulado",
};

const deliveryStatusColors: Record<string, "default" | "warning" | "success" | "error" | "info" | "primary" | "secondary"> = {
  DRAFT: "default",
  CONFIRMED: "info",
  PICKING: "warning",
  PACKED: "secondary",
  DISPATCHED: "primary",
  DELIVERED: "success",
  VOIDED: "error",
};

export default function LogisticaHome({ basePath = "" }: { basePath?: string }) {
  const router = useRouter();
  const bp = basePath.replace(/\/+$/, "");
  const { data: dashboard, isLoading: dashLoading } = useLogisticaDashboard();
  const { data: lastReceipts } = useReceiptsList({ limit: 5 });
  const { data: lastDeliveries } = useDeliveryNotesList({ limit: 5 });

  const statsCards = [
    {
      title: "Recepciones Pendientes",
      value: dashboard ? String(dashboard.RecepcionesPendientes) : "\u2014",
      subtitle: "Esperando completar",
      loading: dashLoading,
      color: brandColors.statBlue,
      chartType: "bar" as const,
    },
    {
      title: "Devoluciones en Proceso",
      value: dashboard ? String(dashboard.DevolucionesEnProceso) : "\u2014",
      subtitle: "En gestion",
      loading: dashLoading,
      color: brandColors.statRed,
      chartType: "line" as const,
    },
    {
      title: "Albaranes en Transito",
      value: dashboard ? String(dashboard.AlbaranesEnTransito) : "\u2014",
      subtitle: "Despachados sin entregar",
      loading: dashLoading,
      color: brandColors.statTeal,
      chartType: "bar" as const,
    },
    {
      title: "Transportistas Activos",
      value: dashboard ? String(dashboard.TransportistasActivos) : "\u2014",
      subtitle: "Disponibles",
      loading: dashLoading,
      color: brandColors.statOrange,
      chartType: "line" as const,
    },
  ];

  const shortcuts = [
    { title: "Recepciones", description: "Recepcion de mercancia", icon: <ReceiptLongIcon sx={{ fontSize: 32 }} />, href: `${bp}/recepciones`, bg: brandColors.shortcutGreen },
    { title: "Devoluciones", description: "Gestionar devoluciones", icon: <AssignmentReturnIcon sx={{ fontSize: 32 }} />, href: `${bp}/devoluciones`, bg: brandColors.shortcutDark },
    { title: "Albaranes", description: "Notas de entrega", icon: <DescriptionIcon sx={{ fontSize: 32 }} />, href: `${bp}/albaranes`, bg: brandColors.shortcutNavy },
    { title: "Transportistas", description: "Catalogo", icon: <LocalShippingIcon sx={{ fontSize: 32 }} />, href: `${bp}/transportistas`, bg: brandColors.shortcutSlate },
  ];

  const receiptRows = (lastReceipts?.rows ?? []) as Record<string, unknown>[];
  const deliveryRows = (lastDeliveries?.rows ?? []) as Record<string, unknown>[];

  return (
    <Box>
      <Typography variant="h5" sx={{ mb: 3, fontWeight: 700, color: "text.primary" }}>
        Dashboard de Logistica
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

      {/* ULTIMAS RECEPCIONES + ULTIMOS ALBARANES */}
      <Grid container spacing={3}>
        <Grid size={{ xs: 12, md: 6 }}>
          <Card sx={{ borderRadius: 2, boxShadow: "0 2px 8px rgba(0,0,0,0.08)", height: "100%" }}>
            <CardContent>
              <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>Ultimas Recepciones</Typography>
              {receiptRows.length > 0 ? (
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell sx={{ fontWeight: 600 }}>N. Recepcion</TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>Proveedor</TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>Fecha</TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>Estado</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {receiptRows.map((r, i) => (
                      <TableRow key={i}>
                        <TableCell>{String(r.ReceiptNumber ?? "")}</TableCell>
                        <TableCell>{String(r.SupplierName ?? "")}</TableCell>
                        <TableCell>{String(r.ReceiptDate ?? "").slice(0, 10)}</TableCell>
                        <TableCell>
                          <Chip
                            label={receiptStatusLabels[String(r.Status)] ?? String(r.Status)}
                            size="small"
                            color={receiptStatusColors[String(r.Status)] ?? "default"}
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
                    <ReceiptLongIcon /> No hay recepciones registradas aun
                  </Typography>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 12, md: 6 }}>
          <Card sx={{ borderRadius: 2, boxShadow: "0 2px 8px rgba(0,0,0,0.08)", height: "100%" }}>
            <CardContent>
              <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>Ultimos Albaranes</Typography>
              {deliveryRows.length > 0 ? (
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell sx={{ fontWeight: 600 }}>N. Albaran</TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>Cliente</TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>Fecha</TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>Estado</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {deliveryRows.map((d, i) => (
                      <TableRow key={i}>
                        <TableCell>{String(d.DeliveryNumber ?? "")}</TableCell>
                        <TableCell>{String(d.CustomerName ?? "")}</TableCell>
                        <TableCell>{String(d.DeliveryDate ?? "").slice(0, 10)}</TableCell>
                        <TableCell>
                          <Chip
                            label={deliveryStatusLabels[String(d.Status)] ?? String(d.Status)}
                            size="small"
                            color={deliveryStatusColors[String(d.Status)] ?? "default"}
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
                    <LocalShippingIcon /> No hay albaranes registrados aun
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
