'use client';
import React from 'react';
import {
  Box,
  Avatar,
  Menu,
  MenuItem,
  ListItemIcon,
  Divider,
  Typography,
  Stack,
} from '@mui/material';
import LogoutIcon from '@mui/icons-material/Logout';
import AccountCircleIcon from '@mui/icons-material/AccountCircle';
import { signOut } from 'next-auth/react';
import { useAuth } from '@/app/authentication/AuthContext';
import { useRouter } from 'next/navigation';
import type { SidebarFooterProps } from '@toolpad/core/DashboardLayout';

export function ToolbarAccountOverride() {
  return null;
}

export default function SidebarFooterAccount({ mini }: SidebarFooterProps) {
  const { userName, userEmail, isAdmin } = useAuth();
  const router = useRouter();
  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);
  const open = Boolean(anchorEl);

  const handleClick = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };

  const handleLogout = async () => {
    handleClose();
    await signOut({ redirect: false });
    router.push('/authentication/login');
  };

  const getInitials = (name: string | null): string => {
    if (!name) return '?';
    return name
      .split(' ')
      .map((n) => n[0])
      .join('')
      .toUpperCase()
      .slice(0, 2);
  };

  return (
    <>
      <Box
        onClick={handleClick}
        sx={{
          p: 1.5,
          gap: 1,
          alignItems: 'center',
          borderRadius: 1,
          bgcolor: 'action.selected',
          border: '1px solid',
          borderColor: 'divider',
          cursor: 'pointer',
          '&:hover': {
            bgcolor: 'action.hover',
          },
        }}
        component="button"
      >
        <Stack direction="row" spacing={1} alignItems="center">
          <Avatar
            sx={{
              width: 32,
              height: 32,
              fontSize: '0.875rem',
              bgcolor: 'primary.main',
            }}
          >
            {getInitials(userName)}
          </Avatar>
          <Stack
            direction="column"
            spacing={0}
            sx={{
              display: mini ? 'none' : { xs: 'none', sm: 'flex' },
              alignItems: 'flex-start',
            }}
          >
            <Typography variant="subtitle2" fontWeight='600'>
              {userName || 'Usuario'}
            </Typography>
            <Typography variant="caption" color="textSecondary">
              {isAdmin ? 'Administrador' : 'Usuario'}
            </Typography>
          </Stack>
        </Stack>
      </Box>

      <Menu
        anchorEl={anchorEl}
        id="account-menu"
        open={open}
        onClose={handleClose}
        onClick={handleClose}
        slotProps={{
          paper: {
            elevation: 0,
            sx: {
              overflow: 'visible',
              filter: 'drop-shadow(0px 2px 8px rgba(0,0,0,0.32))',
              mt: 1.5,
              '& .MuiAvatar-root': {
                width: 32,
                height: 32,
                ml: -0.5,
                mr: 1,
              },
              '&:before': {
                content: '""',
                display: 'block',
                position: 'absolute',
                top: 0,
                right: 14,
                width: 10,
                height: 10,
                bgcolor: 'background.paper',
                transform: 'translateY(-50%) rotate(45deg)',
                zIndex: 0,
              },
            },
          },
        }}
        transformOrigin={{ horizontal: 'right', vertical: 'top' }}
        anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
      >
        <MenuItem>
          <AccountCircleIcon sx={{ mr: 1 }} /> Mi Perfil
        </MenuItem>
        <Divider />
        <MenuItem onClick={handleLogout}>
          <ListItemIcon>
            <LogoutIcon fontSize="small" />
          </ListItemIcon>
          Cerrar Sesión
        </MenuItem>
      </Menu>
    </>
  );
}
