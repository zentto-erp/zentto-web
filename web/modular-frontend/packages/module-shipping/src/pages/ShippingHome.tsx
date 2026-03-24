"use client";

import { Box, Typography, Paper, Grid2 as Grid, Button, Chip } from "@mui/material";
import LocalShippingIcon from "@mui/icons-material/LocalShipping";
import SearchIcon from "@mui/icons-material/Search";
import GavelIcon from "@mui/icons-material/Gavel";
import SpeedIcon from "@mui/icons-material/Speed";
import NotificationsActiveIcon from "@mui/icons-material/NotificationsActive";
import PublicIcon from "@mui/icons-material/Public";

interface Props {
  onNavigate: (path: string) => void;
}

export default function ShippingHome({ onNavigate }: Props) {
  return (
    <Box>
      {/* Hero */}
      <Paper
        sx={{
          p: { xs: 4, md: 8 }, mb: 4, textAlign: "center",
          background: "linear-gradient(135deg, #1565c0 0%, #0d47a1 100%)",
          color: "#fff", borderRadius: 3,
        }}
      >
        <LocalShippingIcon sx={{ fontSize: 64, mb: 2, color: "#ffcc02" }} />
        <Typography variant="h3" fontWeight={800} sx={{ mb: 1, fontSize: { xs: 28, md: 42 } }}>
          Zentto Shipping
        </Typography>
        <Typography variant="h6" sx={{ mb: 3, opacity: 0.9, fontWeight: 400, fontSize: { xs: 16, md: 20 } }}>
          Envía, rastrea y gestiona tus paquetes con los mejores carriers
        </Typography>
        <Box sx={{ display: "flex", gap: 2, justifyContent: "center", flexWrap: "wrap" }}>
          <Button variant="contained" size="large" onClick={() => onNavigate("/registro")}
            sx={{ bgcolor: "#ffcc02", color: "#0d47a1", fontWeight: 700, px: 4, "&:hover": { bgcolor: "#ffd740" } }}>
            Crear cuenta gratis
          </Button>
          <Button variant="outlined" size="large" onClick={() => onNavigate("/rastreo")}
            sx={{ borderColor: "#fff", color: "#fff", px: 4, "&:hover": { bgcolor: "rgba(255,255,255,0.1)" } }}>
            Rastrear envío
          </Button>
        </Box>
      </Paper>

      {/* Features */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        {[
          { icon: <SpeedIcon sx={{ fontSize: 40, color: "#1565c0" }} />, title: "Cotización instantánea", desc: "Compara precios de múltiples carriers en segundos" },
          { icon: <SearchIcon sx={{ fontSize: 40, color: "#1565c0" }} />, title: "Rastreo en tiempo real", desc: "Sigue tu paquete paso a paso con timeline detallado" },
          { icon: <NotificationsActiveIcon sx={{ fontSize: 40, color: "#1565c0" }} />, title: "Notificaciones automáticas", desc: "Email, SMS y WhatsApp en cada cambio de estado" },
          { icon: <GavelIcon sx={{ fontSize: 40, color: "#1565c0" }} />, title: "Gestión de aduanas", desc: "Declaraciones aduaneras y documentación integrada" },
          { icon: <PublicIcon sx={{ fontSize: 40, color: "#1565c0" }} />, title: "Envíos internacionales", desc: "Venezuela, Colombia, España, México, USA y más" },
          { icon: <LocalShippingIcon sx={{ fontSize: 40, color: "#1565c0" }} />, title: "Múltiples carriers", desc: "Zoom, MRW, Liberty Express y más" },
        ].map((f, i) => (
          <Grid key={i} size={{ xs: 12, sm: 6, md: 4 }}>
            <Paper sx={{ p: 3, textAlign: "center", height: "100%", borderRadius: 2, "&:hover": { boxShadow: 4 }, transition: "box-shadow 0.2s" }}>
              {f.icon}
              <Typography variant="h6" fontWeight={700} sx={{ mt: 1, mb: 0.5, fontSize: 16 }}>{f.title}</Typography>
              <Typography variant="body2" color="text.secondary">{f.desc}</Typography>
            </Paper>
          </Grid>
        ))}
      </Grid>

      {/* Carriers */}
      <Paper sx={{ p: 4, textAlign: "center", borderRadius: 2, mb: 4 }}>
        <Typography variant="h5" fontWeight={700} sx={{ mb: 2 }}>Nuestros Carriers</Typography>
        <Box sx={{ display: "flex", gap: 2, justifyContent: "center", flexWrap: "wrap" }}>
          {[
            { name: "Zoom", countries: "VE, CO, EC, PA" },
            { name: "MRW", countries: "ES, PT, VE, CO, MX" },
            { name: "Liberty Express", countries: "VE, CO, PA, DO, CL, US" },
          ].map((c) => (
            <Paper key={c.name} variant="outlined" sx={{ p: 2, minWidth: 200, borderRadius: 2 }}>
              <Typography variant="subtitle1" fontWeight={700}>{c.name}</Typography>
              <Box sx={{ display: "flex", gap: 0.5, justifyContent: "center", flexWrap: "wrap", mt: 1 }}>
                {c.countries.split(", ").map((cc) => (
                  <Chip key={cc} label={cc} size="small" color="primary" variant="outlined" />
                ))}
              </Box>
            </Paper>
          ))}
        </Box>
      </Paper>

      {/* CTA */}
      <Box sx={{ textAlign: "center", py: 4 }}>
        <Typography variant="h5" fontWeight={700} sx={{ mb: 1 }}>
          Comienza a enviar hoy
        </Typography>
        <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
          Registra tu cuenta gratis y envía tu primer paquete en minutos
        </Typography>
        <Button variant="contained" size="large" onClick={() => onNavigate("/registro")}
          sx={{ bgcolor: "#1565c0", px: 5, fontWeight: 700 }}>
          Crear cuenta
        </Button>
      </Box>
    </Box>
  );
}
