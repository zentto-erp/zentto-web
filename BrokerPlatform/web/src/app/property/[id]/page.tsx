"use client";
import { use } from "react";
import {
    Box, Container, Typography, Card, CardContent, Chip, Stack, Button, Grid,
    Divider, Rating, Avatar, CircularProgress, useTheme, alpha,
} from "@mui/material";
import LocationOnIcon from "@mui/icons-material/LocationOn";
import PersonIcon from "@mui/icons-material/Person";
import StarIcon from "@mui/icons-material/Star";
import CalendarTodayIcon from "@mui/icons-material/CalendarToday";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import ExploreIcon from "@mui/icons-material/Explore";
import PhoneIcon from "@mui/icons-material/Phone";
import LanguageIcon from "@mui/icons-material/Language";
import SignpostIcon from "@mui/icons-material/Signpost";
import Link from "next/link";
import { usePropertyDetail } from "@/hooks/useApi";

export default function PropertyDetailPage({ params }: { params: Promise<{ id: string }> }) {
    const { id } = use(params);
    const theme = useTheme();
    const { data: property, isLoading } = usePropertyDetail(id);

    if (isLoading) return <Box sx={{ display: "flex", justifyContent: "center", alignItems: "center", minHeight: "100vh", bgcolor: "background.default" }}><CircularProgress /></Box>;
    if (!property) return <Box sx={{ textAlign: "center", py: 20, bgcolor: "background.default", minHeight: "100vh" }}><Typography variant="h5" color="text.secondary">Property not found</Typography></Box>;

    const images: string[] = property.images ? JSON.parse(property.images) : [];

    return (
        <Box sx={{ minHeight: "100vh", bgcolor: "background.default" }}>
            {/* Header */}
            <Box sx={{ backdropFilter: "blur(20px)", bgcolor: alpha(theme.palette.background.default, 0.8), borderBottom: "1px solid rgba(255,255,255,0.06)", px: 3, py: 1.5, position: "sticky", top: 0, zIndex: 100 }}>
                <Stack direction="row" alignItems="center" justifyContent="space-between" maxWidth="lg" mx="auto">
                    <Stack direction="row" alignItems="center" gap={1} component={Link} href="/" sx={{ textDecoration: "none" }}>
                        <ExploreIcon sx={{ color: "primary.main", fontSize: 28 }} />
                        <Typography variant="h6" fontWeight={700} sx={{ background: "linear-gradient(135deg, #6C63FF, #FF6584)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>BrokerPlatform</Typography>
                    </Stack>
                    <Button component={Link} href="/search" startIcon={<ArrowBackIcon />} size="small" sx={{ color: "text.secondary" }}>Back to Search</Button>
                </Stack>
            </Box>

            <Container maxWidth="lg" sx={{ py: 4 }}>
                {/* Hero Image */}
                {images.length > 0 && (
                    <Box sx={{ borderRadius: 3, overflow: "hidden", mb: 3, height: { xs: 250, md: 400 }, position: "relative" }}>
                        <Box component="img" src={images[0] + "?w=1200&h=400&fit=crop"} alt={property.name} sx={{ width: "100%", height: "100%", objectFit: "cover" }} />
                        <Box sx={{ position: "absolute", bottom: 0, left: 0, right: 0, p: 3, background: "linear-gradient(transparent, rgba(0,0,0,0.8))" }}>
                            <Typography variant="h3" fontWeight={700}>{property.name}</Typography>
                            <Stack direction="row" alignItems="center" gap={1} mt={1}>
                                <LocationOnIcon sx={{ fontSize: 18, color: "primary.light" }} />
                                <Typography color="text.secondary">{property.city}, {property.country}</Typography>
                                <Chip label={property.type} size="small" sx={{ ml: 1, textTransform: "capitalize", bgcolor: alpha(theme.palette.primary.main, 0.15), color: "primary.main" }} />
                            </Stack>
                        </Box>
                    </Box>
                )}

                <Grid container spacing={3}>
                    {/* Main info */}
                    <Grid size={{ xs: 12, md: 8 }}>
                        <Card sx={{ p: 3, mb: 3 }}>
                            <Typography variant="h5" fontWeight={600} gutterBottom>About this property</Typography>
                            <Typography color="text.secondary" sx={{ lineHeight: 1.8 }}>{property.description}</Typography>
                            <Divider sx={{ my: 2 }} />

                            {/* Oficial Real Data Details */}
                            {(property.address || property.zip_code || property.phone || property.website) && (
                                <Box sx={{ mb: 3, p: 2, bgcolor: alpha(theme.palette.primary.main, 0.05), borderRadius: 2 }}>
                                    <Typography variant="subtitle2" fontWeight={700} color="primary.main" gutterBottom>Official Details</Typography>
                                    <Grid container spacing={2} mt={0.5}>
                                        {property.address && (
                                            <Grid size={{ xs: 12, sm: 6 }}>
                                                <Stack direction="row" gap={1} alignItems="flex-start">
                                                    <SignpostIcon sx={{ fontSize: 18, color: "text.secondary", mt: 0.3 }} />
                                                    <Box>
                                                        <Typography variant="body2" color="text.secondary">Address</Typography>
                                                        <Typography variant="body2" fontWeight={600}>{property.address}</Typography>
                                                    </Box>
                                                </Stack>
                                            </Grid>
                                        )}
                                        {property.zip_code && (
                                            <Grid size={{ xs: 12, sm: 6 }}>
                                                <Stack direction="row" gap={1} alignItems="center">
                                                    <LocationOnIcon sx={{ fontSize: 18, color: "text.secondary" }} />
                                                    <Box>
                                                        <Typography variant="body2" color="text.secondary">Zip Code</Typography>
                                                        <Typography variant="body2" fontWeight={600}>{property.zip_code}</Typography>
                                                    </Box>
                                                </Stack>
                                            </Grid>
                                        )}
                                        {property.phone && (
                                            <Grid size={{ xs: 12, sm: 6 }}>
                                                <Stack direction="row" gap={1} alignItems="center">
                                                    <PhoneIcon sx={{ fontSize: 18, color: "text.secondary" }} />
                                                    <Box>
                                                        <Typography variant="body2" color="text.secondary">Phone</Typography>
                                                        <Typography variant="body2" fontWeight={600}>{property.phone}</Typography>
                                                    </Box>
                                                </Stack>
                                            </Grid>
                                        )}
                                        {property.website && (
                                            <Grid size={{ xs: 12, sm: 6 }}>
                                                <Stack direction="row" gap={1} alignItems="center">
                                                    <LanguageIcon sx={{ fontSize: 18, color: "text.secondary" }} />
                                                    <Box>
                                                        <Typography variant="body2" color="text.secondary">Website</Typography>
                                                        <Typography component="a" href={property.website.startsWith("http") ? property.website : `https://${property.website}`} target="_blank" variant="body2" fontWeight={600} color="primary.main" sx={{ textDecoration: "none", "&:hover": { textDecoration: "underline" } }}>
                                                            {property.website.replace(/^https?:\/\//, '')}
                                                        </Typography>
                                                    </Box>
                                                </Stack>
                                            </Grid>
                                        )}
                                    </Grid>
                                </Box>
                            )}

                            <Stack direction="row" gap={3} flexWrap="wrap">
                                <Stack direction="row" alignItems="center" gap={1}>
                                    <PersonIcon sx={{ color: "primary.main" }} />
                                    <Typography>Max {property.max_guests} guests</Typography>
                                </Stack>
                                {property.external_rating > 0 ? (
                                    <Stack direction="row" alignItems="center" gap={1}>
                                        <StarIcon sx={{ color: "#FFB547" }} />
                                        <Typography>Official Rating: {property.external_rating} / 5</Typography>
                                    </Stack>
                                ) : (
                                    <Stack direction="row" alignItems="center" gap={1}>
                                        <StarIcon sx={{ color: "#FFB547" }} />
                                        <Typography>Provider rating: {property.provider_rating || "N/A"}</Typography>
                                    </Stack>
                                )}
                            </Stack>
                        </Card>

                        {/* Amenities */}
                        {property.amenities?.length > 0 && (
                            <Card sx={{ p: 3, mb: 3 }}>
                                <Typography variant="h6" fontWeight={600} gutterBottom>Amenities</Typography>
                                <Stack direction="row" flexWrap="wrap" gap={1}>
                                    {property.amenities.map((a: any) => (
                                        <Chip key={a.id} icon={<CheckCircleIcon sx={{ fontSize: 16 }} />} label={a.name} variant="outlined" sx={{ borderColor: "rgba(255,255,255,0.1)" }} />
                                    ))}
                                </Stack>
                            </Card>
                        )}

                        {/* Reviews */}
                        {property.reviews?.length > 0 && (
                            <Card sx={{ p: 3 }}>
                                <Typography variant="h6" fontWeight={600} gutterBottom>Guest Reviews</Typography>
                                <Stack gap={2}>
                                    {property.reviews.map((r: any) => (
                                        <Box key={r.id} sx={{ p: 2, borderRadius: 2, bgcolor: alpha(theme.palette.background.default, 0.5), border: "1px solid rgba(255,255,255,0.04)" }}>
                                            <Stack direction="row" justifyContent="space-between" alignItems="center" mb={1}>
                                                <Stack direction="row" alignItems="center" gap={1}>
                                                    <Avatar sx={{ width: 32, height: 32, bgcolor: "primary.main", fontSize: 14 }}>{r.first_name?.[0]}{r.last_name?.[0]}</Avatar>
                                                    <Typography variant="body2" fontWeight={600}>{r.first_name} {r.last_name}</Typography>
                                                </Stack>
                                                <Rating value={r.rating} readOnly size="small" />
                                            </Stack>
                                            {r.title && <Typography variant="subtitle2" gutterBottom>{r.title}</Typography>}
                                            <Typography variant="body2" color="text.secondary">{r.comment}</Typography>
                                            {r.response && (
                                                <Box sx={{ mt: 1.5, pl: 2, borderLeft: "2px solid", borderColor: "primary.main" }}>
                                                    <Typography variant="caption" color="primary.main" fontWeight={600}>Provider response:</Typography>
                                                    <Typography variant="body2" color="text.secondary">{r.response}</Typography>
                                                </Box>
                                            )}
                                        </Box>
                                    ))}
                                </Stack>
                            </Card>
                        )}
                    </Grid>

                    {/* Booking sidebar */}
                    <Grid size={{ xs: 12, md: 4 }}>
                        <Card sx={{ p: 3, position: "sticky", top: 80, bgcolor: alpha(theme.palette.background.paper, 0.9), backdropFilter: "blur(20px)" }}>
                            <Typography variant="h5" fontWeight={700} color="primary.main" gutterBottom>
                                {property.rates?.[0]?.price_per_night
                                    ? `$${property.rates[0].price_per_night}`
                                    : property.rates?.[0]?.price_per_hour
                                        ? `$${property.rates[0].price_per_hour}/hr`
                                        : "Contact for pricing"}
                                {property.rates?.[0]?.price_per_night > 0 && (
                                    <Typography component="span" variant="body2" color="text.secondary" ml={0.5}>/night</Typography>
                                )}
                            </Typography>

                            {property.rates?.length > 1 && (
                                <Box sx={{ mb: 2 }}>
                                    <Typography variant="caption" color="text.secondary" gutterBottom>Other rates:</Typography>
                                    {property.rates.slice(1).map((r: any) => (
                                        <Stack key={r.id} direction="row" justifyContent="space-between" sx={{ py: 0.5 }}>
                                            <Typography variant="body2" sx={{ textTransform: "capitalize" }}>{r.name}</Typography>
                                            <Typography variant="body2" fontWeight={600}>${r.price_per_night || r.price_per_hour}{r.price_per_hour ? "/hr" : ""}</Typography>
                                        </Stack>
                                    ))}
                                </Box>
                            )}

                            <Divider sx={{ my: 2 }} />

                            <Stack gap={1.5}>
                                <Typography variant="body2" color="text.secondary">
                                    <strong>Provider:</strong> {property.provider_name}
                                </Typography>
                                <Typography variant="body2" color="text.secondary">
                                    <strong>Type:</strong> {property.provider_type?.replace("_", " ")}
                                </Typography>
                                {property.provider_email && (
                                    <Typography variant="body2" color="text.secondary">
                                        <strong>Contact:</strong> {property.provider_email}
                                    </Typography>
                                )}
                            </Stack>

                            <Button variant="contained" fullWidth size="large" sx={{ mt: 3, py: 1.5 }}>
                                Book Now
                            </Button>
                            <Typography variant="caption" color="text.secondary" textAlign="center" display="block" mt={1}>
                                Secure booking • Instant confirmation
                            </Typography>
                        </Card>
                    </Grid>
                </Grid>
            </Container>
        </Box>
    );
}
