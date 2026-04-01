"use client";

import {
  Box,
  Typography,
  Stack,
  Alert,
} from "@mui/material";
import MoneyIcon from "@mui/icons-material/AttachMoney";

export default function PlanesPage() {
  return (
    <Box>
      <Stack direction="row" alignItems="center" gap={1} mb={2}>
        <MoneyIcon color="primary" />
        <Typography variant="h5" fontWeight={700}>
          Planes y Licencias
        </Typography>
      </Stack>

      <Alert severity="info">
        Esta seccion esta en desarrollo. La gestion de planes se realiza actualmente desde la vista de Tenants.
      </Alert>
    </Box>
  );
}
