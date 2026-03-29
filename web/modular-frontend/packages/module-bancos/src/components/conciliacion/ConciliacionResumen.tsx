"use client";

import { Box, Paper, Typography } from "@mui/material";
import Grid from "@mui/material/Grid2";
import { formatCurrency } from "@zentto/shared-api";

interface ConciliacionResumenProps {
  cabecera: any;
}

export default function ConciliacionResumen({ cabecera }: ConciliacionResumenProps) {
  const conciliados = cabecera?.Conciliados ?? 0;
  const pendientes = cabecera?.Pendientes ?? 0;
  const total = conciliados + pendientes;
  const porcentaje = total > 0 ? ((conciliados / total) * 100).toFixed(1) : "0";

  return (
    <Paper sx={{ mt: 3, p: 3, borderRadius: 2 }}>
      <Typography variant="h6" fontWeight={600} sx={{ mb: 2 }}>
        Resumen de Conciliacion
      </Typography>
      <Grid container spacing={3}>
        <Grid size={{ xs: 12, md: 4 }}>
          <Box sx={{ textAlign: "center" }}>
            <Typography variant="h4" fontWeight={700} color="success.main">
              {porcentaje}%
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Porcentaje conciliado
            </Typography>
          </Box>
        </Grid>
        <Grid size={{ xs: 12, md: 4 }}>
          <Box sx={{ textAlign: "center" }}>
            <Typography variant="h4" fontWeight={700} color="primary.main">
              {formatCurrency(cabecera?.Saldo_Final_Sistema ?? 0)}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Saldo final sistema
            </Typography>
          </Box>
        </Grid>
        <Grid size={{ xs: 12, md: 4 }}>
          <Box sx={{ textAlign: "center" }}>
            <Typography variant="h4" fontWeight={700} color="error.main">
              {formatCurrency(cabecera?.Diferencia ?? 0)}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Diferencia
            </Typography>
          </Box>
        </Grid>
      </Grid>
    </Paper>
  );
}
