import React, { useState } from 'react';
import {
    IconButton, Badge, Menu, Typography, Box, Divider, Button,
    List, ListItem, ListItemAvatar, ListItemText, Avatar, Tooltip
} from '@mui/material';
import { useRouter } from 'next/navigation';
import MailOutlineIcon from '@mui/icons-material/MailOutline';
import { apiGet, apiPatch } from '@zentto/shared-api';

type Message = {
    id: string;
    sender: string;
    avatar?: string;
    subject: string;
    time: string;
    unread: boolean;
};

export default function MessagesMenu() {
    const router = useRouter();
    const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
    const [messages, setMessages] = useState<Message[]>([]);

    React.useEffect(() => {
        const fetchMessages = async () => {
            try {
                // Assuming currently logged in user is admin, sending userId=admin (backend default anyway for now)
                const data = await apiGet('/v1/sistema/mensajes?userId=admin');
                if (data?.data) setMessages(data.data);
            } catch (e) { }
        };
        fetchMessages();
        const interval = setInterval(fetchMessages, 60000); // 1 min update
        return () => clearInterval(interval);
    }, []);

    const open = Boolean(anchorEl);
    const unreadCount = messages.filter(m => m.unread).length;

    const handleClick = (event: React.MouseEvent<HTMLElement>) => {
        setAnchorEl(event.currentTarget);
    };

    const handleClose = () => {
        setAnchorEl(null);
    };

    return (
        <React.Fragment>
            <Tooltip title="Mensajes">
              <IconButton onClick={handleClick} size="small" sx={{ color: 'inherit' }}>
                <Badge badgeContent={unreadCount} color="info" max={99}>
                    <MailOutlineIcon />
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
                    sx: { width: 340, maxHeight: 500, mt: 1.5 },
                }}
            >
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', px: 2, py: 1 }}>
                    <Typography variant="subtitle1" fontWeight="bold">
                        Mensajes
                    </Typography>
                </Box>
                <Divider />
                <List sx={{ p: 0 }}>
                    {messages.map((msg) => (
                        <ListItem
                            key={msg.id}
                            sx={{
                                cursor: 'pointer',
                                bgcolor: msg.unread ? 'action.hover' : 'transparent',
                                '&:hover': { bgcolor: 'action.selected' }
                            }}
                            onClick={async () => {
                                if (msg.unread) {
                                    try {
                                        await apiPatch(`/v1/sistema/mensajes/${msg.id}/leido`, {});
                                    } catch (e) { }
                                    setMessages(messages.map(m => m.id === msg.id ? { ...m, unread: false } : m));
                                }
                            }}
                        >
                            <ListItemAvatar>
                                <Avatar src={msg.avatar}>
                                    {msg.sender.charAt(0)}
                                </Avatar>
                            </ListItemAvatar>
                            <ListItemText
                                primary={
                                    <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                                        <Typography variant="subtitle2" component="span" fontWeight={msg.unread ? 'bold' : 'normal'}>
                                            {msg.sender}
                                        </Typography>
                                        <Typography variant="caption" color="text.secondary">
                                            {msg.time}
                                        </Typography>
                                    </Box>
                                }
                                secondary={
                                    <Typography variant="body2" color={msg.unread ? "text.primary" : "text.secondary"} noWrap>
                                        {msg.subject}
                                    </Typography>
                                }
                            />
                        </ListItem>
                    ))}
                </List>
                <Divider />
                <Box sx={{ p: 1, textAlign: 'center' }}>
                    <Button
                        fullWidth
                        size="small"
                        sx={{ textTransform: 'none' }}
                        onClick={() => { handleClose(); router.push('/notificaciones?tab=mensajes'); }}
                    >
                        Ver todos los mensajes
                    </Button>
                </Box>
            </Menu>
        </React.Fragment>
    );
}
