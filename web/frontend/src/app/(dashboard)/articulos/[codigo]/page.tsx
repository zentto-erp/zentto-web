// app/(dashboard)/articulos/[codigo]/page.tsx
"use client";

import { useParams, useRouter } from "next/navigation";
import { Box, Button, Paper, CircularProgress, Grid, Typography, Chip, Divider } from "@mui/material";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import EditIcon from "@mui/icons-material/Edit";
import { useArticuloById } from "@/hooks/useArticulos";
import { formatCurrency } from "@/lib/formatters";

export default function ArticuloDetailPage() {
  const params = useParams();
  const router = useRouter();
  const codigo = params.codigo as string;

  const { data: articulo, isLoading, error } = useArticuloById(codigo);

  if (isLoading) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", alignItems: "center", height: 400 }}>
        <CircularProgress />
      </Box>
    );
  }

  if (error || !articulo) {
    return (
      <Box sx={{ p: 2 }}>
        <Button
          startIcon={<ArrowBackIcon />}
          onClick={() => router.push("/articulos")}
          sx={{ mb: 2 }}
        >
          Volver
        </Button>
        <Typography color="error">Error al cargar el artículo</Typography>
      </Box>
    );
  }

  /** Ítem de detalle reutilizable */
  const DetailItem = ({ label, value }: { label: string; value: React.ReactNode }) => (
    <Box sx={{ mb: 2 }}>
      <Typography variant="caption" sx={{ color: "text.secondary", fontWeight: 600 }}>
        {label}
      </Typography>
      <Typography variant="body1">{value || "N/A"}</Typography>
    </Box>
  );

  return (
    <Box sx={{ p: 2 }}>
      {/* Header */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
        <Box>
          <Button
            startIcon={<ArrowBackIcon />}
            onClick={() => router.push("/articulos")}
            sx={{ mb: 1 }}
          >
            Volver
          </Button>
          <Typography variant="h5" sx={{ fontWeight: 600 }}>
            {articulo.descripcionCompleta || articulo.descripcion}
          </Typography>
          {articulo.linea && (
            <Chip label={articulo.linea} size="small" color="primary" variant="outlined" sx={{ mt: 0.5 }} />
          )}
        </Box>
        <Box sx={{ display: "flex", gap: 1 }}>
          <Chip
            label={articulo.estado}
            color={articulo.estado === "Activo" ? "success" : "default"}
            variant="outlined"
          />
          <Button
            variant="contained"
            startIcon={<EditIcon />}
            onClick={() => router.push(`/articulos/${codigo}/edit`)}
          >
            Editar
          </Button>
        </Box>
      </Box>

      {/* Detalles */}
      <Paper sx={{ p: 3 }}>
        <Grid container spacing={3}>
          {/* Columna 1: Identificación */}
          <Grid item xs={12} sm={6} md={4}>
            <DetailItem label="CÓDIGO" value={articulo.codigo} />
            <DetailItem label="REFERENCIA" value={articulo.referencia} />
            <DetailItem label="CÓDIGO DE BARRAS" value={articulo.barra} />
            <DetailItem label="UNIDAD" value={articulo.unidad} />
          </Grid>

          {/* Columna 2: Clasificación */}
          <Grid item xs={12} sm={6} md={4}>
            <DetailItem label="LÍNEA" value={articulo.linea} />
            <DetailItem label="CATEGORÍA" value={articulo.categoria} />
            <DetailItem label="TIPO" value={articulo.tipo} />
            <DetailItem label="MARCA" value={articulo.marca} />
            <DetailItem label="CLASE" value={articulo.clase} />
          </Grid>

          {/* Columna 3: Precios y Stock */}
          <Grid item xs={12} sm={6} md={4}>
            <DetailItem
              label="PRECIO VENTA"
              value={
                <Typography fontWeight={600} color="primary.main">
                  {formatCurrency(articulo.precioVenta)}
                </Typography>
              }
            />
            <DetailItem label="PRECIO COMPRA" value={formatCurrency(articulo.precioCompra)} />
            <DetailItem label="% GANANCIA" value={`${articulo.porcentaje}%`} />
            <DetailItem label="ALÍCUOTA IVA" value={`${articulo.alicuota}%`} />
            <DetailItem
              label="STOCK DISPONIBLE"
              value={
                <Typography fontWeight={600} color={articulo.stock <= 0 ? "error.main" : "text.primary"}>
                  {articulo.stock} unidades
                </Typography>
              }
            />
          </Grid>

          {/* Descripción completa */}
          <Grid item xs={12}>
            <Divider sx={{ mb: 2 }} />
            <DetailItem label="DESCRIPCIÓN COMPLETA" value={articulo.descripcionCompleta} />
          </Grid>
        </Grid>
      </Paper>
    </Box>
  );
}
