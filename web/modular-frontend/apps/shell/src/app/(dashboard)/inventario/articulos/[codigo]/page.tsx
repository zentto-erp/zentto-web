"use client";

import { useParams, useRouter } from "next/navigation";
import { useArticuloById } from "@zentto/module-inventario";
import {
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  Divider,
  Skeleton,
  Typography,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";

function FieldItem({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <Box sx={{ mb: 1.5 }}>
      <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 600 }}>
        {label}
      </Typography>
      <Typography variant="body1">{value ?? "\u2014"}</Typography>
    </Box>
  );
}

export default function ArticuloDetallePage() {
  const params = useParams<{ codigo: string }>();
  const router = useRouter();
  const codigo = decodeURIComponent(params.codigo ?? "");
  const { data: articulo, isLoading, isError } = useArticuloById(codigo) as any;

  if (isLoading) {
    return (
      <Box sx={{ p: 3 }}>
        <Skeleton variant="rectangular" height={400} sx={{ borderRadius: 2 }} />
      </Box>
    );
  }

  if (isError || !articulo) {
    return (
      <Box sx={{ p: 3 }}>
        <Button startIcon={<ArrowBackIcon />} onClick={() => router.back()}>
          Volver
        </Button>
        <Typography variant="h6" sx={{ mt: 2 }} color="error">
          No se pudo cargar el artículo con código &ldquo;{codigo}&rdquo;.
        </Typography>
      </Box>
    );
  }

  const formatCurrency = (v: number | undefined | null) =>
    v != null ? v.toLocaleString("es", { style: "currency", currency: "USD" }) : "\u2014";

  return (
    <Box sx={{ p: { xs: 1, md: 3 } }}>
      <Button startIcon={<ArrowBackIcon />} onClick={() => router.back()} sx={{ mb: 2 }}>
        Volver
      </Button>

      <Card sx={{ borderRadius: 2, boxShadow: "0 2px 8px rgba(0,0,0,0.08)" }}>
        <CardContent>
          <Box sx={{ display: "flex", alignItems: "center", gap: 2, mb: 2 }}>
            <Typography variant="h5" sx={{ fontWeight: 700 }}>
              {articulo.descripcionCompleta || articulo.descripcion}
            </Typography>
            <Chip
              label={articulo.estado}
              color={articulo.estado === "Activo" ? "success" : "default"}
              size="small"
            />
          </Box>

          <Divider sx={{ mb: 3 }} />

          <Grid container spacing={3}>
            <Grid size={{ xs: 12, md: 4 }}>
              <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 1 }}>
                Identificación
              </Typography>
              <FieldItem label="Código" value={articulo.codigo} />
              <FieldItem label="Descripción" value={articulo.descripcion} />
              <FieldItem label="Categoría" value={articulo.categoria} />
              <FieldItem label="Tipo" value={articulo.tipo} />
              <FieldItem label="Marca" value={articulo.marca} />
              <FieldItem label="Clase" value={articulo.clase} />
              <FieldItem label="Línea" value={articulo.linea} />
              <FieldItem label="Referencia" value={articulo.referencia} />
              <FieldItem label="Código de Barras" value={articulo.barra} />
            </Grid>

            <Grid size={{ xs: 12, md: 4 }}>
              <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 1 }}>
                Precios
              </Typography>
              <FieldItem label="Precio Venta" value={formatCurrency(articulo.precioVenta)} />
              <FieldItem label="Precio Compra" value={formatCurrency(articulo.precioCompra)} />
              <FieldItem label="Costo Promedio" value={formatCurrency(articulo.costoPromedio)} />
              <FieldItem label="Precio Venta 1" value={formatCurrency(articulo.precioVenta1)} />
              <FieldItem label="Precio Venta 2" value={formatCurrency(articulo.precioVenta2)} />
              <FieldItem label="Precio Venta 3" value={formatCurrency(articulo.precioVenta3)} />
              <FieldItem label="Alícuota %" value={articulo.alicuota} />
            </Grid>

            <Grid size={{ xs: 12, md: 4 }}>
              <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 1 }}>
                Inventario
              </Typography>
              <FieldItem label="Stock Actual" value={articulo.stock} />
              <FieldItem label="Unidad" value={articulo.unidad} />
              <FieldItem label="Mínimo" value={articulo.minimo} />
              <FieldItem label="Máximo" value={articulo.maximo} />
              <FieldItem label="Ubicación" value={articulo.ubicacion} />
              <FieldItem label="Ubicación Física" value={articulo.ubicaFisica} />
              <FieldItem label="Servicio" value={articulo.servicio ? "Sí" : "No"} />
              <FieldItem label="PLU" value={articulo.plu} />
              <FieldItem label="N. Parte" value={articulo.nParte} />
            </Grid>
          </Grid>
        </CardContent>
      </Card>
    </Box>
  );
}
