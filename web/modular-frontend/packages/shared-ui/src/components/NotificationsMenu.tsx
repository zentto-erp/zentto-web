import React, { useState } from 'react';
import {
    IconButton, Badge, Menu, Typography, Box, Divider, Button,
    List, ListItem, ListItemAvatar, ListItemText, Avatar, Tooltip
} from '@mui/material';
import { useRouter } from 'next/navigation';
import NotificationsNoneOutlinedIcon from '@mui/icons-material/NotificationsNoneOutlined';
import ErrorOutlineIcon from '@mui/icons-material/ErrorOutline';
import CheckCircleOutlineIcon from '@mui/icons-material/CheckCircleOutline';
import InfoOutlinedIcon from '@mui/icons-material/InfoOutlined';
import WarningAmberOutlinedIcon from '@mui/icons-material/WarningAmberOutlined';
import { apiGet, apiPost } from '@zentto/shared-api';

type Notification = {
    id: string;
    type: 'info' | 'success' | 'warning' | 'error';
    title: string;
    message: string;
    time: string;
    read: boolean;
    route: string | null;
};

interface NotificationsMenuProps {
    /**
     * Codigo de la app actual (ej: 'crm', 'ventas', 'ecommerce').
     * Si se provee, el backend filtra notificaciones de esa app + broadcasts
     * cross-app. Si no se provee, lee process.env.NEXT_PUBLIC_APP_CODE como
     * fallback. Si ninguno esta disponible, se muestran todas las notificaciones.
     */
    appCode?: string;
}

export default function NotificationsMenu({ appCode: appCodeProp }: NotificationsMenuProps = {}) {
    const router = useRouter();
    const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
    const [notifications, setNotifications] = useState<Notification[]>([]);

    // Fallback a NEXT_PUBLIC_APP_CODE si la app no pasa el prop explicitamente.
    const appCode = (appCodeProp || process.env.NEXT_PUBLIC_APP_CODE || '').toLowerCase() || null;

    React.useEffect(() => {
        const fetchNotifs = async () => {
            try {
                const path = appCode
                    ? `/v1/sistema/notificaciones?appCode=${encodeURIComponent(appCode)}`
                    : '/v1/sistema/notificaciones';
                const data = await apiGet(path);
                if (data?.data) setNotifications(data.data);
            } catch (e) { }
        };
        fetchNotifs();
        const interval = setInterval(fetchNotifs, 30000); // refresh every 30s
        return () => clearInterval(interval);
    }, [appCode]);

    const open = Boolean(anchorEl);
    const unreadCount = notifications.filter(n => !n.read).length;

    const handleClick = (event: React.MouseEvent<HTMLElement>) => {
        setAnchorEl(event.currentTarget);
    };

    const handleClose = () => {
        setAnchorEl(null);
    };

    const handleMarkAllAsRead = async () => {
        const unreadIds = notifications.filter(n => !n.read).map(n => Number(n.id));
        if (unreadIds.length > 0) {
            try {
                await apiPost('/v1/sistema/notificaciones/leido', { ids: unreadIds });
            } catch (e) { }
        }
        setNotifications(notifications.map(n => ({ ...n, read: true })));
    };

    const handleNotificationClick = async (notif: Notification) => {
        if (!notif.read) {
            try {
                await apiPost('/v1/sistema/notificaciones/leido', { ids: [parseInt(notif.id)] });
            } catch (e) { }
            setNotifications(notifications.map(n => n.id === notif.id ? { ...n, read: true } : n));
        }
        if (notif.route) {
            // handle routing
        }
    };

    const getIcon = (type: string) => {
        switch (type) {
            case 'success': return <CheckCircleOutlineIcon color="success" />;
            case 'warning': return <WarningAmberOutlinedIcon color="warning" />;
            case 'error': return <ErrorOutlineIcon color="error" />;
            default: return <InfoOutlinedIcon color="info" />;
        }
    };

    const getAvatarBg = (type: string) => {
        switch (type) {
            case 'success': return '#e8f5e9';
            case 'warning': return '#fff3e0';
            case 'error': return '#ffebee';
            default: return '#e3f2fd';
        }
    };

    return (
        <React.Fragment>
            <Tooltip title="Notificaciones">
              <IconButton onClick={handleClick} size="small" sx={{ color: 'inherit' }}>
                <Badge badgeContent={unreadCount} color="error" max={99}>
                    <NotificationsNoneOutlinedIcon />
                </Badge>
              </IconButton>
            </Tooltip>
            <Menu
                anchorEl={anchorEl}
                open={open}
                onClose={handleClose}
                transformOrigin={{ horizontal: 'right', vertical: 'top' }}
                anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
                PaperProps={{
                    sx: { width: 360, maxHeight: 500, mt: 1.5 },
                }}
            >
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', px: 2, py: 1 }}>
                    <Typography variant="subtitle1" fontWeight="bold">
                        Notificaciones
                    </Typography>
                    {unreadCount > 0 && (
                        <Button size="small" onClick={handleMarkAllAsRead} sx={{ textTransform: 'none', fontSize: '0.75rem' }}>
                            Marcar todo como leído
                        </Button>
                    )}
                </Box>
                <Divider />
                <List sx={{ p: 0 }}>
                    {notifications.length === 0 ? (
                        <Box sx={{ p: 3, textAlign: 'center', color: 'text.secondary' }}>
                            <NotificationsNoneOutlinedIcon sx={{ fontSize: 40, opacity: 0.3, mb: 1 }} />
                            <Typography variant="body2">No tienes notificaciones nuevas.</Typography>
                        </Box>
                    ) : (
                        notifications.map((notif) => (
                            <ListItem
                                key={notif.id}
                                sx={{
                                    bgcolor: notif.read ? 'transparent' : 'action.hover',
                                    borderLeft: notif.read ? '3px solid transparent' : '3px solid #1976d2',
                                    cursor: 'pointer',
                                    '&:hover': { bgcolor: 'action.selected' }
                                }}
                                onClick={() => handleNotificationClick(notif)}
                            >
                                <ListItemAvatar>
                                    <Avatar sx={{ bgcolor: getAvatarBg(notif.type) }}>
                                        {getIcon(notif.type)}
                                    </Avatar>
                                </ListItemAvatar>
                                <ListItemText
                                    primary={
                                        <Typography variant="subtitle2" component="span" fontWeight={notif.read ? 'normal' : 'bold'}>
                                            {notif.title}
                                        </Typography>
                                    }
                                    secondary={
                                        <React.Fragment>
                                            <Typography variant="caption" color="text.secondary" display="block">
                                                {notif.message}
                                            </Typography>
                                            <Typography variant="caption" color="primary.main" display="block" sx={{ mt: 0.5 }}>
                                                {notif.time}
                                            </Typography>
                                        </React.Fragment>
                                    }
                                />
                            </ListItem>
                        ))
                    )}
                </List>
                <Divider />
                <Box sx={{ p: 1, textAlign: 'center' }}>
                    <Button
                        fullWidth
                        size="small"
                        sx={{ textTransform: 'none' }}
                        onClick={() => { handleClose(); router.push('/notificaciones'); }}
                    >
                        Ver todas las notificaciones
                    </Button>
                </Box>
            </Menu>
        </React.Fragment>
    );
}
