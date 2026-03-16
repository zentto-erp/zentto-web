"use client";
import { Box, Container, Card, Typography, TextField, Button, Stack, Alert, useTheme, alpha } from "@mui/material";
import ExploreIcon from "@mui/icons-material/Explore";
import Link from "next/link";
import { useState } from "react";
import { useLogin } from "@/hooks/useApi";
import { useRouter } from "next/navigation";

export default function LoginPage() {
    const theme = useTheme();
    const router = useRouter();
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const login = useLogin();

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        login.mutate({ email, password }, {
            onSuccess: () => router.push("/admin"),
        });
    };

    return (
        <Box sx={{ minHeight: "100vh", bgcolor: "background.default", display: "flex", alignItems: "center", justifyContent: "center", position: "relative", overflow: "hidden" }}>
            <Box sx={{ position: "absolute", top: -150, right: -150, width: 500, height: 500, borderRadius: "50%", background: "radial-gradient(circle, rgba(108,99,255,0.1) 0%, transparent 70%)" }} />
            <Box sx={{ position: "absolute", bottom: -150, left: -150, width: 400, height: 400, borderRadius: "50%", background: "radial-gradient(circle, rgba(255,101,132,0.08) 0%, transparent 70%)" }} />
            <Container maxWidth="xs" sx={{ position: "relative", zIndex: 1 }}>
                <Stack alignItems="center" mb={4}>
                    <ExploreIcon sx={{ color: "primary.main", fontSize: 48, mb: 1 }} />
                    <Typography variant="h4" fontWeight={700} sx={{ background: "linear-gradient(135deg, #6C63FF, #FF6584)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>BrokerPlatform</Typography>
                </Stack>
                <Card sx={{ p: 4, bgcolor: alpha(theme.palette.background.paper, 0.8), backdropFilter: "blur(24px)" }}>
                    <Typography variant="h5" fontWeight={600} gutterBottom textAlign="center">Welcome Back</Typography>
                    <Typography variant="body2" color="text.secondary" textAlign="center" mb={3}>Log in to manage your bookings</Typography>
                    {login.isError && <Alert severity="error" sx={{ mb: 2 }}>{login.error.message}</Alert>}
                    <form onSubmit={handleSubmit}>
                        <Stack gap={2}>
                            <TextField label="Email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} required fullWidth />
                            <TextField label="Password" type="password" value={password} onChange={(e) => setPassword(e.target.value)} required fullWidth />
                            <Button type="submit" variant="contained" fullWidth size="large" disabled={login.isPending} sx={{ mt: 1 }}>
                                {login.isPending ? "Logging in..." : "Log In"}
                            </Button>
                        </Stack>
                    </form>
                    <Typography variant="body2" color="text.secondary" textAlign="center" mt={2}>
                        Don't have an account?{" "}
                        <Typography component={Link} href="/auth/register" variant="body2" color="primary.main" sx={{ textDecoration: "none", fontWeight: 600 }}>Sign Up</Typography>
                    </Typography>
                </Card>
                <Typography variant="body2" color="text.secondary" textAlign="center" mt={3}>
                    <Typography component={Link} href="/" variant="body2" color="text.secondary" sx={{ textDecoration: "none", "&:hover": { color: "primary.main" } }}>← Back to Home</Typography>
                </Typography>
            </Container>
        </Box>
    );
}
