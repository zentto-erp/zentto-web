"use client";

import React from "react";
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Stack,
  IconButton,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import AccountBalanceWalletIcon from "@mui/icons-material/AccountBalanceWallet";
import MenuBookIcon from "@mui/icons-material/MenuBook";
import BarChartIcon from "@mui/icons-material/BarChart";
import AccountTreeIcon from "@mui/icons-material/AccountTree";
import MoreVertIcon from '@mui/icons-material/MoreVert';
import TrendingUpIcon from '@mui/icons-material/TrendingUp';
import CompareArrowsIcon from '@mui/icons-material/CompareArrows';

const statsCards = [
  {
    title: "Ingresos",
    value: "$45.2K",
    subtitle: "Este mes",
    percentage: "(+12.4%)",
    trend: 'up',
    color: "#321fdb", // CoreUI Purple/Blue
    chartType: "line",
  },
  {
    title: "Egresos",
    value: "$12.4K",
    subtitle: "Este mes",
    percentage: "(-5.2%)",
    trend: 'down',
    color: "#39f", // CoreUI Light Blue
    chartType: "line",
  },
  {
    title: "Margen Bruto",
    value: "72.5%",
    subtitle: "Rendimiento",
    percentage: "(+1.2%)",
    trend: 'up',
    color: "#f9b115", // CoreUI Yellow
    chartType: "bar",
  },
  {
    title: "Ctas por Pagar",
    value: "$8.5K",
    subtitle: "Pendientes",
    percentage: "(+14%)",
    trend: 'up',
    color: "#e55353", // CoreUI Red
    chartType: "bar",
  },
];

const shortcuts = [
  {
    title: "Asientos",
    description: "Crear y anular",
    icon: <AccountBalanceWalletIcon sx={{ fontSize: 32 }} />,
    href: "/contabilidad/asientos",
    bg: '#3b5998' // Facebook blue
  },
  {
    title: "Plan de Cuentas",
    description: "Catálogo",
    icon: <AccountTreeIcon sx={{ fontSize: 32 }} />,
    href: "/contabilidad/cuentas",
    bg: '#00aced' // Twitter blue
  },
  {
    title: "Reportes",
    description: "Balances",
    icon: <BarChartIcon sx={{ fontSize: 32 }} />,
    href: "/contabilidad/reportes",
    bg: '#4875b4' // LinkedIn blue
  },
  {
    title: "Ajustes",
    description: "Depreciación",
    icon: <MenuBookIcon sx={{ fontSize: 32 }} />,
    href: "/contabilidad/ajustes",
    bg: '#ffb818' // Warning yellow
  },
];

export default function ContabilidadHome() {
  return (
    <Box>
      <Typography variant="h5" sx={{ mb: 3, fontWeight: 700, color: 'text.primary' }}>
        Dashboard Contable
      </Typography>

      {/* CORE-UI STYLE STATS CARDS */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        {statsCards.map((s, idx) => (
          <Grid size={{ xs: 12, sm: 6, md: 3 }} key={idx}>
            <Card sx={{
              height: "100%",
              bgcolor: s.color,
              color: 'white',
              borderRadius: 2,
              position: 'relative',
              overflow: 'hidden',
              boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
            }}>
              <CardContent sx={{ pb: '16px !important' }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <Box>
                    <Typography variant="h4" sx={{ fontWeight: 700, lineHeight: 1 }}>
                      {s.value} <Typography component="span" variant="body2" sx={{ opacity: 0.8, fontSize: '1rem', fontWeight: 500 }}>{s.percentage}</Typography>
                    </Typography>
                    <Typography variant="body1" sx={{ mt: 1, opacity: 0.9, fontWeight: 500 }}>
                      {s.title}
                    </Typography>
                  </Box>
                  <IconButton size="small" sx={{ color: 'white', opacity: 0.8, p: 0 }}>
                    <MoreVertIcon />
                  </IconButton>
                </Box>

                {/* Micro Chart Mockup (SVG) */}
                <Box sx={{ mt: 3, height: 40, width: '100%' }}>
                  {s.chartType === 'line' ? (
                    <svg viewBox="0 0 100 30" width="100%" height="100%" preserveAspectRatio="none">
                      <path d="M0,20 Q10,10 20,25 T40,15 T60,20 T80,5 T100,10 L100,30 L0,30 Z" fill="rgba(255,255,255,0.1)" />
                      <path d="M0,20 Q10,10 20,25 T40,15 T60,20 T80,5 T100,10" fill="none" stroke="rgba(255,255,255,0.6)" strokeWidth="2" />
                      <circle cx="20" cy="25" r="2" fill="white" />
                      <circle cx="40" cy="15" r="2" fill="white" />
                      <circle cx="60" cy="20" r="2" fill="white" />
                      <circle cx="80" cy="5" r="2" fill="white" />
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
            <Card sx={{ borderRadius: 2, overflow: 'hidden', boxShadow: '0 2px 4px rgba(0,0,0,0.05)' }}>
              <Box sx={{ bgcolor: sc.bg, color: 'white', display: 'flex', justifyContent: 'center', py: 3, position: 'relative' }}>
                {sc.icon}
                {/* Subtle curve effect like CoreUI */}
                <svg preserveAspectRatio="none" style={{ position: 'absolute', bottom: 0, left: 0, width: '100%', height: '30px' }} viewBox="0 0 100 100">
                  <path d="M0,100 C20,0 50,0 100,100 Z" fill="rgba(255,255,255,0.15)" />
                </svg>
              </Box>
              <CardContent sx={{ textAlign: 'center', py: 2 }}>
                <Typography variant="h6" sx={{ fontWeight: 700, color: 'text.primary', mb: 0 }}>
                  {sc.title}
                </Typography>
                <Typography variant="body2" color="text.secondary" sx={{ textTransform: 'uppercase', fontWeight: 600, fontSize: '0.75rem', letterSpacing: 1 }}>
                  {sc.description}
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Large Bottom Card (Traffic & Sales Style) */}
      <Card sx={{ borderRadius: 2, boxShadow: '0 2px 8px rgba(0,0,0,0.08)' }}>
        <CardContent>
          <Typography variant="h6" sx={{ fontWeight: 600, mb: 3 }}>
            Balance & Flujo Mensual
          </Typography>

          <Grid container spacing={4}>
            <Grid size={{ xs: 12, md: 4 }}>
              <Box sx={{ borderLeft: '4px solid #321fdb', pl: 2, mb: 3 }}>
                <Typography variant="body2" color="text.secondary">Ingresos Recaudados</Typography>
                <Typography variant="h5" sx={{ fontWeight: 700 }}>$14,123</Typography>
              </Box>
              <Box sx={{ borderLeft: '4px solid #e55353', pl: 2, mb: 3 }}>
                <Typography variant="body2" color="text.secondary">Gastos Fijos</Typography>
                <Typography variant="h5" sx={{ fontWeight: 700 }}>$8,643</Typography>
              </Box>
              <Box sx={{ borderLeft: '4px solid #f9b115', pl: 2 }}>
                <Typography variant="body2" color="text.secondary">Transferencias</Typography>
                <Typography variant="h5" sx={{ fontWeight: 700 }}>$2,800</Typography>
              </Box>
            </Grid>
            <Grid size={{ xs: 12, md: 8 }} sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', bgcolor: '#f8f9fa', borderRadius: 2, minHeight: 200 }}>
              <Typography variant="body2" color="text.secondary" sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <TrendingUpIcon /> [Gráfico Centralizado de Evolución irá aquí]
              </Typography>
            </Grid>
          </Grid>
        </CardContent>
      </Card>
    </Box>
  );
}
