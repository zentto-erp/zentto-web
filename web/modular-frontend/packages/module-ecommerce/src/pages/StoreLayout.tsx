"use client";

import { useState, useEffect, useRef } from "react";
import {
  AppBar, Toolbar, Typography, IconButton, Badge, Box, Container, Button,
  InputBase, Divider, Menu, MenuItem, ListItemIcon, ListItemText, useMediaQuery, useTheme,
  Paper, Drawer, List, ListItem, ListItemButton,
} from "@mui/material";
import { alpha } from "@mui/material/styles";
import ShoppingCartIcon from "@mui/icons-material/ShoppingCart";
import SearchIcon from "@mui/icons-material/Search";
import PersonOutlineIcon from "@mui/icons-material/PersonOutline";
import LocalShippingOutlinedIcon from "@mui/icons-material/LocalShippingOutlined";
import FavoriteBorderIcon from "@mui/icons-material/FavoriteBorder";
import MenuIcon from "@mui/icons-material/Menu";
import StoreIcon from "@mui/icons-material/Store";
import LogoutIcon from "@mui/icons-material/Logout";
import ReceiptLongIcon from "@mui/icons-material/ReceiptLong";
import HistoryIcon from "@mui/icons-material/History";
import CloseIcon from "@mui/icons-material/Close";
import CategoryIcon from "@mui/icons-material/Category";
import HomeIcon from "@mui/icons-material/Home";
import LocationOnOutlinedIcon from "@mui/icons-material/LocationOnOutlined";
import { useCartStore } from "../store/useCartStore";
import { useSearchHistoryStore } from "../store/useSearchHistoryStore";
import CartDrawer from "../components/CartDrawer";

interface Props {
  children: React.ReactNode;
  onNavigate: (path: string) => void;
}

export default function StoreLayout({ children, onNavigate }: Props) {
  const [cartOpen, setCartOpen] = useState(false);
  const [searchText, setSearchText] = useState("");
  const [userMenuAnchor, setUserMenuAnchor] = useState<null | HTMLElement>(null);
  const [searchFocused, setSearchFocused] = useState(false);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const searchRef = useRef<HTMLDivElement>(null);

  const getItemCount = useCartStore((s) => s.getItemCount);
  const getTotal = useCartStore((s) => s.getTotal);
  const customerToken = useCartStore((s) => s.customerToken);
  const customerInfo = useCartStore((s) => s.customerInfo);
  const setCustomerToken = useCartStore((s) => s.setCustomerToken);

  const searchTerms = useSearchHistoryStore((s) => s.terms);
  const addSearchTerm = useSearchHistoryStore((s) => s.addTerm);
  const removeSearchTerm = useSearchHistoryStore((s) => s.removeTerm);

  const [hydrated, setHydrated] = useState(false);
  useEffect(() => setHydrated(true), []);
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("md"));
  const isSmall = useMediaQuery(theme.breakpoints.down("sm"));

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (searchRef.current && !searchRef.current.contains(e.target as Node)) {
        setSearchFocused(false);
      }
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  const handleSearch = (e?: React.FormEvent) => {
    e?.preventDefault();
    if (searchText.trim()) {
      addSearchTerm(searchText.trim());
      onNavigate(`/productos?search=${encodeURIComponent(searchText.trim())}`);
      setSearchFocused(false);
    }
  };

  const handleSearchTermClick = (term: string) => {
    setSearchText(term);
    addSearchTerm(term);
    onNavigate(`/productos?search=${encodeURIComponent(term)}`);
    setSearchFocused(false);
  };

  const handleLogout = () => {
    setCustomerToken(null);
    setUserMenuAnchor(null);
  };

  const showSuggestions = hydrated && searchFocused && searchTerms.length > 0;
  const cartCount = hydrated ? getItemCount() : 0;
  const cartTotal = hydrated ? getTotal() : 0;

  return (
    <Box sx={{ display: "flex", flexDirection: "column", minHeight: "100vh", bgcolor: "#eaeded" }}>
      {/* Top banner */}
      <Box sx={{ bgcolor: "#232f3e", color: "#fff", py: 0.3, px: 2, display: "flex", justifyContent: "center", gap: { xs: 2, md: 4 }, fontSize: 12 }}>
        <Typography variant="caption" sx={{ display: "flex", alignItems: "center", gap: 0.5, fontSize: 11 }}>
          <LocalShippingOutlinedIcon sx={{ fontSize: 13 }} /> Envíos a todo el país
        </Typography>
        <Typography variant="caption" sx={{ display: { xs: "none", sm: "flex" }, alignItems: "center", gap: 0.5, fontSize: 11 }}>
          Pago seguro garantizado
        </Typography>
        <Typography variant="caption" sx={{ display: { xs: "none", md: "flex" }, alignItems: "center", gap: 0.5, fontSize: 11 }}>
          Atención al cliente 24/7
        </Typography>
      </Box>

      {/* ═══ Main header ═══ */}
      <AppBar position="sticky" elevation={0} sx={{ bgcolor: "#131921", color: "#fff" }}>
        <Toolbar
          sx={{
            gap: { xs: 0.5, md: 1.5 },
            minHeight: { xs: 52, md: 60 },
            px: { xs: 1, md: 2 },
          }}
        >
          {/* Mobile hamburger */}
          {isMobile && (
            <IconButton color="inherit" onClick={() => setDrawerOpen(true)} edge="start" sx={{ p: 0.8 }}>
              <MenuIcon />
            </IconButton>
          )}

          {/* Logo */}
          <Box
            onClick={() => onNavigate("/")}
            sx={{
              display: "flex", alignItems: "center", gap: 0.5, cursor: "pointer",
              flexShrink: 0, mr: { xs: 0.5, md: 1 },
              p: "4px 8px",
              borderRadius: "3px",
              border: "1px solid transparent",
              "&:hover": { border: "1px solid #fff" },
            }}
          >
            <StoreIcon sx={{ fontSize: { xs: 24, md: 28 }, color: "#ff9900" }} />
            {!isSmall && (
              <Typography variant="h6" fontWeight="bold" sx={{ letterSpacing: -0.5, fontSize: { xs: 16, md: 20 }, lineHeight: 1 }}>
                Zentto<span style={{ color: "#ff9900" }}>Store</span>
              </Typography>
            )}
          </Box>

          {/* Location (desktop only) */}
          {!isMobile && (
            <Box
              sx={{
                display: "flex", alignItems: "center", gap: 0.3, cursor: "pointer", flexShrink: 0,
                p: "4px 8px", borderRadius: "3px", border: "1px solid transparent",
                "&:hover": { border: "1px solid #fff" },
              }}
            >
              <LocationOnOutlinedIcon sx={{ fontSize: 18, color: "#fff" }} />
              <Box>
                <Typography variant="caption" sx={{ color: "#ccc", lineHeight: 1, display: "block", fontSize: 10 }}>
                  Enviar a
                </Typography>
                <Typography variant="body2" fontWeight="bold" sx={{ lineHeight: 1, fontSize: 13 }}>
                  Tu ubicación
                </Typography>
              </Box>
            </Box>
          )}

          {/* ═══ Search bar ═══ */}
          <Box ref={searchRef} sx={{ flexGrow: 1, position: "relative", mx: { xs: 0.5, md: 1 } }}>
            <Box
              component="form"
              onSubmit={handleSearch}
              sx={{
                display: "flex",
                bgcolor: "#fff",
                borderRadius: showSuggestions ? "6px 6px 0 0" : "6px",
                overflow: "hidden",
                height: { xs: 36, md: 40 },
                border: "2px solid transparent",
                "&:focus-within": { border: "2px solid #ff9900", boxShadow: "0 0 0 3px rgba(255,153,0,0.2)" },
              }}
            >
              <InputBase
                placeholder="Buscar productos, marcas y más..."
                value={searchText}
                onChange={(e) => setSearchText(e.target.value)}
                onFocus={() => setSearchFocused(true)}
                sx={{ flex: 1, pl: 1.5, fontSize: { xs: 13, md: 14 }, color: "#000" }}
              />
              <Box
                component="button"
                type="submit"
                sx={{
                  bgcolor: "#febd69", border: "none", px: { xs: 1, md: 1.5 }, cursor: "pointer",
                  display: "flex", alignItems: "center",
                  "&:hover": { bgcolor: "#f3a847" },
                }}
              >
                <SearchIcon sx={{ color: "#131921", fontSize: { xs: 20, md: 24 } }} />
              </Box>
            </Box>

            {/* Search suggestions */}
            {showSuggestions && (
              <Paper
                elevation={8}
                sx={{
                  position: "absolute", top: "100%", left: 0, right: 0, zIndex: 1300,
                  borderRadius: "0 0 6px 6px", border: "1px solid #ddd", borderTop: "none",
                  maxHeight: 260, overflow: "auto", bgcolor: "#fff",
                }}
              >
                <Box sx={{ px: 2, py: 0.8, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                  <Typography variant="caption" sx={{ color: "#565959", fontWeight: 600, fontSize: 11 }}>
                    Búsquedas recientes
                  </Typography>
                </Box>
                <Divider />
                {searchTerms.slice(0, 6).map((entry) => (
                  <Box
                    key={entry.term}
                    onClick={() => handleSearchTermClick(entry.term)}
                    sx={{
                      display: "flex", alignItems: "center", px: 2, py: 0.7,
                      cursor: "pointer", "&:hover": { bgcolor: "#f0f0f0" },
                    }}
                  >
                    <HistoryIcon sx={{ fontSize: 15, color: "#999", mr: 1.5 }} />
                    <Typography variant="body2" sx={{ flex: 1, color: "#0f1111", fontSize: 14 }}>
                      {entry.term}
                    </Typography>
                    <IconButton
                      size="small"
                      onClick={(e) => { e.stopPropagation(); removeSearchTerm(entry.term); }}
                      sx={{ p: 0.3 }}
                    >
                      <CloseIcon sx={{ fontSize: 13, color: "#aaa" }} />
                    </IconButton>
                  </Box>
                ))}
              </Paper>
            )}
          </Box>

          {/* ═══ Right side actions ═══ */}

          {/* User / Account */}
          <Box
            onClick={(e) => {
              if (customerToken) setUserMenuAnchor(e.currentTarget);
              else onNavigate("/login");
            }}
            sx={{
              display: { xs: "none", sm: "flex" }, flexDirection: "column", cursor: "pointer",
              p: "4px 8px", borderRadius: "3px", border: "1px solid transparent",
              "&:hover": { border: "1px solid #fff" },
              flexShrink: 0,
            }}
          >
            <Typography variant="caption" sx={{ color: "#ccc", lineHeight: 1.1, fontSize: 11 }}>
              {hydrated && customerToken ? `Hola, ${customerInfo?.name?.split(" ")[0] || "Cliente"}` : "Hola, Identifícate"}
            </Typography>
            <Typography variant="body2" fontWeight="bold" sx={{ lineHeight: 1.2, fontSize: 13 }}>
              Cuenta y Listas
            </Typography>
          </Box>
          <Menu anchorEl={userMenuAnchor} open={!!userMenuAnchor} onClose={() => setUserMenuAnchor(null)}>
            <MenuItem onClick={() => { setUserMenuAnchor(null); onNavigate("/pedidos"); }}>
              <ListItemIcon><ReceiptLongIcon fontSize="small" /></ListItemIcon>
              <ListItemText>Mis pedidos</ListItemText>
            </MenuItem>
            <Divider />
            <MenuItem onClick={handleLogout}>
              <ListItemIcon><LogoutIcon fontSize="small" /></ListItemIcon>
              <ListItemText>Cerrar sesión</ListItemText>
            </MenuItem>
          </Menu>

          {/* Orders */}
          <Box
            onClick={() => onNavigate("/pedidos")}
            sx={{
              display: { xs: "none", md: "flex" }, flexDirection: "column", cursor: "pointer",
              p: "4px 8px", borderRadius: "3px", border: "1px solid transparent",
              "&:hover": { border: "1px solid #fff" },
              flexShrink: 0,
            }}
          >
            <Typography variant="caption" sx={{ color: "#ccc", lineHeight: 1.1, fontSize: 11 }}>Devoluciones</Typography>
            <Typography variant="body2" fontWeight="bold" sx={{ lineHeight: 1.2, fontSize: 13 }}>y Pedidos</Typography>
          </Box>

          {/* ═══ Cart ═══ */}
          <Box
            onClick={() => setCartOpen(true)}
            sx={{
              display: "flex", alignItems: "flex-end", cursor: "pointer",
              p: "4px 8px", borderRadius: "3px", border: "1px solid transparent",
              "&:hover": { border: "1px solid #fff" },
              flexShrink: 0, gap: 0.3,
            }}
          >
            <Badge
              badgeContent={cartCount}
              sx={{
                "& .MuiBadge-badge": {
                  bgcolor: "#ff9900", color: "#0f1111", fontWeight: "bold",
                  fontSize: 14, minWidth: 20, height: 20, top: -2, right: -2,
                },
              }}
            >
              <ShoppingCartIcon sx={{ fontSize: { xs: 26, md: 30 } }} />
            </Badge>
            <Typography variant="body2" fontWeight="bold" sx={{ lineHeight: 1, display: { xs: "none", sm: "block" }, fontSize: 13, mb: "2px" }}>
              Carrito
            </Typography>
          </Box>
        </Toolbar>

        {/* ═══ Category nav bar ═══ */}
        <Box
          sx={{
            bgcolor: "#232f3e", px: { xs: 1, md: 2 }, py: 0.3,
            display: "flex", alignItems: "center", gap: 0, overflowX: "auto",
            "&::-webkit-scrollbar": { display: "none" },
          }}
        >
          <Button
            size="small"
            startIcon={<MenuIcon sx={{ fontSize: 18 }} />}
            onClick={() => isMobile ? setDrawerOpen(true) : onNavigate("/productos")}
            sx={{
              color: "#fff", textTransform: "none", fontWeight: "bold", fontSize: 13,
              whiteSpace: "nowrap", px: 1.5, py: 0.5, borderRadius: "3px",
              "&:hover": { bgcolor: alpha("#fff", 0.1) },
            }}
          >
            Todo
          </Button>
          {["Ofertas del Día", "Novedades", "Más vendidos", "Envío Gratis"].map((label) => (
            <Button
              key={label}
              size="small"
              onClick={() => onNavigate("/productos")}
              sx={{
                color: "#ddd", textTransform: "none", fontSize: 13,
                whiteSpace: "nowrap", px: 1, py: 0.5, borderRadius: "3px",
                "&:hover": { bgcolor: alpha("#fff", 0.1), color: "#fff" },
              }}
            >
              {label}
            </Button>
          ))}
        </Box>
      </AppBar>

      {/* Mobile Navigation Drawer */}
      <Drawer
        anchor="left"
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        PaperProps={{ sx: { width: 300, bgcolor: "#fff" } }}
      >
        <Box sx={{ bgcolor: "#232f3e", color: "#fff", p: 2, display: "flex", alignItems: "center", justifyContent: "space-between" }}>
          <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
            <PersonOutlineIcon />
            <Typography variant="subtitle1" fontWeight="bold">
              {hydrated && customerToken
                ? `Hola, ${customerInfo?.name?.split(" ")[0] || "Cliente"}`
                : "Hola, Identifícate"}
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
          <ListItem disablePadding>
            <ListItemButton onClick={() => { setDrawerOpen(false); onNavigate("/productos"); }}>
              <ListItemIcon><CategoryIcon /></ListItemIcon>
              <ListItemText primary="Todos los productos" />
            </ListItemButton>
          </ListItem>
          <ListItem disablePadding>
            <ListItemButton onClick={() => { setDrawerOpen(false); onNavigate("/productos"); }}>
              <ListItemIcon><FavoriteBorderIcon /></ListItemIcon>
              <ListItemText primary="Favoritos" />
            </ListItemButton>
          </ListItem>
          <ListItem disablePadding>
            <ListItemButton onClick={() => { setDrawerOpen(false); onNavigate("/pedidos"); }}>
              <ListItemIcon><ReceiptLongIcon /></ListItemIcon>
              <ListItemText primary="Mis pedidos" />
            </ListItemButton>
          </ListItem>
          <Divider sx={{ my: 1 }} />
          {["Ofertas del Día", "Novedades", "Más vendidos"].map((label) => (
            <ListItem key={label} disablePadding>
              <ListItemButton onClick={() => { setDrawerOpen(false); onNavigate("/productos"); }}>
                <ListItemText primary={label} sx={{ pl: 2 }} />
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
        <Container maxWidth="xl" sx={{ py: 0, px: { xs: 1, md: 2 } }}>
          {children}
        </Container>
      </Box>

      {/* Footer */}
      <Box
        onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
        sx={{ bgcolor: "#37475a", color: "#fff", py: 1.5, textAlign: "center", cursor: "pointer", "&:hover": { bgcolor: "#485769" } }}
      >
        <Typography variant="body2" sx={{ fontSize: 13 }}>Volver arriba</Typography>
      </Box>
      <Box sx={{ bgcolor: "#232f3e", color: "#fff", py: 4 }}>
        <Container maxWidth="xl">
          <Box sx={{ display: "flex", flexWrap: "wrap", justifyContent: "space-between", gap: 4 }}>
            {[
              { title: "Conócenos", items: [
                { label: "Acerca de Zentto", href: "/ecommerce/acerca" },
                { label: "Trabaja con nosotros", href: "/ecommerce/trabaja-con-nosotros" },
                { label: "Prensa", href: "/ecommerce/prensa" },
              ]},
              { title: "Gana dinero", items: [
                { label: "Vende en Zentto Store", href: "/ecommerce/vende" },
                { label: "Programa de afiliados", href: "/ecommerce/afiliados" },
              ]},
              { title: "Ayuda", items: [
                { label: "Centro de ayuda", href: "/ecommerce/centro-de-ayuda" },
                { label: "Devoluciones", href: "/ecommerce/devoluciones" },
                { label: "Contacto", href: "/ecommerce/contacto" },
              ]},
            ].map((col) => (
              <Box key={col.title}>
                <Typography variant="subtitle2" fontWeight="bold" sx={{ mb: 1, fontSize: 14 }}>{col.title}</Typography>
                {col.items.map((item) => (
                  <Box key={item.label} component="a" href={item.href} sx={{ display: "block", color: "#ddd", mb: 0.5, cursor: "pointer", fontSize: 13, textDecoration: "none", "&:hover": { textDecoration: "underline" } }}>
                    <Typography variant="body2" sx={{ color: "inherit", fontSize: 13 }}>{item.label}</Typography>
                  </Box>
                ))}
              </Box>
            ))}
          </Box>
        </Container>
      </Box>
      <Box sx={{ bgcolor: "#131921", color: "#999", py: 2, textAlign: "center" }}>
        <Typography variant="caption">
          &copy; {new Date().getFullYear()} Zentto Store. Todos los derechos reservados.
        </Typography>
      </Box>

      <CartDrawer
        open={cartOpen}
        onClose={() => setCartOpen(false)}
        onCheckout={() => {
          setCartOpen(false);
          onNavigate("/checkout");
        }}
      />
    </Box>
  );
}
