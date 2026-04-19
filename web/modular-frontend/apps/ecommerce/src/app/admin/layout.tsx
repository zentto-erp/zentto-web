'use client';

import {
    Box, AppBar, Toolbar, Typography, IconButton, Button,
    Drawer, List, ListItem, ListItemButton, ListItemIcon, ListItemText, Divider,
} from '@mui/material';
import DashboardIcon from '@mui/icons-material/Dashboard';
import AssignmentReturnIcon from '@mui/icons-material/AssignmentReturn';
import SpeedIcon from '@mui/icons-material/Speed';
import StoreIcon from '@mui/icons-material/Store';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import { usePathname, useRouter } from 'next/navigation';

const DRAWER_WIDTH = 220;

const NAV_ITEMS = [
    { label: 'Dashboard', href: '/admin/dashboard', icon: <DashboardIcon /> },
    { label: 'Devoluciones', href: '/admin/devoluciones', icon: <AssignmentReturnIcon /> },
    { label: 'Performance', href: '/admin/perf', icon: <SpeedIcon /> },
];

export default function AdminLayout({ children }: { children: React.ReactNode }) {
    const router = useRouter();
    const pathname = usePathname();

    return (
        <Box sx={{ display: 'flex', minHeight: '100vh' }}>
            <AppBar position="fixed" sx={{ zIndex: 1300, bgcolor: '#131921', width: `calc(100% - ${DRAWER_WIDTH}px)`, ml: `${DRAWER_WIDTH}px` }}>
                <Toolbar sx={{ gap: 1 }}>
                    <StoreIcon sx={{ color: '#ff9900' }} />
                    <Typography variant="h6" fontWeight={700} sx={{ flex: 1 }}>
                        Zentto<span style={{ color: '#ff9900' }}>Store</span> Admin
                    </Typography>
                    <Button
                        startIcon={<ArrowBackIcon />}
                        color="inherit"
                        size="small"
                        onClick={() => router.push('/')}
                        sx={{ textTransform: 'none', fontSize: 13 }}
                    >
                        Volver al store
                    </Button>
                </Toolbar>
            </AppBar>

            <Drawer
                variant="permanent"
                sx={{
                    width: DRAWER_WIDTH,
                    flexShrink: 0,
                    '& .MuiDrawer-paper': { width: DRAWER_WIDTH, boxSizing: 'border-box', bgcolor: '#232f3e', color: '#fff' },
                }}
            >
                <Toolbar sx={{ bgcolor: '#131921' }}>
                    <Typography variant="subtitle2" fontWeight={700} sx={{ color: '#ff9900', fontSize: 12 }}>
                        PANEL ADMINISTRATIVO
                    </Typography>
                </Toolbar>
                <Divider sx={{ bgcolor: '#37475a' }} />
                <List dense>
                    {NAV_ITEMS.map((item) => {
                        const active = pathname === item.href;
                        return (
                            <ListItem key={item.href} disablePadding>
                                <ListItemButton
                                    onClick={() => router.push(item.href)}
                                    selected={active}
                                    sx={{
                                        color: '#fff',
                                        '&.Mui-selected': { bgcolor: '#37475a', color: '#ff9900' },
                                        '&:hover': { bgcolor: '#37475a' },
                                    }}
                                >
                                    <ListItemIcon sx={{ color: 'inherit', minWidth: 36 }}>{item.icon}</ListItemIcon>
                                    <ListItemText primary={item.label} primaryTypographyProps={{ fontSize: 13 }} />
                                </ListItemButton>
                            </ListItem>
                        );
                    })}
                </List>
            </Drawer>

            <Box component="main" sx={{ flexGrow: 1, p: 3, mt: 8, bgcolor: '#f5f5f5', minHeight: '100vh' }}>
                {children}
            </Box>
        </Box>
    );
}
