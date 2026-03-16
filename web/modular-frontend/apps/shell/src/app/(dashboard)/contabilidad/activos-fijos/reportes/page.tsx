"use client";
import { Box, Typography, Paper } from "@mui/material";
export default function Page() {
  return (
    <Box sx={{ p: { xs: 2, md: 3 } }}>
      <Paper sx={{ p: 4, textAlign: "center" }}>
        <Typography variant="h5" fontWeight={700} gutterBottom>
          Reportes de Activos Fijos
        </Typography>
        <Typography variant="body1" color="text.secondary">
          En construccion
        </Typography>
      </Paper>
    </Box>
  );
}
