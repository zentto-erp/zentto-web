'use client';
import React from 'react';
import { Box, Avatar, Menu, MenuItem, ListItemIcon, Divider, Typography, Stack } from '@mui/material';
import LogoutIcon from '@mui/icons-material/Logout';
import AccountCircleIcon from '@mui/icons-material/AccountCircle';
import { appAwareSignOut, buildLoginCallbackUrl, useAuth } from '@zentto/shared-auth';
import { brandColors } from '../theme';
import { apiGet } from '@zentto/shared-api';
import { useRouter } from 'next/navigation';
import PerfilDrawer from './PerfilDrawer';

export function ToolbarAccountOverride() { return null; }

export default function SidebarFooterAccount({ mini }: { mini: boolean }) {
  const { userName, userId, isAdmin } = useAuth();
  const router = useRouter();
  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);
  const [perfilOpen, setPerfilOpen] = React.useState(false);
  const [avatarSrc, setAvatarSrc] = React.useState<string | null>(null);

  // Load avatar: from localStorage (instant), then verify with API (authoritative)
  React.useEffect(() => {
    if (!userId || typeof window === 'undefined') return;
    const key = `zentto_avatar_img_${userId}`;
    const cached = localStorage.getItem(key);
    // Show cached version immediately (no flash of initials on page load)
    if (cached) setAvatarSrc(cached);
    // Always fetch from API to get the latest (covers new browser / cleared cache)
    apiGet('/v1/usuarios/me')
      .then((data: unknown) => {
        const avatar = (data as { Avatar?: string | null }).Avatar;
        if (avatar) {
          localStorage.setItem(key, avatar);
          setAvatarSrc(avatar);
        } else if (!cached) {
          // API has no avatar and we had nothing cached — keep showing initials
          setAvatarSrc(null);
        }
        // If API has no avatar but we have a cached one: keep the cache (column may not be migrated)
      })
      .catch(() => { /* ignore — cached version is still shown */ });
    // Custom event fired by PerfilDrawer on same tab (StorageEvent only fires cross-tab)
    const onAvatarUpdated = (e: Event) => {
      const detail = (e as CustomEvent<{ userId: string; src: string | null }>).detail;
      if (detail.userId === userId) setAvatarSrc(detail.src);
    };
    window.addEventListener('zentto-avatar-updated', onAvatarUpdated);
    return () => window.removeEventListener('zentto-avatar-updated', onAvatarUpdated);
  }, [userId]);

  const handlePerfilClose = React.useCallback(() => setPerfilOpen(false), []);
  const open = Boolean(anchorEl);
  const handleClick = (e: React.MouseEvent<HTMLElement>) => setAnchorEl(e.currentTarget);
  const handleClose = () => setAnchorEl(null);
  const handleLogout = async () => { handleClose(); await appAwareSignOut({ redirect: false, callbackUrl: buildLoginCallbackUrl() }); window.location.href = buildLoginCallbackUrl(); };
  const getInitials = (name: string | null) => name ? name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2) : '?';

  return (
    <>
      <Box onClick={handleClick} component="button" sx={{
        p: 0.5, pr: 1.5, gap: 1, alignItems: 'center', borderRadius: 8, bgcolor: 'transparent',
        border: 'none', cursor: 'pointer', color: 'inherit', '&:hover': { bgcolor: 'action.hover' },
      }}>
        <Stack direction="row" spacing={1} alignItems="center">
          <Avatar src={avatarSrc || undefined} sx={{ width: 36, height: 36, fontSize: '1rem', fontWeight: 600, bgcolor: brandColors.indigo, color: '#fff' }}>{!avatarSrc && getInitials(userName)}</Avatar>
          <Stack direction="column" spacing={0} sx={{ display: mini ? 'none' : { xs: 'none', sm: 'flex' }, alignItems: 'flex-start' }}>
            <Typography variant="subtitle2" fontWeight="600" sx={{ color: 'inherit' }}>{userName || 'Usuario'}</Typography>
            <Typography variant="caption" sx={{ color: 'text.secondary' }}>{isAdmin ? 'Administrador' : 'Usuario'}</Typography>
          </Stack>
        </Stack>
      </Box>
      <Menu anchorEl={anchorEl} id="account-menu" open={open} onClose={handleClose}
        slotProps={{ paper: { elevation: 0, sx: { overflow: 'visible', filter: 'drop-shadow(0px 2px 8px rgba(0,0,0,0.32))', mt: 1.5 } } }}
        transformOrigin={{ horizontal: 'right', vertical: 'top' }} anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}>
        <MenuItem onClick={() => { handleClose(); setPerfilOpen(true); }}>
          <AccountCircleIcon sx={{ mr: 1 }} /> Mi Perfil
        </MenuItem>
        <Divider />
        <MenuItem onClick={handleLogout}><ListItemIcon><LogoutIcon fontSize="small" /></ListItemIcon>Cerrar Sesión</MenuItem>
      </Menu>
      <PerfilDrawer open={perfilOpen} onClose={handlePerfilClose} />
    </>
  );
}
