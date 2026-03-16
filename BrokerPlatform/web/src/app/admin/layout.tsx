"use client";
import { Box, Drawer, List, ListItemButton, ListItemIcon, ListItemText, Typography, Stack, Divider, useTheme, alpha } from "@mui/material";
import DashboardIcon from "@mui/icons-material/Dashboard";
import BusinessIcon from "@mui/icons-material/Business";
import ApartmentIcon from "@mui/icons-material/Apartment";
import BookOnlineIcon from "@mui/icons-material/BookOnline";
import PeopleIcon from "@mui/icons-material/People";
import PaymentIcon from "@mui/icons-material/Payment";
import ReviewsIcon from "@mui/icons-material/Reviews";
import LocalOfferIcon from "@mui/icons-material/LocalOffer";
import SettingsIcon from "@mui/icons-material/Settings";
import ExploreIcon from "@mui/icons-material/Explore";
import LogoutIcon from "@mui/icons-material/Logout";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";

const DRAWER_WIDTH = 260;

const navItems = [
    { label: "Dashboard", href: "/admin", icon: <DashboardIcon /> },
    { label: "Providers", href: "/admin/providers", icon: <BusinessIcon /> },
    { label: "Properties", href: "/admin/properties", icon: <ApartmentIcon /> },
    { label: "Bookings", href: "/admin/bookings", icon: <BookOnlineIcon /> },
    { label: "Customers", href: "/admin/customers", icon: <PeopleIcon /> },
    { label: "Payments", href: "/admin/payments", icon: <PaymentIcon /> },
    { label: "Reviews", href: "/admin/reviews", icon: <ReviewsIcon /> },
    { label: "Promotions", href: "/admin/promotions", icon: <LocalOfferIcon /> },
    { label: "Settings", href: "/admin/settings", icon: <SettingsIcon /> },
];

export default function AdminLayout({ children }: { children: React.ReactNode }) {
    const theme = useTheme();
    const pathname = usePathname();
    const router = useRouter();

    const handleLogout = () => {
        if (typeof window !== "undefined") {
            localStorage.removeItem("broker_token");
            localStorage.removeItem("broker_user");
        }
        router.push("/auth/login");
    };

    return (
        <Box sx={{ display: "flex", minHeight: "100vh", bgcolor: "background.default" }}>
            <Drawer
                variant="permanent"
                sx={{
                    width: DRAWER_WIDTH,
                    flexShrink: 0,
                    "& .MuiDrawer-paper": {
                        width: DRAWER_WIDTH,
                        boxSizing: "border-box",
                        bgcolor: alpha(theme.palette.background.paper, 0.95),
                        borderRight: "1px solid rgba(255,255,255,0.06)",
                        backdropFilter: "blur(20px)",
                    },
                }}
            >
                <Stack alignItems="center" py={3} gap={0.5}>
                    <ExploreIcon sx={{ color: "primary.main", fontSize: 36 }} />
                    <Typography variant="h6" fontWeight={700} sx={{ background: "linear-gradient(135deg, #6C63FF, #FF6584)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>
                        Broker Admin
                    </Typography>
                </Stack>
                <Divider sx={{ borderColor: "rgba(255,255,255,0.06)" }} />
                <List sx={{ px: 1.5, py: 1 }}>
                    {navItems.map((item) => {
                        const active = pathname === item.href || (item.href !== "/admin" && pathname.startsWith(item.href));
                        return (
                            <ListItemButton
                                key={item.href}
                                component={Link}
                                href={item.href}
                                sx={{
                                    borderRadius: 2,
                                    mb: 0.5,
                                    bgcolor: active ? alpha(theme.palette.primary.main, 0.12) : "transparent",
                                    color: active ? "primary.main" : "text.secondary",
                                    "&:hover": { bgcolor: alpha(theme.palette.primary.main, 0.08) },
                                }}
                            >
                                <ListItemIcon sx={{ minWidth: 36, color: "inherit" }}>{item.icon}</ListItemIcon>
                                <ListItemText primary={item.label} primaryTypographyProps={{ fontSize: "0.9rem", fontWeight: active ? 600 : 400 }} />
                            </ListItemButton>
                        );
                    })}
                </List>
                <Box sx={{ flexGrow: 1 }} />
                <Divider sx={{ borderColor: "rgba(255,255,255,0.06)" }} />
                <List sx={{ px: 1.5, pb: 2 }}>
                    <ListItemButton component={Link} href="/" sx={{ borderRadius: 2, color: "text.secondary" }}>
                        <ListItemIcon sx={{ minWidth: 36, color: "inherit" }}><ExploreIcon /></ListItemIcon>
                        <ListItemText primary="Public Site" primaryTypographyProps={{ fontSize: "0.9rem" }} />
                    </ListItemButton>
                    <ListItemButton onClick={handleLogout} sx={{ borderRadius: 2, color: "error.main" }}>
                        <ListItemIcon sx={{ minWidth: 36, color: "inherit" }}><LogoutIcon /></ListItemIcon>
                        <ListItemText primary="Logout" primaryTypographyProps={{ fontSize: "0.9rem" }} />
                    </ListItemButton>
                </List>
            </Drawer>
            <Box component="main" sx={{ flexGrow: 1, p: 3, overflow: "auto" }}>
                {children}
            </Box>
        </Box>
    );
}
