"use client";

import { Box, Typography, Card, CardContent, CardActionArea, Stack, Chip } from "@mui/material";
import {
  Inventory as ArticulosIcon,
  Receipt as FacturasIcon,
  Science as LabIcon,
  Extension as StudioIcon,
  AutoFixHigh as WizardIcon,
  Apps as AddonsIcon,
} from "@mui/icons-material";
import { useRouter } from "next/navigation";

const PAGES = [
  {
    title: "Articulos",
    description: "Tabla con filtros avanzados, vista compacta/extendida, precio slider, comodines",
    href: "/articulos",
    icon: <ArticulosIcon sx={{ fontSize: 48 }} />,
    color: "#ff9800",
  },
  {
    title: "Facturas",
    description: "Tabla con ZenttoFilterPanel, master-detail expandible, filtros server-side",
    href: "/facturas",
    icon: <FacturasIcon sx={{ fontSize: 48 }} />,
    color: "#2196f3",
  },
  {
    title: "Studio Designer",
    description: "Designer visual Figma-style con drag-drop, undo/redo, templates y export JSON",
    href: "/studio-designer",
    icon: <StudioIcon sx={{ fontSize: 48 }} />,
    color: "#9c27b0",
  },
  {
    title: "Studio Wizard",
    description: "Wizard 7 pasos para crear apps completas desde plantillas (CRM, E-Commerce, HR)",
    href: "/studio-designer/wizard",
    icon: <WizardIcon sx={{ fontSize: 48 }} />,
    color: "#00bcd4",
  },
  {
    title: "Addons",
    description: "Aplicaciones personalizadas creadas con Studio — API first, localStorage fallback",
    href: "/addons",
    icon: <AddonsIcon sx={{ fontSize: 48 }} />,
    color: "#546e7a",
  },
];

export default function LabHome() {
  const router = useRouter();

  return (
    <Box sx={{ maxWidth: 800, mx: "auto", mt: 6 }}>
      <Stack direction="row" alignItems="center" spacing={2} sx={{ mb: 4 }}>
        <LabIcon sx={{ fontSize: 40, color: "#1a1a2e" }} />
        <Box>
          <Typography variant="h4" fontWeight={700}>
            Zentto Lab
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Sandbox para probar y ajustar ZenttoDataGrid
          </Typography>
        </Box>
        <Chip label="Auto-login activo" color="success" size="small" />
      </Stack>

      <Stack spacing={3}>
        {PAGES.map((p) => (
          <Card key={p.href} variant="outlined" sx={{ borderLeft: `4px solid ${p.color}` }}>
            <CardActionArea onClick={() => router.push(p.href)}>
              <CardContent sx={{ display: "flex", alignItems: "center", gap: 3 }}>
                <Box sx={{ color: p.color }}>{p.icon}</Box>
                <Box>
                  <Typography variant="h6">{p.title}</Typography>
                  <Typography variant="body2" color="text.secondary">
                    {p.description}
                  </Typography>
                </Box>
              </CardContent>
            </CardActionArea>
          </Card>
        ))}
      </Stack>
    </Box>
  );
}
