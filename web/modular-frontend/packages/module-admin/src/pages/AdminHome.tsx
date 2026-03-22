"use client";

import React from "react";
import {
  Box,
  Card,
  CardContent,
  Typography,
  IconButton,
  Skeleton,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import ReceiptIcon from "@mui/icons-material/Receipt";
import PeopleIcon from "@mui/icons-material/People";
import AccountBalanceIcon from "@mui/icons-material/AccountBalance";
import CategoryIcon from "@mui/icons-material/Category";
import MoreVertIcon from "@mui/icons-material/MoreVert";
import TrendingUpIcon from "@mui/icons-material/TrendingUp";
import { useFacturasList } from "../hooks/useFacturas";
import { useClientesList } from "../hooks/useClientes";
import { formatCurrency } from "@zentto/shared-api";
import { brandColors } from "@zentto/shared-ui";

export default function AdminHome() {
  const facturas = useFacturasList({ limit: 5 });
  const clientes = useClientesList({ limit: 1 });

  const totalFacturas = facturas.data?.total ?? "—";
  const totalClientes = clientes.data?.total ?? "—";

  const statsCards = [
    {
      title: "Facturas",
      value: String(totalFacturas),
      subtitle: "Total registradas",
      loading: facturas.isLoading,
      color: brandColors.statBlue,
      chartType: "line" as const,
    },
    {
      title: "Clientes",
      value: String(totalClientes),
      subtitle: "Registrados",
      loading: clientes.isLoading,
      color: brandColors.statTeal,
      chartType: "bar" as const,
    },
    {
      title: "CxC Pendiente",
      value: "—",
      subtitle: "Total por cobrar",
      loading: false,
      color: brandColors.statOrange,
      chartType: "bar" as const,
    },
  ];

  const shortcuts = [
    {
      title: "Facturas",
      description: "Documentos de venta",
      icon: <ReceiptIcon sx={{ fontSize: 32 }} />,
      href: "/ventas/facturas",
      bg: brandColors.shortcutDark,
    },
    {
      title: "Clientes",
      description: "Gestión de clientes",
      icon: <PeopleIcon sx={{ fontSize: 32 }} />,
      href: "/ventas/clientes",
      bg: brandColors.shortcutOrange,
    },
    {
      title: "Cuentas por Cobrar",
      description: "CxC y cobros",
      icon: <AccountBalanceIcon sx={{ fontSize: 32 }} />,
      href: "/ventas/cxc",
      bg: brandColors.shortcutGreen,
    },
    {
      title: "Artículos",
      description: "Catálogo",
      icon: <CategoryIcon sx={{ fontSize: 32 }} />,
      href: "/ventas/articulos",
      bg: brandColors.shortcutNavy,
    },
  ];

  const recentFacturas = facturas.data?.data ?? [];

  return (
    <Box>
      <Typography variant="h5" sx={{ mb: 3, fontWeight: 700, color: "text.primary" }}>
        Dashboard Administrativo
      </Typography>

      {/* STATS CARDS */}
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

      {/* SHORTCUT CARDS */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        {shortcuts.map((sc, idx) => (
          <Grid size={{ xs: 12, sm: 6, md: 3 }} key={idx}>
            <Card sx={{ borderRadius: 2, overflow: "hidden", boxShadow: "0 2px 4px rgba(0,0,0,0.05)" }}>
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
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* RECENT ACTIVITY */}
      <Card sx={{ borderRadius: 2, boxShadow: "0 2px 8px rgba(0,0,0,0.08)" }}>
        <CardContent>
          <Typography variant="h6" sx={{ fontWeight: 600, mb: 3 }}>
            Últimas Facturas
          </Typography>

          {facturas.isLoading ? (
            <Skeleton variant="rectangular" width="100%" height={120} />
          ) : recentFacturas.length > 0 ? (
            <Grid container spacing={2}>
              {recentFacturas.slice(0, 5).map((f: any, idx: number) => (
                <Grid size={{ xs: 12 }} key={idx}>
                  <Box
                    sx={{
                      display: "flex",
                      justifyContent: "space-between",
                      alignItems: "center",
                      borderLeft: `4px solid ${brandColors.statBlue}`,
                      pl: 2,
                      py: 1,
                    }}
                  >
                    <Box>
                      <Typography variant="body2" fontWeight={600}>
                        #{f.numeroFactura}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        {f.nombreCliente} — {f.fecha}
                      </Typography>
                    </Box>
                    <Typography variant="body1" fontWeight={700}>
                      {formatCurrency(f.totalFactura)}
                    </Typography>
                  </Box>
                </Grid>
              ))}
            </Grid>
          ) : (
            <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", py: 4, bgcolor: "#f8f9fa", borderRadius: 2 }}>
              <Typography variant="body2" color="text.secondary" sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                <TrendingUpIcon /> Resumen de actividad se actualizará con datos reales
              </Typography>
            </Box>
          )}
        </CardContent>
      </Card>
    </Box>
  );
}
