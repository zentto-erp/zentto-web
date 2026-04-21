'use client';

/**
 * /admin/login — Login exclusivo para administradores del ecommerce.
 * Usa zentto-auth (no el login de clientes del store).
 * Separado del /login público para no mezclar flujos.
 */

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import {
    Box, Typography, TextField, Button, Paper, Alert,
    InputAdornment, IconButton, CircularProgress,
} from '@mui/material';
import LockOutlinedIcon from '@mui/icons-material/LockOutlined';
import PersonOutlineIcon from '@mui/icons-material/PersonOutline';
import VisibilityIcon from '@mui/icons-material/Visibility';
import VisibilityOffIcon from '@mui/icons-material/VisibilityOff';
import StoreIcon from '@mui/icons-material/Store';
import { useAdminLogin } from '@zentto/module-ecommerce';

export default function AdminLoginPage() {
    const router = useRouter();
    const loginMutation = useAdminLogin();

    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [showPassword, setShowPassword] = useState(false);
    const [error, setError] = useState('');

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        try {
            await loginMutation.mutateAsync({ username: username.trim(), password });
            router.replace('/admin/dashboard');
        } catch (err: any) {
            const msg = err.message || '';
            if (msg === 'not_admin') {
                setError('Esta cuenta no tiene permisos de administrador.');
            } else {
                setError(msg || 'Usuario o contraseña incorrectos.');
            }
        }
    };

    return (
        <Box
            sx={{
                minHeight: '100vh',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                bgcolor: '#131921',
                px: 2,
            }}
        >
            <Paper
                elevation={4}
                sx={{ p: 4, width: '100%', maxWidth: 400, borderRadius: 2 }}
            >
                {/* Header */}
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 3 }}>
                    <StoreIcon sx={{ color: '#ff9900', fontSize: 32 }} />
                    <Box>
                        <Typography variant="h6" fontWeight={700} lineHeight={1.1}>
                            Zentto<span style={{ color: '#ff9900' }}>Store</span>
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                            Panel de administración
                        </Typography>
                    </Box>
                </Box>

                <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
                    Acceso exclusivo para administradores de la plataforma.
                </Typography>

                {error && (
                    <Alert severity="error" sx={{ mb: 2 }}>
                        {error}
                    </Alert>
                )}

                <form onSubmit={handleSubmit}>
                    <TextField
                        label="Usuario"
                        fullWidth
                        required
                        autoFocus
                        value={username}
                        onChange={(e) => setUsername(e.target.value)}
                        sx={{ mb: 2 }}
                        InputProps={{
                            startAdornment: (
                                <InputAdornment position="start">
                                    <PersonOutlineIcon fontSize="small" />
                                </InputAdornment>
                            ),
                        }}
                    />
                    <TextField
                        label="Contraseña"
                        type={showPassword ? 'text' : 'password'}
                        fullWidth
                        required
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        sx={{ mb: 3 }}
                        InputProps={{
                            startAdornment: (
                                <InputAdornment position="start">
                                    <LockOutlinedIcon fontSize="small" />
                                </InputAdornment>
                            ),
                            endAdornment: (
                                <InputAdornment position="end">
                                    <IconButton
                                        size="small"
                                        onClick={() => setShowPassword((v) => !v)}
                                        edge="end"
                                    >
                                        {showPassword ? <VisibilityOffIcon fontSize="small" /> : <VisibilityIcon fontSize="small" />}
                                    </IconButton>
                                </InputAdornment>
                            ),
                        }}
                    />
                    <Button
                        type="submit"
                        variant="contained"
                        fullWidth
                        size="large"
                        disabled={loginMutation.isPending}
                        sx={{
                            bgcolor: '#ff9900',
                            color: '#0f1111',
                            fontWeight: 700,
                            '&:hover': { bgcolor: '#e8890a' },
                            '&:disabled': { bgcolor: '#f3d082' },
                        }}
                    >
                        {loginMutation.isPending
                            ? <CircularProgress size={20} sx={{ color: '#0f1111' }} />
                            : 'Ingresar al panel'}
                    </Button>
                </form>

                <Typography
                    variant="caption"
                    color="text.secondary"
                    sx={{ display: 'block', textAlign: 'center', mt: 3 }}
                >
                    ¿Eres cliente?{' '}
                    <Box
                        component="span"
                        sx={{ color: '#ff9900', cursor: 'pointer', '&:hover': { textDecoration: 'underline' } }}
                        onClick={() => router.push('/login')}
                    >
                        Inicia sesión aquí
                    </Box>
                </Typography>
            </Paper>
        </Box>
    );
}
