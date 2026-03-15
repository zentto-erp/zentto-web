"use client";

import { Box, Typography, Grid, Skeleton, Button, IconButton, useMediaQuery, useTheme } from "@mui/material";
import ArrowForwardIcon from "@mui/icons-material/ArrowForward";
import ArrowBackIosNewIcon from "@mui/icons-material/ArrowBackIosNew";
import ArrowForwardIosIcon from "@mui/icons-material/ArrowForwardIos";
import LocalOfferIcon from "@mui/icons-material/LocalOffer";
import TrendingUpIcon from "@mui/icons-material/TrendingUp";
import NewReleasesIcon from "@mui/icons-material/NewReleases";
import FavoriteIcon from "@mui/icons-material/Favorite";
import HistoryIcon from "@mui/icons-material/History";
import CategoryIcon from "@mui/icons-material/Category";
import { useRef, useState, useEffect, useCallback } from "react";
import { useProductList, useCategoryList } from "../hooks/useStoreProducts";
import { useFavoritesStore } from "../store/useFavoritesStore";
import { useRecentlyViewedStore } from "../store/useRecentlyViewedStore";
import ProductCard from "../components/ProductCard";
import PanelGrid from "../components/PanelGrid";

interface Props {
  onViewProduct: (code: string) => void;
  onViewCategory: (category: string) => void;
  onViewAll: () => void;
}

/* ─── Hero Carousel ──────────────────────────────────────── */

const BANNERS = [
  {
    title: "Las mejores ofertas te esperan",
    subtitle: "Descubre miles de productos con envío gratis y los mejores precios del mercado.",
    cta: "Explorar productos",
    gradient: "linear-gradient(135deg, #232f3e 0%, #37475a 50%, #485769 100%)",
    accent: "#ff9900",
  },
  {
    title: "Nuevas llegadas cada semana",
    subtitle: "Encuentra las últimas novedades en tecnología, hogar y más.",
    cta: "Ver novedades",
    gradient: "linear-gradient(135deg, #1a237e 0%, #283593 50%, #3949ab 100%)",
    accent: "#42a5f5",
  },
  {
    title: "Ofertas exclusivas hoy",
    subtitle: "Aprovecha descuentos de hasta 50% en productos seleccionados.",
    cta: "Ver ofertas",
    gradient: "linear-gradient(135deg, #b71c1c 0%, #c62828 50%, #d32f2f 100%)",
    accent: "#ffcdd2",
  },
];

function HeroCarousel({ onAction }: { onAction: () => void }) {
  const [current, setCurrent] = useState(0);
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  const next = useCallback(() => setCurrent((c) => (c + 1) % BANNERS.length), []);
  const prev = useCallback(() => setCurrent((c) => (c - 1 + BANNERS.length) % BANNERS.length), []);

  useEffect(() => {
    const timer = setInterval(next, 5000);
    return () => clearInterval(timer);
  }, [next]);

  const b = BANNERS[current];

  return (
    <Box
      sx={{
        position: "relative",
        borderRadius: "8px",
        overflow: "hidden",
        mb: 3,
        background: b.gradient,
        minHeight: { xs: 200, md: 350 },
        display: "flex",
        alignItems: "center",
        transition: "background 0.5s ease",
      }}
    >
      <Box sx={{ p: { xs: 3, md: 6 }, maxWidth: 600, zIndex: 1 }}>
        <Typography variant="overline" sx={{ color: b.accent, fontWeight: "bold", letterSpacing: 2 }}>
          DatqBox Store
        </Typography>
        <Typography variant="h3" sx={{ color: "#fff", fontWeight: "bold", mb: 2, fontSize: { xs: 22, md: 36 } }}>
          {b.title}
        </Typography>
        <Typography variant="body1" sx={{ color: "#ddd", mb: 3 }}>
          {b.subtitle}
        </Typography>
        <Button
          variant="contained"
          size="large"
          onClick={onAction}
          sx={{
            bgcolor: "#ff9900",
            color: "#0f1111",
            fontWeight: "bold",
            textTransform: "none",
            borderRadius: "20px",
            px: 4,
            fontSize: { xs: 14, md: 16 },
            "&:hover": { bgcolor: "#e68a00" },
          }}
        >
          {b.cta}
        </Button>
      </Box>

      {/* Decorative circles */}
      <Box sx={{ position: "absolute", right: -60, top: -60, width: 300, height: 300, borderRadius: "50%", bgcolor: "rgba(255,255,255,0.04)" }} />
      <Box sx={{ position: "absolute", right: 80, bottom: -40, width: 200, height: 200, borderRadius: "50%", bgcolor: "rgba(255,255,255,0.03)" }} />

      {/* Arrows */}
      {!isMobile && (
        <>
          <IconButton
            onClick={prev}
            sx={{
              position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)",
              bgcolor: "rgba(255,255,255,0.15)", color: "#fff",
              "&:hover": { bgcolor: "rgba(255,255,255,0.3)" },
            }}
          >
            <ArrowBackIosNewIcon />
          </IconButton>
          <IconButton
            onClick={next}
            sx={{
              position: "absolute", right: 12, top: "50%", transform: "translateY(-50%)",
              bgcolor: "rgba(255,255,255,0.15)", color: "#fff",
              "&:hover": { bgcolor: "rgba(255,255,255,0.3)" },
            }}
          >
            <ArrowForwardIosIcon />
          </IconButton>
        </>
      )}

      {/* Dots */}
      <Box sx={{ position: "absolute", bottom: 12, left: "50%", transform: "translateX(-50%)", display: "flex", gap: 1 }}>
        {BANNERS.map((_, i) => (
          <Box
            key={i}
            onClick={() => setCurrent(i)}
            sx={{
              width: i === current ? 24 : 8,
              height: 8,
              borderRadius: 4,
              bgcolor: i === current ? "#ff9900" : "rgba(255,255,255,0.5)",
              cursor: "pointer",
              transition: "all 0.3s ease",
            }}
          />
        ))}
      </Box>
    </Box>
  );
}

/* ─── Horizontal Scroller ────────────────────────────────── */

function HorizontalScroller({ children }: { children: React.ReactNode }) {
  const ref = useRef<HTMLDivElement>(null);
  const scroll = (dir: number) => {
    ref.current?.scrollBy({ left: dir * 300, behavior: "smooth" });
  };
  return (
    <Box sx={{ position: "relative", "&:hover .scroll-btn": { opacity: 1 } }}>
      <IconButton
        className="scroll-btn"
        onClick={() => scroll(-1)}
        sx={{
          position: "absolute", left: -16, top: "50%", transform: "translateY(-50%)", zIndex: 2,
          bgcolor: "#fff", boxShadow: 2, opacity: 0, transition: "opacity 0.2s",
          "&:hover": { bgcolor: "#f5f5f5" }, width: 36, height: 36,
        }}
      >
        <ArrowBackIosNewIcon sx={{ fontSize: 16 }} />
      </IconButton>
      <Box ref={ref} sx={{ display: "flex", gap: 2, overflowX: "auto", scrollBehavior: "smooth", pb: 1, "&::-webkit-scrollbar": { display: "none" } }}>
        {children}
      </Box>
      <IconButton
        className="scroll-btn"
        onClick={() => scroll(1)}
        sx={{
          position: "absolute", right: -16, top: "50%", transform: "translateY(-50%)", zIndex: 2,
          bgcolor: "#fff", boxShadow: 2, opacity: 0, transition: "opacity 0.2s",
          "&:hover": { bgcolor: "#f5f5f5" }, width: 36, height: 36,
        }}
      >
        <ArrowForwardIosIcon sx={{ fontSize: 16 }} />
      </IconButton>
    </Box>
  );
}

/* ─── Section Header ─────────────────────────────────────── */

function SectionHeader({ icon, title, actionLabel, onAction }: { icon: React.ReactNode; title: string; actionLabel?: string; onAction?: () => void }) {
  return (
    <Box sx={{ display: "flex", alignItems: "center", justifyContent: "space-between", mb: 2, mt: 4 }}>
      <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
        {icon}
        <Typography variant="h5" fontWeight="bold" sx={{ color: "#0f1111" }}>
          {title}
        </Typography>
      </Box>
      {actionLabel && onAction && (
        <Button endIcon={<ArrowForwardIcon />} onClick={onAction} sx={{ color: "#007185", textTransform: "none", fontWeight: 500 }}>
          {actionLabel}
        </Button>
      )}
    </Box>
  );
}

/* ─── StoreFront ─────────────────────────────────────────── */

export default function StoreFront({ onViewProduct, onViewCategory, onViewAll }: Props) {
  const { data: products, isLoading: loadingProducts } = useProductList({ limit: 40 });
  const { data: categories } = useCategoryList();

  // Zustand stores — defer to avoid hydration mismatch
  const [hydrated, setHydrated] = useState(false);
  useEffect(() => setHydrated(true), []);

  const favoriteItems = useFavoritesStore((s) => s.items);
  const recentItems = useRecentlyViewedStore((s) => s.items);

  const rows: any[] = products?.rows ?? [];
  const cats: any[] = categories ?? [];

  // Split products into sections
  const featured = rows.slice(0, 10);
  const trending = rows.slice(10, 20);
  const allGrid = rows.slice(0, 12);

  // Group products by category for panel rows
  const categoryPanels = cats.slice(0, 4).map((cat: any) => ({
    title: cat.name,
    code: cat.code,
    products: rows
      .filter((p: any) => p.category === cat.code || p.category === cat.name)
      .slice(0, 4)
      .map((p: any) => ({ code: p.code, name: p.fullDescription || p.name, price: p.price, imageUrl: p.imageUrl })),
  })).filter((cp) => cp.products.length > 0);

  // Build preference panels (only if hydrated, to avoid SSR mismatch)
  const favPanel = hydrated && favoriteItems.length >= 2
    ? favoriteItems.slice(0, 4).map((f) => ({ code: f.productCode, name: f.productName, price: f.price, imageUrl: f.imageUrl }))
    : null;

  const recentPanel = hydrated && recentItems.length >= 2
    ? recentItems.slice(0, 4).map((r) => ({ code: r.productCode, name: r.productName, price: r.price, imageUrl: r.imageUrl }))
    : null;

  const offersPanel = rows
    .filter((p: any) => p.originalPrice && p.originalPrice > p.price)
    .slice(0, 4)
    .map((p: any) => ({ code: p.code, name: p.fullDescription || p.name, price: p.price, imageUrl: p.imageUrl }));

  const topRatedPanel = [...rows]
    .sort((a: any, b: any) => (b.avgRating || 0) - (a.avgRating || 0))
    .slice(0, 4)
    .map((p: any) => ({ code: p.code, name: p.fullDescription || p.name, price: p.price, imageUrl: p.imageUrl }));

  return (
    <Box>
      {/* ── Hero Carousel ── */}
      <HeroCarousel onAction={onViewAll} />

      {/* ── Panel Grid Row 1: Preferencias + Ofertas ── */}
      <Grid container spacing={2} sx={{ mb: 3, mt: -6, position: "relative", zIndex: 2 }}>
        {favPanel && (
          <Grid xs={12} sm={6} md={3}>
            <PanelGrid
              title="Productos que guardaste"
              products={favPanel}
              actionLabel="Ver todos tus favoritos"
              onAction={onViewAll}
              onViewProduct={onViewProduct}
            />
          </Grid>
        )}
        {recentPanel && (
          <Grid xs={12} sm={6} md={3}>
            <PanelGrid
              title="Basado en tu historial"
              products={recentPanel}
              actionLabel="Ver tu historial"
              onAction={onViewAll}
              onViewProduct={onViewProduct}
            />
          </Grid>
        )}
        {offersPanel.length > 0 && (
          <Grid xs={12} sm={6} md={3}>
            <PanelGrid
              title="Ofertas del día"
              products={offersPanel}
              actionLabel="Ver todas las ofertas"
              onAction={onViewAll}
              onViewProduct={onViewProduct}
            />
          </Grid>
        )}
        {topRatedPanel.length > 0 && (
          <Grid xs={12} sm={6} md={3}>
            <PanelGrid
              title="Más vendidos"
              products={topRatedPanel}
              actionLabel="Ver más"
              onAction={onViewAll}
              onViewProduct={onViewProduct}
            />
          </Grid>
        )}
      </Grid>

      {/* ── Horizontal Scroller: Productos para ti ── */}
      <SectionHeader
        icon={<TrendingUpIcon sx={{ color: "#ff9900" }} />}
        title={hydrated && recentItems.length > 0 ? "Productos para ti" : "Productos destacados"}
        actionLabel="Ver todos"
        onAction={onViewAll}
      />
      {loadingProducts ? (
        <Box sx={{ display: "flex", gap: 2 }}>
          {Array.from({ length: 5 }).map((_, i) => (
            <Skeleton key={i} variant="rectangular" width={220} height={340} sx={{ borderRadius: "8px", flexShrink: 0 }} />
          ))}
        </Box>
      ) : (
        <HorizontalScroller>
          {featured.map((p: any) => (
            <Box key={p.code} sx={{ minWidth: 220, maxWidth: 220, flexShrink: 0 }}>
              <ProductCard
                code={p.code}
                name={p.name}
                fullDescription={p.fullDescription}
                category={p.category}
                brand={p.brand}
                price={p.price}
                stock={p.stock}
                taxRate={p.taxRate}
                imageUrl={p.imageUrl}
                avgRating={p.avgRating}
                reviewCount={p.reviewCount}
                onViewDetail={onViewProduct}
              />
            </Box>
          ))}
        </HorizontalScroller>
      )}

      {/* ── Panel Grid Row 2: Por categoría ── */}
      {categoryPanels.length > 0 && (
        <>
          <SectionHeader
            icon={<CategoryIcon sx={{ color: "#007185" }} />}
            title="Comprar por categoría"
          />
          <Grid container spacing={2} sx={{ mb: 3 }}>
            {categoryPanels.map((cp) => (
              <Grid key={cp.code} xs={12} sm={6} md={3}>
                <PanelGrid
                  title={cp.title}
                  products={cp.products}
                  actionLabel="Ver categoría"
                  onAction={() => onViewCategory(cp.code)}
                  onViewProduct={onViewProduct}
                />
              </Grid>
            ))}
          </Grid>
        </>
      )}

      {/* ── Horizontal Scroller: Tendencias ── */}
      {trending.length > 0 && (
        <>
          <SectionHeader
            icon={<LocalOfferIcon sx={{ color: "#cc0c39" }} />}
            title="Tendencias"
            actionLabel="Ver todas"
            onAction={onViewAll}
          />
          <HorizontalScroller>
            {trending.map((p: any) => (
              <Box key={p.code} sx={{ minWidth: 220, maxWidth: 220, flexShrink: 0 }}>
                <ProductCard
                  code={p.code}
                  name={p.name}
                  fullDescription={p.fullDescription}
                  category={p.category}
                  brand={p.brand}
                  price={p.price}
                  stock={p.stock}
                  taxRate={p.taxRate}
                  imageUrl={p.imageUrl}
                  avgRating={p.avgRating}
                  reviewCount={p.reviewCount}
                  onViewDetail={onViewProduct}
                />
              </Box>
            ))}
          </HorizontalScroller>
        </>
      )}

      {/* ── All Products Grid ── */}
      <SectionHeader
        icon={<NewReleasesIcon sx={{ color: "#007185" }} />}
        title="Todos los productos"
        actionLabel="Ver catálogo completo"
        onAction={onViewAll}
      />
      <Grid container spacing={2}>
        {loadingProducts
          ? Array.from({ length: 8 }).map((_, i) => (
              <Grid key={i} xs={6} sm={4} md={3} lg={2.4}>
                <Skeleton variant="rectangular" height={340} sx={{ borderRadius: "8px" }} />
              </Grid>
            ))
          : allGrid.map((p: any) => (
              <Grid key={p.code} xs={6} sm={4} md={3} lg={2.4}>
                <ProductCard
                  code={p.code}
                  name={p.name}
                  fullDescription={p.fullDescription}
                  category={p.category}
                  brand={p.brand}
                  price={p.price}
                  stock={p.stock}
                  taxRate={p.taxRate}
                  imageUrl={p.imageUrl}
                  avgRating={p.avgRating}
                  reviewCount={p.reviewCount}
                  onViewDetail={onViewProduct}
                />
              </Grid>
            ))}
      </Grid>

      {/* Ver más */}
      <Box sx={{ display: "flex", justifyContent: "center", mt: 3, mb: 2 }}>
        <Button
          variant="outlined"
          size="large"
          onClick={onViewAll}
          sx={{
            color: "#0f1111",
            borderColor: "#d5d9d9",
            borderRadius: "20px",
            textTransform: "none",
            fontWeight: 500,
            px: 6,
            "&:hover": { borderColor: "#ff9900", bgcolor: "#fff8e1" },
          }}
        >
          Ver catálogo completo
        </Button>
      </Box>
    </Box>
  );
}
