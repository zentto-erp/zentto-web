"use client";

import { Box, Grid, Pagination, Typography, CircularProgress } from "@mui/material";
import ProductCard from "./ProductCard";

interface Product {
  id: number;
  code: string;
  name: string;
  fullDescription?: string;
  category?: string;
  brand?: string;
  price: number;
  stock: number;
  taxRate: number;
  imageUrl?: string | null;
  avgRating?: number;
  reviewCount?: number;
  // Marketplace — productos de store.MerchantProduct aprobados
  source?: "zentto" | "merchant";
  merchant?: { id: number; slug: string; name: string; rating?: number | null } | null;
}

interface Props {
  products: Product[];
  total: number;
  page: number;
  limit: number;
  loading?: boolean;
  onPageChange: (page: number) => void;
  onViewDetail?: (code: string) => void;
}

export default function ProductGrid({ products, total, page, limit, loading, onPageChange, onViewDetail }: Props) {
  const pageCount = Math.ceil(total / limit);

  if (loading) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", py: 8 }}>
        <CircularProgress sx={{ color: "#ff9900" }} />
      </Box>
    );
  }

  if (!products.length) {
    return (
      <Box sx={{ textAlign: "center", py: 8 }}>
        <Typography variant="h6" color="text.secondary" sx={{ mb: 1 }}>
          No se encontraron productos
        </Typography>
        <Typography variant="body2" color="text.secondary">
          Intenta con otros filtros o terminos de busqueda
        </Typography>
      </Box>
    );
  }

  return (
    <Box>
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 2 }}>
        <Typography variant="body2" sx={{ color: "#565959" }}>
          {total > 0 ? `${((page - 1) * limit) + 1}-${Math.min(page * limit, total)} de ${total} resultados` : "0 resultados"}
        </Typography>
      </Box>

      <Grid container spacing={2}>
        {products.map((p) => (
          <Grid key={p.code} xs={6} sm={4} md={4} lg={3}>
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
              merchant={p.merchant ?? undefined}
              onViewDetail={onViewDetail}
            />
          </Grid>
        ))}
      </Grid>

      {pageCount > 1 && (
        <Box sx={{ display: "flex", justifyContent: "center", mt: 4 }}>
          <Pagination
            count={pageCount}
            page={page}
            onChange={(_, v) => onPageChange(v)}
            sx={{
              "& .MuiPaginationItem-root": {
                "&.Mui-selected": { bgcolor: "#131921", color: "#fff", "&:hover": { bgcolor: "#232f3e" } },
              },
            }}
          />
        </Box>
      )}
    </Box>
  );
}
