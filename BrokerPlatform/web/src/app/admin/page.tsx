"use client";
import { Box, Card, Typography, Stack, Grid, useTheme, alpha, CircularProgress } from "@mui/material";
import TrendingUpIcon from "@mui/icons-material/TrendingUp";
import BookOnlineIcon from "@mui/icons-material/BookOnline";
import BusinessIcon from "@mui/icons-material/Business";
import PeopleIcon from "@mui/icons-material/People";
import PaymentIcon from "@mui/icons-material/Payment";
import ApartmentIcon from "@mui/icons-material/Apartment";
import { useCrudList } from "@/hooks/useApi";

function StatCard({ title, value, icon, color }: { title: string; value: string | number; icon: React.ReactNode; color: string }) {
    const theme = useTheme();
    return (
        <Card sx={{ p: 3, display: "flex", alignItems: "center", gap: 2, bgcolor: alpha(color, 0.05), border: `1px solid ${alpha(color, 0.15)}`, transition: "all 0.3s", "&:hover": { transform: "translateY(-2px)", boxShadow: `0 8px 24px ${alpha(color, 0.15)}` } }}>
            <Box sx={{ p: 1.5, borderRadius: 2, bgcolor: alpha(color, 0.12), color, display: "flex", "& svg": { fontSize: 28 } }}>{icon}</Box>
            <Box>
                <Typography variant="body2" color="text.secondary">{title}</Typography>
                <Typography variant="h4" fontWeight={700}>{value}</Typography>
            </Box>
        </Card>
    );
}

export default function AdminDashboard() {
    const { data: providers, isLoading: lp } = useCrudList("providers", { limit: "1" });
    const { data: properties, isLoading: lpr } = useCrudList("properties", { limit: "1" });
    const { data: bookings, isLoading: lb } = useCrudList("bookings", { limit: "1" });
    const { data: customers, isLoading: lc } = useCrudList("customers", { limit: "1" });
    const { data: recentBookings } = useCrudList("bookings", { limit: "5" });

    const loading = lp || lpr || lb || lc;

    return (
        <Box>
            <Typography variant="h4" fontWeight={700} mb={3}>Dashboard</Typography>

            {loading ? <CircularProgress /> : (
                <Grid container spacing={3} mb={4}>
                    <Grid size={{ xs: 12, sm: 6, md: 3 }}>
                        <StatCard title="Providers" value={providers?.total ?? 0} icon={<BusinessIcon />} color="#6C63FF" />
                    </Grid>
                    <Grid size={{ xs: 12, sm: 6, md: 3 }}>
                        <StatCard title="Properties" value={properties?.total ?? 0} icon={<ApartmentIcon />} color="#00C9A7" />
                    </Grid>
                    <Grid size={{ xs: 12, sm: 6, md: 3 }}>
                        <StatCard title="Bookings" value={bookings?.total ?? 0} icon={<BookOnlineIcon />} color="#FF6584" />
                    </Grid>
                    <Grid size={{ xs: 12, sm: 6, md: 3 }}>
                        <StatCard title="Customers" value={customers?.total ?? 0} icon={<PeopleIcon />} color="#FFB547" />
                    </Grid>
                </Grid>
            )}

            {/* Recent Bookings */}
            <Card sx={{ p: 3 }}>
                <Typography variant="h6" fontWeight={600} gutterBottom>Recent Bookings</Typography>
                {recentBookings?.rows?.length > 0 ? (
                    <Stack gap={1.5}>
                        {recentBookings.rows.map((b: any) => (
                            <Box key={b.id} sx={{ p: 2, borderRadius: 2, bgcolor: "background.default", border: "1px solid rgba(255,255,255,0.04)", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                                <Box>
                                    <Typography variant="body2" fontWeight={600}>{b.booking_code} – {b.property_name}</Typography>
                                    <Typography variant="caption" color="text.secondary">{b.customer_first} {b.customer_last} • {new Date(b.check_in).toLocaleDateString()} → {new Date(b.check_out).toLocaleDateString()}</Typography>
                                </Box>
                                <Stack direction="row" alignItems="center" gap={2}>
                                    <Typography variant="body2" fontWeight={600} color="primary.main">${b.total_amount}</Typography>
                                    <Box sx={{ px: 1.5, py: 0.3, borderRadius: 1, bgcolor: b.status === "confirmed" ? alpha("#00C9A7", 0.15) : b.status === "cancelled" ? alpha("#FF5252", 0.15) : alpha("#FFB547", 0.15), color: b.status === "confirmed" ? "#00C9A7" : b.status === "cancelled" ? "#FF5252" : "#FFB547" }}>
                                        <Typography variant="caption" fontWeight={600} textTransform="capitalize">{b.status}</Typography>
                                    </Box>
                                </Stack>
                            </Box>
                        ))}
                    </Stack>
                ) : (
                    <Typography variant="body2" color="text.secondary">No bookings yet. Create your first booking via the API or Bookings page.</Typography>
                )}
            </Card>
        </Box>
    );
}
