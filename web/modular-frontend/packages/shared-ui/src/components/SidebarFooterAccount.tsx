'use client';
import React from 'react';
import { Box, Avatar, Menu, MenuItem, ListItemIcon, Divider, Typography, Stack } from '@mui/material';
import LogoutIcon from '@mui/icons-material/Logout';
import AccountCircleIcon from '@mui/icons-material/AccountCircle';
import { signOut } from 'next-auth/react';
import { useAuth } from '@datqbox/shared-auth';
import { useRouter } from 'next/navigation';
import type { SidebarFooterProps } from '@toolpad/core/DashboardLayout';

export function ToolbarAccountOverride() { return null; }

export default function SidebarFooterAccount({ mini }: SidebarFooterProps) {
  const { userName, isAdmin } = useAuth();
  const router = useRouter();
  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);
  const open = Boolean(anchorEl);
  const handleClick = (e: React.MouseEvent<HTMLElement>) => setAnchorEl(e.currentTarget);
  const handleClose = () => setAnchorEl(null);
  const handleLogout = async () => { handleClose(); await signOut({ redirect: false }); router.push('/authentication/login'); };
  const getInitials = (name: string | null) => name ? name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2) : '?';

  return (
    <>
      <Box onClick={handleClick} component="button" sx={{
        p: 0.5, pr: 1.5, gap: 1, alignItems: 'center', borderRadius: 8, bgcolor: 'transparent',
        border: 'none', cursor: 'pointer', '&:hover': { bgcolor: 'rgba(0,0,0,0.04)' },
      }}>
        <Stack direction="row" spacing={1} alignItems="center">
          <Avatar sx={{ width: 36, height: 36, fontSize: '1rem', fontWeight: 600, bgcolor: '#321fdb', color: '#fff' }}>{getInitials(userName)}</Avatar>
          <Stack direction="column" spacing={0} sx={{ display: mini ? 'none' : { xs: 'none', sm: 'flex' }, alignItems: 'flex-start' }}>
            <Typography variant="subtitle2" fontWeight="600">{userName || 'Usuario'}</Typography>
            <Typography variant="caption" color="textSecondary">{isAdmin ? 'Administrador' : 'Usuario'}</Typography>
          </Stack>
        </Stack>
      </Box>
      <Menu anchorEl={anchorEl} id="account-menu" open={open} onClose={handleClose} onClick={handleClose}
        slotProps={{ paper: { elevation: 0, sx: { overflow: 'visible', filter: 'drop-shadow(0px 2px 8px rgba(0,0,0,0.32))', mt: 1.5 } } }}
        transformOrigin={{ horizontal: 'right', vertical: 'top' }} anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}>
        <MenuItem><AccountCircleIcon sx={{ mr: 1 }} /> Mi Perfil</MenuItem>
        <Divider />
        <MenuItem onClick={handleLogout}><ListItemIcon><LogoutIcon fontSize="small" /></ListItemIcon>Cerrar Sesión</MenuItem>
      </Menu>
    </>
  );
}
