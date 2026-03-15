"use client";

import React from "react";
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
import ShoppingCartIcon from "@mui/icons-material/ShoppingCart";
import LocalShippingIcon from "@mui/icons-material/LocalShipping";
import ReceiptLongIcon from "@mui/icons-material/ReceiptLong";
import AddShoppingCartIcon from "@mui/icons-material/AddShoppingCart";
import PersonAddIcon from "@mui/icons-material/PersonAdd";
import AccountBalanceIcon from "@mui/icons-material/AccountBalance";
import MoreVertIcon from "@mui/icons-material/MoreVert";
import TrendingUpIcon from "@mui/icons-material/TrendingUp";
import PaymentIcon from "@mui/icons-material/Payment";
import { useRouter } from "next/navigation";
import { useComprasList } from "../hooks/useCompras";
import { useProveedoresList } from "../hooks/useProveedores";
import { useCuentasPorPagarList } from "../hooks/useCuentasPorPagar";
import { brandColors } from "@datqbox/shared-ui";

export default function ComprasHome({ basePath = "" }: { basePath?: string }) {
  const router = useRouter();
  const bp = basePath.replace(/\/+$/, "");
  const compras = useComprasList({ limit: 1 });
  const proveedores = useProveedoresList({ limit: 1 });
  const cxp = useCuentasPorPagarList({ limit: 1 });

  const totalCompras = compras.data?.total ?? "---";
  const totalProveedores = proveedores.data?.total ?? "---";
  const totalCxp = cxp.data?.total ?? "---";

  const statsCards = [
    {
      title: "Compras del Mes",
      value: String(totalCompras),
      subtitle: "Documentos",
      loading: compras.isLoading,
      color: brandColors.statBlue,
      chartType: "line" as const,
    },
    {
      title: "Proveedores Activos",
      value: String(totalProveedores),
      subtitle: "Directorio",
      loading: proveedores.isLoading,
      color: brandColors.statTeal,
      chartType: "bar" as const,
    },
    {
      title: "CxP Pendiente",
      value: String(totalCxp),
      subtitle: "Cuentas",
      loading: cxp.isLoading,
      color: brandColors.statOrange,
      chartType: "bar" as const,
    },
    {
      title: "Ultimo Pago",
      value: "---",
      subtitle: "Aplicado",
      loading: false,
      color: brandColors.statRed,
      chartType: "line" as const,
    },
  ];

  const shortcuts = [
    {
      title: "Compras",
      description: "Lista de Compras",
      icon: <ShoppingCartIcon sx={{ fontSize: 32 }} />,
      href: `${bp}/compras`,
      bg: brandColors.shortcutGreen,
    },
    {
      title: "Nueva Compra",
      description: "Maestro-Detalle",
      icon: <AddShoppingCartIcon sx={{ fontSize: 32 }} />,
      href: `${bp}/compras/new`,
      bg: brandColors.shortcutDark,
    },
    {
      title: "Proveedores",
      description: "Directorio",
      icon: <LocalShippingIcon sx={{ fontSize: 32 }} />,
      href: `${bp}/proveedores`,
      bg: brandColors.shortcutTeal,
    },
    {
      title: "Nuevo Proveedor",
      description: "Registro",
      icon: <PersonAddIcon sx={{ fontSize: 32 }} />,
      href: `${bp}/proveedores/new`,
      bg: brandColors.shortcutSlate,
    },
    {
      title: "CxP Estado de Cuenta",
      description: "Saldos y Pagos",
      icon: <AccountBalanceIcon sx={{ fontSize: 32 }} />,
      href: `${bp}/cxp`,
      bg: brandColors.success,
    },
    {
      title: "Cuentas por Pagar",
      description: "Listado CxP",
      icon: <ReceiptLongIcon sx={{ fontSize: 32 }} />,
      href: `${bp}/cuentas-por-pagar`,
      bg: brandColors.shortcutOrange,
    },
  ];

  return (
    <Box>
      <Typography variant="h5" sx={{ mb: 3, fontWeight: 700, color: "text.primary" }}>
        Dashboard de Compras / Proveedores / CxP
      </Typography>

      {/* CORE-UI STYLE STATS CARDS */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        {statsCards.map((s, idx) => (
          <Grid size={{ xs: 12, sm: 6, md: 3 }} key={idx}>
            <Card
              sx={{
                height: "100%",
                bgcolor: s.color,
                color: "white",
                borderRadius: 2,
                position: "relative",
                overflow: "hidden",
                boxShadow: "0 4px 6px rgba(0,0,0,0.1)",
              }}
            >
              <CardContent sx={{ pb: "16px !important" }}>
                <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
                  <Box>
                    {s.loading ? (
                      <Skeleton variant="text" width={80} sx={{ bgcolor: "rgba(255,255,255,0.3)", fontSize: "2rem" }} />
                    ) : (
                      <Typography variant="h4" sx={{ fontWeight: 700, lineHeight: 1 }}>
                        {s.value}
                      </Typography>
                    )}
                    <Typography variant="body1" sx={{ mt: 1, opacity: 0.9, fontWeight: 500 }}>
                      {s.title}
                    </Typography>
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

      {/* CORE-UI WIDGETS (SOCIAL-LIKE SHORTCUTS) */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        {shortcuts.map((sc, idx) => (
          <Grid size={{ xs: 12, sm: 6, md: 3 }} key={idx}>
            <Card sx={{ borderRadius: 2, overflow: "hidden", boxShadow: "0 2px 4px rgba(0,0,0,0.05)" }}>
              <CardActionArea onClick={() => router.push(sc.href)}>
                <Box sx={{ bgcolor: sc.bg, color: "white", display: "flex", justifyContent: "center", py: 3, position: "relative" }}>
                  {sc.icon}
                  <svg preserveAspectRatio="none" style={{ position: "absolute", bottom: 0, left: 0, width: "100%", height: "30px" }} viewBox="0 0 100 100">
                    <path d="M0,100 C20,0 50,0 100,100 Z" fill="rgba(255,255,255,0.15)" />
                  </svg>
                </Box>
                <CardContent sx={{ textAlign: "center", py: 2 }}>
                  <Typography variant="h6" sx={{ fontWeight: 700, color: "text.primary", mb: 0 }}>
                    {sc.title}
                  </Typography>
                  <Typography variant="body2" color="text.secondary" sx={{ textTransform: "uppercase", fontWeight: 600, fontSize: "0.75rem", letterSpacing: 1 }}>
                    {sc.description}
                  </Typography>
                </CardContent>
              </CardActionArea>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Large Bottom Card */}
      <Card sx={{ borderRadius: 2, boxShadow: "0 2px 8px rgba(0,0,0,0.08)" }}>
        <CardContent>
          <Typography variant="h6" sx={{ fontWeight: 600, mb: 3 }}>
            Indicadores de Compras y Pagos
          </Typography>

          <Grid container spacing={4}>
            <Grid size={{ xs: 12, md: 4 }}>
              <Box sx={{ borderLeft: `4px solid ${brandColors.statBlue}`, pl: 2, mb: 3 }}>
                <Typography variant="body2" color="text.secondary">Monto Compras</Typography>
                <Typography variant="h5" sx={{ fontWeight: 700 }}>---</Typography>
              </Box>
              <Box sx={{ borderLeft: `4px solid ${brandColors.statRed}`, pl: 2, mb: 3 }}>
                <Typography variant="body2" color="text.secondary">Pagos CxP</Typography>
                <Typography variant="h5" sx={{ fontWeight: 700 }}>---</Typography>
              </Box>
              <Box sx={{ borderLeft: `4px solid ${brandColors.statOrange}`, pl: 2 }}>
                <Typography variant="body2" color="text.secondary">Saldo Pendiente</Typography>
                <Typography variant="h5" sx={{ fontWeight: 700 }}>---</Typography>
              </Box>
            </Grid>
            <Grid size={{ xs: 12, md: 8 }} sx={{ display: "flex", alignItems: "center", justifyContent: "center", bgcolor: "#f8f9fa", borderRadius: 2, minHeight: 200 }}>
              <Typography variant="body2" color="text.secondary" sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                <TrendingUpIcon /> Resumen de compras y pagos se actualizara con datos reales
              </Typography>
            </Grid>
          </Grid>
        </CardContent>
      </Card>
    </Box>
  );
}
