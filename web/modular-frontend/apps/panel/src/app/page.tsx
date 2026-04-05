"use client";

import React from "react";
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  Chip,
  Skeleton,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import {
  Language as SitesIcon,
  Public as PublishedIcon,
  EditNote as DraftIcon,
  Visibility as ViewsIcon,
  Add as AddIcon,
  MenuBook as DocsIcon,
  ArrowForward as ArrowIcon,
} from "@mui/icons-material";
import { useRouter } from "next/navigation";

/* ---------- stat cards ---------- */

interface StatCardProps {
  title: string;
  value: string | number;
  icon: React.ReactNode;
  color: string;
  bgColor: string;
}

function StatCard({ title, value, icon, color, bgColor }: StatCardProps) {
  return (
    <Card elevation={0} sx={{ border: "1px solid #e2e8f0", borderRadius: 3 }}>
      <CardContent sx={{ p: 2.5, "&:last-child": { pb: 2.5 } }}>
        <Box sx={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between" }}>
          <Box>
            <Typography variant="body2" sx={{ color: "#64748b", fontWeight: 500, mb: 0.5 }}>
              {title}
            </Typography>
            <Typography variant="h4" sx={{ fontWeight: 700, color: "#1e293b" }}>
              {value}
            </Typography>
          </Box>
          <Box
            sx={{
              width: 44,
              height: 44,
              borderRadius: 2.5,
              bgcolor: bgColor,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              color,
            }}
          >
            {icon}
          </Box>
        </Box>
      </CardContent>
    </Card>
  );
}

/* ---------- mock data ---------- */

const STATS = [
  { title: "Total Sitios", value: 12, icon: <SitesIcon />, color: "#6366f1", bgColor: "#eef2ff" },
  { title: "Publicados", value: 8, icon: <PublishedIcon />, color: "#059669", bgColor: "#ecfdf5" },
  { title: "Borradores", value: 4, icon: <DraftIcon />, color: "#f59e0b", bgColor: "#fffbeb" },
  { title: "Visitas Totales", value: "3.2k", icon: <ViewsIcon />, color: "#3b82f6", bgColor: "#eff6ff" },
];

const RECENT_SITES = [
  { id: "1", name: "Mi Tienda Online", status: "published", updatedAt: "2026-04-04" },
  { id: "2", name: "Blog Personal", status: "published", updatedAt: "2026-04-03" },
  { id: "3", name: "Landing Producto", status: "draft", updatedAt: "2026-04-02" },
  { id: "4", name: "Portfolio", status: "published", updatedAt: "2026-04-01" },
  { id: "5", name: "Evento 2026", status: "draft", updatedAt: "2026-03-30" },
];

/* ---------- page ---------- */

export default function DashboardPage() {
  const router = useRouter();

  return (
    <Box sx={{ maxWidth: 1100 }}>
      {/* Welcome */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h5" sx={{ fontWeight: 700, color: "#1e293b", mb: 0.5 }}>
          Bienvenido a Zentto Panel
        </Typography>
        <Typography variant="body1" sx={{ color: "#64748b" }}>
          Gestiona tus sitios web, paginas y contenido desde un solo lugar.
        </Typography>
      </Box>

      {/* Stats */}
      <Grid container spacing={2.5} sx={{ mb: 4 }}>
        {STATS.map((stat) => (
          <Grid key={stat.title} size={{ xs: 6, md: 3 }}>
            <StatCard {...stat} />
          </Grid>
        ))}
      </Grid>

      {/* Two-column: recent sites + quick actions */}
      <Grid container spacing={2.5}>
        {/* Recent sites */}
        <Grid size={{ xs: 12, md: 8 }}>
          <Card elevation={0} sx={{ border: "1px solid #e2e8f0", borderRadius: 3 }}>
            <CardContent sx={{ p: 0 }}>
              <Box
                sx={{
                  px: 2.5,
                  py: 2,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "space-between",
                  borderBottom: "1px solid #f1f5f9",
                }}
              >
                <Typography variant="subtitle1" sx={{ fontWeight: 600, color: "#1e293b" }}>
                  Sitios Recientes
                </Typography>
                <Button
                  size="small"
                  onClick={() => router.push("/sites")}
                  endIcon={<ArrowIcon sx={{ fontSize: "16px !important" }} />}
                  sx={{ textTransform: "none", fontSize: 13, color: "#6366f1" }}
                >
                  Ver todos
                </Button>
              </Box>

              {RECENT_SITES.map((site, idx) => (
                <Box
                  key={site.id}
                  sx={{
                    px: 2.5,
                    py: 1.5,
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "space-between",
                    borderBottom: idx < RECENT_SITES.length - 1 ? "1px solid #f1f5f9" : "none",
                    cursor: "pointer",
                    "&:hover": { bgcolor: "#fafbfc" },
                    transition: "background 0.15s",
                  }}
                  onClick={() => router.push(`/sites/${site.id}`)}
                >
                  <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
                    <Box
                      sx={{
                        width: 32,
                        height: 32,
                        borderRadius: 1.5,
                        bgcolor: "#f1f5f9",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                      }}
                    >
                      <SitesIcon sx={{ fontSize: 18, color: "#94a3b8" }} />
                    </Box>
                    <Typography variant="body2" sx={{ fontWeight: 500, color: "#334155" }}>
                      {site.name}
                    </Typography>
                  </Box>
                  <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
                    <Chip
                      label={site.status === "published" ? "Publicado" : "Borrador"}
                      size="small"
                      sx={{
                        height: 24,
                        fontSize: 12,
                        fontWeight: 500,
                        bgcolor: site.status === "published" ? "#ecfdf5" : "#fffbeb",
                        color: site.status === "published" ? "#059669" : "#d97706",
                        border: "none",
                      }}
                    />
                    <Typography variant="caption" sx={{ color: "#94a3b8", minWidth: 80, textAlign: "right" }}>
                      {site.updatedAt}
                    </Typography>
                  </Box>
                </Box>
              ))}
            </CardContent>
          </Card>
        </Grid>

        {/* Quick actions */}
        <Grid size={{ xs: 12, md: 4 }}>
          <Card elevation={0} sx={{ border: "1px solid #e2e8f0", borderRadius: 3 }}>
            <CardContent sx={{ p: 2.5 }}>
              <Typography variant="subtitle1" sx={{ fontWeight: 600, color: "#1e293b", mb: 2 }}>
                Acciones Rapidas
              </Typography>

              <Button
                variant="contained"
                fullWidth
                startIcon={<AddIcon />}
                onClick={() => router.push("/sites/new")}
                sx={{
                  mb: 1.5,
                  py: 1.2,
                  textTransform: "none",
                  fontWeight: 600,
                  borderRadius: 2,
                  bgcolor: "#6366f1",
                  "&:hover": { bgcolor: "#4f46e5" },
                }}
              >
                Crear Sitio
              </Button>

              <Button
                variant="outlined"
                fullWidth
                startIcon={<DocsIcon />}
                onClick={() => window.open("https://docs.zentto.net", "_blank")}
                sx={{
                  py: 1.2,
                  textTransform: "none",
                  fontWeight: 600,
                  borderRadius: 2,
                  borderColor: "#e2e8f0",
                  color: "#475569",
                  "&:hover": { borderColor: "#6366f1", color: "#6366f1", bgcolor: "#fafafe" },
                }}
              >
                Ver Documentacion
              </Button>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}
