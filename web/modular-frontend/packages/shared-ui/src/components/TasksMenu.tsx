import React, { useState } from 'react';
import {
    IconButton, Badge, Menu, Typography, Box, Divider, Button,
    List, ListItem, ListItemText, Checkbox, LinearProgress
} from '@mui/material';
import FormatListBulletedIcon from '@mui/icons-material/FormatListBulleted';
import AssignmentIcon from '@mui/icons-material/Assignment';
import CheckCircleOutlineIcon from '@mui/icons-material/CheckCircleOutline';
import RadioButtonUncheckedIcon from '@mui/icons-material/RadioButtonUnchecked';
import { apiGet, apiPatch } from '@datqbox/shared-api';

type Task = {
    id: string;
    title: string;
    progress: number;
    color: 'primary' | 'secondary' | 'error' | 'info' | 'success' | 'warning';
    dueDate?: string;
};

export default function TasksMenu() {
    const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
    const [tasks, setTasks] = useState<Task[]>([]);

    React.useEffect(() => {
        const fetchTasks = async () => {
            try {
                const data = await apiGet('/v1/sistema/tareas');
                if (data?.data) setTasks(data.data);
            } catch (e) { }
        };
        fetchTasks();
        const interval = setInterval(fetchTasks, 60000); // 1 min update
        return () => clearInterval(interval);
    }, []);

    const open = Boolean(anchorEl);
    const pendingTasks = tasks.filter(t => t.progress < 100).length;

    const handleClick = (event: React.MouseEvent<HTMLElement>) => {
        setAnchorEl(event.currentTarget);
    };

    const handleClose = () => {
        setAnchorEl(null);
    };

    return (
        <React.Fragment>
            <IconButton onClick={handleClick} size="small" sx={{ color: 'inherit' }}>
                <Badge badgeContent={pendingTasks} color="warning" max={9}>
                    <FormatListBulletedIcon />
                </Badge>
            </IconButton>
            <Menu
                anchorEl={anchorEl}
                open={open}
                onClose={handleClose}
                transformOrigin={{ horizontal: 'right', vertical: 'top' }}
                anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
                PaperProps={{
                    sx: { width: 320, maxHeight: 500, mt: 1.5 },
                }}
            >
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', px: 2, py: 1 }}>
                    <Typography variant="subtitle1" fontWeight="bold">
                        Tienes {pendingTasks} tareas pendientes
                    </Typography>
                </Box>
                <Divider />
                <List sx={{ p: 0 }}>
                    {tasks.map((task) => (
                        <ListItem
                            key={task.id}
                            sx={{
                                cursor: 'pointer',
                                '&:hover': { bgcolor: 'action.hover' },
                                flexDirection: 'column',
                                alignItems: 'flex-start'
                            }}
                            onClick={async () => {
                                const newProgress = task.progress === 100 ? 0 : 100;
                                try {
                                    await apiPatch(`/v1/sistema/tareas/${task.id}/progreso`, { progress: newProgress });
                                } catch (e) { }
                                setTasks(tasks.map(t => t.id === task.id ? { ...t, progress: newProgress } : t));
                            }}
                        >
                            <Box sx={{ width: '100%', display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                                <Typography variant="body2" sx={{ fontWeight: 500 }}>
                                    {task.title}
                                </Typography>
                                <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 'bold' }}>
                                    {task.progress}%
                                </Typography>
                            </Box>
                            <Box sx={{ width: '100%', display: 'flex', alignItems: 'center' }}>
                                <LinearProgress
                                    variant="determinate"
                                    value={task.progress}
                                    color={task.color}
                                    sx={{ width: '100%', mr: 1, borderRadius: 1 }}
                                />
                            </Box>
                        </ListItem>
                    ))}
                </List>
                <Divider />
                <Box sx={{ p: 1, textAlign: 'center' }}>
                    <Button fullWidth size="small" sx={{ textTransform: 'none' }}>
                        Ver todas las tareas
                    </Button>
                </Box>
            </Menu>
        </React.Fragment>
    );
}
