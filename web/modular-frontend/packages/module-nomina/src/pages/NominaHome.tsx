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
import PeopleIcon from "@mui/icons-material/People";
import ListAltIcon from "@mui/icons-material/ListAlt";
import BeachAccessIcon from "@mui/icons-material/BeachAccess";
import ExitToAppIcon from "@mui/icons-material/ExitToApp";
import TuneIcon from "@mui/icons-material/Tune";

const sections = [
  {
    title: "Nóminas",
    description: "Procesar, consultar y cerrar nóminas de empleados",
    icon: <PeopleIcon sx={{ fontSize: 48, color: "#aa1816" }} />,
    href: "/nomina/nominas",
  },
  {
    title: "Conceptos",
    description: "Gestión de conceptos de asignación, deducción y bonos",
    icon: <ListAltIcon sx={{ fontSize: 48, color: "#aa1816" }} />,
    href: "/nomina/conceptos",
  },
  {
    title: "Vacaciones",
    description: "Procesar y consultar vacaciones de empleados",
    icon: <BeachAccessIcon sx={{ fontSize: 48, color: "#aa1816" }} />,
    href: "/nomina/vacaciones",
  },
  {
    title: "Liquidaciones",
    description: "Calcular y consultar liquidaciones laborales",
    icon: <ExitToAppIcon sx={{ fontSize: 48, color: "#aa1816" }} />,
    href: "/nomina/liquidaciones",
  },
  {
    title: "Constantes",
    description: "Parámetros y constantes del sistema de nómina",
    icon: <TuneIcon sx={{ fontSize: 48, color: "#aa1816" }} />,
    href: "/nomina/constantes",
  },
];

export default function NominaHome() {
  return (
    <Box>

      <Grid container spacing={3}>
        {sections.map((s) => (
          <Grid size={{ xs: 12, sm: 6, md: 4 }} key={s.title}>
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
