'use client';
import * as React from 'react';
import Box from '@mui/material/Box';

import Toolbar from '@mui/material/Toolbar';
import Typography from '@mui/material/Typography';
import Chip from '@mui/material/Chip';
import Drawer from '@mui/material/Drawer';
import List from '@mui/material/List';
import ListItem from '@mui/material/ListItem';
import ListItemIcon from '@mui/material/ListItemIcon';
import ListItemText from '@mui/material/ListItemText';
import Collapse from '@mui/material/Collapse';
import IconButton from '@mui/material/IconButton';
import { usePathname, useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuth } from '@zentto/shared-auth';
import { useTheme } from '@mui/material/styles';
import ExpandLessIcon from '@mui/icons-material/ExpandLess';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import AppsOutlinedIcon from '@mui/icons-material/AppsOutlined';
import MenuOutlinedIcon from '@mui/icons-material/MenuOutlined';
import MenuOpenOutlinedIcon from '@mui/icons-material/MenuOpenOutlined';
import Tooltip from '@mui/material/Tooltip';
import Menu from '@mui/material/Menu';
import MenuItem from '@mui/material/MenuItem';
import ThemeToggle from './ThemeToggle';
import LocaleSelectorButton from './LocaleSelectorButton';
import NotificationsMenu from './NotificationsMenu';
import HelpButton from './HelpButton';
import TasksMenu from './TasksMenu';
import MessagesMenu from './MessagesMenu';
import AppTitle from './AppTitle';
import SidebarFooterAccount from './SidebarFooterAccount';
import Copyright from './Copyright';
import useMediaQuery from '@mui/material/useMediaQuery';
import { brandColors } from '../theme';
import { useBranding } from '../hooks/useBranding';

export default function OdooLayout({
    children,
    navigationFields,
    rightPanel,
    rightPanelOpen,
    onRightPanelClose
}: {
    children: React.ReactNode,
    navigationFields?: Array<Record<string, unknown>>,
    /**
     * Panel lateral derecho (típicamente un <RightDetailDrawer/>). Opcional.
     * El nodo debe manejar su propia apertura (`open`/`onClose`) — aquí sólo
     * se controla el montaje condicional para evitar renders innecesarios.
     */
    rightPanel?: React.ReactNode,
    /** Si se provee con `rightPanel`, controla el montaje del panel. */
    rightPanelOpen?: boolean,
    /**
     * Callback cuando el usuario cierra el panel lateral. Disponible como
     * prop informativa — normalmente ya lo maneja `rightPanel.onClose`.
     */
    onRightPanelClose?: () => void
}) {
    const pathname = usePathname();
    const router = useRouter();
    const theme = useTheme();
    const { dynamicBrandColors: bc } = useBranding();

    // Handler de navegacion con fallback a hard-nav. En Next 16 + MUI
    // AppRouterCacheProvider (v15-appRouter) hay casos en los que router.push
    // del Link no completa la transicion (click normal no navega, pero click
    // derecho + nueva tab si). Se intenta primero router.push; si tras un
    // frame la URL no cambio, se hace window.location.assign como fallback.
    const handleMenuClick = (e: React.MouseEvent, segment: string) => {
        if (e.metaKey || e.ctrlKey || e.shiftKey || e.button !== 0) return;
        e.preventDefault();
        const anchor = e.currentTarget as HTMLAnchorElement;
        const fullHref = anchor.href;
        const nextPath = `/${segment}`;
        try {
            router.push(nextPath);
        } catch {
            window.location.assign(fullHref);
            return;
        }
        // Fallback: si en 250ms la URL no cambio, navegacion dura.
        const before = window.location.pathname;
        window.setTimeout(() => {
            if (window.location.pathname === before) {
                window.location.assign(fullHref);
            }
        }, 250);
    };

    const isMobile = useMediaQuery(theme.breakpoints.down('md'));
    const hideSidebar = !navigationFields || navigationFields.length === 0;
    const fullSidebarWidth = 260;
    const miniSidebarWidth = 72;

    const [openMenus, setOpenMenus] = React.useState<{ [key: string]: boolean }>({});
    const [isSidebarOpen, setSidebarOpen] = React.useState(!isMobile && !hideSidebar);
    const [companyMenuAnchor, setCompanyMenuAnchor] = React.useState<HTMLElement | null>(null);

    React.useEffect(() => {
        if (hideSidebar) {
            setSidebarOpen(false);
            return;
        }
        if (!isMobile) {
            setSidebarOpen(true);
        } else {
            setSidebarOpen(false);
        }
    }, [isMobile, hideSidebar]);

    const handleToggleMenu = (key: string) => {
        setOpenMenus((prev) => ({ ...prev, [key]: !prev[key] }));
    };

    // Cierra el sidebar en mobile tras completar la navegacion (no en el click,
    // para no interrumpir la transition de Next.js Link con un setState sincrono).
    React.useEffect(() => {
        if (isMobile) {
            setSidebarOpen(false);
        }
    }, [pathname, isMobile]);
    // Parse navigation into Sidebar
    const renderSidebarItems = () => {
        if (!navigationFields || navigationFields.length === 0) return null;

        // Render recursive function
        const renderLevel = (rawItem: Record<string, unknown>, idx: string, level = 0) => {
            const item = rawItem as any;
            if (item.kind === 'header') {
                return (
                    <Typography key={`header-${idx}`} variant="caption" sx={{ px: 3, pt: 2, pb: 1, display: 'block', fontWeight: 700, color: (t) => t.palette.mode === 'dark' ? 'rgba(255,255,255,0.4)' : brandColors.textMuted, textTransform: 'uppercase', whiteSpace: 'nowrap', opacity: isSidebarOpen ? 1 : 0, transition: 'opacity 0.15s ease' }}>
                        {item.title as React.ReactNode}
                    </Typography>
                );
            }
            if (item.kind === 'divider') {
                return (
                    <Box key={`divider-${idx}`} sx={{ my: 1, height: 1, bgcolor: 'divider' }} />
                );
            }

            const isRouteActive = item.segment === ''
                ? pathname === '/' || pathname === ''
                : pathname === `/${item.segment}` || pathname.startsWith(`/${item.segment}/`);
            const hasChildren = item.children && item.children.length > 0;
            const isOpen = openMenus[idx] ?? isRouteActive;

            return (
                <React.Fragment key={`frag-${idx}`}>
                    <ListItem disablePadding sx={{ position: 'relative', my: '4px', px: '12px', minHeight: 48 }}>
                        {/* Capa de fondo — efecto de selección */}
                        <Box
                            sx={{
                                position: 'absolute',
                                top: 0, bottom: 0,
                                left: 12, right: 12,
                                borderRadius: 1.5,
                                bgcolor: isRouteActive && !hasChildren ? (t) => t.palette.mode === 'dark' ? 'rgba(255,181,71,0.15)' : 'rgba(255,181,71,0.1)' : 'transparent',
                                boxShadow: isRouteActive && !hasChildren ? `inset 4px 0 0 0 ${bc.accent}` : 'none',
                                pointerEvents: 'none',
                            }}
                        />
                        {/* Contenido — ícono fijo + texto */}
                        <Box
                            {...(hasChildren
                                ? { onClick: () => handleToggleMenu(idx) }
                                : {
                                      component: Link,
                                      href: `/${item.segment}`,
                                      prefetch: false,
                                      onClick: (e: React.MouseEvent) => handleMenuClick(e, item.segment),
                                  })}
                            sx={{
                                position: 'relative',
                                display: 'flex', alignItems: 'center',
                                minHeight: 48, width: '100%',
                                cursor: 'pointer',
                                color: isRouteActive ? 'text.primary' : 'text.secondary',
                                borderRadius: 1.5,
                                textDecoration: 'none',
                                '&:hover': {
                                    bgcolor: isRouteActive && !hasChildren ? (t) => t.palette.mode === 'dark' ? 'rgba(255,181,71,0.25)' : 'rgba(255,181,71,0.15)' : 'action.hover',
                                }
                            }}
                        >
                            <Tooltip title={!isSidebarOpen ? item.title : ""} placement="right" disableHoverListener={isSidebarOpen}>
                                <ListItemIcon sx={{ minWidth: 48, color: 'inherit', justifyContent: 'center' }}>
                                    {item.icon || <AppsOutlinedIcon fontSize="small" />}
                                </ListItemIcon>
                            </Tooltip>
                            <Box sx={{ overflow: 'hidden', maxWidth: isSidebarOpen ? 200 : 0, opacity: isSidebarOpen ? 1 : 0, transition: 'max-width 0.2s ease, opacity 0.15s ease', display: 'flex', alignItems: 'center', flexGrow: 1, whiteSpace: 'nowrap' }}>
                                <ListItemText
                                    primary={item.title}
                                    primaryTypographyProps={{ fontSize: '0.9rem', fontWeight: isRouteActive ? 600 : 400, whiteSpace: 'nowrap' }}
                                />
                                {hasChildren ? (isOpen ? <ExpandLessIcon fontSize="small" sx={{ color: 'text.disabled' }} /> : <ExpandMoreIcon fontSize="small" sx={{ color: 'text.disabled' }} />) : null}
                            </Box>
                        </Box>
                    </ListItem>
                    {(hasChildren && isSidebarOpen) && (
                        <Collapse in={isOpen} timeout="auto" unmountOnExit>
                            <List component="div" disablePadding>
                                {(item.children as Array<Record<string, unknown>>).map((sub, subIdx: number) => renderLevel(sub, `${idx}-${subIdx}`, level + 1))}
                            </List>
                        </Collapse>
                    )}
                </React.Fragment>
            );
        };

        return (
            <List sx={{ pt: 0, px: 0 }}>
                {navigationFields.map((item, idx) => renderLevel(item, idx.toString()))}
            </List>
        );
    };

    const actualSidebarWidth = hideSidebar ? 0 : (isMobile ? 0 : (isSidebarOpen ? fullSidebarWidth : miniSidebarWidth));
    const drawerPaperWidth = hideSidebar ? 0 : (isMobile ? fullSidebarWidth : (isSidebarOpen ? fullSidebarWidth : miniSidebarWidth));
    const { company: activeCompany, companyAccesses: authCompanyAccesses, setActiveCompany } = useAuth();
    const companyLabel = activeCompany
        ? `${activeCompany.companyCode ?? ''}/${activeCompany.branchCode ?? ''} - ${activeCompany.companyName ?? ''}`
        : 'Sin empresa activa';
    const dbName = process.env.NEXT_PUBLIC_DB_NAME || 'ZenttoWeb';
    const shellUrl = process.env.NEXT_PUBLIC_SHELL_URL || (process.env.NODE_ENV === 'development' ? 'http://localhost:3000' : window.location.origin);
    const goToShell = () => { window.location.href = shellUrl; };

    return (
        <Box sx={{ display: 'flex', height: '100vh', width: '100vw', overflow: 'hidden', bgcolor: 'background.default' }}>

            {/* Sidebar Drawer */}
            {!hideSidebar && (
                <Drawer
                    variant={isMobile ? "temporary" : "permanent"}
                    open={isSidebarOpen}
                    onClose={() => setSidebarOpen(false)}
                    ModalProps={{
                        keepMounted: true,
                        ...(isMobile && !isSidebarOpen && { style: { pointerEvents: 'none' } }),
                        BackdropProps: { style: { pointerEvents: isSidebarOpen ? 'auto' : 'none' } },
                    }}
                    sx={{
                        width: drawerPaperWidth,
                        flexShrink: 0,
                        transition: 'width 0.2s',
                        [`& .MuiDrawer-paper`]: {
                            width: drawerPaperWidth,
                            boxSizing: 'border-box',
                            borderRight: (t) => `1px solid ${t.palette.divider}`,
                            backgroundColor: 'background.paper',
                            color: 'text.primary',
                            boxShadow: isMobile ? '4px 0 20px rgba(0,0,0,0.3)' : 'none',
                            transition: 'width 0.2s',
                            overflowX: 'hidden'
                        },
                    }}
                >
                    <Box sx={{ display: 'flex', alignItems: 'center', px: '12px', borderBottom: (t) => `1px solid ${t.palette.divider}`, height: 64, minHeight: 64 }}>
                        <Tooltip title={isSidebarOpen ? "Contraer menú" : "Expandir menú"}>
                            <Box sx={{ width: 48, minWidth: 48, display: 'flex', justifyContent: 'center' }}>
                                <IconButton onClick={() => setSidebarOpen(!isSidebarOpen)} size="small" sx={{ width: 32, height: 32, borderRadius: '6px', color: 'text.secondary', bgcolor: 'transparent', '&:hover': { bgcolor: 'action.hover' }, '& .MuiSvgIcon-root': { fontSize: '1.15rem' } }}>
                                    {isSidebarOpen ? <MenuOpenOutlinedIcon /> : <MenuOutlinedIcon />}
                                </IconButton>
                            </Box>
                        </Tooltip>
                        <Box sx={{ overflow: 'hidden', maxWidth: isSidebarOpen ? 200 : 0, opacity: isSidebarOpen ? 1 : 0, transition: 'max-width 0.2s ease, opacity 0.15s ease', whiteSpace: 'nowrap' }}>
                            <Tooltip title="Ir al Inicio">
                                <Box onClick={goToShell} sx={{ cursor: 'pointer', ml: 1 }}>
                                    <AppTitle />
                                </Box>
                            </Tooltip>
                        </Box>
                    </Box>
                    <Box sx={{ overflowY: 'auto', flexGrow: 1, py: 2 }}>
                        {renderSidebarItems()}
                    </Box>
                </Drawer>
            )}

            {/* Main Layout Area */}
            <Box sx={{ display: 'flex', flexDirection: 'column', flexGrow: 1, width: `calc(100% - ${actualSidebarWidth}px)`, transition: 'width 0.2s' }}>

                {/* Top Header */}
                <Box component="header" sx={{ backgroundColor: 'background.paper', color: 'text.primary' }}>
                    <Toolbar variant="dense" sx={{ height: 64, minHeight: 64, maxHeight: 64, px: 3, display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: (t) => `1px solid ${t.palette.divider}` }}>

                        <Box sx={{ display: 'flex', alignItems: 'center' }}>
                            {/* Toggle Sidebar Button logic for mobile */}
                            {isMobile && !hideSidebar && (
                                <IconButton onClick={() => setSidebarOpen(true)} size="small" sx={{ width: 32, height: 32, borderRadius: '6px', mr: 2, color: 'text.secondary', bgcolor: 'transparent', '&:hover': { bgcolor: 'action.hover' }, '& .MuiSvgIcon-root': { fontSize: '1.15rem' } }}>
                                    <MenuOutlinedIcon />
                                </IconButton>
                            )}

                            {/* Breadcrumbs */}
                            {!hideSidebar && (
                                <Typography variant="body1" sx={{ ml: { xs: 0, sm: 2 }, color: 'text.secondary', display: 'flex', alignItems: 'center', gap: 1 }}>
                                    <Typography component="span" sx={{ color: (t) => t.palette.mode === 'dark' ? bc.accent : bc.indigo, cursor: 'pointer', fontWeight: 500 }} onClick={goToShell}>Home</Typography>
                                    <span style={{ display: isMobile ? 'none' : 'inline' }}>/</span>
                                    <Typography component="span" sx={{ fontWeight: 500, textTransform: 'capitalize', display: isMobile ? 'none' : 'inline', color: 'text.primary' }}>
                                        {(pathname || '').split('/').filter(Boolean).join(' / ') || 'Dashboard'}
                                    </Typography>
                                </Typography>
                            )}

                            <Box sx={{ ml: 2, display: { xs: 'none', md: 'flex' }, gap: 1 }}>
                                <Chip
                                    size="small"
                                    label={`Empresa: ${companyLabel}`}
                                    onClick={(e) => {
                                        if (authCompanyAccesses.length > 1) {
                                            setCompanyMenuAnchor(e.currentTarget);
                                        }
                                    }}
                                    sx={{
                                        bgcolor: bc.accent, color: bc.dark, fontWeight: 600, fontSize: '0.75rem',
                                        cursor: authCompanyAccesses.length > 1 ? 'pointer' : 'default',
                                    }}
                                />
                                <Chip size="small" label={`BD: ${dbName}`} sx={{ bgcolor: bc.indigo, color: '#fff', fontWeight: 500, fontSize: '0.75rem' }} />
                            </Box>

                            {/* Selector de Empresa/Sucursal */}
                            <Menu
                                anchorEl={companyMenuAnchor}
                                open={Boolean(companyMenuAnchor)}
                                onClose={() => setCompanyMenuAnchor(null)}
                                slotProps={{ paper: { sx: { minWidth: 280 } } }}
                            >
                                {authCompanyAccesses.map((access, idx) => (
                                    <MenuItem
                                        key={idx}
                                        selected={access.companyId === activeCompany?.companyId && access.branchId === activeCompany?.branchId}
                                        onClick={() => {
                                            setCompanyMenuAnchor(null);
                                            setActiveCompany(access.companyId, access.branchId);
                                        }}
                                    >
                                        <Box>
                                            <Typography variant="body2" fontWeight={600}>
                                                {access.companyCode}/{access.branchCode} — {access.companyName}
                                            </Typography>
                                            <Typography variant="caption" color="text.secondary">
                                                {access.branchName} · {access.countryCode}
                                            </Typography>
                                        </Box>
                                    </MenuItem>
                                ))}
                            </Menu>
                        </Box>

                        <Box sx={{ display: 'flex', alignItems: 'center', gap: { xs: 0.5, sm: 1 }, '& .MuiIconButton-root': { width: 32, height: 32, borderRadius: '6px', color: 'text.secondary', '&:hover': { bgcolor: 'action.hover' }, '& .MuiSvgIcon-root': { fontSize: '1.15rem' } } }}>
                            <LocaleSelectorButton />
                            <ThemeToggle />
                            <HelpButton />
                            <NotificationsMenu />
                            <TasksMenu />
                            <MessagesMenu />
                            <SidebarFooterAccount mini={false} />
                        </Box>
                    </Toolbar>
                </Box>

                {/* Page Content */}
                <Box component="main" sx={{ flexGrow: 1, minHeight: 0, overflow: 'auto', bgcolor: 'background.default', p: { xs: 2, md: 3 }, display: 'flex', flexDirection: 'column' }}>
                    <Box sx={{ flexGrow: 1 }}>
                        {children}
                    </Box>
                    <Box sx={{ pt: 4, pb: 1, display: 'flex', justifyContent: 'center' }}>
                        <Copyright />
                    </Box>
                </Box>
            </Box>

            {/* Right detail panel (opcional — drawer tipo HubSpot/Linear) */}
            {rightPanel && rightPanelOpen && (
                <React.Fragment>
                    {typeof rightPanel === 'function'
                        ? (rightPanel as () => React.ReactNode)()
                        : rightPanel}
                </React.Fragment>
            )}
        </Box>
    );
}
