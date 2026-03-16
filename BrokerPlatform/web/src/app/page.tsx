"use client";
import {
  Box, Container, Typography, TextField, Button, Card, CardMedia, CardContent,
  Chip, Rating, Grid, InputAdornment, IconButton, Stack, Select, MenuItem, FormControl, InputLabel,
  useTheme, alpha,
} from "@mui/material";
import SearchIcon from "@mui/icons-material/Search";
import LocationOnIcon from "@mui/icons-material/LocationOn";
import HotelIcon from "@mui/icons-material/Hotel";
import DirectionsCarIcon from "@mui/icons-material/DirectionsCar";
import SailingIcon from "@mui/icons-material/Sailing";
import FlightIcon from "@mui/icons-material/Flight";
import CabinIcon from "@mui/icons-material/Cabin";
import ExploreIcon from "@mui/icons-material/Explore";
import ArrowForwardIcon from "@mui/icons-material/ArrowForward";
import StarIcon from "@mui/icons-material/Star";
import { useState } from "react";
import { useSearch } from "@/hooks/useApi";
import { useRouter } from "next/navigation";
import Link from "next/link";

const categories = [
  { type: "room", label: "Hotels", icon: <HotelIcon />, color: "#6C63FF" },
  { type: "vehicle", label: "Cars", icon: <DirectionsCarIcon />, color: "#FF6584" },
  { type: "boat", label: "Boats", icon: <SailingIcon />, color: "#00C9A7" },
  { type: "flight", label: "Flights", icon: <FlightIcon />, color: "#4FC3F7" },
  { type: "unit", label: "Lodges & Tours", icon: <CabinIcon />, color: "#FFB547" },
];

export default function HomePage() {
  const theme = useTheme();
  const router = useRouter();
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedType, setSelectedType] = useState("");

  const { data: featured } = useSearch({ limit: "6", sort: "rating" });

  const handleSearch = () => {
    const params = new URLSearchParams();
    if (searchQuery) params.set("q", searchQuery);
    if (selectedType) params.set("type", selectedType);
    router.push(`/search?${params.toString()}`);
  };

  return (
    <Box sx={{ minHeight: "100vh", bgcolor: "background.default" }}>
      {/* HEADER */}
      <Box
        component="header"
        sx={{
          position: "sticky",
          top: 0,
          zIndex: 100,
          backdropFilter: "blur(20px)",
          bgcolor: alpha(theme.palette.background.default, 0.8),
          borderBottom: "1px solid rgba(255,255,255,0.06)",
          px: 3,
          py: 1.5,
        }}
      >
        <Stack direction="row" alignItems="center" justifyContent="space-between" maxWidth="lg" mx="auto" gap={1}>
          <Stack direction="row" alignItems="center" gap={1}>
            <ExploreIcon sx={{ color: "primary.main", fontSize: 32 }} />
            <Typography variant="h5" fontWeight={700} sx={{ background: "linear-gradient(135deg, #6C63FF, #FF6584)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>
              BrokerPlatform
            </Typography>
          </Stack>
          <Stack direction="row" gap={1} flexWrap="wrap" justifyContent="flex-end">
            <Button component={Link} href="/auth/login" variant="outlined" size="small" sx={{ borderColor: "rgba(255,255,255,0.15)", color: "text.secondary", minWidth: { xs: 72, sm: 90 } }}>
              Log In
            </Button>
            <Button component={Link} href="/auth/register" variant="contained" size="small" sx={{ minWidth: { xs: 78, sm: 90 } }}>
              Sign Up
            </Button>
            <Button component={Link} href="/admin" variant="text" size="small" sx={{ color: "text.secondary", display: { xs: "none", sm: "inline-flex" } }}>
              Admin
            </Button>
          </Stack>
        </Stack>
      </Box>

      {/* HERO */}
      <Box
        sx={{
          position: "relative",
          py: { xs: 8, md: 14 },
          textAlign: "center",
          overflow: "hidden",
          "&::before": {
            content: '""',
            position: "absolute",
            top: -200,
            left: "50%",
            transform: "translateX(-50%)",
            width: 800,
            height: 800,
            borderRadius: "50%",
            background: "radial-gradient(circle, rgba(108,99,255,0.15) 0%, transparent 70%)",
          },
        }}
      >
        <Container maxWidth="md" sx={{ position: "relative", zIndex: 1 }}>
          <Typography variant="h2" fontWeight={800} sx={{ fontSize: { xs: "2rem", md: "3.5rem" }, lineHeight: 1.15, mb: 2 }}>
            Discover Your Next{" "}
            <Box component="span" sx={{ background: "linear-gradient(135deg, #6C63FF, #FF6584)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>
              Adventure
            </Box>
          </Typography>
          <Typography variant="h6" color="text.secondary" sx={{ mb: 5, maxWidth: 600, mx: "auto", fontWeight: 400 }}>
            Hotels, cars, boats, flights, lodges & tours — all in one place. Best prices, real-time availability.
          </Typography>

          {/* Search Bar */}
          <Card sx={{ p: 2, bgcolor: alpha(theme.palette.background.paper, 0.7), backdropFilter: "blur(24px)", maxWidth: 700, mx: "auto", border: "1px solid rgba(255,255,255,0.08)" }}>
            <Stack direction={{ xs: "column", sm: "row" }} gap={1.5} alignItems="stretch">
              <TextField
                fullWidth
                placeholder="Where are you going?"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && handleSearch()}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <LocationOnIcon sx={{ color: "primary.main" }} />
                    </InputAdornment>
                  ),
                }}
                size="small"
              />
              <FormControl size="small" sx={{ minWidth: 140 }}>
                <InputLabel>Type</InputLabel>
                <Select value={selectedType} label="Type" onChange={(e) => setSelectedType(e.target.value)}>
                  <MenuItem value="">All</MenuItem>
                  {categories.map((c) => (
                    <MenuItem key={c.type} value={c.type}>{c.label}</MenuItem>
                  ))}
                </Select>
              </FormControl>
              <Button variant="contained" onClick={handleSearch} sx={{ px: 4, minWidth: 120 }} startIcon={<SearchIcon />}>
                Search
              </Button>
            </Stack>
          </Card>
        </Container>
      </Box>

      {/* CATEGORIES */}
      <Container maxWidth="lg" sx={{ py: 4 }}>
        <Stack direction="row" flexWrap="wrap" justifyContent="center" gap={2}>
          {categories.map((cat) => (
            <Card
              key={cat.type}
              onClick={() => router.push(`/search?type=${cat.type}`)}
              sx={{
                p: 2.5,
                minWidth: 140,
                textAlign: "center",
                cursor: "pointer",
                transition: "all 0.3s ease",
                bgcolor: alpha(cat.color, 0.08),
                border: `1px solid ${alpha(cat.color, 0.15)}`,
                "&:hover": { transform: "translateY(-4px)", bgcolor: alpha(cat.color, 0.15), boxShadow: `0 8px 32px ${alpha(cat.color, 0.2)}` },
              }}
            >
              <Box sx={{ color: cat.color, mb: 1, "& svg": { fontSize: 36 } }}>{cat.icon}</Box>
              <Typography variant="body2" fontWeight={600}>{cat.label}</Typography>
            </Card>
          ))}
        </Stack>
      </Container>

      {/* FEATURED */}
      <Container maxWidth="lg" sx={{ py: 6 }}>
        <Stack direction="row" justifyContent="space-between" alignItems="center" mb={3}>
          <Typography variant="h4" fontWeight={700}>Featured Listings</Typography>
          <Button component={Link} href="/search" endIcon={<ArrowForwardIcon />} sx={{ color: "primary.main" }}>
            View All
          </Button>
        </Stack>
        <Grid container spacing={3}>
          {featured?.rows?.map((item: any) => (
            <Grid size={{ xs: 12, sm: 6, md: 4 }} key={item.id}>
              <Card
                onClick={() => router.push(`/property/${item.id}`)}
                sx={{
                  cursor: "pointer",
                  transition: "all 0.3s ease",
                  "&:hover": { transform: "translateY(-6px)", boxShadow: "0 12px 40px rgba(108,99,255,0.15)" },
                  height: "100%",
                  display: "flex",
                  flexDirection: "column",
                }}
              >
                <CardMedia
                  component="img"
                  height={200}
                  image={
                    item.images
                      ? JSON.parse(item.images)[0] + "?w=400&h=200&fit=crop"
                      : "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=400&h=200&fit=crop"
                  }
                  alt={item.name}
                  sx={{ objectFit: "cover" }}
                />
                <CardContent sx={{ flex: 1, display: "flex", flexDirection: "column" }}>
                  <Stack direction="row" justifyContent="space-between" alignItems="start" mb={1}>
                    <Chip
                      label={item.provider_type?.replace("_", " ")}
                      size="small"
                      sx={{
                        bgcolor: alpha(categories.find((c) => c.type === item.type)?.color || "#6C63FF", 0.15),
                        color: categories.find((c) => c.type === item.type)?.color || "#6C63FF",
                        fontWeight: 600,
                        textTransform: "capitalize",
                      }}
                    />
                    {item.provider_rating > 0 && (
                      <Stack direction="row" alignItems="center" gap={0.3}>
                        <StarIcon sx={{ fontSize: 16, color: "#FFB547" }} />
                        <Typography variant="body2" fontWeight={600}>{item.provider_rating}</Typography>
                      </Stack>
                    )}
                  </Stack>
                  <Typography variant="subtitle1" fontWeight={600} gutterBottom sx={{ lineHeight: 1.3 }}>
                    {item.name}
                  </Typography>
                  <Stack direction="row" alignItems="center" gap={0.5} mb={1}>
                    <LocationOnIcon sx={{ fontSize: 14, color: "text.secondary" }} />
                    <Typography variant="body2" color="text.secondary">
                      {item.city}{item.country ? `, ${item.country}` : ""}
                    </Typography>
                  </Stack>
                  <Typography variant="body2" color="text.secondary" sx={{ flex: 1, mb: 2, display: "-webkit-box", WebkitLineClamp: 2, WebkitBoxOrient: "vertical", overflow: "hidden" }}>
                    {item.description}
                  </Typography>
                  <Stack direction="row" justifyContent="space-between" alignItems="center">
                    <Typography variant="h6" fontWeight={700} color="primary.main">
                      {item.base_price ? `$${item.base_price}` : "Contact"}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      {item.type === "room" ? "/night" : item.type === "vehicle" ? "/day" : item.type === "flight" ? "/person" : "/unit"}
                    </Typography>
                  </Stack>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>
      </Container>

      {/* FOOTER */}
      <Box component="footer" sx={{ borderTop: "1px solid rgba(255,255,255,0.06)", py: 4, mt: 6 }}>
        <Container maxWidth="lg">
          <Stack direction={{ xs: "column", md: "row" }} justifyContent="space-between" alignItems="center" gap={2}>
            <Stack direction="row" alignItems="center" gap={1}>
              <ExploreIcon sx={{ color: "primary.main" }} />
              <Typography variant="body2" color="text.secondary">© 2026 BrokerPlatform. All rights reserved.</Typography>
            </Stack>
            <Stack direction="row" gap={3}>
              <Typography variant="body2" color="text.secondary" sx={{ cursor: "pointer", "&:hover": { color: "primary.main" } }}>About</Typography>
              <Typography variant="body2" color="text.secondary" sx={{ cursor: "pointer", "&:hover": { color: "primary.main" } }}>Contact</Typography>
              <Typography variant="body2" color="text.secondary" sx={{ cursor: "pointer", "&:hover": { color: "primary.main" } }}>Privacy</Typography>
            </Stack>
          </Stack>
        </Container>
      </Box>
    </Box>
  );
}
