"use client";

import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Box from "@mui/material/Box";
import Typography from "@mui/material/Typography";
import Button from "@mui/material/Button";
import Grid from "@mui/material/Grid2";
import Card from "@mui/material/Card";
import CardContent from "@mui/material/CardContent";
import CardMedia from "@mui/material/CardMedia";
import CardActions from "@mui/material/CardActions";
import Chip from "@mui/material/Chip";
import TextField from "@mui/material/TextField";
import InputAdornment from "@mui/material/InputAdornment";
import MenuItem from "@mui/material/MenuItem";
import Select from "@mui/material/Select";
import FormControl from "@mui/material/FormControl";
import InputLabel from "@mui/material/InputLabel";
import ToggleButton from "@mui/material/ToggleButton";
import ToggleButtonGroup from "@mui/material/ToggleButtonGroup";
import Rating from "@mui/material/Rating";
import Skeleton from "@mui/material/Skeleton";
import Dialog from "@mui/material/Dialog";
import DialogTitle from "@mui/material/DialogTitle";
import DialogContent from "@mui/material/DialogContent";
import DialogActions from "@mui/material/DialogActions";
import CircularProgress from "@mui/material/CircularProgress";
import SearchIcon from "@mui/icons-material/Search";
import DownloadIcon from "@mui/icons-material/Download";
import StorefrontIcon from "@mui/icons-material/Storefront";
import { marketplaceApi } from "@/lib/api";

const CATEGORIES = [
  { value: "", label: "Todas" },
  { value: "saas", label: "SaaS" },
  { value: "blog", label: "Blog" },
  { value: "portfolio", label: "Portfolio" },
  { value: "agency", label: "Agencia" },
  { value: "ecommerce", label: "E-commerce" },
  { value: "landing", label: "Landing Page" },
  { value: "restaurant", label: "Restaurante" },
];

interface Template {
  id: string;
  name: string;
  description: string;
  category: string;
  thumbnail: string;
  rating: number;
  reviewCount: number;
  downloads: number;
  price: number;
  author: string;
  tags: string[];
  createdAt: string;
}

export default function TemplatesPage() {
  const router = useRouter();
  const [templates, setTemplates] = useState<Template[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState("");
  const [sort, setSort] = useState("downloads");
  const [priceFilter, setPriceFilter] = useState<string | null>(null);
  const [selected, setSelected] = useState<Template | null>(null);
  const [using, setUsing] = useState(false);

  const fetchTemplates = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await marketplaceApi.browse({
        category: category || undefined,
        search: search || undefined,
        sort,
        limit: 30,
      });
      let list: Template[] = Array.isArray(data) ? data : data.templates ?? [];
      if (priceFilter === "free") list = list.filter((t) => t.price === 0);
      if (priceFilter === "premium") list = list.filter((t) => t.price > 0);
      setTemplates(list);
    } catch (err: any) {
      setError(err.message ?? "Error al cargar templates");
    } finally {
      setLoading(false);
    }
  }, [category, search, sort, priceFilter]);

  useEffect(() => {
    const timer = setTimeout(() => fetchTemplates(), 300);
    return () => clearTimeout(timer);
  }, [fetchTemplates]);

  const handleUseTemplate = async (template: Template) => {
    try {
      setUsing(true);
      const result = await marketplaceApi.use(template.id);
      const siteId = result?.siteId ?? result?.id;
      if (siteId) {
        router.push(`/sites/${siteId}`);
      }
    } catch (err: any) {
      setError(err.message ?? "Error al usar template");
    } finally {
      setUsing(false);
      setSelected(null);
    }
  };

  const formatPrice = (price: number) => {
    if (price === 0) return "Gratis";
    return `$${price.toFixed(2)}`;
  };

  /* ---------- Loading skeleton ---------- */
  if (loading && templates.length === 0) {
    return (
      <Box sx={{ p: 4 }}>
        <Skeleton variant="text" width={300} height={48} sx={{ mb: 2 }} />
        <Box sx={{ display: "flex", gap: 2, mb: 3 }}>
          <Skeleton variant="rounded" width={300} height={40} />
          <Skeleton variant="rounded" width={150} height={40} />
        </Box>
        <Grid container spacing={3}>
          {[1, 2, 3, 4, 5, 6].map((i) => (
            <Grid key={i} size={{ xs: 12, sm: 6, md: 4 }}>
              <Skeleton variant="rounded" height={320} />
            </Grid>
          ))}
        </Grid>
      </Box>
    );
  }

  /* ---------- Empty state ---------- */
  if (!loading && templates.length === 0 && !error) {
    return (
      <Box
        sx={{
          p: 4,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          minHeight: "60vh",
          textAlign: "center",
        }}
      >
        <StorefrontIcon sx={{ fontSize: 96, color: "text.disabled", mb: 2 }} />
        <Typography variant="h5" gutterBottom>
          No se encontraron templates
        </Typography>
        <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
          Intenta con otros filtros o busqueda.
        </Typography>
        <Button variant="outlined" onClick={() => { setSearch(""); setCategory(""); setPriceFilter(null); }}>
          Limpiar filtros
        </Button>
      </Box>
    );
  }

  return (
    <Box sx={{ p: 4 }}>
      {/* Header */}
      <Typography variant="h4" fontWeight={700} sx={{ mb: 1 }}>
        Marketplace de Templates
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
        Explora templates profesionales para crear tu sitio web.
      </Typography>

      {/* Filters */}
      <Box sx={{ display: "flex", flexWrap: "wrap", gap: 2, mb: 3, alignItems: "center" }}>
        <TextField
          size="small"
          placeholder="Buscar templates..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          sx={{ minWidth: 280 }}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <SearchIcon fontSize="small" />
              </InputAdornment>
            ),
          }}
        />

        <FormControl size="small" sx={{ minWidth: 150 }}>
          <InputLabel>Ordenar por</InputLabel>
          <Select value={sort} label="Ordenar por" onChange={(e) => setSort(e.target.value)}>
            <MenuItem value="downloads">Popular</MenuItem>
            <MenuItem value="rating">Mejor valorado</MenuItem>
            <MenuItem value="newest">Mas reciente</MenuItem>
          </Select>
        </FormControl>

        <ToggleButtonGroup
          value={priceFilter}
          exclusive
          onChange={(_, val) => setPriceFilter(val)}
          size="small"
        >
          <ToggleButton value="free">Gratis</ToggleButton>
          <ToggleButton value="premium">Premium</ToggleButton>
        </ToggleButtonGroup>
      </Box>

      {/* Category chips */}
      <Box sx={{ display: "flex", flexWrap: "wrap", gap: 1, mb: 3 }}>
        {CATEGORIES.map((cat) => (
          <Chip
            key={cat.value}
            label={cat.label}
            variant={category === cat.value ? "filled" : "outlined"}
            color={category === cat.value ? "primary" : "default"}
            onClick={() => setCategory(cat.value)}
            sx={{ cursor: "pointer" }}
          />
        ))}
      </Box>

      {/* Error */}
      {error && (
        <Typography color="error" sx={{ mb: 2 }}>
          {error}
        </Typography>
      )}

      {/* Templates grid */}
      <Grid container spacing={3}>
        {templates.map((template) => (
          <Grid key={template.id} size={{ xs: 12, sm: 6, md: 4 }}>
            <Card
              sx={{
                height: "100%",
                display: "flex",
                flexDirection: "column",
                cursor: "pointer",
                transition: "box-shadow 0.2s, transform 0.2s",
                "&:hover": { boxShadow: 8, transform: "translateY(-2px)" },
              }}
              onClick={() => setSelected(template)}
            >
              <CardMedia
                component="img"
                height={180}
                image={template.thumbnail || "/placeholder-template.png"}
                alt={template.name}
                sx={{ objectFit: "cover", bgcolor: "#f1f5f9" }}
              />
              <CardContent sx={{ flexGrow: 1 }}>
                <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", mb: 1 }}>
                  <Typography variant="h6" noWrap sx={{ maxWidth: "65%", fontSize: 16 }}>
                    {template.name}
                  </Typography>
                  <Chip
                    label={CATEGORIES.find((c) => c.value === template.category)?.label || template.category}
                    size="small"
                    color="primary"
                    variant="outlined"
                  />
                </Box>

                <Typography variant="body2" color="text.secondary" sx={{ mb: 1.5, display: "-webkit-box", WebkitLineClamp: 2, WebkitBoxOrient: "vertical", overflow: "hidden" }}>
                  {template.description}
                </Typography>

                <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 1 }}>
                  <Rating value={template.rating} precision={0.5} size="small" readOnly />
                  <Typography variant="caption" color="text.secondary">
                    ({template.reviewCount})
                  </Typography>
                </Box>

                <Box sx={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                  <Box sx={{ display: "flex", alignItems: "center", gap: 0.5 }}>
                    <DownloadIcon sx={{ fontSize: 16, color: "text.secondary" }} />
                    <Typography variant="caption" color="text.secondary">
                      {template.downloads.toLocaleString()}
                    </Typography>
                  </Box>
                  <Chip
                    label={formatPrice(template.price)}
                    size="small"
                    color={template.price === 0 ? "success" : "warning"}
                    variant="filled"
                  />
                </Box>
              </CardContent>

              <CardActions sx={{ px: 2, pb: 1.5 }} onClick={(e) => e.stopPropagation()}>
                <Button
                  size="small"
                  variant="contained"
                  fullWidth
                  onClick={() => setSelected(template)}
                >
                  Ver detalles
                </Button>
              </CardActions>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Detail dialog */}
      <Dialog open={!!selected} onClose={() => !using && setSelected(null)} maxWidth="sm" fullWidth>
        {selected && (
          <>
            <DialogTitle sx={{ fontWeight: 700 }}>{selected.name}</DialogTitle>
            <DialogContent>
              <Box
                component="img"
                src={selected.thumbnail || "/placeholder-template.png"}
                alt={selected.name}
                sx={{ width: "100%", height: 220, objectFit: "cover", borderRadius: 2, mb: 2, bgcolor: "#f1f5f9" }}
              />
              <Box sx={{ display: "flex", gap: 1, mb: 2 }}>
                <Chip
                  label={CATEGORIES.find((c) => c.value === selected.category)?.label || selected.category}
                  size="small"
                  color="primary"
                />
                <Chip label={formatPrice(selected.price)} size="small" color={selected.price === 0 ? "success" : "warning"} />
              </Box>

              <Typography variant="body1" sx={{ mb: 2 }}>
                {selected.description}
              </Typography>

              <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 1 }}>
                <Rating value={selected.rating} precision={0.5} readOnly />
                <Typography variant="body2" color="text.secondary">
                  {selected.rating.toFixed(1)} ({selected.reviewCount} resenas)
                </Typography>
              </Box>

              <Box sx={{ display: "flex", alignItems: "center", gap: 2 }}>
                <Box sx={{ display: "flex", alignItems: "center", gap: 0.5 }}>
                  <DownloadIcon sx={{ fontSize: 18, color: "text.secondary" }} />
                  <Typography variant="body2" color="text.secondary">
                    {selected.downloads.toLocaleString()} descargas
                  </Typography>
                </Box>
                <Typography variant="body2" color="text.secondary">
                  Por: {selected.author}
                </Typography>
              </Box>
            </DialogContent>
            <DialogActions sx={{ px: 3, pb: 2 }}>
              <Button onClick={() => setSelected(null)} disabled={using}>
                Cancelar
              </Button>
              <Button
                variant="contained"
                onClick={() => handleUseTemplate(selected)}
                disabled={using}
                startIcon={using ? <CircularProgress size={16} /> : undefined}
              >
                {using ? "Creando sitio..." : "Usar template"}
              </Button>
            </DialogActions>
          </>
        )}
      </Dialog>
    </Box>
  );
}
