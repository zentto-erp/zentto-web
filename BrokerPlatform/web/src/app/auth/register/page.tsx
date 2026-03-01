"use client";
import { Box, Container, Card, Typography, TextField, Button, Stack, Alert, useTheme, alpha } from "@mui/material";
import ExploreIcon from "@mui/icons-material/Explore";
import Link from "next/link";
import { useState } from "react";
import { useRegister } from "@/hooks/useApi";
import { useRouter } from "next/navigation";

export default function RegisterPage() {
    const theme = useTheme();
    const router = useRouter();
    const [form, setForm] = useState({ email: "", password: "", first_name: "", last_name: "" });
    const register = useRegister();

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        register.mutate(form, { onSuccess: () => router.push("/auth/login") });
    };

    return (
        <Box sx={{ minHeight: "100vh", bgcolor: "background.default", display: "flex", alignItems: "center", justifyContent: "center", position: "relative", overflow: "hidden" }}>
            <Box sx={{ position: "absolute", top: -150, left: -150, width: 500, height: 500, borderRadius: "50%", background: "radial-gradient(circle, rgba(0,201,167,0.08) 0%, transparent 70%)" }} />
            <Container maxWidth="xs" sx={{ position: "relative", zIndex: 1 }}>
                <Stack alignItems="center" mb={4}>
                    <ExploreIcon sx={{ color: "primary.main", fontSize: 48, mb: 1 }} />
                    <Typography variant="h4" fontWeight={700} sx={{ background: "linear-gradient(135deg, #6C63FF, #FF6584)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>BrokerPlatform</Typography>
                </Stack>
                <Card sx={{ p: 4, bgcolor: alpha(theme.palette.background.paper, 0.8), backdropFilter: "blur(24px)" }}>
                    <Typography variant="h5" fontWeight={600} gutterBottom textAlign="center">Create Account</Typography>
                    <Typography variant="body2" color="text.secondary" textAlign="center" mb={3}>Join and start booking</Typography>
                    {register.isError && <Alert severity="error" sx={{ mb: 2 }}>{register.error.message}</Alert>}
                    {register.isSuccess && <Alert severity="success" sx={{ mb: 2 }}>Account created! Redirecting to login...</Alert>}
                    <form onSubmit={handleSubmit}>
                        <Stack gap={2}>
                            <Stack direction="row" gap={2}>
                                <TextField label="First Name" value={form.first_name} onChange={(e) => setForm({ ...form, first_name: e.target.value })} required fullWidth />
                                <TextField label="Last Name" value={form.last_name} onChange={(e) => setForm({ ...form, last_name: e.target.value })} required fullWidth />
                            </Stack>
                            <TextField label="Email" type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} required fullWidth />
                            <TextField label="Password" type="password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} required fullWidth helperText="Minimum 6 characters" />
                            <Button type="submit" variant="contained" fullWidth size="large" disabled={register.isPending} sx={{ mt: 1 }}>
                                {register.isPending ? "Creating..." : "Sign Up"}
                            </Button>
                        </Stack>
                    </form>
                    <Typography variant="body2" color="text.secondary" textAlign="center" mt={2}>
                        Already have an account?{" "}
                        <Typography component={Link} href="/auth/login" variant="body2" color="primary.main" sx={{ textDecoration: "none", fontWeight: 600 }}>Log In</Typography>
                    </Typography>
                </Card>
            </Container>
        </Box>
    );
}
