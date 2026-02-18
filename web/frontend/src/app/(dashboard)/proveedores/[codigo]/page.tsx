// app/(dashboard)/proveedores/[codigo]/page.tsx
"use client";

import { useParams, useRouter } from "next/navigation";
import { Box, Button, Paper, CircularProgress, Grid, Typography, Chip } from "@mui/material";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import EditIcon from "@mui/icons-material/Edit";
import { useProveedorById } from "@/hooks/useProveedores";
import { formatCurrency, formatDate } from "@/lib/formatters";

export default function ProveedorDetailPage() {
  const params = useParams();
  const router = useRouter();
  const codigo = params.codigo as string;

  const { data: proveedor, isLoading, error } = useProveedorById(codigo);

  if (isLoading) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", alignItems: "center", height: 400 }}>
        <CircularProgress />
      </Box>
    );
  }

  if (error || !proveedor) {
    return (
      <Box sx={{ p: 2 }}>
        <Button
          startIcon={<ArrowBackIcon />}
          onClick={() => router.push("/proveedores")}
          sx={{ mb: 2 }}
        >
          Volver
        </Button>
        <Typography color="error">Error al cargar el proveedor</Typography>
      </Box>
    );
  }

  return (
    <Box sx={{ p: 2 }}>
      {/* Header */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
        <Box>
          <Button
            startIcon={<ArrowBackIcon />}
            onClick={() => router.push("/proveedores")}
            sx={{ mb: 1 }}
          >
            Volver
          </Button>
          <Typography variant="h5" sx={{ fontWeight: 600 }}>
            {proveedor.nombre}
          </Typography>
        </Box>
        <Box sx={{ display: "flex", gap: 1 }}>
          <Chip
            label={proveedor.estado}
            color={proveedor.estado === "Activo" ? "success" : "default"}
            variant="outlined"
          />
          <Button
            variant="contained"
            startIcon={<EditIcon />}
            onClick={() => router.push(`/proveedores/${codigo}/edit`)}
          >
            Editar
          </Button>
        </Box>
      </Box>

      {/* Details */}
      <Paper sx={{ p: 3 }}>
        <Grid container spacing={3}>
          {/* Column 1 */}
          <Grid item xs={12} sm={6}>
            <Typography variant="caption" sx={{ color: "text.secondary", fontWeight: 600 }}>
              CÓDIGO
            </Typography>
            <Typography variant="body1" sx={{ mb: 2 }}>
              {proveedor.codigo}
            </Typography>

            <Typography variant="caption" sx={{ color: "text.secondary", fontWeight: 600 }}>
              RIF
            </Typography>
            <Typography variant="body1" sx={{ mb: 2 }}>
              {proveedor.rif}
            </Typography>

            <Typography variant="caption" sx={{ color: "text.secondary", fontWeight: 600 }}>
              TELÉFONO
            </Typography>
            <Typography variant="body1" sx={{ mb: 2 }}>
              {proveedor.telefono || "N/A"}
            </Typography>
          </Grid>

          {/* Column 2 */}
          <Grid item xs={12} sm={6}>
            <Typography variant="caption" sx={{ color: "text.secondary", fontWeight: 600 }}>
              EMAIL
            </Typography>
            <Typography variant="body1" sx={{ mb: 2 }}>
              {proveedor.email || "N/A"}
            </Typography>

            <Typography variant="caption" sx={{ color: "text.secondary", fontWeight: 600 }}>
              SALDO
            </Typography>
            <Typography variant="body1" sx={{ mb: 2 }}>
              {formatCurrency(proveedor.saldo || 0)}
            </Typography>
          </Grid>

          {/* Dirección (Full Width) */}
          <Grid item xs={12}>
            <Typography variant="caption" sx={{ color: "text.secondary", fontWeight: 600 }}>
              DIRECCIÓN
            </Typography>
            <Typography variant="body1">{proveedor.direccion}</Typography>
          </Grid>
        </Grid>
      </Paper>
    </Box>
  );
}
