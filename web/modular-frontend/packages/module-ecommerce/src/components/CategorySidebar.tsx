"use client";

import { useState } from "react";
import {
  Box, Typography, Skeleton, Divider, Slider, Rating, Switch,
  FormControlLabel, Button, Collapse,
} from "@mui/material";
import ExpandMoreIcon from "@mui/icons-material/ExpandMore";
import ExpandLessIcon from "@mui/icons-material/ExpandLess";

interface CategoryItem {
  code: string;
  name: string;
  productCount: number;
}

export interface SidebarFilters {
  category?: string;
  brand?: string;
  priceMin?: number;
  priceMax?: number;
  minRating?: number;
  inStockOnly?: boolean;
}

interface Props {
  categories: CategoryItem[];
  brands?: CategoryItem[];
  filters: SidebarFilters;
  onFiltersChange: (filters: Partial<SidebarFilters>) => void;
  loading?: boolean;
}

function CollapsibleSection({ title, defaultOpen = true, children }: { title: string; defaultOpen?: boolean; children: React.ReactNode }) {
  const [open, setOpen] = useState(defaultOpen);
  return (
    <Box sx={{ mb: 1 }}>
      <Box
        onClick={() => setOpen(!open)}
        sx={{ display: "flex", alignItems: "center", justifyContent: "space-between", cursor: "pointer", py: 0.5 }}
      >
        <Typography variant="subtitle2" fontWeight="bold" sx={{ color: "#0f1111", fontSize: 14 }}>
          {title}
        </Typography>
        {open ? <ExpandLessIcon sx={{ fontSize: 18, color: "#565959" }} /> : <ExpandMoreIcon sx={{ fontSize: 18, color: "#565959" }} />}
      </Box>
      <Collapse in={open}>{children}</Collapse>
    </Box>
  );
}

function FilterList({
  items,
  selected,
  onSelect,
}: {
  items: CategoryItem[];
  selected?: string;
  onSelect: (code: string | undefined) => void;
}) {
  return (
    <Box>
      <Box
        onClick={() => onSelect(undefined)}
        sx={{
          py: 0.4, px: 1, cursor: "pointer", borderRadius: "4px",
          bgcolor: !selected ? "#edfdff" : "transparent",
          "&:hover": { bgcolor: !selected ? "#edfdff" : "#f7f7f7" },
        }}
      >
        <Typography variant="body2" sx={{ color: !selected ? "#007185" : "#0f1111", fontWeight: !selected ? 600 : 400, fontSize: 13 }}>
          Todas
        </Typography>
      </Box>
      {items.map((item) => (
        <Box
          key={item.code}
          onClick={() => onSelect(item.code)}
          sx={{
            py: 0.4, px: 1, cursor: "pointer", borderRadius: "4px",
            bgcolor: selected === item.code ? "#edfdff" : "transparent",
            "&:hover": { bgcolor: selected === item.code ? "#edfdff" : "#f7f7f7" },
            display: "flex", justifyContent: "space-between", alignItems: "center",
          }}
        >
          <Typography variant="body2" sx={{ color: selected === item.code ? "#007185" : "#0f1111", fontWeight: selected === item.code ? 600 : 400, fontSize: 13 }}>
            {item.name}
          </Typography>
          <Typography variant="caption" sx={{ color: "#565959", fontSize: 11 }}>
            ({item.productCount})
          </Typography>
        </Box>
      ))}
    </Box>
  );
}

export default function CategorySidebar({ categories, brands, filters, onFiltersChange, loading }: Props) {
  const [priceRange, setPriceRange] = useState<number[]>([filters.priceMin ?? 0, filters.priceMax ?? 10000]);

  if (loading) {
    return (
      <Box sx={{ p: 2 }}>
        {[...Array(8)].map((_, i) => (
          <Skeleton key={i} height={32} sx={{ mb: 0.5 }} />
        ))}
      </Box>
    );
  }

  const handlePriceCommit = (_: any, val: number | number[]) => {
    const [min, max] = val as number[];
    onFiltersChange({
      priceMin: min > 0 ? min : undefined,
      priceMax: max < 10000 ? max : undefined,
    });
  };

  return (
    <Box sx={{ pr: 2 }}>
      <Typography variant="h6" fontWeight="bold" sx={{ color: "#0f1111", mb: 1.5, fontSize: 16 }}>
        Filtros
      </Typography>

      {/* Categorías */}
      <CollapsibleSection title="Categoria">
        <FilterList
          items={categories}
          selected={filters.category}
          onSelect={(c) => onFiltersChange({ category: c })}
        />
      </CollapsibleSection>

      <Divider sx={{ my: 1 }} />

      {/* Marcas */}
      {brands && brands.length > 0 && (
        <>
          <CollapsibleSection title="Marca">
            <FilterList
              items={brands}
              selected={filters.brand}
              onSelect={(b) => onFiltersChange({ brand: b })}
            />
          </CollapsibleSection>
          <Divider sx={{ my: 1 }} />
        </>
      )}

      {/* Rango de precio */}
      <CollapsibleSection title="Precio">
        <Box sx={{ px: 1.5, pt: 1 }}>
          <Slider
            value={priceRange}
            onChange={(_, val) => setPriceRange(val as number[])}
            onChangeCommitted={handlePriceCommit}
            min={0}
            max={10000}
            step={50}
            valueLabelDisplay="auto"
            valueLabelFormat={(v) => `$${v.toLocaleString()}`}
            sx={{
              color: "#ff9900",
              "& .MuiSlider-thumb": { bgcolor: "#fff", border: "2px solid #ff9900", width: 18, height: 18 },
              "& .MuiSlider-valueLabel": { bgcolor: "#131921" },
            }}
          />
          <Box sx={{ display: "flex", justifyContent: "space-between" }}>
            <Typography variant="caption" sx={{ color: "#565959" }}>${priceRange[0].toLocaleString()}</Typography>
            <Typography variant="caption" sx={{ color: "#565959" }}>${priceRange[1].toLocaleString()}</Typography>
          </Box>
        </Box>
      </CollapsibleSection>

      <Divider sx={{ my: 1 }} />

      {/* Rating mínimo */}
      <CollapsibleSection title="Calificacion">
        <Box sx={{ px: 0.5 }}>
          {[4, 3, 2, 1].map((stars) => (
            <Box
              key={stars}
              onClick={() => onFiltersChange({ minRating: filters.minRating === stars ? undefined : stars })}
              sx={{
                display: "flex", alignItems: "center", gap: 0.5, py: 0.4, px: 0.5,
                cursor: "pointer", borderRadius: "4px",
                bgcolor: filters.minRating === stars ? "#edfdff" : "transparent",
                "&:hover": { bgcolor: filters.minRating === stars ? "#edfdff" : "#f7f7f7" },
              }}
            >
              <Rating value={stars} readOnly size="small" sx={{ color: "#ffa41c" }} />
              <Typography variant="caption" sx={{ color: "#0f1111", fontSize: 12 }}>
                y mas
              </Typography>
            </Box>
          ))}
        </Box>
      </CollapsibleSection>

      <Divider sx={{ my: 1 }} />

      {/* Disponibilidad */}
      <CollapsibleSection title="Disponibilidad" defaultOpen={false}>
        <Box sx={{ px: 0.5 }}>
          <FormControlLabel
            control={
              <Switch
                checked={filters.inStockOnly !== false}
                onChange={(e) => onFiltersChange({ inStockOnly: e.target.checked })}
                size="small"
                sx={{ "& .MuiSwitch-switchBase.Mui-checked": { color: "#ff9900" }, "& .MuiSwitch-switchBase.Mui-checked + .MuiSwitch-track": { bgcolor: "#ff9900" } }}
              />
            }
            label={<Typography variant="body2" sx={{ fontSize: 13 }}>Solo en stock</Typography>}
          />
        </Box>
      </CollapsibleSection>

      <Divider sx={{ my: 1 }} />

      {/* Limpiar filtros */}
      <Button
        size="small"
        fullWidth
        onClick={() => {
          setPriceRange([0, 10000]);
          onFiltersChange({
            category: undefined,
            brand: undefined,
            priceMin: undefined,
            priceMax: undefined,
            minRating: undefined,
            inStockOnly: true,
          });
        }}
        sx={{
          mt: 1,
          textTransform: "none",
          color: "#007185",
          fontSize: 13,
          "&:hover": { bgcolor: "#f7fafa" },
        }}
      >
        Limpiar filtros
      </Button>
    </Box>
  );
}
