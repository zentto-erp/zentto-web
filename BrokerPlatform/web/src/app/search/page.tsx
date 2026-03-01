"use client";

import { Suspense, useCallback, useMemo, useState } from "react";
import Link from "next/link";
import dynamic from "next/dynamic";
import { useRouter, useSearchParams } from "next/navigation";
import {
    Alert,
    Box,
    Button,
    Card,
    CardContent,
    CardMedia,
    Chip,
    CircularProgress,
    Divider,
    FormControl,
    InputAdornment,
    InputLabel,
    MenuItem,
    Select,
    Slider,
    Stack,
    TextField,
    ToggleButton,
    ToggleButtonGroup,
    Typography,
    alpha,
    useMediaQuery,
    useTheme,
} from "@mui/material";
import ExploreIcon from "@mui/icons-material/Explore";
import SearchIcon from "@mui/icons-material/Search";
import StarIcon from "@mui/icons-material/Star";
import LocationOnIcon from "@mui/icons-material/LocationOn";
import RoomOutlinedIcon from "@mui/icons-material/RoomOutlined";
import ListAltOutlinedIcon from "@mui/icons-material/ListAltOutlined";
import MapOutlinedIcon from "@mui/icons-material/MapOutlined";
import MyLocationIcon from "@mui/icons-material/MyLocation";
import { useSearch } from "@/hooks/useApi";

const defaultCenter = { lat: 40.7128, lng: -74.006 };
const GeoapifyMap = dynamic(() => import("./GeoapifyMap"), {
    ssr: false,
    loading: () => (
        <Stack alignItems="center" justifyContent="center" sx={{ height: "100%" }}>
            <CircularProgress size={24} />
        </Stack>
    ),
});

type ViewMode = "list" | "map";

function normalizeCoord(value: number) {
    return Number(value.toFixed(4));
}

function SearchPageInner() {
    const theme = useTheme();
    const isDesktop = useMediaQuery(theme.breakpoints.up("md"));
    const router = useRouter();
    const searchParams = useSearchParams();

    const [q, setQ] = useState(searchParams.get("q") || "");
    const [type, setType] = useState(searchParams.get("type") || "");
    const [city, setCity] = useState(searchParams.get("city") || "");
    const [sort, setSort] = useState(searchParams.get("sort") || "rating");
    const [priceRange, setPriceRange] = useState<number[]>([0, 1000]);
    const [radiusKm, setRadiusKm] = useState<number>(Number(searchParams.get("radius_km") || 20));
    const [geoEnabled, setGeoEnabled] = useState(true);
    const [page, setPage] = useState(1);
    const [viewMode, setViewMode] = useState<ViewMode>("list");
    const [mapCenter, setMapCenter] = useState(defaultCenter);
    const [activeMarker, setActiveMarker] = useState<any>(null);
    const [geoError, setGeoError] = useState<string | null>(null);
    const [locating, setLocating] = useState(false);

    const mapsKey = process.env.NEXT_PUBLIC_GEOAPIFY_API_KEY || "";
    const mapsConfigured = mapsKey.length > 0;

    const requestParams = useMemo(() => {
        const p: Record<string, string> = {
            page: String(page),
            limit: "16",
            sort,
        };
        if (q) p.q = q;
        if (type) p.type = type;
        if (city) p.city = city;
        if (priceRange[0] > 0) p.min_price = String(priceRange[0]);
        if (priceRange[1] < 1000) p.max_price = String(priceRange[1]);
        if (geoEnabled) {
            p.lat = String(mapCenter.lat);
            p.lng = String(mapCenter.lng);
            p.radius_km = String(radiusKm);
        }
        return p;
    }, [page, sort, q, type, city, priceRange, geoEnabled, mapCenter, radiusKm]);

    const { data, isLoading, error } = useSearch(requestParams);

    const handleMapCenterChange = useCallback((next: { lat: number; lng: number }) => {
        if (!geoEnabled) return;
        if (next.lat !== mapCenter.lat || next.lng !== mapCenter.lng) {
            setMapCenter(next);
        }
    }, [geoEnabled, mapCenter.lat, mapCenter.lng]);

    const useCurrentLocation = useCallback(() => {
        if (!navigator.geolocation) {
            setGeoError("El navegador no soporta geolocalizacion.");
            return;
        }
        setLocating(true);
        setGeoError(null);

        navigator.geolocation.getCurrentPosition(
            (position) => {
                const next = {
                    lat: normalizeCoord(position.coords.latitude),
                    lng: normalizeCoord(position.coords.longitude),
                };
                setMapCenter(next);
                setGeoEnabled(true);
                setLocating(false);
            },
            () => {
                setGeoError("No se pudo obtener tu ubicacion.");
                setLocating(false);
            },
            { enableHighAccuracy: true, timeout: 10000 }
        );
    }, []);

    const activeRows = data?.rows || [];

    const filtersBlock = (
        <Card
            sx={{
                p: { xs: 2, md: 2.5 },
                mb: 2,
                border: "1px solid rgba(255,255,255,0.08)",
                bgcolor: alpha(theme.palette.background.paper, 0.7),
                backdropFilter: "blur(16px)",
            }}
        >
            <Stack spacing={2}>
                <Stack
                    direction={{ xs: "column", sm: "row" }}
                    spacing={1.25}
                    alignItems={{ xs: "stretch", sm: "center" }}
                >
                    <TextField
                        fullWidth
                        size="small"
                        placeholder="Buscar por propiedad, ciudad o proveedor"
                        value={q}
                        onChange={(e) => {
                            setQ(e.target.value);
                            setPage(1);
                        }}
                        InputProps={{
                            startAdornment: (
                                <InputAdornment position="start">
                                    <SearchIcon sx={{ color: "text.secondary" }} />
                                </InputAdornment>
                            ),
                        }}
                    />

                    <Button
                        variant="outlined"
                        color={geoEnabled ? "primary" : "inherit"}
                        startIcon={<RoomOutlinedIcon />}
                        onClick={() => {
                            setGeoEnabled((prev) => !prev);
                            setPage(1);
                        }}
                    >
                        {geoEnabled ? "Geo ON" : "Geo OFF"}
                    </Button>
                    <Button
                        variant="contained"
                        startIcon={<MyLocationIcon />}
                        disabled={locating}
                        onClick={useCurrentLocation}
                    >
                        {locating ? "Ubicando..." : "Mi ubicacion"}
                    </Button>
                </Stack>

                <Stack direction={{ xs: "column", sm: "row" }} spacing={1.25}>
                    <FormControl size="small" fullWidth>
                        <InputLabel>Tipo</InputLabel>
                        <Select
                            value={type}
                            label="Tipo"
                            onChange={(e) => {
                                setType(e.target.value);
                                setPage(1);
                            }}
                        >
                            <MenuItem value="">Todos</MenuItem>
                            <MenuItem value="room">Hoteles</MenuItem>
                            <MenuItem value="vehicle">Vehiculos</MenuItem>
                            <MenuItem value="boat">Botes</MenuItem>
                            <MenuItem value="flight">Vuelos</MenuItem>
                            <MenuItem value="train">Trenes</MenuItem>
                            <MenuItem value="unit">Tours/Unidades</MenuItem>
                        </Select>
                    </FormControl>

                    <TextField
                        size="small"
                        fullWidth
                        label="Ciudad"
                        value={city}
                        onChange={(e) => {
                            setCity(e.target.value);
                            setPage(1);
                        }}
                    />

                    <FormControl size="small" fullWidth>
                        <InputLabel>Orden</InputLabel>
                        <Select
                            value={sort}
                            label="Orden"
                            onChange={(e) => {
                                setSort(e.target.value);
                                setPage(1);
                            }}
                        >
                            <MenuItem value="rating">Mejor valorados</MenuItem>
                            <MenuItem value="price_asc">Precio ascendente</MenuItem>
                            <MenuItem value="price_desc">Precio descendente</MenuItem>
                            <MenuItem value="newest">Mas recientes</MenuItem>
                            <MenuItem value="distance_asc">Mas cercanos</MenuItem>
                            <MenuItem value="distance_desc">Mas lejanos</MenuItem>
                        </Select>
                    </FormControl>
                </Stack>

                <Divider />

                <Stack direction={{ xs: "column", md: "row" }} spacing={2} alignItems={{ md: "center" }}>
                    <Box sx={{ minWidth: 220, flex: 1 }}>
                        <Typography variant="body2" color="text.secondary" mb={0.75}>
                            Rango de precio (USD)
                        </Typography>
                        <Slider
                            value={priceRange}
                            min={0}
                            max={1000}
                            onChange={(_, next) => {
                                setPriceRange(next as number[]);
                                setPage(1);
                            }}
                            valueLabelDisplay="auto"
                        />
                    </Box>

                    <Box sx={{ minWidth: 220, flex: 1 }}>
                        <Typography variant="body2" color="text.secondary" mb={0.75}>
                            Radio de busqueda: {radiusKm} km
                        </Typography>
                        <Slider
                            disabled={!geoEnabled}
                            value={radiusKm}
                            min={1}
                            max={200}
                            onChange={(_, next) => {
                                setRadiusKm(next as number);
                                setPage(1);
                            }}
                            valueLabelDisplay="auto"
                        />
                    </Box>
                </Stack>

                {geoError && <Alert severity="warning">{geoError}</Alert>}
                {!mapsConfigured && (
                    <Alert severity="info">
                        Define <code>NEXT_PUBLIC_GEOAPIFY_API_KEY</code> en <code>web/.env.local</code> para
                        habilitar mapa interactivo.
                    </Alert>
                )}
                {error && <Alert severity="error">{String((error as Error).message || error)}</Alert>}
            </Stack>
        </Card>
    );

    const listBlock = (
        <Box>
            <Stack
                direction={{ xs: "column", sm: "row" }}
                justifyContent="space-between"
                alignItems={{ xs: "flex-start", sm: "center" }}
                spacing={1}
                mb={2}
            >
                <Typography variant="h6" fontWeight={700}>
                    {isLoading ? "Buscando propiedades..." : `${data?.total ?? 0} resultados`}
                </Typography>
                {data?.geo?.enabled && data?.geo?.radiusKm && (
                    <Chip label={`Radio: ${data.geo.radiusKm} km`} color="primary" size="small" />
                )}
            </Stack>

            {isLoading && (
                <Box sx={{ py: 8, textAlign: "center" }}>
                    <CircularProgress />
                </Box>
            )}

            <Box
                sx={{
                    display: "grid",
                    gridTemplateColumns: { xs: "1fr", sm: "repeat(2, minmax(0, 1fr))" },
                    gap: 2,
                }}
            >
                {activeRows.map((item: any) => (
                    <Card
                        key={item.id}
                        onMouseEnter={() => setActiveMarker(item)}
                        onClick={() => router.push(`/property/${item.id}`)}
                        sx={{
                            cursor: "pointer",
                            height: "100%",
                            display: "flex",
                            flexDirection: "column",
                            border: "1px solid rgba(255,255,255,0.08)",
                            transition: "all 0.25s ease",
                            "&:hover": {
                                transform: "translateY(-4px)",
                                boxShadow: "0 10px 32px rgba(108,99,255,0.18)",
                                borderColor: alpha(theme.palette.primary.main, 0.45),
                            },
                        }}
                    >
                        <CardMedia
                            component="img"
                            height={165}
                            image={
                                item.images
                                    ? JSON.parse(item.images)[0] + "?w=560&h=165&fit=crop"
                                    : "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=560&h=165&fit=crop"
                            }
                            alt={item.name}
                            sx={{ objectFit: "cover" }}
                        />
                        <CardContent sx={{ flex: 1, display: "flex", flexDirection: "column", p: 2 }}>
                            <Stack direction="row" justifyContent="space-between" alignItems="center" mb={1}>
                                <Chip
                                    label={String(item.provider_type || "hotel").replace("_", " ")}
                                    size="small"
                                    sx={{
                                        textTransform: "capitalize",
                                        bgcolor: alpha(theme.palette.primary.main, 0.1),
                                        color: "primary.main",
                                        fontWeight: 700,
                                    }}
                                />
                                <Stack direction="row" alignItems="center" spacing={0.4}>
                                    <StarIcon sx={{ color: "#FFB547", fontSize: 16 }} />
                                    <Typography variant="caption" fontWeight={700}>
                                        {item.provider_rating || 0}
                                    </Typography>
                                </Stack>
                            </Stack>

                            <Typography variant="subtitle1" fontWeight={700} lineHeight={1.2} mb={0.6}>
                                {item.name}
                            </Typography>

                            <Stack direction="row" alignItems="center" spacing={0.4} mb={0.5}>
                                <LocationOnIcon sx={{ color: "text.secondary", fontSize: 14 }} />
                                <Typography variant="caption" color="text.secondary">
                                    {item.city || "Sin ciudad"}
                                </Typography>
                            </Stack>

                            {item.distance_km !== null && item.distance_km !== undefined && (
                                <Typography variant="caption" color="text.secondary">
                                    Distancia: {Number(item.distance_km).toFixed(1)} km
                                </Typography>
                            )}

                            <Box mt="auto" pt={1}>
                                <Typography variant="h6" color="primary.main" fontWeight={800}>
                                    {item.base_price ? `$${item.base_price}` : "Contact"}
                                    <Typography component="span" variant="caption" color="text.secondary" ml={0.5}>
                                        /{" "}
                                        {item.type === "room"
                                            ? "night"
                                            : item.type === "vehicle"
                                              ? "day"
                                              : item.type === "flight"
                                                ? "trip"
                                                : item.type === "train"
                                                  ? "ticket"
                                                  : "unit"}
                                    </Typography>
                                </Typography>
                            </Box>
                        </CardContent>
                    </Card>
                ))}
            </Box>

            {data && data.total > 16 && (
                <Stack direction="row" justifyContent="center" spacing={1} mt={3}>
                    <Button
                        variant="outlined"
                        disabled={page <= 1}
                        onClick={() => setPage((prev) => Math.max(prev - 1, 1))}
                    >
                        Previous
                    </Button>
                    <Button
                        variant="outlined"
                        disabled={page * 16 >= data.total}
                        onClick={() => setPage((prev) => prev + 1)}
                    >
                        Next
                    </Button>
                </Stack>
            )}
        </Box>
    );

    const mapBlock = (
        <Box
            sx={{
                borderRadius: 3,
                overflow: "hidden",
                border: "1px solid rgba(255,255,255,0.1)",
                height: { xs: "60vh", md: "calc(100vh - 250px)" },
                minHeight: { md: 500 },
                bgcolor: "rgba(255,255,255,0.02)",
            }}
        >
            {mapsConfigured ? (
                <GeoapifyMap
                    apiKey={mapsKey}
                    center={mapCenter}
                    rows={activeRows}
                    radiusKm={radiusKm}
                    geoEnabled={geoEnabled}
                    activeMarker={activeMarker}
                    onActiveMarker={setActiveMarker}
                    onCenterChange={handleMapCenterChange}
                    onOpenProperty={(id) => router.push(`/property/${id}`)}
                />
            ) : (
                <Stack
                    alignItems="center"
                    justifyContent="center"
                    spacing={1.2}
                    sx={{ height: "100%", p: 2, textAlign: "center" }}
                >
                    {mapsConfigured ? <CircularProgress size={24} /> : <MapOutlinedIcon color="disabled" />}
                    <Typography variant="body2" color="text.secondary">
                        {mapsConfigured
                            ? "Cargando mapa..."
                            : "Mapa no configurado. Define NEXT_PUBLIC_GEOAPIFY_API_KEY."}
                    </Typography>
                </Stack>
            )}
        </Box>
    );

    return (
        <Box sx={{ minHeight: "100vh", bgcolor: "background.default" }}>
            <Box
                sx={{
                    position: "sticky",
                    top: 0,
                    zIndex: 100,
                    borderBottom: "1px solid rgba(255,255,255,0.08)",
                    backdropFilter: "blur(14px)",
                    bgcolor: alpha(theme.palette.background.default, 0.88),
                    px: { xs: 1.5, md: 2.5 },
                    py: 1.25,
                }}
            >
                <Stack direction="row" alignItems="center" justifyContent="space-between" spacing={1}>
                    <Stack
                        direction="row"
                        component={Link}
                        href="/"
                        alignItems="center"
                        spacing={0.8}
                        sx={{ textDecoration: "none" }}
                    >
                        <ExploreIcon sx={{ color: "primary.main", fontSize: 28 }} />
                        <Typography
                            variant="h6"
                            fontWeight={700}
                            sx={{
                                background: "linear-gradient(135deg, #6C63FF, #FF6584)",
                                WebkitBackgroundClip: "text",
                                WebkitTextFillColor: "transparent",
                            }}
                        >
                            BrokerPlatform
                        </Typography>
                    </Stack>
                    <Button variant="outlined" component={Link} href="/admin" size="small">
                        Admin
                    </Button>
                </Stack>
            </Box>

            <Box sx={{ maxWidth: 1480, mx: "auto", p: { xs: 1.5, md: 2.5 } }}>
                {filtersBlock}

                {!isDesktop && (
                    <ToggleButtonGroup
                        color="primary"
                        exclusive
                        value={viewMode}
                        onChange={(_, val) => val && setViewMode(val)}
                        sx={{ mb: 2 }}
                    >
                        <ToggleButton value="list">
                            <ListAltOutlinedIcon sx={{ mr: 0.6 }} />
                            Lista
                        </ToggleButton>
                        <ToggleButton value="map">
                            <MapOutlinedIcon sx={{ mr: 0.6 }} />
                            Mapa
                        </ToggleButton>
                    </ToggleButtonGroup>
                )}

                {isDesktop ? (
                    <Box
                        sx={{
                            display: "grid",
                            gridTemplateColumns: "minmax(0, 7fr) minmax(0, 5fr)",
                            gap: 2,
                        }}
                    >
                        <Box>{listBlock}</Box>
                        <Box>{mapBlock}</Box>
                    </Box>
                ) : viewMode === "list" ? (
                    listBlock
                ) : (
                    mapBlock
                )}
            </Box>
        </Box>
    );
}

export default function SearchPage() {
    return (
        <Suspense
            fallback={
                <Box sx={{ minHeight: "50vh", display: "flex", justifyContent: "center", alignItems: "center" }}>
                    <CircularProgress />
                </Box>
            }
        >
            <SearchPageInner />
        </Suspense>
    );
}
