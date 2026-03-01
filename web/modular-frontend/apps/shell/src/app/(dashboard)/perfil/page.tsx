'use client';

import React, { useEffect, useState } from 'react';
import {
    Alert,
    Avatar,
    Box,
    Button,
    Card,
    CardContent,
    Chip,
    CircularProgress,
    Divider,
    Grid,
    InputAdornment,
    IconButton,
    Stack,
    TextField,
    Tooltip,
    Typography,
} from '@mui/material';
import { useAuth } from '@datqbox/shared-auth';
import { apiGet, apiPost, apiPut } from '@datqbox/shared-api';
import dynamic from 'next/dynamic';

const EditIcon = dynamic(() => import('@mui/icons-material/Edit'), { ssr: false });
const SaveIcon = dynamic(() => import('@mui/icons-material/Save'), { ssr: false });
const CancelIcon = dynamic(() => import('@mui/icons-material/Cancel'), { ssr: false });
const LockResetIcon = dynamic(() => import('@mui/icons-material/LockReset'), { ssr: false });
const VisibilityIcon = dynamic(() => import('@mui/icons-material/Visibility'), { ssr: false });
const VisibilityOffIcon = dynamic(() => import('@mui/icons-material/VisibilityOff'), { ssr: false });
const BadgeIcon = dynamic(() => import('@mui/icons-material/Badge'), { ssr: false });
const ManageAccountsIcon = dynamic(() => import('@mui/icons-material/ManageAccounts'), { ssr: false });

// Palette of colors for the avatar
const AVATAR_COLORS = [
    '#321fdb', '#1a73e8', '#0097a7', '#2e7d32',
    '#f57c00', '#c62828', '#6a1b9a', '#37474f',
    '#1565c0', '#00695c',
];

const AVATAR_STORAGE_KEY = 'datqbox_avatar_color';

type ProfileData = {
    Cod_Usuario?: string;
    Nombre?: string;
    Tipo?: string;
    Cambiar?: boolean;
};

export default function PerfilPage() {
    const { userName, userId, isAdmin, tipo, company, isLoading: authLoading } = useAuth();

    // Profile data
    const [profile, setProfile] = useState<ProfileData>({});
    const [loadingProfile, setLoadingProfile] = useState(true);
    const [profileError, setProfileError] = useState<string | null>(null);

    // Editing name
    const [editingName, setEditingName] = useState(false);
    const [draftName, setDraftName] = useState('');
    const [savingName, setSavingName] = useState(false);
    const [nameSuccess, setNameSuccess] = useState(false);
    const [nameError, setNameError] = useState<string | null>(null);

    // Avatar color
    const [avatarColor, setAvatarColor] = useState<string>(() => {
        if (typeof window !== 'undefined') {
            return localStorage.getItem(AVATAR_STORAGE_KEY) || AVATAR_COLORS[0];
        }
        return AVATAR_COLORS[0];
    });

    // Password
    const [currentPwd, setCurrentPwd] = useState('');
    const [newPwd, setNewPwd] = useState('');
    const [confirmPwd, setConfirmPwd] = useState('');
    const [showCurrent, setShowCurrent] = useState(false);
    const [showNew, setShowNew] = useState(false);
    const [showConfirm, setShowConfirm] = useState(false);
    const [savingPwd, setSavingPwd] = useState(false);
    const [pwdSuccess, setPwdSuccess] = useState(false);
    const [pwdError, setPwdError] = useState<string | null>(null);

    useEffect(() => {
        if (authLoading) return;
        setLoadingProfile(true);
        apiGet('/v1/usuarios/me')
            .then((data: unknown) => {
                const d = data as ProfileData;
                setProfile(d);
                setDraftName(d.Nombre || userName || '');
            })
            .catch(err => setProfileError(err?.message || 'Error al cargar perfil'))
            .finally(() => setLoadingProfile(false));
    }, [authLoading, userName]);

    const getInitials = (name: string | null) =>
        name ? name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2) : '??';

    const handleAvatarColor = (color: string) => {
        setAvatarColor(color);
        if (typeof window !== 'undefined') {
            localStorage.setItem(AVATAR_STORAGE_KEY, color);
        }
    };

    const handleSaveName = async () => {
        setSavingName(true);
        setNameError(null);
        setNameSuccess(false);
        try {
            await apiPut('/v1/usuarios/me', { Nombre: draftName });
            setProfile(p => ({ ...p, Nombre: draftName }));
            setNameSuccess(true);
            setEditingName(false);
            setTimeout(() => setNameSuccess(false), 3000);
        } catch (err: unknown) {
            setNameError(err instanceof Error ? err.message : 'Error al guardar nombre');
        } finally {
            setSavingName(false);
        }
    };

    const handleChangePassword = async () => {
        setPwdError(null);
        setPwdSuccess(false);

        if (!currentPwd) { setPwdError('Ingresa tu contraseña actual.'); return; }
        if (newPwd.length < 4) { setPwdError('La nueva contraseña debe tener al menos 4 caracteres.'); return; }
        if (newPwd !== confirmPwd) { setPwdError('Las contraseñas no coinciden.'); return; }

        setSavingPwd(true);
        try {
            await apiPost('/v1/usuarios/me/change-password', { currentPassword: currentPwd, newPassword: newPwd });
            setPwdSuccess(true);
            setCurrentPwd('');
            setNewPwd('');
            setConfirmPwd('');
            setTimeout(() => setPwdSuccess(false), 4000);
        } catch (err: unknown) {
            setPwdError(err instanceof Error ? err.message : 'No se pudo cambiar la contraseña. Verifica tu contraseña actual.');
        } finally {
            setSavingPwd(false);
        }
    };

    const canChangePwd = isAdmin || Boolean(profile.Cambiar);
    const displayName = profile.Nombre || userName || userId || '';

    if (authLoading || loadingProfile) {
        return (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
                <CircularProgress />
            </Box>
        );
    }

    if (profileError) {
        return (
            <Box sx={{ p: 3 }}>
                <Alert severity="error">{profileError}</Alert>
            </Box>
        );
    }

    return (
        <Box sx={{ maxWidth: 860, mx: 'auto', p: { xs: 2, md: 3 } }}>
            <Typography variant="h5" sx={{ fontWeight: 700, mb: 0.5 }}>
                Mi Perfil
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
                Gestiona tu información personal, avatar y acceso de seguridad.
            </Typography>

            <Grid container spacing={3}>

                {/* ── Tarjeta de Identidad ──────────────────────────── */}
                <Grid item xs={12} md={4}>
                    <Card variant="outlined">
                        <CardContent sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2, py: 3 }}>

                            <Avatar
                                sx={{
                                    width: 88, height: 88,
                                    fontSize: '2rem', fontWeight: 700,
                                    bgcolor: avatarColor,
                                    color: '#fff',
                                    boxShadow: '0 4px 12px rgba(0,0,0,0.18)',
                                }}
                            >
                                {getInitials(displayName)}
                            </Avatar>

                            <Typography variant="h6" fontWeight={700} textAlign="center">
                                {displayName}
                            </Typography>
                            <Chip
                                size="small"
                                label={isAdmin ? 'Administrador' : 'Usuario'}
                                color={isAdmin ? 'primary' : 'default'}
                            />
                            <Typography variant="body2" color="text.secondary">
                                Código: <strong>{userId ?? profile.Cod_Usuario ?? '—'}</strong>
                            </Typography>
                            {company && (
                                <Typography variant="caption" color="text.secondary" textAlign="center">
                                    {company.companyName} · {company.branchName}
                                </Typography>
                            )}

                            {/* Avatar color picker */}
                            <Divider sx={{ width: '100%' }} />
                            <Typography variant="caption" color="text.secondary">Color de avatar</Typography>
                            <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.8, justifyContent: 'center' }}>
                                {AVATAR_COLORS.map(color => (
                                    <Tooltip key={color} title={color}>
                                        <Box
                                            onClick={() => handleAvatarColor(color)}
                                            sx={{
                                                width: 24, height: 24, borderRadius: '50%',
                                                bgcolor: color, cursor: 'pointer',
                                                border: color === avatarColor ? '2.5px solid' : '2px solid transparent',
                                                borderColor: color === avatarColor ? 'text.primary' : 'transparent',
                                                transition: 'transform 0.15s',
                                                '&:hover': { transform: 'scale(1.25)' },
                                            }}
                                        />
                                    </Tooltip>
                                ))}
                            </Box>
                        </CardContent>
                    </Card>
                </Grid>

                {/* ── Información del Perfil ────────────────────────── */}
                <Grid item xs={12} md={8}>
                    <Stack spacing={2}>

                        {/* Nombre */}
                        <Card variant="outlined">
                            <CardContent>
                                <Stack direction="row" alignItems="center" spacing={1} sx={{ mb: 2 }}>
                                    <BadgeIcon color="action" fontSize="small" />
                                    <Typography variant="subtitle1" fontWeight={600}>
                                        Información Personal
                                    </Typography>
                                </Stack>

                                {nameSuccess && (
                                    <Alert severity="success" sx={{ mb: 1.5 }}>Nombre actualizado correctamente.</Alert>
                                )}
                                {nameError && (
                                    <Alert severity="error" sx={{ mb: 1.5 }}>{nameError}</Alert>
                                )}

                                <Stack spacing={1.5}>
                                    <TextField
                                        size="small"
                                        label="Código de Usuario"
                                        value={userId ?? profile.Cod_Usuario ?? ''}
                                        disabled
                                        fullWidth
                                    />
                                    <TextField
                                        size="small"
                                        label="Nombre Completo"
                                        value={editingName ? draftName : displayName}
                                        onChange={e => setDraftName(e.target.value)}
                                        disabled={!editingName}
                                        fullWidth
                                        InputProps={{
                                            endAdornment: !editingName ? (
                                                <InputAdornment position="end">
                                                    <Tooltip title="Editar nombre">
                                                        <IconButton size="small" onClick={() => { setEditingName(true); setDraftName(displayName); }}>
                                                            <EditIcon fontSize="small" />
                                                        </IconButton>
                                                    </Tooltip>
                                                </InputAdornment>
                                            ) : undefined,
                                        }}
                                    />
                                    <TextField
                                        size="small"
                                        label="Rol"
                                        value={isAdmin ? 'Administrador' : (tipo || 'Usuario')}
                                        disabled
                                        fullWidth
                                    />
                                </Stack>

                                {editingName && (
                                    <Stack direction="row" spacing={1} sx={{ mt: 1.5 }}>
                                        <Button
                                            variant="contained"
                                            size="small"
                                            startIcon={<SaveIcon />}
                                            onClick={handleSaveName}
                                            disabled={savingName || !draftName.trim()}
                                        >
                                            {savingName ? 'Guardando...' : 'Guardar'}
                                        </Button>
                                        <Button
                                            variant="outlined"
                                            size="small"
                                            startIcon={<CancelIcon />}
                                            onClick={() => { setEditingName(false); setNameError(null); }}
                                            disabled={savingName}
                                        >
                                            Cancelar
                                        </Button>
                                    </Stack>
                                )}
                            </CardContent>
                        </Card>

                        {/* Cambiar contraseña */}
                        <Card variant="outlined">
                            <CardContent>
                                <Stack direction="row" alignItems="center" spacing={1} sx={{ mb: 2 }}>
                                    <LockResetIcon color="action" fontSize="small" />
                                    <Typography variant="subtitle1" fontWeight={600}>
                                        Cambiar Contraseña
                                    </Typography>
                                </Stack>

                                {!canChangePwd ? (
                                    <Alert severity="info">
                                        Tu usuario no tiene permiso para cambiar su propia contraseña.
                                        Contacta a un administrador.
                                    </Alert>
                                ) : (
                                    <>
                                        {pwdSuccess && (
                                            <Alert severity="success" sx={{ mb: 1.5 }}>
                                                Contraseña actualizada correctamente.
                                            </Alert>
                                        )}
                                        {pwdError && (
                                            <Alert severity="error" sx={{ mb: 1.5 }}>{pwdError}</Alert>
                                        )}

                                        <Stack spacing={1.5}>
                                            <TextField
                                                size="small" fullWidth
                                                label="Contraseña actual"
                                                type={showCurrent ? 'text' : 'password'}
                                                value={currentPwd}
                                                onChange={e => setCurrentPwd(e.target.value)}
                                                InputProps={{
                                                    endAdornment: (
                                                        <InputAdornment position="end">
                                                            <IconButton size="small" onClick={() => setShowCurrent(p => !p)}>
                                                                {showCurrent ? <VisibilityOffIcon fontSize="small" /> : <VisibilityIcon fontSize="small" />}
                                                            </IconButton>
                                                        </InputAdornment>
                                                    ),
                                                }}
                                            />
                                            <TextField
                                                size="small" fullWidth
                                                label="Nueva contraseña"
                                                type={showNew ? 'text' : 'password'}
                                                value={newPwd}
                                                onChange={e => setNewPwd(e.target.value)}
                                                helperText="Mínimo 4 caracteres"
                                                InputProps={{
                                                    endAdornment: (
                                                        <InputAdornment position="end">
                                                            <IconButton size="small" onClick={() => setShowNew(p => !p)}>
                                                                {showNew ? <VisibilityOffIcon fontSize="small" /> : <VisibilityIcon fontSize="small" />}
                                                            </IconButton>
                                                        </InputAdornment>
                                                    ),
                                                }}
                                            />
                                            <TextField
                                                size="small" fullWidth
                                                label="Confirmar nueva contraseña"
                                                type={showConfirm ? 'text' : 'password'}
                                                value={confirmPwd}
                                                onChange={e => setConfirmPwd(e.target.value)}
                                                error={confirmPwd.length > 0 && confirmPwd !== newPwd}
                                                helperText={confirmPwd.length > 0 && confirmPwd !== newPwd ? 'Las contraseñas no coinciden' : ''}
                                                InputProps={{
                                                    endAdornment: (
                                                        <InputAdornment position="end">
                                                            <IconButton size="small" onClick={() => setShowConfirm(p => !p)}>
                                                                {showConfirm ? <VisibilityOffIcon fontSize="small" /> : <VisibilityIcon fontSize="small" />}
                                                            </IconButton>
                                                        </InputAdornment>
                                                    ),
                                                }}
                                            />
                                            <Button
                                                variant="contained"
                                                onClick={handleChangePassword}
                                                disabled={savingPwd || !currentPwd || !newPwd || newPwd !== confirmPwd}
                                                startIcon={savingPwd ? <CircularProgress size={16} /> : <LockResetIcon />}
                                                sx={{ alignSelf: 'flex-start' }}
                                            >
                                                {savingPwd ? 'Actualizando...' : 'Actualizar Contraseña'}
                                            </Button>
                                        </Stack>
                                    </>
                                )}
                            </CardContent>
                        </Card>

                        {/* Empresa activa */}
                        {company && (
                            <Card variant="outlined">
                                <CardContent>
                                    <Stack direction="row" alignItems="center" spacing={1} sx={{ mb: 1.5 }}>
                                        <ManageAccountsIcon color="action" fontSize="small" />
                                        <Typography variant="subtitle1" fontWeight={600}>
                                            Empresa Activa
                                        </Typography>
                                    </Stack>
                                    <Stack spacing={1}>
                                        <TextField size="small" label="Empresa" value={`${company.companyCode} - ${company.companyName}`} disabled fullWidth />
                                        <TextField size="small" label="Sucursal" value={`${company.branchCode} - ${company.branchName}`} disabled fullWidth />
                                        <TextField size="small" label="País" value={company.countryCode} disabled fullWidth />
                                    </Stack>
                                </CardContent>
                            </Card>
                        )}

                    </Stack>
                </Grid>
            </Grid>
        </Box>
    );
}
