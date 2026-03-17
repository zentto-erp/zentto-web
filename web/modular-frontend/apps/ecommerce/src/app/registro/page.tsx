'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Box, Typography, TextField, Button, Paper, Alert, Link as MuiLink, Grid } from '@mui/material';
import { useCustomerRegister } from '@zentto/module-ecommerce';

export default function RegistroPage() {
    const router = useRouter();
    const registerMutation = useCustomerRegister();

    const [name, setName] = useState('');
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    const [phone, setPhone] = useState('');
    const [error, setError] = useState('');
    const [success, setSuccess] = useState(false);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');

        if (password !== confirmPassword) {
            setError('Las contraseñas no coinciden');
            return;
        }
        if (password.length < 6) {
            setError('La contraseña debe tener al menos 6 caracteres');
            return;
        }

        try {
            await registerMutation.mutateAsync({
                name: name.trim(),
                email: email.trim(),
                password,
                phone: phone.trim() || undefined,
            });
            setSuccess(true);
        } catch (err: any) {
            setError(err.message || 'Error al registrarse');
        }
    };

    if (success) {
        return (
            <Box sx={{ maxWidth: 480, mx: 'auto', py: 6 }}>
                <Paper sx={{ p: 5, textAlign: 'center' }}>
                    <Typography sx={{ fontSize: 56, lineHeight: 1, mb: 2 }}>&#9993;</Typography>
                    <Typography variant="h5" fontWeight={700} gutterBottom>
                        Revisa tu correo
                    </Typography>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                        Enviamos un enlace de confirmacion a:
                    </Typography>
                    <Typography variant="body1" fontWeight={600} sx={{ mb: 2 }}>
                        {email}
                    </Typography>
                    <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mb: 3, maxWidth: 340, mx: 'auto' }}>
                        Haz clic en el enlace del email para activar tu cuenta.
                        Si no lo ves, revisa la carpeta de spam o correo no deseado.
                    </Typography>
                    <Button variant="contained" size="large" sx={{ px: 5, mb: 2 }} onClick={() => router.push('/login')}>
                        Ir al login
                    </Button>
                    <Typography variant="caption" display="block" color="text.secondary">
                        No recibiste el email?{' '}
                        <MuiLink component="span" sx={{ cursor: 'pointer', fontSize: 'inherit' }} onClick={() => setSuccess(false)}>
                            Intentar de nuevo
                        </MuiLink>
                    </Typography>
                </Paper>
            </Box>
        );
    }

    return (
        <Box sx={{ maxWidth: 500, mx: 'auto', py: 4 }}>
            <Paper sx={{ p: 4 }}>
                <Typography variant="h5" gutterBottom textAlign="center">
                    Crear cuenta
                </Typography>

                {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

                <form onSubmit={handleSubmit}>
                    <Grid container spacing={2}>
                        <Grid xs={12}>
                            <TextField label="Nombre completo" fullWidth required value={name} onChange={(e) => setName(e.target.value)} />
                        </Grid>
                        <Grid xs={12}>
                            <TextField label="Email" type="email" fullWidth required value={email} onChange={(e) => setEmail(e.target.value)} />
                        </Grid>
                        <Grid xs={12}>
                            <TextField label="Telefono (opcional)" fullWidth value={phone} onChange={(e) => setPhone(e.target.value)} />
                        </Grid>
                        <Grid xs={12} sm={6}>
                            <TextField label="Contraseña" type="password" fullWidth required value={password} onChange={(e) => setPassword(e.target.value)} />
                        </Grid>
                        <Grid xs={12} sm={6}>
                            <TextField label="Confirmar contraseña" type="password" fullWidth required value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} />
                        </Grid>
                    </Grid>
                    <Button type="submit" variant="contained" fullWidth size="large" disabled={registerMutation.isPending} sx={{ mt: 3 }}>
                        {registerMutation.isPending ? 'Registrando...' : 'Crear cuenta'}
                    </Button>
                </form>

                <Typography variant="body2" textAlign="center" sx={{ mt: 2 }}>
                    Ya tienes cuenta?{' '}
                    <MuiLink component="span" sx={{ cursor: 'pointer' }} onClick={() => router.push('/login')}>
                        Inicia sesion
                    </MuiLink>
                </Typography>
            </Paper>
        </Box>
    );
}
