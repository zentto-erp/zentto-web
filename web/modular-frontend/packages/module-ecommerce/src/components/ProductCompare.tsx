"use client";

import { useMemo } from "react";
import {
  Box, Typography, Paper, Button, IconButton, Chip, CircularProgress, Alert,
} from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import CheckIcon from "@mui/icons-material/Check";
import { useCompareProducts } from "../hooks/useStoreSearch";
import { useCompareStore } from "../store/useCompareStore";
import { useCartStore } from "../store/useCartStore";
import { formatPrice } from "../utils/formatCurrency";

interface Props {
  onClear?: () => void;
}

const fmt = (v: number | null | undefined, suffix = "") =>
  v == null ? "—" : `${Number(v).toLocaleString()}${suffix}`;

export default function ProductCompare({ onClear }: Props) {
  const codes = useCompareStore((s) => s.codes);
  const toggle = useCompareStore((s) => s.toggle);
  const clear = useCompareStore((s) => s.clear);
  const currency = useCartStore((s) => s.currency);
  const { data, isLoading, error } = useCompareProducts(codes);

  const allSpecKeys = useMemo(() => {
    if (!data) return [] as string[];
    const set = new Set<string>();
    for (const p of data) Object.keys(p.specs || {}).forEach((k) => set.add(k));
    return Array.from(set).sort();
  }, [data]);

  if (codes.length < 2) {
    return (
      <Alert severity="info">
        Selecciona al menos 2 productos para compararlos.
        <Typography variant="caption" sx={{ display: "block", mt: 0.5 }}>
          Tip: usa el botón "Comparar" en cada tarjeta de producto.
        </Typography>
      </Alert>
    );
  }

  if (isLoading) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", py: 4 }}>
        <CircularProgress />
      </Box>
    );
  }

  if (error || !data) {
    return <Alert severity="error">No se pudo cargar la comparación.</Alert>;
  }

  const cols = data.length;

  const Row = ({ label, render }: { label: string; render: (p: typeof data[number]) => React.ReactNode }) => (
    <Box sx={{ display: "grid", gridTemplateColumns: `200px repeat(${cols}, minmax(180px, 1fr))`, borderBottom: "1px solid #e3e6e6" }}>
      <Box sx={{ p: 1.5, bgcolor: "#f7f7f7", color: "#565959", fontSize: 13, fontWeight: 600 }}>
        {label}
      </Box>
      {data.map((p) => (
        <Box key={p.code} sx={{ p: 1.5, fontSize: 14, color: "#0f1111" }}>
          {render(p)}
        </Box>
      ))}
    </Box>
  );

  return (
    <Box>
      <Box sx={{ display: "flex", alignItems: "center", justifyContent: "space-between", mb: 2 }}>
        <Typography variant="h5" fontWeight={700}>Comparar productos ({cols})</Typography>
        <Button
          variant="text"
          color="error"
          size="small"
          onClick={() => { clear(); onClear?.(); }}
        >
          Vaciar comparador
        </Button>
      </Box>

      <Paper sx={{ overflow: "hidden", borderRadius: 2 }}>
        {/* Header con imagen + remove */}
        <Box sx={{ display: "grid", gridTemplateColumns: `200px repeat(${cols}, minmax(180px, 1fr))`, borderBottom: "2px solid #e3e6e6" }}>
          <Box sx={{ p: 1.5, bgcolor: "#f0f2f2" }} />
          {data.map((p) => (
            <Box key={p.code} sx={{ p: 1.5, position: "relative" }}>
              <IconButton
                size="small"
                onClick={() => toggle(p.code)}
                sx={{ position: "absolute", top: 4, right: 4 }}
              >
                <CloseIcon fontSize="small" />
              </IconButton>
              <Box
                component="img"
                src={p.imageUrl}
                alt={p.name}
                sx={{ width: "100%", height: 130, objectFit: "contain", bgcolor: "#fafafa", borderRadius: 1, mb: 1 }}
              />
              <Typography variant="body2" fontWeight={600} sx={{ display: "-webkit-box", WebkitLineClamp: 2, WebkitBoxOrient: "vertical", overflow: "hidden", minHeight: 36 }}>
                {p.name}
              </Typography>
              <Typography variant="h6" fontWeight={700} color="primary" sx={{ mt: 0.5 }}>
                {formatPrice(p.price, currency)}
              </Typography>
            </Box>
          ))}
        </Box>

        <Row label="Marca"        render={(p) => p.brand || "—"} />
        <Row label="Categoría"    render={(p) => p.category || "—"} />
        <Row label="Stock"        render={(p) => p.stock > 0
          ? <Chip size="small" color="success" icon={<CheckIcon />} label={`${p.stock} disponibles`} />
          : <Chip size="small" color="error" label="Agotado" />} />
        <Row label="Calificación" render={(p) => p.avgRating > 0 ? `${p.avgRating.toFixed(1)} ★ (${p.reviewCount})` : "Sin reseñas"} />
        <Row label="Garantía"     render={(p) => fmt(p.warrantyMonths, " meses")} />
        <Row label="Peso"         render={(p) => fmt(p.weightKg, " kg")} />
        <Row label="Dimensiones"  render={(p) =>
          p.widthCm && p.heightCm && p.depthCm
            ? `${p.widthCm} × ${p.heightCm} × ${p.depthCm} cm`
            : "—"
        } />

        {allSpecKeys.length > 0 && (
          <>
            <Box sx={{ p: 1.5, bgcolor: "#0f1111", color: "#fff", fontSize: 13, fontWeight: 700 }}>
              Especificaciones técnicas
            </Box>
            {allSpecKeys.map((key) => (
              <Row
                key={key}
                label={key}
                render={(p) => p.specs[key] || "—"}
              />
            ))}
          </>
        )}
      </Paper>
    </Box>
  );
}
