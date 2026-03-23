'use client';

import React, { useEffect, useState, useCallback, useRef } from 'react';
import {
    Alert,
    Avatar,
    Box,
    Button,
    Chip,
    CircularProgress,
    Divider,
    Drawer,
    IconButton,
    InputAdornment,
    Stack,
    TextField,
    Tooltip,
    Typography,
} from '@mui/material';
import CloseIcon from '@mui/icons-material/Close';
import EditIcon from '@mui/icons-material/Edit';
import SaveIcon from '@mui/icons-material/Save';
import CancelIcon from '@mui/icons-material/Cancel';
import LockResetIcon from '@mui/icons-material/LockReset';
import VisibilityIcon from '@mui/icons-material/Visibility';
import VisibilityOffIcon from '@mui/icons-material/VisibilityOff';
import BusinessIcon from '@mui/icons-material/Business';
import CameraAltIcon from '@mui/icons-material/CameraAlt';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import { useAuth } from '@zentto/shared-auth';
import { apiGet, apiPost, apiPut } from '@zentto/shared-api';

// ──────────────────────────────────────────────
const AVATAR_COLORS = [
    '#321fdb', '#1a73e8', '#0097a7', '#2e7d32',
    '#f57c00', '#c62828', '#6a1b9a', '#37474f',
    '#1565c0', '#00695c',
];
const AVATAR_STORAGE_KEY = 'zentto_avatar_color';
const avatarImgKey = (uid: string) => `zentto_avatar_img_${uid}`;

type ProfileData = {
    Cod_Usuario?: string;
    Nombre?: string;
    Tipo?: string;
    Cambiar?: boolean;
    Avatar?: string | null;
};

function SectionTitle({ children }: { children: React.ReactNode }) {
    return (
        <Typography variant="subtitle1" fontWeight={700} sx={{ mb: 0.5 }}>
            {children}
        </Typography>
    );
}

interface PerfilDrawerProps {
    open: boolean;
    onClose: () => void;
}

export default function PerfilDrawer({ open, onClose }: PerfilDrawerProps) {
    const { userName, userId, isAdmin, tipo, company, isLoading: authLoading } = useAuth();

    // profile load
    const [profile, setProfile] = useState<ProfileData>({});
    const [loadingProfile, setLoadingProfile] = useState(false);
    const [profileError, setProfileError] = useState<string | null>(null);

    // avatar color
    const [avatarColor, setAvatarColor] = useState<string>(AVATAR_COLORS[0]);
    useEffect(() => {
        if (typeof window !== 'undefined') {
            setAvatarColor(localStorage.getItem(AVATAR_STORAGE_KEY) || AVATAR_COLORS[0]);
        }
    }, []);

    // avatar image
    const [avatarSrc, setAvatarSrc] = useState<string | null>(null);
    const [uploadingAvatar, setUploadingAvatar] = useState(false);
    const [avatarError, setAvatarError] = useState<string | null>(null);
    const fileInputRef = useRef<HTMLInputElement>(null);

    // load cached avatar from localStorage on mount
    useEffect(() => {
        if (userId && typeof window !== 'undefined') {
            const cached = localStorage.getItem(avatarImgKey(userId));
            if (cached) setAvatarSrc(cached);
        }
    }, [userId]);

    // name edit
    const [editingName, setEditingName] = useState(false);
    const [draftName, setDraftName] = useState('');
    const [savingName, setSavingName] = useState(false);
    const [nameSuccess, setNameSuccess] = useState(false);
    const [nameError, setNameError] = useState<string | null>(null);

    // password
    const [currentPwd, setCurrentPwd] = useState('');
    const [newPwd, setNewPwd] = useState('');
    const [confirmPwd, setConfirmPwd] = useState('');
    const [showCurrent, setShowCurrent] = useState(false);
    const [showNew, setShowNew] = useState(false);
    const [showConfirm, setShowConfirm] = useState(false);
    const [savingPwd, setSavingPwd] = useState(false);
    const [pwdSuccess, setPwdSuccess] = useState(false);
    const [pwdError, setPwdError] = useState<string | null>(null);

    const loadProfile = useCallback(() => {
        setLoadingProfile(true);
        setProfileError(null);
        apiGet('/v1/usuarios/me')
            .then((data: unknown) => {
                const d = data as ProfileData;
                setProfile(d);
                setDraftName(d.Nombre || userName || '');
                // Avatar from API → update cache and notify header
                if (d.Avatar) {
                    setAvatarSrc(d.Avatar);
                    if (userId) {
                        localStorage.setItem(avatarImgKey(userId), d.Avatar);
                        window.dispatchEvent(new CustomEvent('zentto-avatar-updated', { detail: { userId, src: d.Avatar } }));
                    }
                } else {
                    // d.Avatar === null could mean "column not yet migrated" or "no avatar".
                    // Only clear the local UI — do NOT touch localStorage so a cached
                    // image from a previous upload (before migration) is preserved.
                    setAvatarSrc(null);
                }
            })
            .catch(err => setProfileError((err as Error)?.message || 'Error al cargar perfil'))
            .finally(() => setLoadingProfile(false));
    }, [userName]);

    useEffect(() => {
        if (open && !authLoading) loadProfile();
    }, [open, authLoading, loadProfile]);

    // reset form on close
    const handleClose = () => {
        setEditingName(false);
        setNameError(null);
        setNameSuccess(false);
        setCurrentPwd(''); setNewPwd(''); setConfirmPwd('');
        setPwdError(null); setPwdSuccess(false);
        setAvatarError(null);
        onClose();
    };

    /** Resize selected image to 256×256 JPEG on a canvas and upload */
    const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;
        // Reset input so the same file can be re-selected
        e.target.value = '';
        setAvatarError(null);
        const reader = new FileReader();
        reader.onload = (ev) => {
            const img = new Image();
            img.onload = async () => {
                const SIZE = 256;
                const canvas = document.createElement('canvas');
                canvas.width = SIZE;
                canvas.height = SIZE;
                const ctx = canvas.getContext('2d')!;
                // Cover crop: center the image
                const scale = Math.max(SIZE / img.width, SIZE / img.height);
                const x = (SIZE - img.width * scale) / 2;
                const y = (SIZE - img.height * scale) / 2;
                ctx.drawImage(img, x, y, img.width * scale, img.height * scale);
                const dataUrl = canvas.toDataURL('image/jpeg', 0.82);
                // Optimistic: update UI and cache BEFORE the API call so the
                // header avatar refreshes immediately even if drawer is closed first
                setAvatarSrc(dataUrl);
                if (userId) {
                    localStorage.setItem(avatarImgKey(userId), dataUrl);
                    window.dispatchEvent(new CustomEvent('zentto-avatar-updated', { detail: { userId, src: dataUrl } }));
                }
                // Persist to API
                setUploadingAvatar(true);
                try {
                    await apiPost('/v1/usuarios/me/avatar', { avatar: dataUrl });
                } catch (err: unknown) {
                    // Rollback on failure
                    setAvatarError(err instanceof Error ? err.message : 'Error al guardar avatar');
                    setAvatarSrc(null);
                    if (userId) {
                        localStorage.removeItem(avatarImgKey(userId));
                        window.dispatchEvent(new CustomEvent('zentto-avatar-updated', { detail: { userId, src: null } }));
                    }
                } finally {
                    setUploadingAvatar(false);
                }
            };
            img.src = ev.target?.result as string;
        };
        reader.readAsDataURL(file);
    };

    /** Remove avatar */
    const handleRemoveAvatar = async () => {
        setAvatarError(null);
        setUploadingAvatar(true);
        // Optimistic removal
        setAvatarSrc(null);
        if (userId) {
            localStorage.removeItem(avatarImgKey(userId));
            window.dispatchEvent(new CustomEvent('zentto-avatar-updated', { detail: { userId, src: null } }));
        }
        try {
            await apiPost('/v1/usuarios/me/avatar', { avatar: null });
        } catch (err: unknown) {
            setAvatarError(err instanceof Error ? err.message : 'Error al eliminar avatar');
        } finally {
            setUploadingAvatar(false);
        }
    };

    const getInitials = (name: string | null) =>
        name ? name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2) : '??';

    const handleAvatarColor = (color: string) => {
        setAvatarColor(color);
        if (typeof window !== 'undefined') localStorage.setItem(AVATAR_STORAGE_KEY, color);
    };

    const handleSaveName = async () => {
        setSavingName(true);
        setNameError(null);
        try {
            await apiPut('/v1/usuarios/me', { Nombre: draftName });
            setProfile(p => ({ ...p, Nombre: draftName }));
            setNameSuccess(true);
            setEditingName(false);
            setTimeout(() => setNameSuccess(false), 3000);
        } catch (err: unknown) {
            setNameError(err instanceof Error ? err.message : 'Error al guardar');
        } finally {
            setSavingName(false);
        }
    };

    const handleChangePwd = async () => {
        setPwdError(null);
        if (!currentPwd) { setPwdError('Ingresa tu contraseña actual.'); return; }
        if (newPwd.length < 4) { setPwdError('La nueva contraseña debe tener al menos 4 caracteres.'); return; }
        if (newPwd !== confirmPwd) { setPwdError('Las contraseñas no coinciden.'); return; }
        setSavingPwd(true);
        try {
            await apiPost('/v1/usuarios/me/change-password', { currentPassword: currentPwd, newPassword: newPwd });
            setPwdSuccess(true);
            setCurrentPwd(''); setNewPwd(''); setConfirmPwd('');
            setTimeout(() => setPwdSuccess(false), 4000);
        } catch (err: unknown) {
            setPwdError(err instanceof Error ? err.message : 'Verifica tu contraseña actual.');
        } finally {
            setSavingPwd(false);
        }
    };

    const displayName = profile.Nombre || userName || userId || '';
    const canChangePwd = isAdmin || Boolean(profile.Cambiar);

    return (
        <Drawer
            anchor="right"
            open={open}
            onClose={handleClose}
            PaperProps={{ sx: { width: { xs: '100vw', sm: 440 }, display: 'flex', flexDirection: 'column' } }}
        >
            {/* ── Header ─────────────────────────────────────────── */}
            <Stack direction="row" alignItems="center" sx={{ px: 2.5, py: 2, borderBottom: '1px solid', borderColor: 'divider' }}>
                <Typography variant="h6" fontWeight={700} sx={{ flexGrow: 1 }}>
                    Mi Perfil
                </Typography>
                <Tooltip title="Cerrar">
                  <IconButton onClick={handleClose}>
                    <CloseIcon />
                  </IconButton>
                </Tooltip>
            </Stack>

            {/* ── Body ───────────────────────────────────────────── */}
            <Box sx={{ flex: 1, overflowY: 'auto', p: 3 }}>
                {(authLoading || loadingProfile) ? (
                    <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
                        <CircularProgress />
                    </Box>
                ) : profileError ? (
                    <Alert severity="error">{profileError}</Alert>
                ) : (
                    <Stack spacing={3}>

                        {/* ── Avatar ─────────────────────────────────── */}
                        <Stack alignItems="center" spacing={1.5}>
                            {/* Hidden file input */}
                            <input
                                ref={fileInputRef}
                                type="file"
                                accept="image/*"
                                style={{ display: 'none' }}
                                onChange={handleFileSelect}
                            />

                            {/* Clickable avatar with camera overlay */}
                            <Tooltip title="Cambiar foto de perfil">
                                <Box
                                    onClick={() => !uploadingAvatar && fileInputRef.current?.click()}
                                    sx={{
                                        position: 'relative', width: 96, height: 96,
                                        cursor: uploadingAvatar ? 'default' : 'pointer',
                                        '&:hover .avatar-overlay': { opacity: 1 },
                                    }}
                                >
                                    <Avatar
                                        src={avatarSrc || undefined}
                                        sx={{
                                            width: 96, height: 96,
                                            fontSize: '2rem', fontWeight: 700,
                                            bgcolor: avatarColor, color: '#fff',
                                            boxShadow: '0 4px 14px rgba(0,0,0,0.18)',
                                        }}
                                    >
                                        {!avatarSrc && getInitials(displayName)}
                                    </Avatar>
                                    {/* Camera overlay */}
                                    <Box
                                        className="avatar-overlay"
                                        sx={{
                                            position: 'absolute', inset: 0, borderRadius: '50%',
                                            bgcolor: 'rgba(0,0,0,0.45)',
                                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                                            opacity: 0, transition: 'opacity 0.2s',
                                        }}
                                    >
                                        {uploadingAvatar
                                            ? <CircularProgress size={24} sx={{ color: '#fff' }} />
                                            : <CameraAltIcon sx={{ color: '#fff', fontSize: 28 }} />
                                        }
                                    </Box>
                                </Box>
                            </Tooltip>

                            <Typography variant="h6" fontWeight={700}>{displayName}</Typography>
                            <Chip label={isAdmin ? 'Administrador' : 'Usuario'} color={isAdmin ? 'primary' : 'default'} />

                            {avatarError && (
                                <Alert severity="error" sx={{ width: '100%' }}>{avatarError}</Alert>
                            )}

                            {/* Remove photo button (only when a real image exists) */}
                            {avatarSrc && (
                                <Button
                                    size="small"
                                    color="error"
                                    variant="text"
                                    startIcon={<DeleteOutlineIcon />}
                                    onClick={handleRemoveAvatar}
                                    disabled={uploadingAvatar}
                                >
                                    Eliminar foto
                                </Button>
                            )}

                            {/* Color picker (only when no real image) */}
                            {!avatarSrc && (
                                <Stack direction="row" flexWrap="wrap" gap={0.8} justifyContent="center" sx={{ pt: 0.5 }}>
                                    {AVATAR_COLORS.map(color => (
                                        <Tooltip key={color} title="Seleccionar color">
                                            <Box
                                                onClick={() => handleAvatarColor(color)}
                                                sx={{
                                                    width: 26, height: 26, borderRadius: '50%', bgcolor: color,
                                                    cursor: 'pointer',
                                                    outline: color === avatarColor ? '2.5px solid' : '2px solid transparent',
                                                    outlineColor: color === avatarColor ? 'text.primary' : 'transparent',
                                                    outlineOffset: '2px',
                                                    transition: 'transform 0.15s',
                                                    '&:hover': { transform: 'scale(1.3)' },
                                                }}
                                            />
                                        </Tooltip>
                                    ))}
                                </Stack>
                            )}
                        </Stack>

                        <Divider />

                        {/* ── Información Personal ────────────────────── */}
                        <Box>
                            <SectionTitle>Información Personal</SectionTitle>
                            <Stack spacing={2} sx={{ mt: 1.5 }}>
                                {nameSuccess && <Alert severity="success">Nombre actualizado correctamente.</Alert>}
                                {nameError && <Alert severity="error">{nameError}</Alert>}

                                <TextField
                                    label="Código de Usuario"
                                    value={userId ?? profile.Cod_Usuario ?? ''}
                                    disabled
                                    fullWidth
                                />
                                <TextField
                                    label="Nombre Completo"
                                    fullWidth
                                    value={editingName ? draftName : displayName}
                                    onChange={e => setDraftName(e.target.value)}
                                    disabled={!editingName}
                                    InputProps={{
                                        endAdornment: !editingName ? (
                                            <InputAdornment position="end">
                                                <Tooltip title="Editar nombre">
                                                    <IconButton onClick={() => { setEditingName(true); setDraftName(displayName); }}>
                                                        <EditIcon />
                                                    </IconButton>
                                                </Tooltip>
                                            </InputAdornment>
                                        ) : undefined,
                                    }}
                                />
                                <TextField
                                    label="Rol"
                                    value={isAdmin ? 'Administrador' : (tipo || 'Usuario')}
                                    disabled
                                    fullWidth
                                />
                            </Stack>

                            {editingName && (
                                <Stack direction="row" spacing={1} sx={{ mt: 2 }}>
                                    <Button variant="contained" startIcon={<SaveIcon />} onClick={handleSaveName} disabled={savingName || !draftName.trim()}>
                                        {savingName ? 'Guardando...' : 'Guardar'}
                                    </Button>
                                    <Button variant="outlined" startIcon={<CancelIcon />} onClick={() => { setEditingName(false); setNameError(null); }} disabled={savingName}>
                                        Cancelar
                                    </Button>
                                </Stack>
                            )}
                        </Box>

                        <Divider />

                        {/* ── Cambiar Contraseña ─────────────────────── */}
                        <Box>
                            <SectionTitle>Cambiar Contraseña</SectionTitle>

                            {!canChangePwd ? (
                                <Alert severity="info" sx={{ mt: 1.5 }}>
                                    Sin permiso para cambiar contraseña. Contacta a un administrador.
                                </Alert>
                            ) : (
                                <Stack spacing={2} sx={{ mt: 1.5 }}>
                                    {pwdSuccess && <Alert severity="success">Contraseña actualizada correctamente.</Alert>}
                                    {pwdError && <Alert severity="error">{pwdError}</Alert>}

                                    {([
                                        { field: 'current' as const, label: 'Contraseña actual', value: currentPwd, show: showCurrent, setShow: setShowCurrent, setVal: setCurrentPwd },
                                        { field: 'new' as const, label: 'Nueva contraseña', value: newPwd, show: showNew, setShow: setShowNew, setVal: setNewPwd, helper: 'Mínimo 4 caracteres' },
                                        { field: 'confirm' as const, label: 'Confirmar contraseña', value: confirmPwd, show: showConfirm, setShow: setShowConfirm, setVal: setConfirmPwd },
                                    ]).map(({ field, label, value, show, setShow, setVal, helper }) => {
                                        const hasError = field === 'confirm' && confirmPwd.length > 0 && confirmPwd !== newPwd;
                                        return (
                                            <TextField
                                                key={field}
                                                fullWidth
                                                label={label}
                                                type={show ? 'text' : 'password'}
                                                value={value}
                                                onChange={e => setVal(e.target.value)}
                                                error={hasError}
                                                helperText={hasError ? 'Las contraseñas no coinciden' : (helper ?? '')}
                                                InputProps={{
                                                    endAdornment: (
                                                        <InputAdornment position="end">
                                                            <Tooltip title={show ? "Ocultar contrasena" : "Mostrar contrasena"}>
                                                              <IconButton onClick={() => setShow(p => !p)}>
                                                                {show ? <VisibilityOffIcon /> : <VisibilityIcon />}
                                                              </IconButton>
                                                            </Tooltip>
                                                        </InputAdornment>
                                                    ),
                                                }}
                                            />
                                        );
                                    })}

                                    <Box>
                                        <Button
                                            variant="contained"
                                            startIcon={savingPwd ? <CircularProgress size={16} color="inherit" /> : <LockResetIcon />}
                                            onClick={handleChangePwd}
                                            disabled={savingPwd || !currentPwd || !newPwd || newPwd !== confirmPwd}
                                        >
                                            {savingPwd ? 'Actualizando...' : 'Actualizar Contraseña'}
                                        </Button>
                                    </Box>
                                </Stack>
                            )}
                        </Box>

                        {/* ── Empresa Activa ─────────────────────────── */}
                        {company && (
                            <>
                                <Divider />
                                <Box>
                                    <Stack direction="row" alignItems="center" spacing={0.75} sx={{ mb: 1.5 }}>
                                        <BusinessIcon fontSize="small" color="action" />
                                        <SectionTitle>Empresa Activa</SectionTitle>
                                    </Stack>
                                    <Stack spacing={2}>
                                        <TextField label="Empresa" value={`${company.companyCode} · ${company.companyName}`} disabled fullWidth />
                                        <TextField label="Sucursal" value={`${company.branchCode} · ${company.branchName}`} disabled fullWidth />
                                        <TextField label="País" value={company.countryCode} disabled fullWidth />
                                    </Stack>
                                </Box>
                            </>
                        )}

                    </Stack>
                )}
            </Box>
        </Drawer>
    );
}
