'use client';

import {
    Box, AppBar, Toolbar, Typography, IconButton, Button,
    Drawer, List, ListItem, ListItemButton, ListItemIcon, ListItemText, Divider,
    Accordion, AccordionSummary, AccordionDetails,
} from '@mui/material';
import DashboardIcon from '@mui/icons-material/Dashboard';
import AssignmentReturnIcon from '@mui/icons-material/AssignmentReturn';
import SpeedIcon from '@mui/icons-material/Speed';
import StoreIcon from '@mui/icons-material/Store';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import Inventory2Icon from '@mui/icons-material/Inventory2';
import CategoryIcon from '@mui/icons-material/Category';
import LabelIcon from '@mui/icons-material/Label';
import RateReviewIcon from '@mui/icons-material/RateReview';
import ShoppingCartIcon from '@mui/icons-material/ShoppingCart';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import CachedIcon from '@mui/icons-material/Cached';
import { usePathname, useRouter } from 'next/navigation';

const DRAWER_WIDTH = 240;

interface NavItem { label: string; href: string; icon: React.ReactNode; }
interface NavSection { id: string; label: string; items: NavItem[]; }

const NAV_SECTIONS: NavSection[] = [
    {
        id: 'ventas',
        label: 'Ventas',
        items: [
            { label: 'Dashboard', href: '/admin/dashboard', icon: <DashboardIcon fontSize="small" /> },
            { label: 'Devoluciones', href: '/admin/devoluciones', icon: <AssignmentReturnIcon fontSize="small" /> },
        ],
    },
    {
        id: 'catalogo',
        label: 'Catálogo',
        items: [
            { label: 'Productos', href: '/admin/productos', icon: <Inventory2Icon fontSize="small" /> },
            { label: 'Categorías', href: '/admin/categorias', icon: <CategoryIcon fontSize="small" /> },
            { label: 'Marcas', href: '/admin/marcas', icon: <LabelIcon fontSize="small" /> },
        ],
    },
    {
        id: 'contenido',
        label: 'Contenido',
        items: [
            { label: 'Reseñas', href: '/admin/reviews', icon: <RateReviewIcon fontSize="small" /> },
        ],
    },
    {
        id: 'sistema',
        label: 'Sistema',
        items: [
            { label: 'Performance', href: '/admin/perf', icon: <SpeedIcon fontSize="small" /> },
        ],
    },
];

export default function AdminLayout({ children }: { children: React.ReactNode }) {
    const router = useRouter();
    const pathname = usePathname();

    const defaultExpanded = NAV_SECTIONS.find((s) => s.items.some((i) => pathname.startsWith(i.href)))?.id
        ?? 'ventas';

    return (
        <Box sx={{ display: 'flex', minHeight: '100vh' }}>
            <AppBar
                position="fixed"
                sx={{
                    zIndex: 1300,
                    bgcolor: '#131921',
                    width: `calc(100% - ${DRAWER_WIDTH}px)`,
                    ml: `${DRAWER_WIDTH}px`,
                }}
            >
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
                    '& .MuiDrawer-paper': {
                        width: DRAWER_WIDTH,
                        boxSizing: 'border-box',
                        bgcolor: '#232f3e',
                        color: '#fff',
                    },
                }}
            >
                <Toolbar sx={{ bgcolor: '#131921' }}>
                    <Typography variant="subtitle2" fontWeight={700} sx={{ color: '#ff9900', fontSize: 12 }}>
                        PANEL ADMINISTRATIVO
                    </Typography>
                </Toolbar>
                <Divider sx={{ bgcolor: '#37475a' }} />

                <Box sx={{ overflowY: 'auto' }}>
                    {NAV_SECTIONS.map((section) => (
                        <Accordion
                            key={section.id}
                            defaultExpanded={section.id === defaultExpanded}
                            disableGutters
                            square
                            elevation={0}
                            sx={{
                                bgcolor: 'transparent',
                                color: '#fff',
                                '&:before': { display: 'none' },
                                borderBottom: '1px solid #37475a',
                            }}
                        >
                            <AccordionSummary
                                expandIcon={<ExpandMoreIcon sx={{ color: '#aab7c4' }} />}
                                sx={{
                                    minHeight: 40,
                                    '& .MuiAccordionSummary-content': { my: 0.5 },
                                    '&:hover': { bgcolor: '#37475a' },
                                }}
                            >
                                <Typography
                                    variant="caption"
                                    sx={{
                                        fontWeight: 700,
                                        letterSpacing: 0.8,
                                        textTransform: 'uppercase',
                                        color: '#ff9900',
                                    }}
                                >
                                    {section.label}
                                </Typography>
                            </AccordionSummary>
                            <AccordionDetails sx={{ p: 0 }}>
                                <List dense disablePadding>
                                    {section.items.map((item) => {
                                        const active = pathname === item.href || pathname.startsWith(item.href + '/');
                                        return (
                                            <ListItem key={item.href} disablePadding>
                                                <ListItemButton
                                                    onClick={() => router.push(item.href)}
                                                    selected={active}
                                                    sx={{
                                                        pl: 3,
                                                        color: '#fff',
                                                        '&.Mui-selected': { bgcolor: '#37475a', color: '#ff9900' },
                                                        '&:hover': { bgcolor: '#37475a' },
                                                    }}
                                                >
                                                    <ListItemIcon sx={{ color: 'inherit', minWidth: 32 }}>
                                                        {item.icon}
                                                    </ListItemIcon>
                                                    <ListItemText
                                                        primary={item.label}
                                                        primaryTypographyProps={{ fontSize: 13 }}
                                                    />
                                                </ListItemButton>
                                            </ListItem>
                                        );
                                    })}
                                </List>
                            </AccordionDetails>
                        </Accordion>
                    ))}
                </Box>
            </Drawer>

            <Box
                component="main"
                sx={{ flexGrow: 1, p: 3, mt: 8, bgcolor: '#f5f5f5', minHeight: '100vh' }}
            >
                {children}
            </Box>
        </Box>
    );
}
