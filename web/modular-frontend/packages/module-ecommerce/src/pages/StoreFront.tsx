"use client";

import { Box, Typography, Grid, Skeleton, Paper, Button, IconButton, useMediaQuery, useTheme } from "@mui/material";
import ArrowForwardIcon from "@mui/icons-material/ArrowForward";
import ArrowBackIosNewIcon from "@mui/icons-material/ArrowBackIosNew";
import ArrowForwardIosIcon from "@mui/icons-material/ArrowForwardIos";
import LocalOfferIcon from "@mui/icons-material/LocalOffer";
import TrendingUpIcon from "@mui/icons-material/TrendingUp";
import NewReleasesIcon from "@mui/icons-material/NewReleases";
import CategoryIcon from "@mui/icons-material/Category";
import StarIcon from "@mui/icons-material/Star";
import WhatshotIcon from "@mui/icons-material/Whatshot";
import { useRef, useState, useEffect, useCallback, useMemo } from "react";
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
    gradient: "linear-gradient(135deg, #0d3b28 0%, #1b5e20 50%, #2e7d32 100%)",
    accent: "#a5d6a7",
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
        overflow: "hidden",
        background: b.gradient,
        minHeight: { xs: 180, sm: 250, md: 320 },
        display: "flex",
        alignItems: "center",
        transition: "background 0.5s ease",
        // Fade at bottom to blend with panel cards
        "&::after": {
          content: '""',
          position: "absolute",
          bottom: 0, left: 0, right: 0,
          height: { xs: 80, md: 140 },
          background: "linear-gradient(to bottom, transparent, #eaeded)",
          pointerEvents: "none",
        },
      }}
    >
      <Box sx={{ p: { xs: 3, md: 5 }, maxWidth: 550, zIndex: 1 }}>
        <Typography variant="overline" sx={{ color: b.accent, fontWeight: "bold", letterSpacing: 2, fontSize: { xs: 10, md: 12 } }}>
          DATQBOX STORE
        </Typography>
        <Typography sx={{ color: "#fff", fontWeight: "bold", mb: 1.5, fontSize: { xs: 20, sm: 26, md: 34 }, lineHeight: 1.2 }}>
          {b.title}
        </Typography>
        <Typography variant="body2" sx={{ color: "#ddd", mb: 2.5, display: { xs: "none", sm: "block" } }}>
          {b.subtitle}
        </Typography>
        <Button
          variant="contained"
          size={isMobile ? "small" : "large"}
          onClick={onAction}
          sx={{
            bgcolor: "#ff9900", color: "#0f1111", fontWeight: "bold", textTransform: "none",
            borderRadius: "20px", px: { xs: 3, md: 4 }, fontSize: { xs: 13, md: 15 },
            "&:hover": { bgcolor: "#e68a00" },
          }}
        >
          {b.cta}
        </Button>
      </Box>

      {/* Arrows */}
      <IconButton
        onClick={prev}
        sx={{
          position: "absolute", left: { xs: 4, md: 12 }, top: "40%", transform: "translateY(-50%)",
          bgcolor: "rgba(255,255,255,0.08)", color: "#fff", width: { xs: 36, md: 44 }, height: { xs: 72, md: 88 },
          borderRadius: "4px",
          "&:hover": { bgcolor: "rgba(255,255,255,0.15)" },
        }}
      >
        <ArrowBackIosNewIcon sx={{ fontSize: { xs: 16, md: 22 } }} />
      </IconButton>
      <IconButton
        onClick={next}
        sx={{
          position: "absolute", right: { xs: 4, md: 12 }, top: "40%", transform: "translateY(-50%)",
          bgcolor: "rgba(255,255,255,0.08)", color: "#fff", width: { xs: 36, md: 44 }, height: { xs: 72, md: 88 },
          borderRadius: "4px",
          "&:hover": { bgcolor: "rgba(255,255,255,0.15)" },
        }}
      >
        <ArrowForwardIosIcon sx={{ fontSize: { xs: 16, md: 22 } }} />
      </IconButton>

      {/* Dots */}
      <Box sx={{ position: "absolute", bottom: { xs: 80, md: 130 }, left: "50%", transform: "translateX(-50%)", display: "flex", gap: 0.8, zIndex: 2 }}>
        {BANNERS.map((_, i) => (
          <Box
            key={i}
            onClick={() => setCurrent(i)}
            sx={{
              width: i === current ? 20 : 8, height: 8, borderRadius: 4,
              bgcolor: i === current ? "#ff9900" : "rgba(255,255,255,0.5)",
              cursor: "pointer", transition: "all 0.3s ease",
            }}
          />
        ))}
      </Box>
    </Box>
  );
}

/* ─── Horizontal Scroller ────────────────────────────────── */

function HorizontalScroller({ children, title, actionLabel, onAction, icon }: {
  children: React.ReactNode;
  title: string;
  actionLabel?: string;
  onAction?: () => void;
  icon?: React.ReactNode;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const scroll = (dir: number) => {
    ref.current?.scrollBy({ left: dir * 320, behavior: "smooth" });
  };
  return (
    <Box sx={{ bgcolor: "#fff", p: { xs: 1.5, md: 2.5 }, mb: 1.5 }}>
      {/* Header */}
      <Box sx={{ display: "flex", alignItems: "center", justifyContent: "space-between", mb: 1.5 }}>
        <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
          {icon}
          <Typography sx={{ fontWeight: 700, color: "#0f1111", fontSize: { xs: 16, md: 20 } }}>
            {title}
          </Typography>
        </Box>
        {actionLabel && onAction && (
          <Button size="small" endIcon={<ArrowForwardIcon sx={{ fontSize: 14 }} />} onClick={onAction} sx={{ color: "#007185", textTransform: "none", fontWeight: 500, fontSize: 13 }}>
            {actionLabel}
          </Button>
        )}
      </Box>
      {/* Scroller */}
      <Box sx={{ position: "relative", "&:hover .scroll-btn": { opacity: 1 } }}>
        <IconButton
          className="scroll-btn"
          onClick={() => scroll(-1)}
          sx={{
            position: "absolute", left: 0, top: "50%", transform: "translateY(-50%)", zIndex: 2,
            bgcolor: "#fff", boxShadow: 3, opacity: 0, transition: "opacity 0.2s",
            "&:hover": { bgcolor: "#f5f5f5" }, width: 40, height: 80, borderRadius: "4px",
          }}
        >
          <ArrowBackIosNewIcon sx={{ fontSize: 16 }} />
        </IconButton>
        <Box ref={ref} sx={{ display: "flex", gap: 1.5, overflowX: "auto", scrollBehavior: "smooth", pb: 0.5, "&::-webkit-scrollbar": { display: "none" } }}>
          {children}
        </Box>
        <IconButton
          className="scroll-btn"
          onClick={() => scroll(1)}
          sx={{
            position: "absolute", right: 0, top: "50%", transform: "translateY(-50%)", zIndex: 2,
            bgcolor: "#fff", boxShadow: 3, opacity: 0, transition: "opacity 0.2s",
            "&:hover": { bgcolor: "#f5f5f5" }, width: 40, height: 80, borderRadius: "4px",
          }}
        >
          <ArrowForwardIosIcon sx={{ fontSize: 16 }} />
        </IconButton>
      </Box>
    </Box>
  );
}

/* ─── StoreFront ─────────────────────────────────────────── */

function toPanel(p: any) {
  return { code: p.code, name: p.fullDescription || p.name, price: p.price, imageUrl: p.imageUrl };
}

export default function StoreFront({ onViewProduct, onViewCategory, onViewAll }: Props) {
  const { data: products, isLoading: loadingProducts } = useProductList({ limit: 40 });
  const { data: categories } = useCategoryList();

  const [hydrated, setHydrated] = useState(false);
  useEffect(() => setHydrated(true), []);

  const favoriteItems = useFavoritesStore((s) => s.items);
  const recentItems = useRecentlyViewedStore((s) => s.items);

  const rows: any[] = products?.rows ?? [];
  const cats: any[] = categories ?? [];

  // Split products
  const featured = rows.slice(0, 12);
  const trending = rows.slice(12, 24);
  const allGrid = rows.slice(0, 15);

  // ── Build exactly 4 panels (always fill the row) ──
  const panels = useMemo(() => {
    const result: Array<{ key: string; title: string; products: any[]; actionLabel: string; onAction: () => void }> = [];

    // 1. Favorites (if available)
    if (hydrated && favoriteItems.length >= 2) {
      result.push({
        key: "fav",
        title: "Productos que guardaste",
        products: favoriteItems.slice(0, 4).map((f) => ({ code: f.productCode, name: f.productName, price: f.price, imageUrl: f.imageUrl })),
        actionLabel: "Ver favoritos",
        onAction: onViewAll,
      });
    }

    // 2. Recently viewed (if available)
    if (hydrated && recentItems.length >= 2) {
      result.push({
        key: "recent",
        title: "Basado en tu historial",
        products: recentItems.slice(0, 4).map((r) => ({ code: r.productCode, name: r.productName, price: r.price, imageUrl: r.imageUrl })),
        actionLabel: "Ver historial",
        onAction: onViewAll,
      });
    }

    // 3. Top rated products
    if (rows.length >= 4) {
      const topRated = [...rows].sort((a, b) => (b.avgRating || 0) - (a.avgRating || 0)).slice(0, 4);
      result.push({
        key: "top",
        title: "Más vendidos",
        products: topRated.map(toPanel),
        actionLabel: "Ver más",
        onAction: onViewAll,
      });
    }

    // 4. Products by categories (fill remaining slots)
    const usedCodes = new Set(result.flatMap((r) => r.products.map((p: any) => p.code)));
    for (const cat of cats) {
      if (result.length >= 4) break;
      const catProducts = rows
        .filter((p: any) => (p.category === cat.code || p.category === cat.name) && !usedCodes.has(p.code))
        .slice(0, 4);
      if (catProducts.length >= 2) {
        result.push({
          key: `cat-${cat.code}`,
          title: cat.name,
          products: catProducts.map(toPanel),
          actionLabel: "Ver categoría",
          onAction: () => onViewCategory(cat.code),
        });
        catProducts.forEach((p: any) => usedCodes.add(p.code));
      }
    }

    // 5. Fallback panels to always fill 4
    if (result.length < 4 && rows.length >= 8) {
      const fallbacks = [
        { key: "new", title: "Novedades", slice: [0, 4] as const },
        { key: "deals", title: "Ofertas del día", slice: [4, 8] as const },
        { key: "discover", title: "Descubre más", slice: [8, 12] as const },
        { key: "trending", title: "En tendencia", slice: [12, 16] as const },
      ];
      for (const fb of fallbacks) {
        if (result.length >= 4) break;
        if (result.some((r) => r.key === fb.key)) continue;
        const fbProducts = rows.slice(fb.slice[0], fb.slice[1]).filter((p: any) => !usedCodes.has(p.code));
        if (fbProducts.length >= 2) {
          result.push({
            key: fb.key,
            title: fb.title,
            products: fbProducts.map(toPanel),
            actionLabel: "Ver más",
            onAction: onViewAll,
          });
          fbProducts.forEach((p: any) => usedCodes.add(p.code));
        }
      }
    }

    return result.slice(0, 4);
  }, [rows, cats, hydrated, favoriteItems, recentItems, onViewAll, onViewCategory]);

  // Category panels row 2
  const categoryPanels = useMemo(() => {
    const panelCatCodes = new Set(panels.filter((p) => p.key.startsWith("cat-")).map((p) => p.key.replace("cat-", "")));
    return cats
      .filter((cat: any) => !panelCatCodes.has(cat.code))
      .slice(0, 4)
      .map((cat: any) => ({
        code: cat.code,
        title: cat.name,
        products: rows
          .filter((p: any) => p.category === cat.code || p.category === cat.name)
          .slice(0, 4)
          .map(toPanel),
      }))
      .filter((cp) => cp.products.length >= 2);
  }, [rows, cats, panels]);

  return (
    <Box sx={{ bgcolor: "#eaeded" }}>
      {/* ── Hero Carousel ── */}
      <HeroCarousel onAction={onViewAll} />

      {/* ── Panel Grid Row 1 (overlapping hero) ── */}
      {panels.length > 0 && (
        <Grid
          container
          spacing={1.5}
          sx={{
            px: { xs: 1, md: 2 },
            mt: { xs: -4, sm: -6, md: -10 },
            mb: 1.5,
            position: "relative",
            zIndex: 2,
          }}
        >
          {panels.map((panel) => (
            <Grid key={panel.key} xs={12} sm={6} md={3}>
              <PanelGrid
                title={panel.title}
                products={panel.products}
                actionLabel={panel.actionLabel}
                onAction={panel.onAction}
                onViewProduct={onViewProduct}
              />
            </Grid>
          ))}
        </Grid>
      )}

      {/* Loading skeleton */}
      {loadingProducts && panels.length === 0 && (
        <Grid container spacing={1.5} sx={{ px: { xs: 1, md: 2 }, mt: -8, mb: 1.5, position: "relative", zIndex: 2 }}>
          {Array.from({ length: 4 }).map((_, i) => (
            <Grid key={i} xs={12} sm={6} md={3}>
              <Skeleton variant="rectangular" height={380} sx={{ borderRadius: "8px" }} />
            </Grid>
          ))}
        </Grid>
      )}

      {/* ── Horizontal Scroller 1: Productos destacados ── */}
      {featured.length > 0 && (
        <HorizontalScroller
          title={hydrated && recentItems.length > 0 ? "Productos para ti" : "Productos destacados"}
          actionLabel="Ver todos"
          onAction={onViewAll}
          icon={<TrendingUpIcon sx={{ color: "#ff9900", fontSize: 22 }} />}
        >
          {featured.map((p: any) => (
            <Box key={p.code} sx={{ minWidth: 200, maxWidth: 200, flexShrink: 0 }}>
              <ProductCard
                code={p.code} name={p.name} fullDescription={p.fullDescription} category={p.category}
                brand={p.brand} price={p.price} stock={p.stock} taxRate={p.taxRate} imageUrl={p.imageUrl}
                avgRating={p.avgRating} reviewCount={p.reviewCount} onViewDetail={onViewProduct}
              />
            </Box>
          ))}
        </HorizontalScroller>
      )}

      {/* ── Panel Grid Row 2: Por categoría ── */}
      {categoryPanels.length > 0 && (
        <Box sx={{ px: { xs: 1, md: 2 }, mb: 1.5 }}>
          <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 1.5, mt: 0.5 }}>
            <CategoryIcon sx={{ color: "#007185", fontSize: 22 }} />
            <Typography sx={{ fontWeight: 700, color: "#0f1111", fontSize: { xs: 16, md: 20 } }}>
              Comprar por categoría
            </Typography>
          </Box>
          <Grid container spacing={1.5}>
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
        </Box>
      )}

      {/* ── Horizontal Scroller 2: Tendencias ── */}
      {trending.length > 0 && (
        <HorizontalScroller
          title="Tendencias"
          actionLabel="Ver todas"
          onAction={onViewAll}
          icon={<WhatshotIcon sx={{ color: "#cc0c39", fontSize: 22 }} />}
        >
          {trending.map((p: any) => (
            <Box key={p.code} sx={{ minWidth: 200, maxWidth: 200, flexShrink: 0 }}>
              <ProductCard
                code={p.code} name={p.name} fullDescription={p.fullDescription} category={p.category}
                brand={p.brand} price={p.price} stock={p.stock} taxRate={p.taxRate} imageUrl={p.imageUrl}
                avgRating={p.avgRating} reviewCount={p.reviewCount} onViewDetail={onViewProduct}
              />
            </Box>
          ))}
        </HorizontalScroller>
      )}

      {/* ── All Products Grid ── */}
      <Box sx={{ bgcolor: "#fff", p: { xs: 1.5, md: 2.5 }, mb: 1.5 }}>
        <Box sx={{ display: "flex", alignItems: "center", justifyContent: "space-between", mb: 1.5 }}>
          <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
            <NewReleasesIcon sx={{ color: "#007185", fontSize: 22 }} />
            <Typography sx={{ fontWeight: 700, color: "#0f1111", fontSize: { xs: 16, md: 20 } }}>
              Todos los productos
            </Typography>
          </Box>
          <Button size="small" endIcon={<ArrowForwardIcon sx={{ fontSize: 14 }} />} onClick={onViewAll} sx={{ color: "#007185", textTransform: "none", fontWeight: 500, fontSize: 13 }}>
            Ver catálogo completo
          </Button>
        </Box>
        <Grid container spacing={1.5}>
          {loadingProducts
            ? Array.from({ length: 10 }).map((_, i) => (
                <Grid key={i} xs={6} sm={4} md={3} lg={2.4}>
                  <Skeleton variant="rectangular" height={320} sx={{ borderRadius: "8px" }} />
                </Grid>
              ))
            : allGrid.map((p: any) => (
                <Grid key={p.code} xs={6} sm={4} md={3} lg={2.4}>
                  <ProductCard
                    code={p.code} name={p.name} fullDescription={p.fullDescription} category={p.category}
                    brand={p.brand} price={p.price} stock={p.stock} taxRate={p.taxRate} imageUrl={p.imageUrl}
                    avgRating={p.avgRating} reviewCount={p.reviewCount} onViewDetail={onViewProduct}
                  />
                </Grid>
              ))}
        </Grid>

        <Box sx={{ display: "flex", justifyContent: "center", mt: 2.5 }}>
          <Button
            variant="outlined"
            onClick={onViewAll}
            sx={{
              color: "#0f1111", borderColor: "#d5d9d9", borderRadius: "20px",
              textTransform: "none", fontWeight: 500, px: 5, fontSize: 13,
              "&:hover": { borderColor: "#ff9900", bgcolor: "#fff8e1" },
            }}
          >
            Ver catálogo completo
          </Button>
        </Box>
      </Box>
    </Box>
  );
}
