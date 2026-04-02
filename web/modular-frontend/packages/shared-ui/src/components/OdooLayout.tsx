'use client';
import * as React from 'react';
import Box from '@mui/material/Box';

import Toolbar from '@mui/material/Toolbar';
import Typography from '@mui/material/Typography';
import Chip from '@mui/material/Chip';
import Drawer from '@mui/material/Drawer';
import List from '@mui/material/List';
import ListItem from '@mui/material/ListItem';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemIcon from '@mui/material/ListItemIcon';
import ListItemText from '@mui/material/ListItemText';
import Collapse from '@mui/material/Collapse';
import IconButton from '@mui/material/IconButton';
import { useRouter, usePathname } from 'next/navigation';
import { useSession } from 'next-auth/react';
import { useAuth } from '@zentto/shared-auth';
import { useTheme } from '@mui/material/styles';
import KeyboardArrowDownIcon from '@mui/icons-material/KeyboardArrowDown';
import ExpandLessIcon from '@mui/icons-material/ExpandLess';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import AppsOutlinedIcon from '@mui/icons-material/AppsOutlined';
import MenuOutlinedIcon from '@mui/icons-material/MenuOutlined';
import MenuOpenOutlinedIcon from '@mui/icons-material/MenuOpenOutlined';
import Tooltip from '@mui/material/Tooltip';
import Menu from '@mui/material/Menu';
import MenuItem from '@mui/material/MenuItem';
import Avatar from '@mui/material/Avatar';
import ThemeToggle from './ThemeToggle';
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

// Type definition for our custom navigation (ignoring toolpad core for this specific top nav)
interface NavItem {
    title: string;
    segment?: string;
    children?: NavItem[];
}

export default function OdooLayout({
    children,
    navigationFields
}: {
    children: React.ReactNode,
    navigationFields?: Array<Record<string, unknown>>
}) {
    const router = useRouter();
    const pathname = usePathname();
    const theme = useTheme();
    const { data: session } = useSession();
    const { dynamicBrandColors: bc } = useBranding();

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

    // Auto close sidebar on mobile when navigating
    const handleToggleMenu = (key: string) => {
        setOpenMenus((prev) => ({ ...prev, [key]: !prev[key] }));
    };

    const handleNavigate = (path: string) => {
        router.push(`/${path}`);
        if (isMobile) {
            setSidebarOpen(false);
        }
    };
    // Parse navigation into Sidebar
    const renderSidebarItems = () => {
        if (!navigationFields || navigationFields.length === 0) return null;

        // Render recursive function
        const renderLevel = (rawItem: Record<string, unknown>, idx: string, level = 0) => {
            const item = rawItem as any;
            if (item.kind === 'header') {
                if (!isDrawerExpanded) return <Box key={`header-${idx}`} sx={{ height: 16 }} />;
                return (
                    <Typography key={`header-${idx}`} variant="caption" sx={{ px: 3, pt: 2, pb: 1, display: 'block', fontWeight: 700, color: (t) => t.palette.mode === 'dark' ? 'rgba(255,255,255,0.4)' : brandColors.textMuted, textTransform: 'uppercase', whiteSpace: 'nowrap' }}>
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
                : pathname === `/${item.segment}`;
            const hasChildren = item.children && item.children.length > 0;
            const isOpen = openMenus[idx] ?? isRouteActive;

            return (
                <React.Fragment key={`frag-${idx}`}>
                    <ListItem disablePadding sx={{ display: 'block' }}>
                        <ListItemButton
                            selected={isRouteActive && !hasChildren}
                            onClick={() => hasChildren ? handleToggleMenu(idx) : handleNavigate(item.segment)}
                            sx={{
                                minHeight: 48,
                                px: isDrawerExpanded ? (2 + level) : 0,
                                m: isDrawerExpanded ? '4px 12px' : '4px auto',
                                mx: isDrawerExpanded ? '12px' : 'auto',
                                width: isDrawerExpanded ? 'auto' : 48,
                                borderRadius: 1.5,
                                justifyContent: isDrawerExpanded ? 'flex-start' : 'center',
                                color: isRouteActive ? 'text.primary' : 'text.secondary',
                                bgcolor: isRouteActive && !hasChildren ? (t) => t.palette.mode === 'dark' ? 'rgba(255,181,71,0.15)' : 'rgba(255,181,71,0.1)' : 'transparent',
                                boxShadow: isRouteActive && !hasChildren ? `inset 4px 0 0 0 ${bc.accent}` : 'none',
                                transition: 'all 0.2s',
                                '&:hover': {
                                    bgcolor: isRouteActive && !hasChildren ? (t) => t.palette.mode === 'dark' ? 'rgba(255,181,71,0.25)' : 'rgba(255,181,71,0.15)' : 'action.hover',
                                }
                            }}
                        >
                            <Tooltip title={!isDrawerExpanded ? item.title : ""} placement="right" disableHoverListener={isDrawerExpanded}>
                                <ListItemIcon sx={{ minWidth: isDrawerExpanded ? 36 : 'auto', color: isRouteActive ? 'text.primary' : 'text.secondary', justifyContent: 'center' }}>
                                    {item.icon || <AppsOutlinedIcon fontSize="small" />}
                                </ListItemIcon>
                            </Tooltip>
                            {isDrawerExpanded && (
                                <ListItemText
                                    primary={item.title}
                                    primaryTypographyProps={{ fontSize: '0.9rem', fontWeight: isRouteActive ? 600 : 400, whiteSpace: 'nowrap' }}
                                />
                            )}
                            {(isDrawerExpanded && hasChildren) ? (isOpen ? <ExpandLessIcon fontSize="small" sx={{ color: 'text.disabled' }} /> : <ExpandMoreIcon fontSize="small" sx={{ color: 'text.disabled' }} />) : null}
                        </ListItemButton>
                    </ListItem>
                    {(hasChildren && isDrawerExpanded) && (
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

    const isDrawerExpanded = isSidebarOpen;
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
                            transition: 'width 0.2s, background-color 0.3s, color 0.3s',
                            overflowX: 'hidden'
                        },
                    }}
                >
                    <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: isDrawerExpanded ? 'flex-start' : 'center', px: isDrawerExpanded ? 2 : 0, borderBottom: (t) => `1px solid ${t.palette.divider}`, height: 64, minHeight: 64 }}>
                        <Tooltip title={isDrawerExpanded ? "Contraer menú" : "Expandir menú"}>
                            <IconButton onClick={() => setSidebarOpen(!isSidebarOpen)} size="small" sx={{ width: 32, height: 32, borderRadius: '6px', mr: isDrawerExpanded ? 1 : 0, color: 'text.secondary', bgcolor: 'transparent', '&:hover': { bgcolor: 'action.hover' }, '& .MuiSvgIcon-root': { fontSize: '1.15rem' } }}>
                                {isDrawerExpanded ? <MenuOpenOutlinedIcon /> : <MenuOutlinedIcon />}
                            </IconButton>
                        </Tooltip>
                        {isDrawerExpanded && (
                            <Tooltip title="Ir al Inicio">
                                <Box onClick={goToShell} sx={{ cursor: 'pointer', ml: 1 }}>
                                    <AppTitle />
                                </Box>
                            </Tooltip>
                        )}
                    </Box>
                    <Box sx={{ overflowY: 'auto', flexGrow: 1, py: 2 }}>
                        {renderSidebarItems()}
                    </Box>
                </Drawer>
            )}

            {/* Main Layout Area */}
            <Box sx={{ display: 'flex', flexDirection: 'column', flexGrow: 1, width: `calc(100% - ${actualSidebarWidth}px)`, transition: 'width 0.2s' }}>

                {/* Top Header */}
                <Box component="header" sx={{ backgroundColor: 'background.paper', color: 'text.primary', transition: 'background-color 0.3s, color 0.3s' }}>
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
                <Box component="main" sx={{ flexGrow: 1, minHeight: 0, overflow: 'auto', bgcolor: 'background.default', p: { xs: 2, md: 3 } }}>
                    {children}
                    <Box sx={{ pt: 4, pb: 1, display: 'flex', justifyContent: 'center' }}>
                        <Copyright />
                    </Box>
                </Box>
            </Box>
        </Box>
    );
}
