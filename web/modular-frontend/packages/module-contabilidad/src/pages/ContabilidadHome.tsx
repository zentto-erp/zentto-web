"use client";

import React from "react";
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Stack,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import AccountBalanceWalletIcon from "@mui/icons-material/AccountBalanceWallet";
import MenuBookIcon from "@mui/icons-material/MenuBook";
import BarChartIcon from "@mui/icons-material/BarChart";
import AccountTreeIcon from "@mui/icons-material/AccountTree";

const sections = [
  {
    title: "Asientos Contables",
    description: "Crear, consultar y anular asientos contables",
    icon: <AccountBalanceWalletIcon sx={{ fontSize: 48, color: "#aa1816" }} />,
    href: "/contabilidad/asientos",
  },
  {
    title: "Plan de Cuentas",
    description: "Catálogo de cuentas contables del sistema",
    icon: <AccountTreeIcon sx={{ fontSize: 48, color: "#aa1816" }} />,
    href: "/contabilidad/cuentas",
  },
  {
    title: "Reportes",
    description: "Libro mayor, balance de comprobación, estado de resultados y balance general",
    icon: <BarChartIcon sx={{ fontSize: 48, color: "#aa1816" }} />,
    href: "/contabilidad/reportes",
  },
  {
    title: "Ajustes y Depreciación",
    description: "Ajustes contables y generación de depreciación periódica",
    icon: <MenuBookIcon sx={{ fontSize: 48, color: "#aa1816" }} />,
    href: "/contabilidad/ajustes",
  },
];

export default function ContabilidadHome() {
  return (
    <Box>

      <Grid container spacing={3}>
        {sections.map((s) => (
          <Grid size={{ xs: 12, sm: 6, md: 3 }} key={s.title}>
            <Card sx={{ height: "100%", display: "flex", flexDirection: "column" }}>
              <CardContent sx={{ flexGrow: 1, textAlign: "center" }}>
                <Box mb={2}>{s.icon}</Box>
                <Typography variant="h6" fontWeight={600} mb={1}>
                  {s.title}
                </Typography>
                <Typography variant="body2" color="text.secondary" mb={2}>
                  {s.description}
                </Typography>
                <Stack alignItems="center">
                  <Button variant="outlined" href={s.href} size="small">
                    Ir al módulo
                  </Button>
                </Stack>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>
    </Box>
  );
}
