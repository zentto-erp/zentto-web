'use client';

/**
 * Admin layout — sidebar con acordeones por sección.
 *
 * Designer Ola 2 specs:
 *   - Orden de secciones: Ventas → Catálogo → Contenido → Sistema
 *   - Badges naranja con count pending (reviews, devoluciones) desde la API.
 *   - Item activo: bg #37475a + color #ff9900.
 *   - Persistencia estado acordeón en localStorage (`zentto_admin_sidebar_<section>`).
 *   - Auto-expand de la sección activa al cargar según `pathname`.
 */

import {
    Box, AppBar, Toolbar, Typography, Button, Chip, IconButton,
    Drawer, List, ListItem, ListItemButton, ListItemIcon, ListItemText, Divider,
    Accordion, AccordionSummary, AccordionDetails,
    Select, MenuItem as MuiMenuItem, FormControl, Tooltip,
    useMediaQuery, useTheme,
} from '@mui/material';
import MenuIcon from '@mui/icons-material/Menu';
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
import MonetizationOnIcon from '@mui/icons-material/MonetizationOn';
import StorefrontIcon from '@mui/icons-material/Storefront';
import ReceiptLongIcon from '@mui/icons-material/ReceiptLong';
import FactCheckIcon from '@mui/icons-material/FactCheck';
import { usePathname, useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { useAdminReviewsList, useAdminLogout, useAdminAuthStore } from '@zentto/module-ecommerce';
import type { CompanyAccess } from '@zentto/module-ecommerce';
import LogoutIcon from '@mui/icons-material/Logout';
import BusinessIcon from '@mui/icons-material/Business';

const DRAWER_WIDTH = 240;

interface NavItem {
    label: string;
    href: string;
    icon: React.ReactNode;
    /** Si es función, se evalúa cada render con los contadores pending. */
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
        label: 'Catálogo',
        items: [
            { label: 'Productos', href: '/admin/productos', icon: <Inventory2Icon fontSize="small" /> },
            { label: 'Categorías', href: '/admin/categorias', icon: <CategoryIcon fontSize="small" /> },
            { label: 'Marcas', href: '/admin/marcas', icon: <LabelIcon fontSize="small" /> },
        ],
    },
    {
        id: 'marketplace',
        label: 'Marketplace',
        items: [
            { label: 'Afiliados',              href: '/admin/afiliados',              icon: <MonetizationOnIcon fontSize="small" /> },
            { label: 'Comisiones',             href: '/admin/afiliados/comisiones',   icon: <ReceiptLongIcon fontSize="small" /> },
            { label: 'Vendedores',             href: '/admin/vendedores',             icon: <StorefrontIcon fontSize="small" /> },
            { label: 'Productos marketplace',  href: '/admin/vendedores/productos',   icon: <FactCheckIcon fontSize="small" /> },
        ],
    },
    {
        id: 'contenido',
        label: 'Contenido',
        items: [
            {
                label: 'Reseñas',
                href: '/admin/reviews',
                icon: <RateReviewIcon fontSize="small" />,
                badge: (c) => c.reviewsPending || null,
            },
            { label: 'CMS Pages',      href: '/admin/cms',    icon: <ArticleIcon fontSize="small" /> },
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

const storageKey = (section: string) => `zentto_admin_sidebar_${section}`;

function readStoredState(sectionId: string): boolean | null {
    if (typeof window === 'undefined') return null;
    const v = window.localStorage.getItem(storageKey(sectionId));
    if (v === 'open') return true;
    if (v === 'closed') return false;
    return null;
}

function OrangeBadge({ count }: { count: number }) {
    return (
        <Chip
            size="small"
            label={count}
            sx={{
                bgcolor: '#ff9900',
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

// Componente interno que solo monta cuando el admin está autenticado.
// Extrae todos los hooks que necesitan auth para no violar Rules of Hooks.
function AdminShell({ children }: { children: React.ReactNode }) {
    const router = useRouter();
    const pathname = usePathname();
    const theme = useTheme();
    const isMobile = useMediaQuery(theme.breakpoints.down('md'));
    const [mobileOpen, setMobileOpen] = useState(false);
    const adminUser        = useAdminAuthStore((s) => s.user);
    const companyAccesses  = useAdminAuthStore((s) => s.companyAccesses);
    const activeCompanyId  = useAdminAuthStore((s) => s.activeCompanyId);
    const setActiveCompany = useAdminAuthStore((s) => s.setActiveCompany);
    const logout           = useAdminLogout();

    // Cerrar drawer al navegar en mobile
    useEffect(() => {
        if (isMobile) setMobileOpen(false);
    }, [pathname, isMobile]);

    const { data: reviewsPending } = useAdminReviewsList({ status: 'pending', limit: 1 });
    const counts: BadgeCounts = {
        reviewsPending: Number(reviewsPending?.total ?? 0),
        returnsPending: 0,
    };

    const handleLogout = () => {
        logout();
        router.replace('/admin/login');
    };

    const handleCompanyChange = (companyId: number) => {
        const access = companyAccesses.find((c) => c.companyId === companyId);
        if (access) setActiveCompany(access.companyId, access.branchId ?? null);
    };

    const activeSectionId =
        NAV_SECTIONS.find((s) => s.items.some((i) => pathname.startsWith(i.href)))?.id ?? 'ventas';

    // Estado por acordeón con hidratación idempotente desde localStorage.
    const [expandedMap, setExpandedMap] = useState<Record<string, boolean>>({});

    useEffect(() => {
        const init: Record<string, boolean> = {};
        for (const s of NAV_SECTIONS) {
            const stored = readStoredState(s.id);
            init[s.id] = stored ?? s.id === activeSectionId;
        }
        setExpandedMap(init);
    }, [activeSectionId]);

    const handleExpandChange = (sectionId: string) => (_: unknown, expanded: boolean) => {
        setExpandedMap((prev) => ({ ...prev, [sectionId]: expanded }));
        if (typeof window !== 'undefined') {
            window.localStorage.setItem(storageKey(sectionId), expanded ? 'open' : 'closed');
        }
    };

    return (
        <Box sx={{ display: 'flex', minHeight: '100vh' }}>
            <AppBar
                position="fixed"
                sx={{
                    zIndex: 1300,
                    bgcolor: '#131921',
                    width: { xs: '100%', md: `calc(100% - ${DRAWER_WIDTH}px)` },
                    ml: { xs: 0, md: `${DRAWER_WIDTH}px` },
                }}
            >
                <Toolbar sx={{ gap: 1 }}>
                    <IconButton
                        color="inherit"
                        edge="start"
                        onClick={() => setMobileOpen((o) => !o)}
                        sx={{ display: { xs: 'inline-flex', md: 'none' }, mr: 0.5 }}
                        aria-label="Abrir menu"
                    >
                        <MenuIcon />
                    </IconButton>
                    <StoreIcon sx={{ color: '#ff9900' }} />
                    <Typography variant="h6" fontWeight={700} sx={{ flex: 1 }}>
                        Zentto<span style={{ color: '#ff9900' }}>Store</span> Admin
                    </Typography>

                    {/* Selector multi-empresa — visible solo cuando hay más de 1 empresa */}
                    {companyAccesses.length > 1 && (
                        <Tooltip title="Empresa activa">
                            <FormControl size="small" sx={{ minWidth: 180 }}>
                                <Select
                                    value={activeCompanyId ?? ''}
                                    onChange={(e) => handleCompanyChange(Number(e.target.value))}
                                    displayEmpty
                                    startAdornment={<BusinessIcon sx={{ color: '#aab7c4', fontSize: 16, mr: 0.5 }} />}
                                    sx={{
                                        color: '#fff',
                                        fontSize: 13,
                                        '.MuiOutlinedInput-notchedOutline': { borderColor: '#37475a' },
                                        '&:hover .MuiOutlinedInput-notchedOutline': { borderColor: '#ff9900' },
                                        '.MuiSvgIcon-root': { color: '#aab7c4' },
                                        bgcolor: '#1a2634',
                                    }}
                                >
                                    {companyAccesses.map((c: CompanyAccess) => (
                                        <MuiMenuItem key={c.companyId} value={c.companyId}>
                                            <Box>
                                                <Typography variant="body2" fontWeight={600} lineHeight={1.2}>
                                                    {c.companyName}
                                                </Typography>
                                                {c.branchName && (
                                                    <Typography variant="caption" sx={{ color: '#888', lineHeight: 1 }}>
                                                        {c.branchName}
                                                    </Typography>
                                                )}
                                            </Box>
                                        </MuiMenuItem>
                                    ))}
                                </Select>
                            </FormControl>
                        </Tooltip>
                    )}

                    {/* Empresa única — solo mostrar nombre */}
                    {companyAccesses.length === 1 && (
                        <Tooltip title="Empresa activa">
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mr: 1 }}>
                                <BusinessIcon sx={{ color: '#aab7c4', fontSize: 16 }} />
                                <Typography variant="caption" sx={{ color: '#aab7c4' }}>
                                    {companyAccesses[0].companyName}
                                </Typography>
                            </Box>
                        </Tooltip>
                    )}

                    {adminUser?.name && (
                        <Typography variant="caption" sx={{ color: '#aab7c4', mx: 1 }}>
                            {adminUser.name}
                        </Typography>
                    )}
                    <Button
                        startIcon={<ArrowBackIcon />}
                        color="inherit"
                        size="small"
                        onClick={() => router.push('/')}
                        sx={{ textTransform: 'none', fontSize: 13 }}
                    >
                        Volver al store
                    </Button>
                    <Button
                        startIcon={<LogoutIcon />}
                        color="inherit"
                        size="small"
                        onClick={handleLogout}
                        sx={{ textTransform: 'none', fontSize: 13, color: '#ff9900' }}
                    >
                        Salir
                    </Button>
                </Toolbar>
            </AppBar>

            <Box
                component="nav"
                sx={{ width: { md: DRAWER_WIDTH }, flexShrink: { md: 0 } }}
                aria-label="Panel administrativo"
            >
                <Drawer
                    variant="temporary"
                    open={mobileOpen}
                    onClose={() => setMobileOpen(false)}
                    ModalProps={{ keepMounted: true }}
                    sx={{
                        display: { xs: 'block', md: 'none' },
                        '& .MuiDrawer-paper': {
                            width: DRAWER_WIDTH,
                            boxSizing: 'border-box',
                            bgcolor: '#232f3e',
                            color: '#fff',
                        },
                    }}
                >
                    <DrawerContent
                        sections={NAV_SECTIONS}
                        expandedMap={expandedMap}
                        activeSectionId={activeSectionId}
                        handleExpandChange={handleExpandChange}
                        pathname={pathname}
                        router={router}
                        counts={counts}
                    />
                </Drawer>
                <Drawer
                    variant="permanent"
                    open
                    sx={{
                        display: { xs: 'none', md: 'block' },
                        '& .MuiDrawer-paper': {
                            width: DRAWER_WIDTH,
                            boxSizing: 'border-box',
                            bgcolor: '#232f3e',
                            color: '#fff',
                        },
                    }}
                >
                    <DrawerContent
                        sections={NAV_SECTIONS}
                        expandedMap={expandedMap}
                        activeSectionId={activeSectionId}
                        handleExpandChange={handleExpandChange}
                        pathname={pathname}
                        router={router}
                        counts={counts}
                    />
                </Drawer>
            </Box>

            <Box
                component="main"
                sx={{
                    flexGrow: 1,
                    p: { xs: 2, sm: 3 },
                    mt: 8,
                    bgcolor: '#f5f5f5',
                    minHeight: '100vh',
                    width: { md: `calc(100% - ${DRAWER_WIDTH}px)` },
                }}
            >
                {children}
            </Box>
        </Box>
    );
}

// Contenido del drawer — compartido entre mobile y desktop
function DrawerContent({
    sections,
    expandedMap,
    activeSectionId,
    handleExpandChange,
    pathname,
    router,
    counts,
}: {
    sections: NavSection[];
    expandedMap: Record<string, boolean>;
    activeSectionId: string;
    handleExpandChange: (id: string) => (_: unknown, expanded: boolean) => void;
    pathname: string;
    router: ReturnType<typeof useRouter>;
    counts: BadgeCounts;
}) {
    return (
        <>
            <Toolbar sx={{ bgcolor: '#131921' }}>
                    <Typography variant="subtitle2" fontWeight={700} sx={{ color: '#ff9900', fontSize: 12 }}>
                        PANEL ADMINISTRATIVO
                    </Typography>
                </Toolbar>
                <Divider sx={{ bgcolor: '#37475a' }} />

            <Box sx={{ overflowY: 'auto' }}>
                {sections.map((section) => {
                    const expanded = expandedMap[section.id] ?? section.id === activeSectionId;
                        return (
                            <Accordion
                                key={section.id}
                                expanded={expanded}
                                onChange={handleExpandChange(section.id)}
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
                                    expandIcon={
                                        <ExpandMoreIcon
                                            sx={{
                                                color: '#aab7c4',
                                                transition: 'transform 150ms',
                                            }}
                                        />
                                    }
                                    sx={{
                                        minHeight: 40,
                                        px: 2,
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
                                            color: '#cccccc',
                                            fontSize: 12,
                                        }}
                                    >
                                        {section.label}
                                    </Typography>
                                </AccordionSummary>
                                <AccordionDetails sx={{ p: 0 }}>
                                    <List dense disablePadding>
                                        {section.items.map((item) => {
                                            const active = pathname === item.href || pathname.startsWith(item.href + '/');
                                            const badgeVal = typeof item.badge === 'function'
                                                ? item.badge(counts)
                                                : (item.badge ?? null);
                                            return (
                                                <ListItem key={item.href} disablePadding>
                                                    <ListItemButton
                                                        onClick={() => router.push(item.href)}
                                                        selected={active}
                                                        sx={{
                                                            pl: 3,
                                                            color: '#fff',
                                                            position: 'relative',
                                                            '&.Mui-selected': {
                                                                bgcolor: '#37475a',
                                                                color: '#ff9900',
                                                                '&::before': {
                                                                    content: '""',
                                                                    position: 'absolute',
                                                                    left: 0,
                                                                    top: 0,
                                                                    bottom: 0,
                                                                    width: 3,
                                                                    bgcolor: '#ff9900',
                                                                },
                                                            },
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
                                                        {badgeVal && badgeVal > 0 ? (
                                                            <OrangeBadge count={badgeVal} />
                                                        ) : null}
                                                    </ListItemButton>
                                                </ListItem>
                                            );
                                        })}
                                    </List>
                                </AccordionDetails>
                            </Accordion>
                        );
                })}
            </Box>
        </>
    );
}

// ── Export principal — guard de autenticación ────────────────────────────────
export default function AdminLayout({ children }: { children: React.ReactNode }) {
    const router   = useRouter();
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

    // La página de login se renderiza sin sidebar
    if (pathname === '/admin/login') return <>{children}</>;

    // Sin token → null mientras redirige
    if (!adminToken) return null;

    return <AdminShell>{children}</AdminShell>;
}
