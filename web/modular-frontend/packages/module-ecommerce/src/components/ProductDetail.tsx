"use client";

import { useState, useRef, useCallback, useEffect } from "react";
import { Box, Typography, Button, Chip, Divider, Grid, Paper, Select, MenuItem, IconButton } from "@mui/material";
import ShoppingCartIcon from "@mui/icons-material/ShoppingCart";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import LocalShippingIcon from "@mui/icons-material/LocalShipping";
import ShieldIcon from "@mui/icons-material/Shield";
import VerifiedIcon from "@mui/icons-material/Verified";
import FavoriteBorderIcon from "@mui/icons-material/FavoriteBorder";
import FavoriteIcon from "@mui/icons-material/Favorite";
import ShareIcon from "@mui/icons-material/Share";
import ContentCopyIcon from "@mui/icons-material/ContentCopy";
import PlayCircleFilledIcon from "@mui/icons-material/PlayCircleFilled";
import ThreeSixtyIcon from "@mui/icons-material/ThreeSixty";
import ZoomInIcon from "@mui/icons-material/ZoomIn";
import ChevronLeftIcon from "@mui/icons-material/ChevronLeft";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import { useCartStore } from "../store/useCartStore";
import { useFavoritesStore } from "../store/useFavoritesStore";
import { useRecentlyViewedStore } from "../store/useRecentlyViewedStore";
import ReviewStars from "./ReviewStars";
import { useTrackRecentlyViewed } from "../hooks/useRecentlyViewed";
import { useToggleWishlist, useWishlist } from "../hooks/useWishlist";
import RecentlyViewedRail from "./RecentlyViewedRail";
import ProductRecommendations from "./ProductRecommendations";

interface MediaItem {
  id: number;
  url: string;
  role: string;
  isPrimary: boolean;
  altText?: string;
  type?: "image" | "video" | "360";
  videoUrl?: string;
}

interface ProductSpec {
  group: string;
  key: string;
  value: string;
}

interface VariantOptionInfo {
  groupCode: string;
  groupName: string;
  displayType: string; // BUTTON | SWATCH | DROPDOWN | IMAGE
  optionCode: string;
  optionLabel: string;
  colorHex?: string;
  imageUrl?: string;
}

interface ProductVariant {
  variantId: number;
  code: string;
  name: string;
  sku: string;
  price: number;
  priceDelta: number;
  stock: number;
  isDefault: boolean;
  sortOrder: number;
  options: VariantOptionInfo[];
}

interface IndustryAttribute {
  key: string;
  label: string;
  dataType: string;
  displayGroup: string;
  value: any;
  valueText?: string;
  valueNumber?: number;
  valueDate?: string;
  valueBoolean?: boolean;
}

interface Props {
  product: {
    code: string;
    name: string;
    fullDescription: string;
    shortDescription?: string;
    longDescription?: string;
    category?: string;
    categoryName?: string;
    brand?: string;
    brandName?: string;
    price: number;
    compareAtPrice?: number;
    stock: number;
    isService: boolean;
    unitCode?: string;
    taxRate: number;
    weightKg?: number;
    widthCm?: number;
    heightCm?: number;
    depthCm?: number;
    warrantyMonths?: number;
    barCode?: string;
    images?: MediaItem[];
    avgRating?: number;
    reviewCount?: number;
    highlights?: string[];
    specs?: ProductSpec[];
    isVariantParent?: boolean;
    parentProductCode?: string;
    industryTemplateCode?: string;
    industryTemplateName?: string;
    variants?: ProductVariant[];
    industryAttributes?: IndustryAttribute[];
  };
  onBack?: () => void;
  reviews?: React.ReactNode;
}

// ─── Image Zoom Component (Amazon-style lens) ─────────────────
function ZoomableImage({ src, alt }: { src: string; alt: string }) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [zooming, setZooming] = useState(false);
  const [zoomPos, setZoomPos] = useState({ x: 50, y: 50 });
  const [lensPos, setLensPos] = useState({ left: 0, top: 0 });
  const ZOOM_LEVEL = 2.5;
  const LENS_SIZE = 160;

  const handleMouseMove = useCallback((e: React.MouseEvent<HTMLDivElement>) => {
    const rect = containerRef.current?.getBoundingClientRect();
    if (!rect) return;
    const x = ((e.clientX - rect.left) / rect.width) * 100;
    const y = ((e.clientY - rect.top) / rect.height) * 100;
    setZoomPos({ x: Math.max(0, Math.min(100, x)), y: Math.max(0, Math.min(100, y)) });
    setLensPos({
      left: Math.max(0, Math.min(rect.width - LENS_SIZE, e.clientX - rect.left - LENS_SIZE / 2)),
      top: Math.max(0, Math.min(rect.height - LENS_SIZE, e.clientY - rect.top - LENS_SIZE / 2)),
    });
  }, []);

  return (
    <Box sx={{ position: "relative" }}>
      <Box
        ref={containerRef}
        onMouseEnter={() => setZooming(true)}
        onMouseLeave={() => setZooming(false)}
        onMouseMove={handleMouseMove}
        sx={{
          cursor: zooming ? "none" : "crosshair",
          position: "relative",
          overflow: "hidden",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          minHeight: 400,
          maxHeight: 500,
        }}
      >
        <Box
          component="img"
          src={src}
          alt={alt}
          sx={{ maxWidth: "100%", maxHeight: 480, objectFit: "contain", userSelect: "none" }}
          onError={(e: any) => { e.target.src = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='400' height='400'%3E%3Crect fill='%23f0f0f0' width='400' height='400'/%3E%3Ctext fill='%23999' x='50%25' y='50%25' text-anchor='middle' dy='.3em' font-size='16'%3ESin imagen%3C/text%3E%3C/svg%3E"; }}
        />

        {/* Lens indicator */}
        {zooming && (
          <Box
            sx={{
              position: "absolute",
              left: lensPos.left,
              top: lensPos.top,
              width: LENS_SIZE,
              height: LENS_SIZE,
              border: "2px solid rgba(255,153,0,0.6)",
              bgcolor: "rgba(255,153,0,0.08)",
              borderRadius: "4px",
              pointerEvents: "none",
              zIndex: 2,
            }}
          />
        )}
      </Box>

      {/* Zoom preview panel (appears to the right) */}
      {zooming && (
        <Box
          sx={{
            position: "absolute",
            top: 0,
            left: "calc(100% + 16px)",
            width: 450,
            height: 450,
            border: "2px solid #e3e6e6",
            borderRadius: "8px",
            overflow: "hidden",
            bgcolor: "#fff",
            zIndex: 100,
            boxShadow: "0 8px 24px rgba(0,0,0,0.15)",
            display: { xs: "none", md: "block" },
            backgroundImage: `url(${src})`,
            backgroundSize: `${ZOOM_LEVEL * 100}%`,
            backgroundPosition: `${zoomPos.x}% ${zoomPos.y}%`,
            backgroundRepeat: "no-repeat",
          }}
        />
      )}

      {/* Zoom hint */}
      {!zooming && (
        <Box sx={{ position: "absolute", bottom: 8, right: 8, display: "flex", alignItems: "center", gap: 0.5, bgcolor: "rgba(0,0,0,0.6)", borderRadius: "12px", px: 1, py: 0.3 }}>
          <ZoomInIcon sx={{ fontSize: 14, color: "#fff" }} />
          <Typography variant="caption" sx={{ color: "#fff", fontSize: 10 }}>Pasa el mouse para zoom</Typography>
        </Box>
      )}
    </Box>
  );
}

// ─── Video Player ─────────────────────────────────────────────
function VideoPlayer({ src }: { src: string }) {
  return (
    <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", minHeight: 400, bgcolor: "#000", borderRadius: "4px" }}>
      <video
        src={src}
        controls
        style={{ maxWidth: "100%", maxHeight: 480, borderRadius: "4px" }}
        poster=""
      >
        Tu navegador no soporta video.
      </video>
    </Box>
  );
}

// ─── 360° Viewer (simulated with auto-rotating images) ────────
function View360({ images, alt }: { images: string[]; alt: string }) {
  const [frame, setFrame] = useState(0);
  const containerRef = useRef<HTMLDivElement>(null);
  const dragging = useRef(false);
  const lastX = useRef(0);

  const handleMouseDown = (e: React.MouseEvent) => {
    dragging.current = true;
    lastX.current = e.clientX;
  };
  const handleMouseMove = (e: React.MouseEvent) => {
    if (!dragging.current) return;
    const dx = e.clientX - lastX.current;
    if (Math.abs(dx) > 15) {
      setFrame((prev) => (prev + (dx > 0 ? 1 : -1) + images.length) % images.length);
      lastX.current = e.clientX;
    }
  };
  const handleMouseUp = () => { dragging.current = false; };

  return (
    <Box
      ref={containerRef}
      onMouseDown={handleMouseDown}
      onMouseMove={handleMouseMove}
      onMouseUp={handleMouseUp}
      onMouseLeave={handleMouseUp}
      sx={{
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        minHeight: 400,
        cursor: "grab",
        userSelect: "none",
        position: "relative",
        "&:active": { cursor: "grabbing" },
      }}
    >
      <Box component="img" src={images[frame]} alt={alt} sx={{ maxWidth: "100%", maxHeight: 480, objectFit: "contain", pointerEvents: "none" }} />
      <Box sx={{ position: "absolute", bottom: 8, left: "50%", transform: "translateX(-50%)", display: "flex", alignItems: "center", gap: 0.5, bgcolor: "rgba(0,0,0,0.6)", borderRadius: "12px", px: 1.5, py: 0.5 }}>
        <ThreeSixtyIcon sx={{ fontSize: 16, color: "#fff" }} />
        <Typography variant="caption" sx={{ color: "#fff", fontSize: 11 }}>Arrastra para girar 360°</Typography>
      </Box>
    </Box>
  );
}

// ─── Main Component ───────────────────────────────────────────
export default function ProductDetail({ product, onBack, reviews }: Props) {
  const addItem = useCartStore((s) => s.addItem);
  const toggleFavoriteLocal = useFavoritesStore((s) => s.toggleFavorite);
  const isFavoriteLocal = useFavoritesStore((s) => s.isFavorite(product.code));
  const addRecentView = useRecentlyViewedStore((s) => s.addView);
  const trackRecent = useTrackRecentlyViewed();
  const toggleServerWishlist = useToggleWishlist();
  const { data: serverWishlist } = useWishlist(true);
  const isFavoriteServer = (serverWishlist || []).some((w) => w.productCode === product.code);
  const isFavorite = isFavoriteLocal || isFavoriteServer;
  const toggleFavorite = (item: { productCode: string; productName: string; price: number; imageUrl: string | null }) => {
    toggleFavoriteLocal(item);
    toggleServerWishlist.mutate(item.productCode);
  };
  const [qty, setQty] = useState(1);
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [shareMsg, setShareMsg] = useState("");

  // Variant selection state
  const hasVariants = product.isVariantParent && product.variants && product.variants.length > 0;
  const defaultVariant = product.variants?.find((v) => v.isDefault) ?? product.variants?.[0] ?? null;
  const [selectedVariant, setSelectedVariant] = useState<ProductVariant | null>(defaultVariant);

  // Effective price/stock based on selected variant
  const effectivePrice = selectedVariant ? selectedVariant.price : product.price;
  const effectiveStock = selectedVariant ? selectedVariant.stock : product.stock;

  // Register product view for "recently viewed" recommendations (local + server)
  useEffect(() => {
    addRecentView({
      productCode: product.code,
      productName: product.name,
      price: product.price,
      imageUrl: product.images?.[0]?.url ?? null,
      category: product.category,
    });
    trackRecent.mutate(product.code);
  }, [product.code]); // eslint-disable-line react-hooks/exhaustive-deps

  const media: MediaItem[] = product.images?.length
    ? product.images.map((img) => ({ ...img, type: img.type || "image" as const }))
    : [{ id: 0, url: "", role: "PRIMARY", isPrimary: true, type: "image" as const }];

  const currentItem = media[selectedIndex] || media[0];
  const thumbStartRef = useRef(0);
  const VISIBLE_THUMBS = 6;
  const [thumbStart, setThumbStart] = useState(0);
  const visibleThumbs = media.slice(thumbStart, thumbStart + VISIBLE_THUMBS);

  const handleAdd = () => {
    addItem({
      productCode: selectedVariant ? selectedVariant.code : product.code,
      productName: selectedVariant ? selectedVariant.name : product.name,
      quantity: qty,
      unitPrice: effectivePrice,
      taxRate: product.taxRate > 1 ? product.taxRate / 100 : product.taxRate,
      imageUrl: media[0]?.url || null,
    });
  };

  const subtotal = effectivePrice * qty;
  const taxRate = product.taxRate > 1 ? product.taxRate / 100 : product.taxRate;
  const tax = subtotal * taxRate;

  return (
    <Box>
      {onBack && (
        <Button
          startIcon={<ArrowBackIcon />}
          onClick={onBack}
          sx={{ mb: 2, color: "#007185", textTransform: "none", "&:hover": { bgcolor: "transparent", textDecoration: "underline" } }}
        >
          Volver a resultados
        </Button>
      )}

      <Paper elevation={0} sx={{ border: "1px solid #e3e6e6", borderRadius: "8px", overflow: "hidden" }}>
        <Grid container>
          {/* ═══ Image Gallery with Zoom ═══ */}
          <Grid xs={12} md={5}>
            <Box sx={{ p: 2 }}>
              {/* Thumbnails (vertical on left, like Amazon) */}
              <Box sx={{ display: "flex", gap: 1 }}>
                {/* Vertical thumbnail strip */}
                <Box sx={{ display: { xs: "none", sm: "flex" }, flexDirection: "column", gap: 0.5, minWidth: 56 }}>
                  {thumbStart > 0 && (
                    <IconButton size="small" onClick={() => setThumbStart(Math.max(0, thumbStart - 1))} sx={{ mx: "auto" }}>
                      <ChevronLeftIcon sx={{ transform: "rotate(90deg)", fontSize: 18 }} />
                    </IconButton>
                  )}
                  {visibleThumbs.map((item, i) => {
                    const realIdx = thumbStart + i;
                    const isVideo = item.type === "video";
                    const is360 = item.type === "360";
                    return (
                      <Box
                        key={item.id}
                        onClick={() => setSelectedIndex(realIdx)}
                        onMouseEnter={() => setSelectedIndex(realIdx)}
                        sx={{
                          width: 54, height: 54, borderRadius: "4px", cursor: "pointer",
                          border: "2px solid", borderColor: realIdx === selectedIndex ? "#ff9900" : "#e3e6e6",
                          bgcolor: "#fff", display: "flex", alignItems: "center", justifyContent: "center",
                          position: "relative", overflow: "hidden",
                          transition: "border-color 0.15s", "&:hover": { borderColor: "#ff9900" },
                        }}
                      >
                        <Box component="img" src={item.url} alt={item.altText || ""} sx={{ maxWidth: "100%", maxHeight: "100%", objectFit: "contain" }} />
                        {isVideo && (
                          <Box sx={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", bgcolor: "rgba(0,0,0,0.3)" }}>
                            <PlayCircleFilledIcon sx={{ fontSize: 24, color: "#fff" }} />
                          </Box>
                        )}
                        {is360 && (
                          <Box sx={{ position: "absolute", bottom: 1, right: 1 }}>
                            <ThreeSixtyIcon sx={{ fontSize: 14, color: "#ff9900" }} />
                          </Box>
                        )}
                      </Box>
                    );
                  })}
                  {thumbStart + VISIBLE_THUMBS < media.length && (
                    <IconButton size="small" onClick={() => setThumbStart(Math.min(media.length - VISIBLE_THUMBS, thumbStart + 1))} sx={{ mx: "auto" }}>
                      <ChevronLeftIcon sx={{ transform: "rotate(-90deg)", fontSize: 18 }} />
                    </IconButton>
                  )}
                </Box>

                {/* Main image / video / 360 viewer */}
                <Box sx={{ flex: 1, bgcolor: "#fff", borderRadius: "8px", border: "1px solid #e3e6e6", overflow: "visible", position: "relative" }}>
                  {currentItem.type === "video" && currentItem.videoUrl ? (
                    <VideoPlayer src={currentItem.videoUrl} />
                  ) : currentItem.type === "360" ? (
                    <View360 images={media.filter((m) => m.type === "360").map((m) => m.url)} alt={product.name} />
                  ) : currentItem.url ? (
                    <ZoomableImage src={currentItem.url} alt={product.name} />
                  ) : (
                    <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", minHeight: 400 }}>
                      <Typography color="text.secondary" sx={{ fontSize: 64, opacity: 0.3 }}>Sin imagen</Typography>
                    </Box>
                  )}
                </Box>
              </Box>

              {/* Mobile horizontal thumbs */}
              <Box sx={{ display: { xs: "flex", sm: "none" }, gap: 1, mt: 1, overflowX: "auto", pb: 1 }}>
                {media.map((item, i) => (
                  <Box
                    key={item.id}
                    onClick={() => setSelectedIndex(i)}
                    sx={{
                      minWidth: 48, height: 48, borderRadius: "4px", cursor: "pointer",
                      border: "2px solid", borderColor: i === selectedIndex ? "#ff9900" : "#e3e6e6",
                      bgcolor: "#fff", display: "flex", alignItems: "center", justifyContent: "center", position: "relative",
                    }}
                  >
                    <Box component="img" src={item.url} alt="" sx={{ maxWidth: "100%", maxHeight: "100%", objectFit: "contain" }} />
                    {item.type === "video" && <PlayCircleFilledIcon sx={{ position: "absolute", fontSize: 20, color: "#fff" }} />}
                  </Box>
                ))}
              </Box>
            </Box>
          </Grid>

          {/* ═══ Product Info ═══ */}
          <Grid xs={12} md={4}>
            <Box sx={{ p: 3 }}>
              <Typography variant="h5" sx={{ fontWeight: 400, color: "#0f1111", lineHeight: 1.35, mb: 0.5 }}>
                {product.name}
              </Typography>

              {product.shortDescription && (
                <Typography variant="body2" sx={{ color: "#565959", mb: 1, lineHeight: 1.4 }}>
                  {product.shortDescription}
                </Typography>
              )}

              {(product.brandName || product.brand) && (
                <Typography variant="body2" sx={{ mb: 1 }}>
                  Marca: <span style={{ color: "#007185" }}>{product.brandName || product.brand}</span>
                </Typography>
              )}

              {product.avgRating != null && product.avgRating > 0 && (
                <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 1 }}>
                  <Typography variant="body2" sx={{ color: "#007185" }}>{product.avgRating.toFixed(1)}</Typography>
                  <ReviewStars rating={product.avgRating} count={product.reviewCount} size="medium" />
                </Box>
              )}

              <Divider sx={{ my: 1.5 }} />

              <Box sx={{ mb: 2 }}>
                <Typography variant="caption" sx={{ color: "#565959" }}>Precio:</Typography>
                {product.compareAtPrice != null && product.compareAtPrice > product.price && (
                  <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 0.3 }}>
                    <Typography variant="body2" sx={{ color: "#565959", textDecoration: "line-through" }}>
                      ${product.compareAtPrice.toFixed(2)}
                    </Typography>
                    <Typography variant="body2" sx={{ color: "#cc0c39", fontWeight: 600 }}>
                      -{Math.round(((product.compareAtPrice - product.price) / product.compareAtPrice) * 100)}%
                    </Typography>
                  </Box>
                )}
                <Box sx={{ display: "flex", alignItems: "baseline", gap: 0.5 }}>
                  <Typography sx={{ fontSize: 14, color: "#0f1111" }}>$</Typography>
                  <Typography sx={{ fontSize: 28, fontWeight: 400, color: "#0f1111", lineHeight: 1 }}>
                    {Math.floor(product.price).toLocaleString()}
                  </Typography>
                  <Typography sx={{ fontSize: 14, color: "#0f1111", position: "relative", top: -8 }}>
                    {(product.price % 1).toFixed(2).substring(1)}
                  </Typography>
                </Box>
                {taxRate > 0 && (
                  <Typography variant="caption" sx={{ color: "#565959" }}>
                    + {(taxRate * 100).toFixed(0)}% IVA (${tax.toFixed(2)})
                  </Typography>
                )}
              </Box>

              {/* ═══ Variant Selector ═══ */}
              {hasVariants && (() => {
                // Agrupar opciones únicas por grupo desde todas las variantes
                const groupMap = new Map<string, { groupName: string; displayType: string; options: Map<string, VariantOptionInfo> }>();
                for (const v of product.variants!) {
                  for (const opt of v.options) {
                    if (!groupMap.has(opt.groupCode)) {
                      groupMap.set(opt.groupCode, { groupName: opt.groupName, displayType: opt.displayType, options: new Map() });
                    }
                    groupMap.get(opt.groupCode)!.options.set(opt.optionCode, opt);
                  }
                }

                // Opciones seleccionadas del variante actual
                const selectedOptions = new Map<string, string>();
                if (selectedVariant) {
                  for (const opt of selectedVariant.options) {
                    selectedOptions.set(opt.groupCode, opt.optionCode);
                  }
                }

                const handleOptionClick = (groupCode: string, optionCode: string) => {
                  // Buscar variante que coincida con la nueva selección
                  const newSelection = new Map(selectedOptions);
                  newSelection.set(groupCode, optionCode);
                  const match = product.variants!.find((v) =>
                    v.options.every((opt) => newSelection.get(opt.groupCode) === opt.optionCode)
                  );
                  if (match) setSelectedVariant(match);
                };

                return (
                  <Box sx={{ mb: 2 }}>
                    {Array.from(groupMap.entries()).map(([groupCode, group]) => (
                      <Box key={groupCode} sx={{ mb: 1.5 }}>
                        <Typography variant="body2" sx={{ fontWeight: 600, mb: 0.5, color: "#0f1111", fontSize: 13 }}>
                          {group.groupName}: <span style={{ fontWeight: 400 }}>{selectedOptions.get(groupCode) ? Array.from(group.options.values()).find(o => o.optionCode === selectedOptions.get(groupCode))?.optionLabel : ""}</span>
                        </Typography>
                        <Box sx={{ display: "flex", gap: 1, flexWrap: "wrap" }}>
                          {Array.from(group.options.values()).map((opt) => {
                            const isSelected = selectedOptions.get(groupCode) === opt.optionCode;
                            // SWATCH — círculos de color
                            if (group.displayType === "SWATCH" && opt.colorHex) {
                              return (
                                <Box
                                  key={opt.optionCode}
                                  onClick={() => handleOptionClick(groupCode, opt.optionCode)}
                                  title={opt.optionLabel}
                                  sx={{
                                    width: 36, height: 36, borderRadius: "50%",
                                    bgcolor: opt.colorHex,
                                    border: "3px solid", borderColor: isSelected ? "#ff9900" : "#e3e6e6",
                                    cursor: "pointer", transition: "all 0.15s",
                                    "&:hover": { borderColor: "#ff9900", transform: "scale(1.1)" },
                                    boxShadow: isSelected ? "0 0 0 2px #fff, 0 0 0 4px #ff9900" : "none",
                                  }}
                                />
                              );
                            }
                            // IMAGE — miniatura
                            if (group.displayType === "IMAGE" && opt.imageUrl) {
                              return (
                                <Box
                                  key={opt.optionCode}
                                  onClick={() => handleOptionClick(groupCode, opt.optionCode)}
                                  sx={{
                                    width: 48, height: 48, borderRadius: "4px",
                                    border: "2px solid", borderColor: isSelected ? "#ff9900" : "#e3e6e6",
                                    cursor: "pointer", overflow: "hidden",
                                    "&:hover": { borderColor: "#ff9900" },
                                  }}
                                >
                                  <Box component="img" src={opt.imageUrl} alt={opt.optionLabel} sx={{ width: "100%", height: "100%", objectFit: "cover" }} />
                                </Box>
                              );
                            }
                            // DROPDOWN — se renderiza como Select abajo
                            if (group.displayType === "DROPDOWN") return null;
                            // BUTTON (default) — botones de texto
                            return (
                              <Box
                                key={opt.optionCode}
                                onClick={() => handleOptionClick(groupCode, opt.optionCode)}
                                sx={{
                                  px: 2, py: 0.8, borderRadius: "8px",
                                  border: "2px solid", borderColor: isSelected ? "#ff9900" : "#e3e6e6",
                                  bgcolor: isSelected ? "#fff8e8" : "#fff",
                                  cursor: "pointer", transition: "all 0.15s",
                                  "&:hover": { borderColor: "#ff9900", bgcolor: "#fff8e8" },
                                }}
                              >
                                <Typography variant="body2" sx={{ fontSize: 13, fontWeight: isSelected ? 600 : 400 }}>
                                  {opt.optionLabel}
                                </Typography>
                              </Box>
                            );
                          })}
                        </Box>
                        {/* DROPDOWN rendering */}
                        {group.displayType === "DROPDOWN" && (
                          <Select
                           
                            value={selectedOptions.get(groupCode) || ""}
                            onChange={(e) => handleOptionClick(groupCode, e.target.value as string)}
                            sx={{ mt: 0.5, minWidth: 150, bgcolor: "#f0f2f2", borderRadius: "8px" }}
                          >
                            {Array.from(group.options.values()).map((opt) => (
                              <MenuItem key={opt.optionCode} value={opt.optionCode}>{opt.optionLabel}</MenuItem>
                            ))}
                          </Select>
                        )}
                      </Box>
                    ))}
                    {selectedVariant && selectedVariant.sku && (
                      <Typography variant="caption" sx={{ color: "#565959", mt: 0.5 }}>
                        SKU: {selectedVariant.sku}
                      </Typography>
                    )}
                  </Box>
                );
              })()}

              <Box sx={{ display: "flex", gap: 1, flexWrap: "wrap", mb: 2 }}>
                {(product.categoryName || product.category) && (
                  <Chip label={product.categoryName || product.category} size="small" sx={{ bgcolor: "#f0f2f2" }} />
                )}
              </Box>

              <Box sx={{ mb: 2 }}>
                <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 0.5 }}>
                  <LocalShippingIcon sx={{ fontSize: 18, color: "#067D62" }} />
                  <Typography variant="body2" sx={{ color: "#067D62" }}>Envio gratis</Typography>
                </Box>
                <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 0.5 }}>
                  <ShieldIcon sx={{ fontSize: 18, color: "#067D62" }} />
                  <Typography variant="body2" sx={{ color: "#067D62" }}>
                    {product.warrantyMonths && product.warrantyMonths > 0
                      ? `Garantía de ${product.warrantyMonths} ${product.warrantyMonths === 1 ? "mes" : "meses"}`
                      : "Garantia del vendedor"}
                  </Typography>
                </Box>
                <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                  <VerifiedIcon sx={{ fontSize: 18, color: "#067D62" }} />
                  <Typography variant="body2" sx={{ color: "#067D62" }}>Producto original</Typography>
                </Box>
              </Box>

              {/* Highlights / Acerca de este artículo */}
              {product.highlights && product.highlights.length > 0 && (
                <Box sx={{ mb: 2 }}>
                  <Typography variant="body2" fontWeight={700} sx={{ mb: 0.5 }}>
                    Acerca de este artículo
                  </Typography>
                  <Box component="ul" sx={{ m: 0, pl: 2.5 }}>
                    {product.highlights.map((h, i) => (
                      <Box component="li" key={i} sx={{ mb: 0.4 }}>
                        <Typography variant="body2" sx={{ color: "#0f1111", lineHeight: 1.4, fontSize: 13 }}>{h}</Typography>
                      </Box>
                    ))}
                  </Box>
                </Box>
              )}

              {/* Quick specs */}
              <Box sx={{ bgcolor: "#f7f7f7", borderRadius: "4px", p: 1.5, mb: 2 }}>
                <Typography variant="caption" fontWeight="bold" sx={{ mb: 0.5, display: "block" }}>Especificaciones:</Typography>
                {[
                  ["Codigo", product.code],
                  ...(product.unitCode ? [["Unidad", product.unitCode]] : []),
                  ...(product.barCode ? [["Código de barras", product.barCode]] : []),
                  ...(product.weightKg ? [["Peso", `${product.weightKg} kg`]] : []),
                  ...(product.widthCm && product.heightCm && product.depthCm
                    ? [["Dimensiones", `${product.widthCm} × ${product.heightCm} × ${product.depthCm} cm`]]
                    : []),
                  ...(product.warrantyMonths ? [["Garantía", `${product.warrantyMonths} meses`]] : []),
                ].map(([k, v]) => (
                  <Box key={k} sx={{ display: "flex", py: 0.3 }}>
                    <Typography variant="caption" sx={{ color: "#565959", minWidth: 110 }}>{k}:</Typography>
                    <Typography variant="caption">{v}</Typography>
                  </Box>
                ))}
              </Box>

              <Box sx={{ display: "flex", gap: 1, alignItems: "center" }}>
                <Button
                  startIcon={isFavorite ? <FavoriteIcon sx={{ color: "#cc0c39" }} /> : <FavoriteBorderIcon />}
                  onClick={() => toggleFavorite({
                    productCode: product.code,
                    productName: product.name,
                    price: product.price,
                    imageUrl: media[0]?.url || null,
                  })}
                  sx={{
                    color: isFavorite ? "#cc0c39" : "#565959",
                    textTransform: "none",
                    fontSize: 12,
                    "&:hover": { bgcolor: "rgba(204,12,57,0.04)" },
                  }}
                >
                  {isFavorite ? "En favoritos" : "Favoritos"}
                </Button>
                <Button
                  startIcon={<ShareIcon />}
                  onClick={async () => {
                    const url = typeof window !== "undefined" ? window.location.href : "";
                    const text = `${product.name} - $${product.price.toFixed(2)}`;
                    if (typeof navigator !== "undefined" && navigator.share) {
                      try {
                        await navigator.share({ title: product.name, text, url });
                      } catch { /* user cancelled */ }
                    } else if (typeof navigator !== "undefined" && navigator.clipboard) {
                      await navigator.clipboard.writeText(url);
                      setShareMsg("Enlace copiado");
                      setTimeout(() => setShareMsg(""), 2000);
                    }
                  }}
                  sx={{ color: "#565959", textTransform: "none", fontSize: 12 }}
                >
                  Compartir
                </Button>
                {shareMsg && (
                  <Typography variant="caption" sx={{ color: "#067D62", fontWeight: 500 }}>
                    {shareMsg}
                  </Typography>
                )}
              </Box>
            </Box>
          </Grid>

          {/* ═══ Buy Box ═══ */}
          <Grid xs={12} md={3}>
            <Box sx={{ p: 3, borderLeft: { md: "1px solid #e3e6e6" }, height: "100%" }}>
              <Paper elevation={0} sx={{ border: "1px solid #e3e6e6", borderRadius: "8px", p: 2 }}>
                {product.compareAtPrice != null && product.compareAtPrice > product.price && (
                  <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 0.3 }}>
                    <Typography variant="body2" sx={{ color: "#565959", textDecoration: "line-through" }}>
                      ${(product.compareAtPrice * qty + product.compareAtPrice * qty * taxRate).toFixed(2)}
                    </Typography>
                    <Chip
                      label={`-${Math.round(((product.compareAtPrice - product.price) / product.compareAtPrice) * 100)}%`}
                      size="small"
                      sx={{ bgcolor: "#cc0c39", color: "#fff", fontWeight: 700, fontSize: 12, height: 22 }}
                    />
                  </Box>
                )}
                <Typography sx={{ fontSize: 18, fontWeight: 400, color: "#0f1111", mb: 1 }}>
                  ${(subtotal + tax).toFixed(2)}
                </Typography>

                {taxRate > 0 && (
                  <Typography variant="caption" sx={{ color: "#565959", display: "block", mb: 1 }}>
                    ${subtotal.toFixed(2)} + ${tax.toFixed(2)} IVA
                  </Typography>
                )}

                <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 1.5 }}>
                  <LocalShippingIcon sx={{ fontSize: 16, color: "#067D62" }} />
                  <Typography variant="body2" sx={{ color: "#067D62", fontWeight: 500 }}>
                    Envio GRATIS
                  </Typography>
                </Box>

                <Typography
                  variant="body2"
                  sx={{
                    color: effectiveStock > 0 ? "#067D62" : "#cc0c39",
                    fontWeight: "bold",
                    fontSize: 16,
                    mb: 2,
                  }}
                >
                  {effectiveStock > 0
                    ? product.isService
                      ? "Disponible"
                      : effectiveStock > 10
                        ? "En stock"
                        : `Solo quedan ${effectiveStock}`
                    : "Agotado"}
                </Typography>

                <Box sx={{ mb: 2 }}>
                  <Typography variant="caption" sx={{ mb: 0.5, display: "block" }}>Cantidad:</Typography>
                  <Select
                   
                    value={qty}
                    onChange={(e) => setQty(Number(e.target.value))}
                    fullWidth
                    sx={{
                      bgcolor: "#f0f2f2",
                      borderRadius: "8px",
                      "& .MuiOutlinedInput-notchedOutline": { border: "1px solid #d5d9d9" },
                    }}
                  >
                    {Array.from({ length: Math.min(effectiveStock || 1, 10) }, (_, i) => i + 1).map((v) => (
                      <MenuItem key={v} value={v}>{v}</MenuItem>
                    ))}
                  </Select>
                </Box>

                <Button
                  variant="contained"
                  fullWidth
                  startIcon={<ShoppingCartIcon />}
                  onClick={handleAdd}
                  disabled={effectiveStock <= 0 && !product.isService}
                  sx={{
                    bgcolor: "#ffd814",
                    color: "#0f1111",
                    fontWeight: "bold",
                    textTransform: "none",
                    borderRadius: "20px",
                    py: 1,
                    fontSize: 14,
                    boxShadow: "none",
                    border: "1px solid #fcd200",
                    "&:hover": { bgcolor: "#f7ca00", boxShadow: "none" },
                    mb: 1,
                  }}
                >
                  Agregar al carrito
                </Button>

                <Button
                  variant="contained"
                  fullWidth
                  disabled={effectiveStock <= 0 && !product.isService}
                  sx={{
                    bgcolor: "#ffa41c",
                    color: "#0f1111",
                    fontWeight: "bold",
                    textTransform: "none",
                    borderRadius: "20px",
                    py: 1,
                    fontSize: 14,
                    boxShadow: "none",
                    border: "1px solid #ff8f00",
                    "&:hover": { bgcolor: "#fa8900", boxShadow: "none" },
                    mb: 2,
                  }}
                >
                  Comprar ahora
                </Button>

                <Box sx={{ display: "flex", alignItems: "center", gap: 0.5, justifyContent: "center" }}>
                  <ShieldIcon sx={{ fontSize: 14, color: "#067D62" }} />
                  <Typography variant="caption" sx={{ color: "#067D62" }}>
                    Transaccion segura
                  </Typography>
                </Box>
              </Paper>
            </Box>
          </Grid>
        </Grid>
      </Paper>

      {/* ═══ Descripción del producto ═══ */}
      {product.longDescription && (
        <Paper elevation={0} sx={{ border: "1px solid #e3e6e6", borderRadius: "8px", mt: 3, p: 3 }}>
          <Typography variant="h6" sx={{ fontWeight: 700, color: "#0f1111", mb: 2, fontSize: 18 }}>
            Descripción del producto
          </Typography>
          <Typography variant="body2" sx={{ color: "#333", lineHeight: 1.7, whiteSpace: "pre-line" }}>
            {product.longDescription}
          </Typography>
        </Paper>
      )}

      {/* ═══ Especificaciones técnicas completas ═══ */}
      {product.specs && product.specs.length > 0 && (() => {
        const groups: Record<string, ProductSpec[]> = {};
        for (const s of product.specs) {
          (groups[s.group] ??= []).push(s);
        }
        return (
          <Paper elevation={0} sx={{ border: "1px solid #e3e6e6", borderRadius: "8px", mt: 3, p: 3 }}>
            <Typography variant="h6" sx={{ fontWeight: 700, color: "#0f1111", mb: 2, fontSize: 18 }}>
              Especificaciones técnicas
            </Typography>
            {Object.entries(groups).map(([groupName, items]) => (
              <Box key={groupName} sx={{ mb: 2 }}>
                <Typography variant="body2" fontWeight={600} sx={{ color: "#0f1111", mb: 0.5 }}>
                  {groupName}
                </Typography>
                <Box sx={{ border: "1px solid #e3e6e6", borderRadius: "4px", overflow: "hidden" }}>
                  {items.map((spec, i) => (
                    <Box
                      key={`${spec.key}-${i}`}
                      sx={{
                        display: "flex",
                        borderBottom: i < items.length - 1 ? "1px solid #e3e6e6" : "none",
                        "&:nth-of-type(odd)": { bgcolor: "#f7f7f7" },
                      }}
                    >
                      <Box sx={{ flex: "0 0 40%", p: 1, pl: 1.5 }}>
                        <Typography variant="body2" sx={{ color: "#565959", fontSize: 13 }}>{spec.key}</Typography>
                      </Box>
                      <Box sx={{ flex: 1, p: 1 }}>
                        <Typography variant="body2" sx={{ color: "#0f1111", fontSize: 13 }}>{spec.value}</Typography>
                      </Box>
                    </Box>
                  ))}
                </Box>
              </Box>
            ))}
          </Paper>
        );
      })()}

      {/* ═══ Atributos de industria ═══ */}
      {product.industryAttributes && product.industryAttributes.length > 0 && (() => {
        const groups: Record<string, IndustryAttribute[]> = {};
        for (const a of product.industryAttributes) {
          (groups[a.displayGroup] ??= []).push(a);
        }
        const formatValue = (attr: IndustryAttribute) => {
          if (attr.dataType === "BOOLEAN") return attr.valueBoolean ? "Si" : "No";
          if (attr.dataType === "DATE" && attr.valueDate) return new Date(attr.valueDate).toLocaleDateString("es-VE");
          if (attr.dataType === "NUMBER" && attr.valueNumber != null) return String(attr.valueNumber);
          return attr.valueText || attr.value || "-";
        };
        return (
          <Paper elevation={0} sx={{ border: "1px solid #e3e6e6", borderRadius: "8px", mt: 3, p: 3 }}>
            <Typography variant="h6" sx={{ fontWeight: 700, color: "#0f1111", mb: 2, fontSize: 18 }}>
              {product.industryTemplateName ? `Informacion ${product.industryTemplateName}` : "Atributos del producto"}
            </Typography>
            {Object.entries(groups).map(([groupName, attrs]) => (
              <Box key={groupName} sx={{ mb: 2 }}>
                <Typography variant="body2" fontWeight={600} sx={{ color: "#0f1111", mb: 0.5 }}>
                  {groupName}
                </Typography>
                <Box sx={{ border: "1px solid #e3e6e6", borderRadius: "4px", overflow: "hidden" }}>
                  {attrs.map((attr, i) => (
                    <Box
                      key={attr.key}
                      sx={{
                        display: "flex",
                        borderBottom: i < attrs.length - 1 ? "1px solid #e3e6e6" : "none",
                        "&:nth-of-type(odd)": { bgcolor: "#f7f7f7" },
                      }}
                    >
                      <Box sx={{ flex: "0 0 40%", p: 1, pl: 1.5 }}>
                        <Typography variant="body2" sx={{ color: "#565959", fontSize: 13 }}>{attr.label}</Typography>
                      </Box>
                      <Box sx={{ flex: 1, p: 1 }}>
                        <Typography variant="body2" sx={{ color: "#0f1111", fontSize: 13 }}>{formatValue(attr)}</Typography>
                      </Box>
                    </Box>
                  ))}
                </Box>
              </Box>
            ))}
          </Paper>
        );
      })()}

      {reviews && (
        <Box sx={{ mt: 3 }}>
          {reviews}
        </Box>
      )}

      <ProductRecommendations
        productCode={product.code}
        onProductClick={(code) => {
          if (typeof window !== "undefined") {
            window.location.href = `/productos/${code}`;
          }
        }}
      />

      <RecentlyViewedRail
        title="Vistos recientemente"
        onProductClick={(code) => {
          if (code !== product.code && typeof window !== "undefined") {
            window.location.href = `/productos/${code}`;
          }
        }}
      />
    </Box>
  );
}
