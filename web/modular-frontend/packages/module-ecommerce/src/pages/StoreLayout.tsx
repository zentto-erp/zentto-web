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
import DeleteIcon from "@mui/icons-material/Delete";
import CategoryIcon from "@mui/icons-material/Category";
import HomeIcon from "@mui/icons-material/Home";
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

  // Defer persisted store values to avoid hydration mismatch (server=0, client=localStorage)
  const [hydrated, setHydrated] = useState(false);
  useEffect(() => setHydrated(true), []);
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("md"));

  // Close search suggestions on outside click
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

  return (
    <Box sx={{ display: "flex", flexDirection: "column", minHeight: "100vh", bgcolor: "#f5f5f5" }}>
      {/* Top banner */}
      <Box sx={{ bgcolor: "#232f3e", color: "#fff", py: 0.5, px: 2, display: "flex", justifyContent: "center", gap: 4 }}>
        <Typography variant="caption" sx={{ display: "flex", alignItems: "center", gap: 0.5 }}>
          <LocalShippingOutlinedIcon sx={{ fontSize: 14 }} /> Envios a todo el pais
        </Typography>
        <Typography variant="caption" sx={{ display: { xs: "none", sm: "flex" }, alignItems: "center", gap: 0.5 }}>
          Pago seguro garantizado
        </Typography>
        <Typography variant="caption" sx={{ display: { xs: "none", md: "flex" }, alignItems: "center", gap: 0.5 }}>
          Atencion al cliente 24/7
        </Typography>
      </Box>

      {/* Main header */}
      <AppBar position="sticky" elevation={0} sx={{ bgcolor: "#131921", color: "#fff" }}>
        <Toolbar sx={{ gap: 1, minHeight: { xs: 56, md: 64 } }}>
          {/* Mobile menu button */}
          {isMobile && (
            <IconButton color="inherit" onClick={() => setDrawerOpen(true)} sx={{ mr: 0.5 }}>
              <MenuIcon />
            </IconButton>
          )}

          {/* Logo */}
          <Box
            onClick={() => onNavigate("/")}
            sx={{
              display: "flex", alignItems: "center", gap: 0.5, cursor: "pointer", mr: 2,
              borderBottom: "2px solid transparent",
              "&:hover": { opacity: 0.85, borderBottomColor: "#fff" },
              pb: 0.3,
            }}
          >
            <StoreIcon sx={{ fontSize: 28, color: "#ff9900" }} />
            {!isMobile && (
              <Typography variant="h6" fontWeight="bold" sx={{ letterSpacing: -0.5 }}>
                DatqBox<span style={{ color: "#ff9900" }}>Store</span>
              </Typography>
            )}
          </Box>

          {/* Search bar with suggestions */}
          <Box ref={searchRef} sx={{ flexGrow: 1, position: "relative", maxWidth: 700 }}>
            <Box
              component="form"
              onSubmit={handleSearch}
              sx={{
                display: "flex",
                bgcolor: "#fff",
                borderRadius: showSuggestions ? "8px 8px 0 0" : "8px",
                overflow: "hidden",
                height: 40,
                border: "2px solid #ff9900",
                "&:focus-within": { border: "2px solid #febd69" },
              }}
            >
              <InputBase
                placeholder="Buscar productos, marcas y mas..."
                value={searchText}
                onChange={(e) => setSearchText(e.target.value)}
                onFocus={() => setSearchFocused(true)}
                sx={{ flex: 1, pl: 2, fontSize: 14, color: "#000" }}
              />
              <Box
                component="button"
                type="submit"
                sx={{
                  bgcolor: "#febd69", border: "none", px: 1.5, cursor: "pointer",
                  display: "flex", alignItems: "center",
                  "&:hover": { bgcolor: "#f3a847" },
                }}
              >
                <SearchIcon sx={{ color: "#131921" }} />
              </Box>
            </Box>

            {/* Search suggestions dropdown */}
            {showSuggestions && (
              <Paper
                elevation={4}
                sx={{
                  position: "absolute",
                  top: "100%",
                  left: 0,
                  right: 0,
                  zIndex: 1300,
                  borderRadius: "0 0 8px 8px",
                  border: "1px solid #e3e6e6",
                  borderTop: "none",
                  maxHeight: 280,
                  overflow: "auto",
                }}
              >
                <Box sx={{ px: 2, py: 1, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                  <Typography variant="caption" sx={{ color: "#565959", fontWeight: 600 }}>
                    Busquedas recientes
                  </Typography>
                </Box>
                <Divider />
                {searchTerms.slice(0, 5).map((entry) => (
                  <Box
                    key={entry.term}
                    sx={{
                      display: "flex",
                      alignItems: "center",
                      px: 2,
                      py: 0.8,
                      cursor: "pointer",
                      "&:hover": { bgcolor: "#f7f7f7" },
                    }}
                  >
                    <HistoryIcon sx={{ fontSize: 16, color: "#565959", mr: 1.5 }} />
                    <Typography
                      variant="body2"
                      sx={{ flex: 1, color: "#0f1111", fontSize: 14 }}
                      onClick={() => handleSearchTermClick(entry.term)}
                    >
                      {entry.term}
                    </Typography>
                    <IconButton
                      size="small"
                      onClick={(e) => {
                        e.stopPropagation();
                        removeSearchTerm(entry.term);
                      }}
                      sx={{ p: 0.3 }}
                    >
                      <CloseIcon sx={{ fontSize: 14, color: "#999" }} />
                    </IconButton>
                  </Box>
                ))}
              </Paper>
            )}
          </Box>

          {/* User */}
          <Box
            onClick={(e) => {
              if (customerToken) setUserMenuAnchor(e.currentTarget);
              else onNavigate("/login");
            }}
            sx={{
              display: { xs: "none", sm: "flex" }, flexDirection: "column", cursor: "pointer", ml: 1,
              "&:hover": { opacity: 0.85 }, minWidth: 80,
            }}
          >
            <Typography variant="caption" sx={{ color: "#ccc", lineHeight: 1.2 }}>
              {hydrated && customerToken ? `Hola, ${customerInfo?.name?.split(" ")[0] || "Cliente"}` : "Hola, Identifícate"}
            </Typography>
            <Typography variant="body2" fontWeight="bold" sx={{ lineHeight: 1.2, display: "flex", alignItems: "center", gap: 0.3 }}>
              <PersonOutlineIcon sx={{ fontSize: 16 }} />
              {hydrated && customerToken ? "Mi cuenta" : "Ingresar"}
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
              <ListItemText>Cerrar sesion</ListItemText>
            </MenuItem>
          </Menu>

          {/* Orders */}
          <Box
            onClick={() => onNavigate("/pedidos")}
            sx={{
              display: { xs: "none", md: "flex" }, flexDirection: "column", cursor: "pointer",
              "&:hover": { opacity: 0.85 },
            }}
          >
            <Typography variant="caption" sx={{ color: "#ccc", lineHeight: 1.2 }}>Devoluciones</Typography>
            <Typography variant="body2" fontWeight="bold" sx={{ lineHeight: 1.2 }}>y Pedidos</Typography>
          </Box>

          {/* Cart */}
          <Box
            onClick={() => setCartOpen(true)}
            sx={{
              display: "flex", alignItems: "center", cursor: "pointer", ml: 1,
              "&:hover": { opacity: 0.85 },
            }}
          >
            <Badge
              badgeContent={hydrated ? getItemCount() : 0}
              sx={{ "& .MuiBadge-badge": { bgcolor: "#ff9900", color: "#000", fontWeight: "bold", fontSize: 13, top: 2 } }}
            >
              <ShoppingCartIcon sx={{ fontSize: 30 }} />
            </Badge>
            <Box sx={{ display: { xs: "none", sm: "flex" }, flexDirection: "column", ml: 0.5 }}>
              <Typography variant="caption" sx={{ color: "#ccc", lineHeight: 1 }}>
                ${hydrated ? getTotal().toFixed(2) : "0.00"}
              </Typography>
              <Typography variant="body2" fontWeight="bold" sx={{ lineHeight: 1.2 }}>
                Carrito
              </Typography>
            </Box>
          </Box>
        </Toolbar>

        {/* Category nav bar (desktop) */}
        {!isMobile && (
          <Box sx={{ bgcolor: "#37475a", px: 2, py: 0.5, display: "flex", alignItems: "center", gap: 0.5, overflowX: "auto" }}>
            <Button
              size="small"
              startIcon={<MenuIcon />}
              onClick={() => onNavigate("/productos")}
              sx={{ color: "#fff", textTransform: "none", fontWeight: "bold", fontSize: 13, whiteSpace: "nowrap", "&:hover": { bgcolor: alpha("#fff", 0.1) } }}
            >
              Todos los productos
            </Button>
            {["Ofertas", "Novedades", "Mas vendidos"].map((label) => (
              <Button
                key={label}
                size="small"
                onClick={() => onNavigate("/productos")}
                sx={{ color: "#fff", textTransform: "none", fontSize: 13, whiteSpace: "nowrap", "&:hover": { bgcolor: alpha("#fff", 0.1) } }}
              >
                {label}
              </Button>
            ))}
          </Box>
        )}
      </AppBar>

      {/* Mobile Navigation Drawer */}
      <Drawer
        anchor="left"
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        PaperProps={{ sx: { width: 280, bgcolor: "#fff" } }}
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
          <ListItem disablePadding>
            <ListItemButton onClick={() => { setDrawerOpen(false); onNavigate("/productos"); }}>
              <ListItemText primary="Ofertas" sx={{ pl: 2 }} />
            </ListItemButton>
          </ListItem>
          <ListItem disablePadding>
            <ListItemButton onClick={() => { setDrawerOpen(false); onNavigate("/productos"); }}>
              <ListItemText primary="Novedades" sx={{ pl: 2 }} />
            </ListItemButton>
          </ListItem>
          <ListItem disablePadding>
            <ListItemButton onClick={() => { setDrawerOpen(false); onNavigate("/productos"); }}>
              <ListItemText primary="Más vendidos" sx={{ pl: 2 }} />
            </ListItemButton>
          </ListItem>
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
        <Container maxWidth="xl" sx={{ py: 2 }}>
          {children}
        </Container>
      </Box>

      {/* Footer */}
      <Box sx={{ bgcolor: "#37475a", color: "#fff", py: 4 }}>
        <Container maxWidth="xl">
          <Box sx={{ display: "flex", flexWrap: "wrap", justifyContent: "space-between", gap: 4, mb: 3 }}>
            {[
              { title: "Conócenos", items: ["Acerca de DatqBox", "Trabaja con nosotros", "Prensa"] },
              { title: "Gana dinero", items: ["Vende en DatqBox Store", "Programa de afiliados"] },
              { title: "Ayuda", items: ["Centro de ayuda", "Devoluciones", "Contacto"] },
            ].map((col) => (
              <Box key={col.title}>
                <Typography variant="subtitle2" fontWeight="bold" sx={{ mb: 1 }}>{col.title}</Typography>
                {col.items.map((item) => (
                  <Typography key={item} variant="body2" sx={{ color: "#ddd", mb: 0.5, cursor: "pointer", "&:hover": { textDecoration: "underline" } }}>
                    {item}
                  </Typography>
                ))}
              </Box>
            ))}
          </Box>
        </Container>
      </Box>
      <Box sx={{ bgcolor: "#131921", color: "#999", py: 2, textAlign: "center" }}>
        <Typography variant="caption">
          &copy; {new Date().getFullYear()} DatqBox Store. Todos los derechos reservados.
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
