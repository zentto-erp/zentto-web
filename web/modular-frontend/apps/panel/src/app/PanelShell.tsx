"use client";

import React, { useState, useEffect } from "react";
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
  Tooltip,
} from "@mui/material";
import {
  Dashboard as DashboardIcon,
  Language as SitesIcon,
  Add as AddIcon,
  Menu as MenuIcon,
  Settings as SettingsIcon,
  Article as ArticleIcon,
  Inventory as InventoryIcon,
  ShoppingCart as ShoppingCartIcon,
  LocalOffer as LocalOfferIcon,
  Group as GroupIcon,
  AutoAwesome as AutoAwesomeIcon,
  Logout as LogoutIcon,
  Storefront as StorefrontIcon,
} from "@mui/icons-material";
import { ThemeProvider, createTheme, useTheme } from "@mui/material/styles";
import CssBaseline from "@mui/material/CssBaseline";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { useRouter, usePathname } from "next/navigation";
import { isAuthenticated, getUser, logout } from "../lib/auth";
import { } from '@zentto/shared-ui';

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
  { label: "Templates", href: "/templates", icon: <StorefrontIcon /> },
  { label: "Crear Sitio", href: "/sites/new", icon: <AddIcon />, color: "#059669" },
  { label: "AI Generator", href: "/sites/ai", icon: <AutoAwesomeIcon />, color: "#8b5cf6" },
];

function getSiteNavItems(pathname: string) {
  const match = pathname.match(/^\/sites\/([^/]+)/);
  if (!match || match[1] === "new" || match[1] === "ai") return [];
  const siteId = match[1];
  return [
    { label: "Blog", href: `/sites/${siteId}/blog`, icon: <ArticleIcon /> },
    { label: "Productos", href: `/sites/${siteId}/products`, icon: <InventoryIcon /> },
    { label: "Pedidos", href: `/sites/${siteId}/orders`, icon: <ShoppingCartIcon /> },
    { label: "Cupones", href: `/sites/${siteId}/coupons`, icon: <LocalOfferIcon /> },
    { label: "Equipo", href: `/sites/${siteId}/team`, icon: <GroupIcon /> },
  ];
}

function SidebarContent({ pathname, onNavigate }: { pathname: string; onNavigate: (href: string) => void }) {
  const siteNav = getSiteNavItems(pathname);
  return (
    <Box sx={{ display: "flex", flexDirection: "column", height: "100%" }}>
      <Box sx={{ px: 2.5, py: 3, display: "flex", alignItems: "center", gap: 1.5 }}>
        <Box sx={{ width: 36, height: 36, borderRadius: 2, background: "linear-gradient(135deg, #6366f1, #8b5cf6)", display: "flex", alignItems: "center", justifyContent: "center", color: "#fff", fontWeight: 800, fontSize: 16 }}>Z</Box>
        <Typography variant="h6" sx={{ color: "#fff", fontWeight: 700, fontSize: 18 }}>Zentto Panel</Typography>
      </Box>
      <Divider sx={{ borderColor: "rgba(255,255,255,0.08)", mx: 2 }} />
      <List sx={{ flex: 1, px: 1.5, pt: 2 }}>
        {NAV_ITEMS.map((item) => {
          const isActive = item.href === "/" ? pathname === "/" : pathname.startsWith(item.href);
          return (
            <ListItem key={item.href} disablePadding sx={{ mb: 0.5 }}>
              <ListItemButton onClick={() => onNavigate(item.href)} sx={{ borderRadius: 2, px: 2, py: 1, color: isActive ? "#fff" : "rgba(255,255,255,0.6)", bgcolor: isActive ? "rgba(99,102,241,0.25)" : "transparent", "&:hover": { bgcolor: isActive ? "rgba(99,102,241,0.3)" : "rgba(255,255,255,0.06)", color: "#fff" } }}>
                <ListItemIcon sx={{ minWidth: 36, color: item.color || (isActive ? "#818cf8" : "rgba(255,255,255,0.4)") }}>{item.icon}</ListItemIcon>
                <ListItemText primary={item.label} primaryTypographyProps={{ fontSize: 14, fontWeight: isActive ? 600 : 400 }} />
              </ListItemButton>
            </ListItem>
          );
        })}
        {siteNav.length > 0 && (
          <>
            <Divider sx={{ borderColor: "rgba(255,255,255,0.08)", mx: 2, my: 1 }} />
            <Typography variant="caption" sx={{ px: 2.5, color: "rgba(255,255,255,0.35)", fontWeight: 600, textTransform: "uppercase", letterSpacing: 1 }}>Sitio</Typography>
            {siteNav.map((item) => {
              const isActive = pathname.startsWith(item.href);
              return (
                <ListItem key={item.href} disablePadding sx={{ mb: 0.5 }}>
                  <ListItemButton onClick={() => onNavigate(item.href)} sx={{ borderRadius: 2, px: 2, py: 1, color: isActive ? "#fff" : "rgba(255,255,255,0.6)", bgcolor: isActive ? "rgba(99,102,241,0.25)" : "transparent", "&:hover": { bgcolor: isActive ? "rgba(99,102,241,0.3)" : "rgba(255,255,255,0.06)", color: "#fff" } }}>
                    <ListItemIcon sx={{ minWidth: 36, color: isActive ? "#818cf8" : "rgba(255,255,255,0.4)" }}>{item.icon}</ListItemIcon>
                    <ListItemText primary={item.label} primaryTypographyProps={{ fontSize: 14, fontWeight: isActive ? 600 : 400 }} />
                  </ListItemButton>
                </ListItem>
              );
            })}
          </>
        )}
      </List>
      <Divider sx={{ borderColor: "rgba(255,255,255,0.08)", mx: 2 }} />
      <List sx={{ px: 1.5, pb: 1 }}>
        <ListItem disablePadding>
          <ListItemButton onClick={() => onNavigate("/settings")} sx={{ borderRadius: 2, px: 2, py: 1, color: "rgba(255,255,255,0.5)", "&:hover": { bgcolor: "rgba(255,255,255,0.06)", color: "#fff" } }}>
            <ListItemIcon sx={{ minWidth: 36, color: "rgba(255,255,255,0.35)" }}><SettingsIcon fontSize="small" /></ListItemIcon>
            <ListItemText primary="Configuracion" primaryTypographyProps={{ fontSize: 14 }} />
          </ListItemButton>
        </ListItem>
      </List>
    </Box>
  );
}

export default function PanelShell({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const muiTheme = useTheme();
  const isMobile = useMediaQuery(muiTheme.breakpoints.down("md"));
  const [mobileOpen, setMobileOpen] = useState(false);
  const [checked, setChecked] = useState(false);

  const PUBLIC_PATHS = ["/login", "/register", "/forgot-password"];
  const isPublic = PUBLIC_PATHS.some((p) => pathname?.startsWith(p));

  useEffect(() => {
    if (isPublic) { setChecked(true); return; }
    if (!isAuthenticated()) { router.replace("/login"); return; }
    setChecked(true);
  }, [pathname, isPublic, router]);

  // Public pages — render directly without shell
  if (isPublic) return <>{children}</>;

  if (!checked) {
    return (
      <div style={{ display: "flex", alignItems: "center", justifyContent: "center", height: "100vh" }}>
        <div style={{ width: 36, height: 36, border: "3px solid #e2e8f0", borderTopColor: "#6366f1", borderRadius: "50%", animation: "spin 0.7s linear infinite" }} />
        <style>{"@keyframes spin { to { transform: rotate(360deg); } }"}</style>
      </div>
    );
  }

  const user = getUser();
  const navigate = (href: string) => { router.push(href); if (isMobile) setMobileOpen(false); };

  const drawerContent = <SidebarContent pathname={pathname} onNavigate={navigate} />;

  return (
    <Box sx={{ display: "flex", minHeight: "100vh", bgcolor: "#f8fafc" }}>
      {/* Sidebar */}
      {isMobile ? (
        <Drawer variant="temporary" open={mobileOpen} onClose={() => setMobileOpen(false)} ModalProps={{ keepMounted: true }} sx={{ "& .MuiDrawer-paper": { width: DRAWER_WIDTH, bgcolor: "#0f172a", borderRight: "none" } }}>
          {drawerContent}
        </Drawer>
      ) : (
        <Drawer variant="permanent" sx={{ width: DRAWER_WIDTH, flexShrink: 0, "& .MuiDrawer-paper": { width: DRAWER_WIDTH, bgcolor: "#0f172a", borderRight: "none" } }}>
          {drawerContent}
        </Drawer>
      )}

      {/* Main content */}
      <Box sx={{ flex: 1, display: "flex", flexDirection: "column" }}>
        <AppBar position="sticky" elevation={0} sx={{ bgcolor: "#fff", borderBottom: "1px solid #f1f5f9" }}>
          <Toolbar sx={{ minHeight: "56px !important" }}>
            {isMobile && (
              <IconButton edge="start" onClick={() => setMobileOpen(true)} sx={{ mr: 1, color: "#64748b" }}>
                <MenuIcon />
              </IconButton>
            )}
            <Box sx={{ flex: 1 }} />
            <Tooltip title={user?.name || "Usuario"}>
              <Avatar sx={{ width: 32, height: 32, bgcolor: "#6366f1", fontSize: 14, fontWeight: 600, cursor: "pointer" }}>
                {(user?.name || "U")[0].toUpperCase()}
              </Avatar>
            </Tooltip>
            <Tooltip title="Cerrar sesion">
              <IconButton onClick={() => logout()} sx={{ ml: 1, color: "#94a3b8" }}>
                <LogoutIcon fontSize="small" />
              </IconButton>
            </Tooltip>
          </Toolbar>
        </AppBar>
        <Box component="main" sx={{ flex: 1, p: { xs: 2, md: 3 } }}>
          {children}
        </Box>
        <script src="https://docs.zentto.net/widget.js" defer />
      </Box>
    </Box>
  );
}
