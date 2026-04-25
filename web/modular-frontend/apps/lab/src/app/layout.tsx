"use client";

// Pull in web component JSX type declarations (zentto-grid, report-viewer, report-designer)
import '@zentto/shared-ui/web-components';

import React, { useState, useMemo } from "react";
import { ZenttoChatWidget } from '@zentto/shared-ui';
import {
  AppBar,
  Box,
  Button,
  CssBaseline,
  Drawer,
  IconButton,
  List,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Toolbar,
  Typography,
  Chip,
  useMediaQuery,
} from "@mui/material";
import {
  Science as LabIcon,
  Science as ScienceIcon,
  Inventory as ArticulosIcon,
  Receipt as FacturasIcon,
  AutoAwesome as ShowcaseIcon,
  Description as ReportIcon,
  Menu as MenuIcon,
  Close as CloseIcon,
  RocketLaunch as RocketLaunchIcon,
} from "@mui/icons-material";
import { ThemeProvider, createTheme } from "@mui/material/styles";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { usePathname, useRouter } from "next/navigation";

const NAV_ITEMS = [
  { label: "Articulos", href: "/articulos", icon: <ArticulosIcon fontSize="small" /> },
  { label: "Facturas", href: "/facturas", icon: <FacturasIcon fontSize="small" /> },
  { label: "Nativo: Articulos", href: "/nativo-articulos", icon: <ScienceIcon fontSize="small" /> },
  { label: "Nativo: Facturas", href: "/nativo-facturas", icon: <ScienceIcon fontSize="small" /> },
  { label: "Showcase v1.0", href: "/showcase", icon: <ShowcaseIcon fontSize="small" />, color: "#7c3aed" },
  { label: "Report Designer", href: "/reportes", icon: <ReportIcon fontSize="small" />, color: "#0d9488" },
  { label: "Landing Designer", href: "/landing-designer", icon: <RocketLaunchIcon fontSize="small" />, color: "#e91e63" },
];

// Tema minimo — sin depender de shared-ui theme
const labTheme = createTheme({
  palette: {
    primary: { main: "#f59e0b" },
    secondary: { main: "#1a1a2e" },
  },
});

function LabNav() {
  const pathname = usePathname();
  const router = useRouter();
  const isMobile = useMediaQuery("(max-width:768px)");
  const [drawerOpen, setDrawerOpen] = useState(false);

  const navigate = (href: string) => {
    router.push(href);
    setDrawerOpen(false);
  };

  return (
    <>
      <AppBar position="static" sx={{ bgcolor: "#1a1a2e" }}>
        <Toolbar sx={{ gap: 1, minHeight: { xs: 48, sm: 64 } }}>
          <LabIcon sx={{ fontSize: { xs: 20, sm: 24 } }} />
          <Typography variant="h6" sx={{ fontSize: { xs: 15, sm: 20 } }}>
            Zentto Lab
          </Typography>
          <Chip label="SANDBOX" color="warning" size="small" variant="filled" />
          <Box sx={{ flex: 1 }} />

          {/* Desktop: botones inline */}
          {!isMobile &&
            NAV_ITEMS.map((item) => (
              <Button
                key={item.href}
                startIcon={item.icon}
                onClick={() => navigate(item.href)}
                variant={pathname === item.href ? "contained" : "text"}
                color={pathname === item.href ? "warning" : "inherit"}
                sx={{
                  color: pathname === item.href ? undefined : (item as any).color || "#fff",
                  textTransform: "none",
                  ...((item as any).color && pathname !== item.href ? { fontWeight: 600 } : {}),
                }}
                size="small"
              >
                {item.label}
              </Button>
            ))}

          {/* Mobile: hamburguesa */}
          {isMobile && (
            <IconButton color="inherit" onClick={() => setDrawerOpen(true)} edge="end">
              <MenuIcon />
            </IconButton>
          )}
        </Toolbar>
      </AppBar>

      {/* Mobile Drawer */}
      <Drawer
        anchor="right"
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        PaperProps={{ sx: { width: 260, bgcolor: "#1a1a2e", color: "#fff" } }}
      >
        <Box sx={{ display: "flex", alignItems: "center", justifyContent: "space-between", p: 1.5, borderBottom: "1px solid rgba(255,255,255,0.1)" }}>
          <Typography variant="subtitle1" fontWeight={600}>Zentto Lab</Typography>
          <IconButton color="inherit" onClick={() => setDrawerOpen(false)} size="small">
            <CloseIcon fontSize="small" />
          </IconButton>
        </Box>
        <List sx={{ pt: 1 }}>
          {NAV_ITEMS.map((item) => (
            <ListItemButton
              key={item.href}
              selected={pathname === item.href}
              onClick={() => navigate(item.href)}
              sx={{
                borderRadius: 1,
                mx: 1,
                mb: 0.5,
                "&.Mui-selected": { bgcolor: "rgba(245, 158, 11, 0.15)", color: "#f59e0b" },
                "&.Mui-selected .MuiListItemIcon-root": { color: "#f59e0b" },
              }}
            >
              <ListItemIcon sx={{ color: "inherit", minWidth: 36 }}>{item.icon}</ListItemIcon>
              <ListItemText primary={item.label} primaryTypographyProps={{ fontSize: 14, fontWeight: pathname === item.href ? 600 : 400 }} />
            </ListItemButton>
          ))}
        </List>
      </Drawer>
    </>
  );
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: { staleTime: 30_000, retry: 1, refetchOnWindowFocus: false },
        },
      })
  );

  return (
    <html lang="es">
      <head>
        <title>Zentto Lab — Sandbox ZenttoDataGrid</title>
      </head>
      <body style={{ margin: 0 }}>
        <QueryClientProvider client={queryClient}>
          <ThemeProvider theme={labTheme}>
            <CssBaseline />
            <Box sx={{ display: "flex", flexDirection: "column", height: "100vh" }}>
              <LabNav />
              <Box sx={{ flex: 1, overflow: "auto", p: { xs: 1, sm: 2 } }}>
                {children}
              </Box>
              <script src="https://docs.zentto.net/widget.js" defer />
            </Box>
          </ThemeProvider>
        </QueryClientProvider>
      </body>
    </html>
  );
}
