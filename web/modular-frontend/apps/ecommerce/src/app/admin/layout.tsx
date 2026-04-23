'use client';

/**
 * Admin layout — estilo ZenttoLayout (@zentto/shared-ui).
 *
 * Sigue el mismo patron visual que el resto del ERP:
 *   - Sidebar 260px full / 72px mini (toggle con boton)
 *   - Drawer temporary en mobile (<md), permanent en desktop
 *   - AppBar limpio con breadcrumbs + chip de empresa
 *   - Item activo: indicador izquierdo + bg naranja translucido
 *   - Acordeones por seccion con expand/collapse
 */

import {
    Box, Toolbar, Typography, Chip, Drawer, List, ListItem,
    ListItemIcon, ListItemText, Collapse, IconButton, Tooltip,
    Menu, MenuItem, Button, Avatar, useMediaQuery, useTheme,
} from '@mui/material';
import DashboardIcon from '@mui/icons-material/Dashboard';
import AssignmentReturnIcon from '@mui/icons-material/AssignmentReturn';
import SpeedIcon from '@mui/icons-material/Speed';
import StoreIcon from '@mui/icons-material/Store';
import ArticleIcon from '@mui/icons-material/Article';
import NewspaperIcon from '@mui/icons-material/Newspaper';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import Inventory2Icon from '@mui/icons-material/Inventory2';
import CategoryIcon from '@mui/icons-material/Category';
import LabelIcon from '@mui/icons-material/Label';
import RateReviewIcon from '@mui/icons-material/RateReview';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import ExpandLessIcon from '@mui/icons-material/ExpandLess';
import MonetizationOnIcon from '@mui/icons-material/MonetizationOn';
import StorefrontIcon from '@mui/icons-material/Storefront';
import ReceiptLongIcon from '@mui/icons-material/ReceiptLong';
import FactCheckIcon from '@mui/icons-material/FactCheck';
import MenuOutlinedIcon from '@mui/icons-material/MenuOutlined';
import MenuOpenOutlinedIcon from '@mui/icons-material/MenuOpenOutlined';
import LogoutIcon from '@mui/icons-material/Logout';
import BusinessIcon from '@mui/icons-material/Business';
import { usePathname, useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { useAdminReviewsList, useAdminLogout, useAdminAuthStore } from '@zentto/module-ecommerce';
import type { CompanyAccess } from '@zentto/module-ecommerce';

const FULL_SIDEBAR_WIDTH = 260;
const MINI_SIDEBAR_WIDTH = 72;
const ACCENT = '#ff9900';

interface NavItem {
    label: string;
    href: string;
    icon: React.ReactNode;
    badge?: number | null | ((counts: BadgeCounts) => number | null);
}
interface NavSection { id: string; label: string; items: NavItem[]; }

interface BadgeCounts {
    reviewsPending: number;
    returnsPending: number;
}

const NAV_SECTIONS: NavSection[] = [
    {
        id: 'ventas',
        label: 'Ventas',
        items: [
            { label: 'Dashboard', href: '/admin/dashboard', icon: <DashboardIcon fontSize="small" /> },
            {
                label: 'Devoluciones',
                href: '/admin/devoluciones',
                icon: <AssignmentReturnIcon fontSize="small" />,
                badge: (c) => c.returnsPending || null,
            },
        ],
    },
    {
        id: 'catalogo',
        label: 'Catalogo',
        items: [
            { label: 'Productos', href: '/admin/productos', icon: <Inventory2Icon fontSize="small" /> },
            { label: 'Categorias', href: '/admin/categorias', icon: <CategoryIcon fontSize="small" /> },
            { label: 'Marcas', href: '/admin/marcas', icon: <LabelIcon fontSize="small" /> },
        ],
    },
    {
        id: 'marketplace',
        label: 'Marketplace',
        items: [
            { label: 'Afiliados', href: '/admin/afiliados', icon: <MonetizationOnIcon fontSize="small" /> },
            { label: 'Comisiones', href: '/admin/afiliados/comisiones', icon: <ReceiptLongIcon fontSize="small" /> },
            { label: 'Vendedores', href: '/admin/vendedores', icon: <StorefrontIcon fontSize="small" /> },
            { label: 'Productos marketplace', href: '/admin/vendedores/productos', icon: <FactCheckIcon fontSize="small" /> },
        ],
    },
    {
        id: 'contenido',
        label: 'Contenido',
        items: [
            {
                label: 'Resenas',
                href: '/admin/reviews',
                icon: <RateReviewIcon fontSize="small" />,
                badge: (c) => c.reviewsPending || null,
            },
            { label: 'CMS Pages', href: '/admin/cms', icon: <ArticleIcon fontSize="small" /> },
            { label: 'Press Releases', href: '/admin/prensa', icon: <NewspaperIcon fontSize="small" /> },
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

function OrangeBadge({ count }: { count: number }) {
    return (
        <Chip
            size="small"
            label={count}
            sx={{
                bgcolor: ACCENT,
                color: '#0f1111',
                height: 18,
                fontSize: 11,
                fontWeight: 700,
                ml: 1,
                '& .MuiChip-label': { px: 0.8 },
            }}
        />
    );
}

function AdminShell({ children }: { children: React.ReactNode }) {
    const router = useRouter();
    const pathname = usePathname();
    const theme = useTheme();
    const isMobile = useMediaQuery(theme.breakpoints.down('md'));

    const adminUser = useAdminAuthStore((s) => s.user);
    const companyAccesses = useAdminAuthStore((s) => s.companyAccesses);
    const activeCompanyId = useAdminAuthStore((s) => s.activeCompanyId);
    const setActiveCompany = useAdminAuthStore((s) => s.setActiveCompany);
    const logout = useAdminLogout();

    const { data: reviewsPending } = useAdminReviewsList({ status: 'pending', limit: 1 });
    const counts: BadgeCounts = {
        reviewsPending: Number(reviewsPending?.total ?? 0),
        returnsPending: 0,
    };

    const [sidebarOpen, setSidebarOpen] = useState(!isMobile);
    const [openSections, setOpenSections] = useState<Record<string, boolean>>({});
    const [companyMenuAnchor, setCompanyMenuAnchor] = useState<HTMLElement | null>(null);
    const [userMenuAnchor, setUserMenuAnchor] = useState<HTMLElement | null>(null);

    const activeSectionId =
        NAV_SECTIONS.find((s) => s.items.some((i) => pathname === i.href || pathname.startsWith(i.href + '/')))?.id ?? 'ventas';

    useEffect(() => {
        setOpenSections((prev) => ({ ...prev, [activeSectionId]: true }));
    }, [activeSectionId]);

    useEffect(() => {
        if (isMobile) setSidebarOpen(false);
    }, [pathname, isMobile]);

    useEffect(() => {
        setSidebarOpen(!isMobile);
    }, [isMobile]);

    const handleLogout = () => {
        setUserMenuAnchor(null);
        logout();
        router.replace('/admin/login');
    };

    const handleCompanyChange = (companyId: number, branchId: number | null) => {
        setActiveCompany(companyId, branchId);
        setCompanyMenuAnchor(null);
    };

    const toggleSection = (id: string) => {
        setOpenSections((prev) => ({ ...prev, [id]: !prev[id] }));
    };

    const activeCompany = companyAccesses.find((c) => c.companyId === activeCompanyId);
    const companyLabel = activeCompany
        ? `${activeCompany.companyCode}${activeCompany.branchCode ? '/' + activeCompany.branchCode : ''} - ${activeCompany.companyName}`
        : 'Sin empresa';

    const actualSidebarWidth = isMobile ? 0 : (sidebarOpen ? FULL_SIDEBAR_WIDTH : MINI_SIDEBAR_WIDTH);
    const drawerPaperWidth = isMobile ? FULL_SIDEBAR_WIDTH : (sidebarOpen ? FULL_SIDEBAR_WIDTH : MINI_SIDEBAR_WIDTH);

    const renderSidebarContent = () => (
        <>
            <Box sx={{ display: 'flex', alignItems: 'center', px: 1.5, height: 64, minHeight: 64, borderBottom: (t) => `1px solid ${t.palette.divider}` }}>
                <Tooltip title={sidebarOpen ? 'Contraer menu' : 'Expandir menu'}>
                    <Box sx={{ width: 48, minWidth: 48, display: 'flex', justifyContent: 'center' }}>
                        <IconButton
                            onClick={() => setSidebarOpen(!sidebarOpen)}
                            size="small"
                            sx={{ width: 32, height: 32, borderRadius: '6px', color: 'text.secondary' }}
                        >
                            {sidebarOpen ? <MenuOpenOutlinedIcon fontSize="small" /> : <MenuOutlinedIcon fontSize="small" />}
                        </IconButton>
                    </Box>
                </Tooltip>
                <Box sx={{ overflow: 'hidden', maxWidth: sidebarOpen ? 200 : 0, opacity: sidebarOpen ? 1 : 0, transition: 'max-width 0.2s ease, opacity 0.15s ease', whiteSpace: 'nowrap', ml: 1 }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <StoreIcon sx={{ color: ACCENT, fontSize: 22 }} />
                        <Typography variant="subtitle1" fontWeight={700} sx={{ fontSize: '0.95rem' }}>
                            Zentto<span style={{ color: ACCENT }}>Store</span>
                        </Typography>
                    </Box>
                </Box>
            </Box>

            <Box sx={{ overflowY: 'auto', flexGrow: 1, py: 1 }}>
                {NAV_SECTIONS.map((section) => {
                    const isOpen = openSections[section.id] ?? section.id === activeSectionId;
                    return (
                        <Box key={section.id}>
                            {sidebarOpen && (
                                <Box
                                    onClick={() => toggleSection(section.id)}
                                    sx={{
                                        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                                        px: 3, pt: 2, pb: 0.5, cursor: 'pointer',
                                        '&:hover': { bgcolor: 'action.hover' },
                                    }}
                                >
                                    <Typography
                                        variant="caption"
                                        sx={{
                                            fontWeight: 700,
                                            letterSpacing: 0.8,
                                            textTransform: 'uppercase',
                                            color: 'text.secondary',
                                            fontSize: 11,
                                        }}
                                    >
                                        {section.label}
                                    </Typography>
                                    {isOpen ? <ExpandLessIcon fontSize="small" sx={{ color: 'text.disabled' }} /> : <ExpandMoreIcon fontSize="small" sx={{ color: 'text.disabled' }} />}
                                </Box>
                            )}
                            <Collapse in={sidebarOpen ? isOpen : true} timeout="auto" unmountOnExit>
                                <List sx={{ py: 0 }}>
                                    {section.items.map((item) => {
                                        const active = pathname === item.href || pathname.startsWith(item.href + '/');
                                        const badgeVal = typeof item.badge === 'function' ? item.badge(counts) : (item.badge ?? null);
                                        return (
                                            <ListItem key={item.href} disablePadding sx={{ position: 'relative', my: '2px', px: '12px', minHeight: 44 }}>
                                                <Box
                                                    sx={{
                                                        position: 'absolute',
                                                        top: 0, bottom: 0,
                                                        left: 12, right: 12,
                                                        borderRadius: 1.5,
                                                        bgcolor: active ? (t) => t.palette.mode === 'dark' ? 'rgba(255,153,0,0.15)' : 'rgba(255,153,0,0.1)' : 'transparent',
                                                        boxShadow: active ? `inset 4px 0 0 0 ${ACCENT}` : 'none',
                                                        pointerEvents: 'none',
                                                    }}
                                                />
                                                <Box
                                                    onClick={() => router.push(item.href)}
                                                    sx={{
                                                        position: 'relative',
                                                        display: 'flex', alignItems: 'center',
                                                        minHeight: 44, width: '100%',
                                                        cursor: 'pointer',
                                                        color: active ? 'text.primary' : 'text.secondary',
                                                        borderRadius: 1.5,
                                                        '&:hover': {
                                                            bgcolor: active ? (t) => t.palette.mode === 'dark' ? 'rgba(255,153,0,0.25)' : 'rgba(255,153,0,0.15)' : 'action.hover',
                                                        }
                                                    }}
                                                >
                                                    <Tooltip title={!sidebarOpen ? item.label : ''} placement="right" disableHoverListener={sidebarOpen}>
                                                        <ListItemIcon sx={{ minWidth: 48, color: 'inherit', justifyContent: 'center' }}>
                                                            {item.icon}
                                                        </ListItemIcon>
                                                    </Tooltip>
                                                    <Box sx={{ overflow: 'hidden', maxWidth: sidebarOpen ? 200 : 0, opacity: sidebarOpen ? 1 : 0, transition: 'max-width 0.2s ease, opacity 0.15s ease', display: 'flex', alignItems: 'center', flexGrow: 1, whiteSpace: 'nowrap' }}>
                                                        <ListItemText
                                                            primary={item.label}
                                                            primaryTypographyProps={{ fontSize: '0.88rem', fontWeight: active ? 600 : 400, whiteSpace: 'nowrap' }}
                                                        />
                                                        {badgeVal && badgeVal > 0 ? <OrangeBadge count={badgeVal} /> : null}
                                                    </Box>
                                                </Box>
                                            </ListItem>
                                        );
                                    })}
                                </List>
                            </Collapse>
                        </Box>
                    );
                })}
            </Box>
        </>
    );

    return (
        <Box sx={{ display: 'flex', height: '100vh', width: '100vw', overflow: 'hidden', bgcolor: 'background.default' }}>
            <Drawer
                variant={isMobile ? 'temporary' : 'permanent'}
                open={sidebarOpen}
                onClose={() => setSidebarOpen(false)}
                ModalProps={{ keepMounted: true }}
                sx={{
                    width: drawerPaperWidth,
                    flexShrink: 0,
                    transition: 'width 0.2s',
                    '& .MuiDrawer-paper': {
                        width: drawerPaperWidth,
                        boxSizing: 'border-box',
                        borderRight: (t) => `1px solid ${t.palette.divider}`,
                        backgroundColor: 'background.paper',
                        color: 'text.primary',
                        boxShadow: isMobile ? '4px 0 20px rgba(0,0,0,0.3)' : 'none',
                        transition: 'width 0.2s',
                        overflowX: 'hidden',
                    },
                }}
            >
                {renderSidebarContent()}
            </Drawer>

            <Box sx={{ display: 'flex', flexDirection: 'column', flexGrow: 1, width: `calc(100% - ${actualSidebarWidth}px)`, transition: 'width 0.2s', minWidth: 0 }}>
                <Box component="header" sx={{ backgroundColor: 'background.paper', color: 'text.primary' }}>
                    <Toolbar variant="dense" sx={{ height: 64, minHeight: 64, maxHeight: 64, px: { xs: 1.5, sm: 3 }, display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: (t) => `1px solid ${t.palette.divider}`, gap: 1 }}>
                        <Box sx={{ display: 'flex', alignItems: 'center', minWidth: 0, flexGrow: 1 }}>
                            {isMobile && (
                                <IconButton
                                    onClick={() => setSidebarOpen(true)}
                                    size="small"
                                    sx={{ width: 32, height: 32, borderRadius: '6px', mr: 1, color: 'text.secondary' }}
                                    aria-label="Abrir menu"
                                >
                                    <MenuOutlinedIcon fontSize="small" />
                                </IconButton>
                            )}
                            <Typography variant="body2" sx={{ color: 'text.secondary', display: { xs: 'none', sm: 'flex' }, alignItems: 'center', gap: 1, minWidth: 0 }}>
                                <Typography component="span" sx={{ color: ACCENT, fontWeight: 600, cursor: 'pointer' }} onClick={() => router.push('/')}>
                                    Store
                                </Typography>
                                <span>/</span>
                                <Typography component="span" sx={{ fontWeight: 500, textTransform: 'capitalize', color: 'text.primary', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: 300 }}>
                                    {(pathname || '').replace('/admin/', '').replace(/\//g, ' / ') || 'Admin'}
                                </Typography>
                            </Typography>
                            <Box sx={{ display: { xs: 'flex', sm: 'none' }, alignItems: 'center', gap: 0.5 }}>
                                <StoreIcon sx={{ color: ACCENT, fontSize: 20 }} />
                                <Typography variant="subtitle2" fontWeight={700} sx={{ fontSize: '0.9rem' }}>
                                    Store
                                </Typography>
                            </Box>
                            <Box sx={{ ml: 2, display: { xs: 'none', md: 'flex' }, gap: 1, minWidth: 0 }}>
                                <Chip
                                    size="small"
                                    icon={<BusinessIcon sx={{ fontSize: 14 }} />}
                                    label={companyLabel}
                                    onClick={(e) => {
                                        if (companyAccesses.length > 1) setCompanyMenuAnchor(e.currentTarget);
                                    }}
                                    sx={{
                                        bgcolor: ACCENT, color: '#0f1111', fontWeight: 600, fontSize: '0.72rem',
                                        cursor: companyAccesses.length > 1 ? 'pointer' : 'default',
                                        maxWidth: 280,
                                        '& .MuiChip-label': { overflow: 'hidden', textOverflow: 'ellipsis' },
                                    }}
                                />
                            </Box>
                        </Box>

                        <Box sx={{ display: 'flex', alignItems: 'center', gap: { xs: 0.5, sm: 1 } }}>
                            <Button
                                startIcon={<ArrowBackIcon />}
                                size="small"
                                onClick={() => router.push('/')}
                                sx={{ textTransform: 'none', fontSize: 13, display: { xs: 'none', md: 'inline-flex' }, color: 'text.secondary' }}
                            >
                                Volver al store
                            </Button>
                            <IconButton
                                onClick={(e) => setUserMenuAnchor(e.currentTarget)}
                                size="small"
                                sx={{ ml: 0.5 }}
                                aria-label="Cuenta"
                            >
                                <Avatar sx={{ width: 30, height: 30, bgcolor: ACCENT, color: '#0f1111', fontSize: '0.8rem', fontWeight: 700 }}>
                                    {(adminUser?.name ?? 'A').charAt(0).toUpperCase()}
                                </Avatar>
                            </IconButton>
                        </Box>

                        <Menu
                            anchorEl={companyMenuAnchor}
                            open={Boolean(companyMenuAnchor)}
                            onClose={() => setCompanyMenuAnchor(null)}
                            slotProps={{ paper: { sx: { minWidth: 280 } } }}
                        >
                            {companyAccesses.map((c: CompanyAccess, idx) => (
                                <MenuItem
                                    key={idx}
                                    selected={c.companyId === activeCompanyId}
                                    onClick={() => handleCompanyChange(c.companyId, c.branchId ?? null)}
                                >
                                    <Box>
                                        <Typography variant="body2" fontWeight={600}>
                                            {c.companyCode}{c.branchCode ? '/' + c.branchCode : ''} - {c.companyName}
                                        </Typography>
                                        {c.branchName && (
                                            <Typography variant="caption" color="text.secondary">
                                                {c.branchName} . {c.countryCode}
                                            </Typography>
                                        )}
                                    </Box>
                                </MenuItem>
                            ))}
                        </Menu>

                        <Menu
                            anchorEl={userMenuAnchor}
                            open={Boolean(userMenuAnchor)}
                            onClose={() => setUserMenuAnchor(null)}
                            slotProps={{ paper: { sx: { minWidth: 220 } } }}
                        >
                            <Box sx={{ px: 2, py: 1 }}>
                                <Typography variant="body2" fontWeight={600}>{adminUser?.name || 'Administrador'}</Typography>
                                {adminUser?.email && (
                                    <Typography variant="caption" color="text.secondary">{adminUser.email}</Typography>
                                )}
                            </Box>
                            {companyAccesses.length > 1 && (
                                <MenuItem onClick={(e) => { setUserMenuAnchor(null); setCompanyMenuAnchor(e.currentTarget); }}>
                                    <BusinessIcon fontSize="small" sx={{ mr: 1 }} /> Cambiar empresa
                                </MenuItem>
                            )}
                            <MenuItem onClick={() => { setUserMenuAnchor(null); router.push('/'); }}>
                                <ArrowBackIcon fontSize="small" sx={{ mr: 1 }} /> Volver al store
                            </MenuItem>
                            <MenuItem onClick={handleLogout} sx={{ color: 'error.main' }}>
                                <LogoutIcon fontSize="small" sx={{ mr: 1 }} /> Salir
                            </MenuItem>
                        </Menu>
                    </Toolbar>
                </Box>

                <Box component="main" sx={{ flexGrow: 1, minHeight: 0, overflow: 'auto', bgcolor: 'background.default', p: { xs: 1.5, sm: 2, md: 3 } }}>
                    {children}
                </Box>
            </Box>
        </Box>
    );
}

export default function AdminLayout({ children }: { children: React.ReactNode }) {
    const router = useRouter();
    const pathname = usePathname();
    const adminToken = useAdminAuthStore((s) => s.token);
    const [hydrated, setHydrated] = useState(false);

    useEffect(() => { setHydrated(true); }, []);

    useEffect(() => {
        if (!hydrated) return;
        if (pathname === '/admin/login') return;
        if (!adminToken) router.replace('/admin/login');
    }, [hydrated, adminToken, pathname, router]);

    if (!hydrated) return null;
    if (pathname === '/admin/login') return <>{children}</>;
    if (!adminToken) return null;

    return <AdminShell>{children}</AdminShell>;
}
