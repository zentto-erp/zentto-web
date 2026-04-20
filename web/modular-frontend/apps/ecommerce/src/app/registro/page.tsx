'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Box, Typography, TextField, Button, Paper, Alert, Link as MuiLink } from '@mui/material';
import EmailOutlined from '@mui/icons-material/EmailOutlined';
import { FormGrid, FormField } from '@zentto/shared-ui';
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
                    <EmailOutlined
                        aria-hidden="true"
                        sx={{ fontSize: 56, color: '#ff9900', mb: 2, display: 'block', mx: 'auto' }}
                    />
                    <Typography variant="h5" fontWeight={700} gutterBottom>
                        Revisa tu correo
                    </Typography>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                        Enviamos un enlace de confirmacion a:
                    </Typography>
                    <Typography variant="body1" fontWeight={600} component="strong" sx={{ mb: 2, display: 'block' }}>
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
                    <FormGrid spacing={2}>
                        <FormField xs={12} sm={12} md={12}>
                            <TextField fullWidth label="Nombre completo" required value={name} onChange={(e) => setName(e.target.value)} />
                        </FormField>
                        <FormField xs={12} sm={12} md={12}>
                            <TextField fullWidth label="Email" type="email" required value={email} onChange={(e) => setEmail(e.target.value)} />
                        </FormField>
                        <FormField xs={12} sm={12} md={12}>
                            <TextField fullWidth label="Telefono (opcional)" value={phone} onChange={(e) => setPhone(e.target.value)} />
                        </FormField>
                        <FormField xs={12} sm={6} md={6}>
                            <TextField fullWidth label="Contraseña" type="password" required value={password} onChange={(e) => setPassword(e.target.value)} />
                        </FormField>
                        <FormField xs={12} sm={6} md={6}>
                            <TextField fullWidth label="Confirmar contraseña" type="password" required value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} />
                        </FormField>
                    </FormGrid>
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
