'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Box, Typography, TextField, Button, Paper, Alert, Link as MuiLink } from '@mui/material';
import { useCustomerLogin } from '@datqbox/module-ecommerce';

export default function LoginPage() {
    const router = useRouter();
    const loginMutation = useCustomerLogin();

    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        try {
            await loginMutation.mutateAsync({ email: email.trim(), password });
            router.push('/pedidos');
        } catch (err: any) {
            setError(err.message || 'Error al iniciar sesion');
        }
    };

    return (
        <Box sx={{ maxWidth: 400, mx: 'auto', py: 4 }}>
            <Paper sx={{ p: 4 }}>
                <Typography variant="h5" gutterBottom textAlign="center">
                    Iniciar sesion
                </Typography>

                {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

                <form onSubmit={handleSubmit}>
                    <TextField
                        label="Email"
                        type="email"
                        fullWidth
                        required
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                        sx={{ mb: 2 }}
                    />
                    <TextField
                        label="Contraseña"
                        type="password"
                        fullWidth
                        required
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        sx={{ mb: 3 }}
                    />
                    <Button
                        type="submit"
                        variant="contained"
                        fullWidth
                        size="large"
                        disabled={loginMutation.isPending}
                    >
                        {loginMutation.isPending ? 'Ingresando...' : 'Ingresar'}
                    </Button>
                </form>

                <Typography variant="body2" textAlign="center" sx={{ mt: 2 }}>
                    No tienes cuenta?{' '}
                    <MuiLink component="span" sx={{ cursor: 'pointer' }} onClick={() => router.push('/registro')}>
                        Registrate
                    </MuiLink>
                </Typography>
            </Paper>
        </Box>
    );
}
