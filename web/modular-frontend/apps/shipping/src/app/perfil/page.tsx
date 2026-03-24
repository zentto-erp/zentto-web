'use client';

import { useState } from 'react';
import { Box, Typography, Paper, Button, TextField, Grid2 as Grid, Alert, Dialog, DialogTitle, DialogContent, DialogActions, MenuItem, Chip, IconButton } from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import EditIcon from '@mui/icons-material/Edit';
import StarIcon from '@mui/icons-material/Star';
import { useShippingProfile, useShippingAddresses, useUpsertAddress, useShippingStore } from '@zentto/module-shipping';

export default function PerfilPage() {
    const { data: profile } = useShippingProfile();
    const { data: addresses, isLoading } = useShippingAddresses();
    const upsertMutation = useUpsertAddress();
    const customerInfo = useShippingStore((s) => s.customerInfo);

    const [dialogOpen, setDialogOpen] = useState(false);
    const [editAddress, setEditAddress] = useState<any>(null);
    const [form, setForm] = useState({
        label: 'Principal', contactName: '', phone: '', addressLine1: '', addressLine2: '',
        city: '', state: '', postalCode: '', countryCode: 'VE', isDefault: false,
    });

    const openNew = () => {
        setEditAddress(null);
        setForm({ label: 'Principal', contactName: customerInfo?.name || '', phone: '', addressLine1: '', addressLine2: '', city: '', state: '', postalCode: '', countryCode: 'VE', isDefault: false });
        setDialogOpen(true);
    };

    const openEdit = (addr: any) => {
        setEditAddress(addr);
        setForm({
            label: addr.Label || '', contactName: addr.ContactName || '', phone: addr.Phone || '',
            addressLine1: addr.AddressLine1 || '', addressLine2: addr.AddressLine2 || '',
            city: addr.City || '', state: addr.State || '', postalCode: addr.PostalCode || '',
            countryCode: addr.CountryCode || 'VE', isDefault: addr.IsDefault || false,
        });
        setDialogOpen(true);
    };

    const handleSave = async () => {
        await upsertMutation.mutateAsync({
            shippingAddressId: editAddress?.ShippingAddressId || undefined,
            ...form,
        });
        setDialogOpen(false);
    };

    return (
        <Box>
            <Typography variant="h5" fontWeight={700} sx={{ mb: 3 }}>Mi Perfil</Typography>

            {/* Profile Info */}
            <Paper sx={{ p: 3, mb: 3, borderRadius: 2 }}>
                <Typography variant="subtitle1" fontWeight={700} sx={{ mb: 2 }}>Información Personal</Typography>
                <Grid container spacing={2}>
                    <Grid size={{ xs: 12, sm: 6 }}><Typography variant="body2"><strong>Nombre:</strong> {profile?.DisplayName || customerInfo?.name}</Typography></Grid>
                    <Grid size={{ xs: 12, sm: 6 }}><Typography variant="body2"><strong>Email:</strong> {profile?.Email || customerInfo?.email}</Typography></Grid>
                    <Grid size={{ xs: 12, sm: 6 }}><Typography variant="body2"><strong>Teléfono:</strong> {profile?.Phone || '-'}</Typography></Grid>
                    <Grid size={{ xs: 12, sm: 6 }}><Typography variant="body2"><strong>Empresa:</strong> {profile?.CompanyName || '-'}</Typography></Grid>
                </Grid>
            </Paper>

            {/* Addresses */}
            <Paper sx={{ p: 3, borderRadius: 2 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                    <Typography variant="subtitle1" fontWeight={700}>Mis Direcciones</Typography>
                    <Button variant="contained" startIcon={<AddIcon />} size="small" onClick={openNew} sx={{ bgcolor: '#1565c0' }}>
                        Agregar
                    </Button>
                </Box>

                {isLoading ? (
                    <Typography>Cargando...</Typography>
                ) : (addresses as any[] || []).length === 0 ? (
                    <Typography color="text.secondary">No tienes direcciones guardadas</Typography>
                ) : (
                    (addresses as any[]).map((addr: any) => (
                        <Paper key={addr.ShippingAddressId} variant="outlined" sx={{ p: 2, mb: 1.5, borderRadius: 1 }}>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                                <Box>
                                    <Box sx={{ display: 'flex', gap: 1, alignItems: 'center', mb: 0.5 }}>
                                        <Typography variant="subtitle2" fontWeight={700}>{addr.Label}</Typography>
                                        {addr.IsDefault && <Chip label="Predeterminada" size="small" color="primary" icon={<StarIcon />} />}
                                        <Chip label={addr.CountryCode} size="small" variant="outlined" />
                                    </Box>
                                    <Typography variant="body2">{addr.ContactName} · {addr.Phone}</Typography>
                                    <Typography variant="body2" color="text.secondary">{addr.AddressLine1}{addr.AddressLine2 ? `, ${addr.AddressLine2}` : ''}</Typography>
                                    <Typography variant="body2" color="text.secondary">{addr.City}, {addr.State} {addr.PostalCode}</Typography>
                                </Box>
                                <IconButton size="small" onClick={() => openEdit(addr)}><EditIcon /></IconButton>
                            </Box>
                        </Paper>
                    ))
                )}
            </Paper>

            {/* Address Dialog */}
            <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
                <DialogTitle>{editAddress ? 'Editar Dirección' : 'Nueva Dirección'}</DialogTitle>
                <DialogContent>
                    <Grid container spacing={2} sx={{ mt: 0.5 }}>
                        <Grid size={{ xs: 12, sm: 6 }}><TextField label="Etiqueta" fullWidth size="small" value={form.label} onChange={(e) => setForm({ ...form, label: e.target.value })} /></Grid>
                        <Grid size={{ xs: 12, sm: 6 }}><TextField label="Nombre contacto" fullWidth size="small" required value={form.contactName} onChange={(e) => setForm({ ...form, contactName: e.target.value })} /></Grid>
                        <Grid size={{ xs: 12, sm: 6 }}><TextField label="Teléfono" fullWidth size="small" value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} /></Grid>
                        <Grid size={{ xs: 12, sm: 6 }}>
                            <TextField label="País" select fullWidth size="small" value={form.countryCode} onChange={(e) => setForm({ ...form, countryCode: e.target.value })}>
                                {['VE','CO','ES','MX','US','PA','DO','EC','CL','PT'].map((c) => <MenuItem key={c} value={c}>{c}</MenuItem>)}
                            </TextField>
                        </Grid>
                        <Grid size={{ xs: 12 }}><TextField label="Dirección línea 1" fullWidth size="small" required value={form.addressLine1} onChange={(e) => setForm({ ...form, addressLine1: e.target.value })} /></Grid>
                        <Grid size={{ xs: 12 }}><TextField label="Dirección línea 2" fullWidth size="small" value={form.addressLine2} onChange={(e) => setForm({ ...form, addressLine2: e.target.value })} /></Grid>
                        <Grid size={{ xs: 12, sm: 4 }}><TextField label="Ciudad" fullWidth size="small" required value={form.city} onChange={(e) => setForm({ ...form, city: e.target.value })} /></Grid>
                        <Grid size={{ xs: 12, sm: 4 }}><TextField label="Estado" fullWidth size="small" value={form.state} onChange={(e) => setForm({ ...form, state: e.target.value })} /></Grid>
                        <Grid size={{ xs: 12, sm: 4 }}><TextField label="Código postal" fullWidth size="small" value={form.postalCode} onChange={(e) => setForm({ ...form, postalCode: e.target.value })} /></Grid>
                    </Grid>
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
                    <Button variant="contained" onClick={handleSave} disabled={upsertMutation.isPending} sx={{ bgcolor: '#1565c0' }}>
                        {upsertMutation.isPending ? 'Guardando...' : 'Guardar'}
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
}
