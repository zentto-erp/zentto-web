"use client";

import { useState, useEffect } from "react";
import {
  AppBar, Toolbar, Typography, IconButton, Box, Container, Button,
  Menu, MenuItem, ListItemIcon, ListItemText, Divider, useMediaQuery, useTheme,
  Drawer, List, ListItem, ListItemButton, Chip,
} from "@mui/material";
import { alpha } from "@mui/material/styles";
import LocalShippingIcon from "@mui/icons-material/LocalShipping";
import PersonOutlineIcon from "@mui/icons-material/PersonOutline";
import DashboardIcon from "@mui/icons-material/Dashboard";
import AddBoxIcon from "@mui/icons-material/AddBox";
import ListAltIcon from "@mui/icons-material/ListAlt";
import SearchIcon from "@mui/icons-material/Search";
import LocationOnIcon from "@mui/icons-material/LocationOn";
import LogoutIcon from "@mui/icons-material/Logout";
import MenuIcon from "@mui/icons-material/Menu";
import CloseIcon from "@mui/icons-material/Close";
import HomeIcon from "@mui/icons-material/Home";
import GavelIcon from "@mui/icons-material/Gavel";
import PrintIcon from "@mui/icons-material/Print";
import { useShippingStore } from "../store/useShippingStore";

interface Props {
  children: React.ReactNode;
  onNavigate: (path: string) => void;
}

export default function ShippingLayout({ children, onNavigate }: Props) {
  const [userMenuAnchor, setUserMenuAnchor] = useState<null | HTMLElement>(null);
  const [drawerOpen, setDrawerOpen] = useState(false);

  const customerToken = useShippingStore((s) => s.customerToken);
  const customerInfo = useShippingStore((s) => s.customerInfo);
  const logout = useShippingStore((s) => s.logout);

  const [hydrated, setHydrated] = useState(false);
  useEffect(() => setHydrated(true), []);
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("md"));

  const handleLogout = () => {
    logout();
    setUserMenuAnchor(null);
    onNavigate("/login");
  };

  const navItems = [
    { label: "Dashboard", icon: <DashboardIcon />, path: "/dashboard" },
    { label: "Nuevo Envío", icon: <AddBoxIcon />, path: "/envios/nuevo" },
    { label: "Mis Envíos", icon: <ListAltIcon />, path: "/envios" },
    { label: "Rastrear", icon: <SearchIcon />, path: "/rastreo" },
    { label: "Direcciones", icon: <LocationOnIcon />, path: "/perfil" },
    { label: "Reportes", icon: <PrintIcon />, path: "/reportes" },
  ];

  return (
    <Box sx={{ display: "flex", flexDirection: "column", minHeight: "100vh", bgcolor: "#f5f6fa" }}>
      {/* Top banner */}
      <Box sx={{ bgcolor: "#0d47a1", color: "#fff", py: 0.3, px: 2, display: "flex", justifyContent: "center", gap: { xs: 2, md: 4 }, fontSize: 12 }}>
        <Typography variant="caption" sx={{ display: "flex", alignItems: "center", gap: 0.5, fontSize: 11 }}>
          <LocalShippingIcon sx={{ fontSize: 13 }} /> Envíos nacionales e internacionales
        </Typography>
        <Typography variant="caption" sx={{ display: { xs: "none", sm: "flex" }, alignItems: "center", gap: 0.5, fontSize: 11 }}>
          Rastreo en tiempo real
        </Typography>
        <Typography variant="caption" sx={{ display: { xs: "none", md: "flex" }, alignItems: "center", gap: 0.5, fontSize: 11 }}>
          <GavelIcon sx={{ fontSize: 12 }} /> Gestión de aduanas
        </Typography>
      </Box>

      {/* Main header */}
      <AppBar position="sticky" elevation={0} sx={{ bgcolor: "#1565c0", color: "#fff" }}>
        <Toolbar sx={{ gap: { xs: 0.5, md: 1.5 }, minHeight: { xs: 52, md: 60 }, px: { xs: 1, md: 2 } }}>
          {isMobile && (
            <IconButton color="inherit" onClick={() => setDrawerOpen(true)} edge="start">
              <MenuIcon />
            </IconButton>
          )}

          {/* Logo */}
          <Box
            onClick={() => onNavigate("/")}
            sx={{
              display: "flex", alignItems: "center", gap: 0.5, cursor: "pointer",
              p: "4px 8px", borderRadius: "3px", border: "1px solid transparent",
              "&:hover": { border: "1px solid rgba(255,255,255,0.3)" },
            }}
          >
            <LocalShippingIcon sx={{ fontSize: { xs: 24, md: 28 }, color: "#ffcc02" }} />
            <Typography variant="h6" fontWeight="bold" sx={{ letterSpacing: -0.5, fontSize: { xs: 16, md: 20 } }}>
              Zentto<span style={{ color: "#ffcc02" }}>Shipping</span>
            </Typography>
          </Box>

          <Box sx={{ flexGrow: 1 }} />

          {/* Nav items (desktop) */}
          {!isMobile && hydrated && customerToken && navItems.map((item) => (
            <Button
              key={item.path}
              size="small"
              onClick={() => onNavigate(item.path)}
              sx={{
                color: "#fff", textTransform: "none", fontSize: 13,
                px: 1.5, borderRadius: "3px",
                "&:hover": { bgcolor: alpha("#fff", 0.1) },
              }}
            >
              {item.label}
            </Button>
          ))}

          {/* User / Account */}
          {hydrated && customerToken ? (
            <Box
              onClick={(e) => setUserMenuAnchor(e.currentTarget)}
              sx={{
                display: "flex", flexDirection: "column", cursor: "pointer",
                p: "4px 8px", borderRadius: "3px", border: "1px solid transparent",
                "&:hover": { border: "1px solid rgba(255,255,255,0.3)" },
              }}
            >
              <Typography variant="caption" sx={{ color: "#bbdefb", lineHeight: 1.1, fontSize: 11 }}>
                Hola, {customerInfo?.name?.split(" ")[0] || "Cliente"}
              </Typography>
              <Typography variant="body2" fontWeight="bold" sx={{ lineHeight: 1.2, fontSize: 13 }}>
                Mi Cuenta
              </Typography>
            </Box>
          ) : hydrated ? (
            <Button color="inherit" onClick={() => onNavigate("/login")} sx={{ textTransform: "none", fontWeight: 600 }}>
              Iniciar sesión
            </Button>
          ) : null}

          <Menu anchorEl={userMenuAnchor} open={!!userMenuAnchor} onClose={() => setUserMenuAnchor(null)}>
            <MenuItem onClick={() => { setUserMenuAnchor(null); onNavigate("/dashboard"); }}>
              <ListItemIcon><DashboardIcon fontSize="small" /></ListItemIcon>
              <ListItemText>Dashboard</ListItemText>
            </MenuItem>
            <MenuItem onClick={() => { setUserMenuAnchor(null); onNavigate("/envios"); }}>
              <ListItemIcon><ListAltIcon fontSize="small" /></ListItemIcon>
              <ListItemText>Mis envíos</ListItemText>
            </MenuItem>
            <MenuItem onClick={() => { setUserMenuAnchor(null); onNavigate("/perfil"); }}>
              <ListItemIcon><PersonOutlineIcon fontSize="small" /></ListItemIcon>
              <ListItemText>Mi perfil</ListItemText>
            </MenuItem>
            <Divider />
            <MenuItem onClick={handleLogout}>
              <ListItemIcon><LogoutIcon fontSize="small" /></ListItemIcon>
              <ListItemText>Cerrar sesión</ListItemText>
            </MenuItem>
          </Menu>
        </Toolbar>
      </AppBar>

      {/* Mobile drawer */}
      <Drawer anchor="left" open={drawerOpen} onClose={() => setDrawerOpen(false)} PaperProps={{ sx: { width: 280 } }}>
        <Box sx={{ bgcolor: "#1565c0", color: "#fff", p: 2, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
            <PersonOutlineIcon />
            <Typography variant="subtitle1" fontWeight="bold">
              {hydrated && customerToken ? `Hola, ${customerInfo?.name?.split(" ")[0] || "Cliente"}` : "Zentto Shipping"}
            </Typography>
          </Box>
          <IconButton color="inherit" onClick={() => setDrawerOpen(false)} size="small">
            <CloseIcon />
          </IconButton>
        </Box>
        <List>
          <ListItem disablePadding>
            <ListItemButton onClick={() => { setDrawerOpen(false); onNavigate("/"); }}>
              <ListItemIcon><HomeIcon /></ListItemIcon>
              <ListItemText primary="Inicio" />
            </ListItemButton>
          </ListItem>
          {navItems.map((item) => (
            <ListItem key={item.path} disablePadding>
              <ListItemButton onClick={() => { setDrawerOpen(false); onNavigate(item.path); }}>
                <ListItemIcon>{item.icon}</ListItemIcon>
                <ListItemText primary={item.label} />
              </ListItemButton>
            </ListItem>
          ))}
          {hydrated && customerToken && (
            <>
              <Divider sx={{ my: 1 }} />
              <ListItem disablePadding>
                <ListItemButton onClick={() => { handleLogout(); setDrawerOpen(false); }}>
                  <ListItemIcon><LogoutIcon /></ListItemIcon>
                  <ListItemText primary="Cerrar sesión" />
                </ListItemButton>
              </ListItem>
            </>
          )}
        </List>
      </Drawer>

      {/* Content */}
      <Box sx={{ flexGrow: 1 }}>
        <Container maxWidth="xl" sx={{ py: 2, px: { xs: 1, md: 2 } }}>
          {children}
        </Container>
      </Box>

      {/* Footer */}
      <Box sx={{ bgcolor: "#1565c0", color: "#fff", py: 3 }}>
        <Container maxWidth="xl">
          <Box sx={{ display: "flex", flexWrap: "wrap", justifyContent: "space-between", gap: 3 }}>
            <Box>
              <Typography variant="subtitle2" fontWeight="bold" sx={{ mb: 1 }}>Zentto Shipping</Typography>
              <Typography variant="caption" sx={{ color: "#bbdefb" }}>
                Plataforma de envíos nacionales e internacionales
              </Typography>
            </Box>
            <Box>
              <Typography variant="subtitle2" fontWeight="bold" sx={{ mb: 1 }}>Carriers</Typography>
              <Box sx={{ display: "flex", gap: 0.5, flexWrap: "wrap" }}>
                {["Zoom", "MRW", "Liberty Express"].map((c) => (
                  <Chip key={c} label={c} size="small" sx={{ bgcolor: alpha("#fff", 0.15), color: "#fff", fontSize: 11 }} />
                ))}
              </Box>
            </Box>
            <Box>
              <Typography variant="subtitle2" fontWeight="bold" sx={{ mb: 1 }}>Soporte</Typography>
              {[{ label: "Centro de ayuda", href: "#" }, { label: "Contacto", href: "#" }].map((item) => (
                <Typography key={item.label} variant="body2" sx={{ color: "#bbdefb", fontSize: 13, cursor: "pointer", "&:hover": { textDecoration: "underline" } }}>
                  {item.label}
                </Typography>
              ))}
            </Box>
          </Box>
        </Container>
      </Box>
      <Box sx={{ bgcolor: "#0d47a1", color: "#90caf9", py: 1.5, textAlign: "center" }}>
        <Typography variant="caption">&copy; {new Date().getFullYear()} Zentto Shipping. Todos los derechos reservados.</Typography>
      </Box>
    </Box>
  );
}
