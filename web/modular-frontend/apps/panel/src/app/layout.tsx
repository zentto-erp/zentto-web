"use client";

import React, { useState } from "react";
import {
  Box,
  Drawer,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  AppBar,
  Toolbar,
  Typography,
  IconButton,
  Avatar,
  Divider,
  useMediaQuery,
} from "@mui/material";
import {
  Dashboard as DashboardIcon,
  Language as SitesIcon,
  Add as AddIcon,
  Menu as MenuIcon,
  Settings as SettingsIcon,
} from "@mui/icons-material";
import { ThemeProvider, createTheme, useTheme } from "@mui/material/styles";
import CssBaseline from "@mui/material/CssBaseline";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { useRouter, usePathname } from "next/navigation";

const theme = createTheme({
  palette: {
    mode: "light",
    primary: { main: "#6366f1" },
    background: { default: "#f8fafc" },
  },
  typography: { fontFamily: "Inter, system-ui, sans-serif" },
  shape: { borderRadius: 10 },
});

const DRAWER_WIDTH = 240;
const queryClient = new QueryClient();

const NAV_ITEMS = [
  { label: "Dashboard", href: "/", icon: <DashboardIcon /> },
  { label: "Mis Sitios", href: "/sites", icon: <SitesIcon /> },
  { label: "Crear Sitio", href: "/sites/new", icon: <AddIcon />, color: "#059669" },
];

function SidebarContent({ pathname, onNavigate }: { pathname: string; onNavigate: (href: string) => void }) {
  return (
    <Box sx={{ display: "flex", flexDirection: "column", height: "100%" }}>
      {/* Brand */}
      <Box sx={{ px: 2.5, py: 3, display: "flex", alignItems: "center", gap: 1.5 }}>
        <Box
          sx={{
            width: 36,
            height: 36,
            borderRadius: 2,
            background: "linear-gradient(135deg, #6366f1, #8b5cf6)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            color: "#fff",
            fontWeight: 800,
            fontSize: 16,
          }}
        >
          Z
        </Box>
        <Typography variant="h6" sx={{ color: "#fff", fontWeight: 700, fontSize: 18 }}>
          Zentto Panel
        </Typography>
      </Box>

      <Divider sx={{ borderColor: "rgba(255,255,255,0.08)", mx: 2 }} />

      {/* Nav */}
      <List sx={{ flex: 1, px: 1.5, pt: 2 }}>
        {NAV_ITEMS.map((item) => {
          const isActive = item.href === "/" ? pathname === "/" : pathname.startsWith(item.href);
          return (
            <ListItem key={item.href} disablePadding sx={{ mb: 0.5 }}>
              <ListItemButton
                onClick={() => onNavigate(item.href)}
                sx={{
                  borderRadius: 2,
                  px: 2,
                  py: 1,
                  color: isActive ? "#fff" : "rgba(255,255,255,0.6)",
                  bgcolor: isActive ? "rgba(99,102,241,0.25)" : "transparent",
                  "&:hover": {
                    bgcolor: isActive ? "rgba(99,102,241,0.3)" : "rgba(255,255,255,0.06)",
                    color: "#fff",
                  },
                }}
              >
                <ListItemIcon
                  sx={{
                    minWidth: 36,
                    color: item.color || (isActive ? "#818cf8" : "rgba(255,255,255,0.4)"),
                  }}
                >
                  {item.icon}
                </ListItemIcon>
                <ListItemText
                  primary={item.label}
                  primaryTypographyProps={{ fontSize: 14, fontWeight: isActive ? 600 : 400 }}
                />
              </ListItemButton>
            </ListItem>
          );
        })}
      </List>

      {/* Footer */}
      <Divider sx={{ borderColor: "rgba(255,255,255,0.08)", mx: 2 }} />
      <List sx={{ px: 1.5, pb: 1 }}>
        <ListItem disablePadding>
          <ListItemButton
            onClick={() => onNavigate("/settings")}
            sx={{
              borderRadius: 2,
              px: 2,
              py: 1,
              color: "rgba(255,255,255,0.5)",
              "&:hover": { bgcolor: "rgba(255,255,255,0.06)", color: "#fff" },
            }}
          >
            <ListItemIcon sx={{ minWidth: 36, color: "rgba(255,255,255,0.35)" }}>
              <SettingsIcon fontSize="small" />
            </ListItemIcon>
            <ListItemText
              primary="Configuracion"
              primaryTypographyProps={{ fontSize: 14 }}
            />
          </ListItemButton>
        </ListItem>
      </List>
    </Box>
  );
}

function PanelLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const muiTheme = useTheme();
  const isMobile = useMediaQuery(muiTheme.breakpoints.down("md"));
  const [mobileOpen, setMobileOpen] = useState(false);

  const handleNavigate = (href: string) => {
    router.push(href);
    if (isMobile) setMobileOpen(false);
  };

  const drawerContent = <SidebarContent pathname={pathname} onNavigate={handleNavigate} />;

  const drawerSx = {
    "& .MuiDrawer-paper": {
      width: DRAWER_WIDTH,
      bgcolor: "#1e293b",
      border: "none",
      boxShadow: "2px 0 8px rgba(0,0,0,0.1)",
    },
  };

  return (
    <Box sx={{ display: "flex", minHeight: "100vh" }}>
      {/* Sidebar - permanent on desktop, temporary on mobile */}
      {isMobile ? (
        <Drawer
          variant="temporary"
          open={mobileOpen}
          onClose={() => setMobileOpen(false)}
          ModalProps={{ keepMounted: true }}
          sx={drawerSx}
        >
          {drawerContent}
        </Drawer>
      ) : (
        <Drawer variant="permanent" sx={drawerSx}>
          {drawerContent}
        </Drawer>
      )}

      {/* Main content */}
      <Box sx={{ flex: 1, display: "flex", flexDirection: "column", ml: isMobile ? 0 : `${DRAWER_WIDTH}px` }}>
        {/* Top bar */}
        <AppBar
          position="sticky"
          elevation={0}
          sx={{
            bgcolor: "#fff",
            borderBottom: "1px solid #e2e8f0",
            color: "#1e293b",
          }}
        >
          <Toolbar sx={{ gap: 2 }}>
            {isMobile && (
              <IconButton edge="start" onClick={() => setMobileOpen(true)} sx={{ color: "#64748b" }}>
                <MenuIcon />
              </IconButton>
            )}
            <Typography variant="h6" sx={{ flex: 1, fontWeight: 600, fontSize: 16, color: "#334155" }}>
              Zentto Panel
            </Typography>
            <Avatar
              sx={{
                width: 34,
                height: 34,
                bgcolor: "#6366f1",
                fontSize: 14,
                fontWeight: 600,
                cursor: "pointer",
              }}
            >
              U
            </Avatar>
          </Toolbar>
        </AppBar>

        {/* Page content */}
        <Box component="main" sx={{ flex: 1, p: { xs: 2, md: 3 } }}>
          {children}
        </Box>
      </Box>
    </Box>
  );
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="es">
      <body style={{ margin: 0 }}>
        <QueryClientProvider client={queryClient}>
          <ThemeProvider theme={theme}>
            <CssBaseline />
            <PanelLayout>{children}</PanelLayout>
          </ThemeProvider>
        </QueryClientProvider>
      </body>
    </html>
  );
}
