'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Box, Typography, TextField, Button, Paper, Alert, Link as MuiLink, MenuItem } from '@mui/material';
import { useShippingRegister } from '@zentto/module-shipping';

export default function RegistroPage() {
    const router = useRouter();
    const registerMutation = useShippingRegister();
    const [displayName, setDisplayName] = useState('');
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    const [phone, setPhone] = useState('');
    const [companyName, setCompanyName] = useState('');
    const [countryCode, setCountryCode] = useState('VE');
    const [error, setError] = useState('');
    const [success, setSuccess] = useState(false);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        if (password !== confirmPassword) { setError('Las contraseñas no coinciden'); return; }
        if (password.length < 6) { setError('Mínimo 6 caracteres'); return; }

        try {
            await registerMutation.mutateAsync({
                email: email.trim(), password, displayName: displayName.trim(),
                phone: phone.trim() || undefined, companyName: companyName.trim() || undefined, countryCode,
            });
            setSuccess(true);
        } catch (err: any) {
            setError(err.message || 'Error al registrarse');
        }
    };

    if (success) {
        return (
            <Box sx={{ maxWidth: 480, mx: 'auto', py: 6 }}>
                <Paper sx={{ p: 5, textAlign: 'center', borderRadius: 2 }}>
                    <Typography sx={{ fontSize: 56, lineHeight: 1, mb: 2 }}>&#128230;</Typography>
                    <Typography variant="h5" fontWeight={700} gutterBottom>Cuenta creada</Typography>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
                        Tu cuenta ha sido creada exitosamente. Ahora puedes iniciar sesión y comenzar a enviar paquetes.
                    </Typography>
                    <Button variant="contained" size="large" onClick={() => router.push('/login')} sx={{ bgcolor: '#1565c0' }}>
                        Iniciar sesión
                    </Button>
                </Paper>
            </Box>
        );
    }

    return (
        <Box sx={{ maxWidth: 550, mx: 'auto', py: 4 }}>
            <Paper sx={{ p: 4, borderRadius: 2 }}>
                <Typography variant="h5" fontWeight={700} gutterBottom textAlign="center">Crear cuenta</Typography>
                <Typography variant="body2" color="text.secondary" textAlign="center" sx={{ mb: 3 }}>
                    Regístrate para enviar y rastrear tus paquetes
                </Typography>

                {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

                <form onSubmit={handleSubmit}>
                    <TextField label="Nombre completo" required fullWidth value={displayName} onChange={(e) => setDisplayName(e.target.value)} sx={{ mb: 2 }} />
                    <TextField label="Email" type="email" required fullWidth value={email} onChange={(e) => setEmail(e.target.value)} sx={{ mb: 2 }} />
                    <TextField label="Nombre de empresa (opcional)" fullWidth value={companyName} onChange={(e) => setCompanyName(e.target.value)} sx={{ mb: 2 }} />
                    <Box sx={{ display: 'flex', gap: 2, mb: 2 }}>
                        <TextField label="Teléfono" fullWidth value={phone} onChange={(e) => setPhone(e.target.value)} />
                        <TextField label="País" select fullWidth value={countryCode} onChange={(e) => setCountryCode(e.target.value)} sx={{ maxWidth: 120 }}>
                            {['VE','CO','ES','MX','US','PA','DO','EC','CL','PT'].map((c) => <MenuItem key={c} value={c}>{c}</MenuItem>)}
                        </TextField>
                    </Box>
                    <Box sx={{ display: 'flex', gap: 2, mb: 3 }}>
                        <TextField label="Contraseña" type="password" required fullWidth value={password} onChange={(e) => setPassword(e.target.value)} />
                        <TextField label="Confirmar" type="password" required fullWidth value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} />
                    </Box>
                    <Button type="submit" variant="contained" fullWidth size="large" disabled={registerMutation.isPending}
                        sx={{ bgcolor: '#1565c0' }}>
                        {registerMutation.isPending ? 'Registrando...' : 'Crear cuenta'}
                    </Button>
                </form>

                <Typography variant="body2" textAlign="center" sx={{ mt: 2 }}>
                    ¿Ya tienes cuenta?{' '}
                    <MuiLink component="span" sx={{ cursor: 'pointer' }} onClick={() => router.push('/login')}>Inicia sesión</MuiLink>
                </Typography>
            </Paper>
        </Box>
    );
}
