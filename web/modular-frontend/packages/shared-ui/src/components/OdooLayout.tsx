'use client';
import * as React from 'react';
import Box from '@mui/material/Box';
import AppBar from '@mui/material/AppBar';
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
import { useTheme } from '@mui/material/styles';
import KeyboardArrowDownIcon from '@mui/icons-material/KeyboardArrowDown';
import ExpandLessIcon from '@mui/icons-material/ExpandLess';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import AppsIcon from '@mui/icons-material/Apps';
import MenuIcon from '@mui/icons-material/Menu';
import MenuOpenIcon from '@mui/icons-material/MenuOpen';
import Tooltip from '@mui/material/Tooltip';
import Avatar from '@mui/material/Avatar';
import Brightness4Icon from '@mui/icons-material/Brightness4';
import NotificationsMenu from './NotificationsMenu';
import TasksMenu from './TasksMenu';
import MessagesMenu from './MessagesMenu';
import AppTitle from './AppTitle';
import SidebarFooterAccount from './SidebarFooterAccount';
import Copyright from './Copyright';
import useMediaQuery from '@mui/material/useMediaQuery';
import { useColorScheme } from '@mui/material/styles';
import { brandColors } from '../theme';

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

    const { mode, setMode } = useColorScheme();
    const isMobile = useMediaQuery(theme.breakpoints.down('md'));
    const hideSidebar = !navigationFields || navigationFields.length === 0;
    const fullSidebarWidth = 260;
    const miniSidebarWidth = 72;

    const [openMenus, setOpenMenus] = React.useState<{ [key: string]: boolean }>({});
    const [isSidebarOpen, setSidebarOpen] = React.useState(false);

    React.useEffect(() => {
        if (hideSidebar) return;
        setSidebarOpen(!isMobile);
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
                if (!isSidebarOpen) return <Box key={`header-${idx}`} sx={{ height: 16 }} />;
                return (
                    <Typography key={`header-${idx}`} variant="caption" sx={{ px: 3, pt: 2, pb: 1, display: 'block', fontWeight: 700, color: 'rgba(255,255,255,0.4)', textTransform: 'uppercase', whiteSpace: 'nowrap' }}>
                        {item.title as React.ReactNode}
                    </Typography>
                );
            }
            if (item.kind === 'divider') {
                return (
                    <Box key={`divider-${idx}`} sx={{ my: 1, height: 1, bgcolor: 'rgba(255,255,255,0.1)' }} />
                );
            }

            const isRouteActive = item.segment === '' ? pathname === '/' : pathname.includes(`/${item.segment}`);
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
                                px: isSidebarOpen ? (2 + level) : 0,
                                m: isSidebarOpen ? '4px 12px' : '4px auto',
                                mx: isSidebarOpen ? '12px' : 'auto',
                                width: isSidebarOpen ? 'auto' : 48,
                                borderRadius: 1.5,
                                justifyContent: isSidebarOpen ? 'flex-start' : 'center',
                                color: isRouteActive ? '#fff' : 'rgba(255,255,255,0.7)',
                                bgcolor: isRouteActive && !hasChildren ? 'rgba(255,153,0,0.15)' : 'transparent',
                                boxShadow: isRouteActive && !hasChildren ? `inset 4px 0 0 0 ${brandColors.accent}` : 'none',
                                transition: 'all 0.2s',
                                '&:hover': {
                                    bgcolor: isRouteActive && !hasChildren ? 'rgba(255,153,0,0.25)' : 'rgba(255,255,255,0.06)',
                                }
                            }}
                        >
                            <Tooltip title={!isSidebarOpen ? item.title : ""} placement="right" disableHoverListener={isSidebarOpen}>
                                <ListItemIcon sx={{ minWidth: isSidebarOpen ? 36 : 'auto', color: isRouteActive ? '#fff' : 'rgba(255,255,255,0.7)', justifyContent: 'center' }}>
                                    {item.icon || <AppsIcon fontSize="small" />}
                                </ListItemIcon>
                            </Tooltip>
                            {isSidebarOpen && (
                                <ListItemText
                                    primary={item.title}
                                    primaryTypographyProps={{ fontSize: '0.9rem', fontWeight: isRouteActive ? 600 : 400, whiteSpace: 'nowrap' }}
                                />
                            )}
                            {(isSidebarOpen && hasChildren) ? (isOpen ? <ExpandLessIcon fontSize="small" sx={{ color: 'rgba(255,255,255,0.5)' }} /> : <ExpandMoreIcon fontSize="small" sx={{ color: 'rgba(255,255,255,0.5)' }} />) : null}
                        </ListItemButton>
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
    // @ts-ignore extended session fields from NextAuth callbacks in shell auth.ts
    const activeCompany = session?.company as
        | { companyCode?: string; companyName?: string; branchCode?: string; branchName?: string }
        | undefined;
    const companyLabel = activeCompany
        ? `${activeCompany.companyCode ?? ''}/${activeCompany.branchCode ?? ''} - ${activeCompany.companyName ?? ''}`
        : 'Sin empresa activa';
    const dbName = process.env.NEXT_PUBLIC_DB_NAME || 'ZenttoWeb';
    const shellUrl = process.env.NEXT_PUBLIC_SHELL_URL || 'http://localhost:3000';
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
                        keepMounted: true, // Better open performance on mobile.
                    }}
                    sx={{
                        width: drawerPaperWidth,
                        flexShrink: 0,
                        transition: 'width 0.2s',
                        [`& .MuiDrawer-paper`]: {
                            width: drawerPaperWidth,
                            boxSizing: 'border-box',
                            borderRight: 'none',
                            bgcolor: brandColors.dark, /* Zentto Brand Dark */
                            color: '#fff',
                            boxShadow: 'none',
                            transition: 'width 0.2s',
                            overflowX: 'hidden'
                        },
                    }}
                >
                    <Box sx={{ h: 64, display: 'flex', alignItems: 'center', justifyContent: isSidebarOpen ? 'flex-start' : 'center', px: isSidebarOpen ? 2 : 0, borderBottom: '1px solid rgba(255,255,255,0.08)', minHeight: 64 }}>
                        <Tooltip title={isSidebarOpen ? "Contraer menú" : "Expandir menú"}>
                            <IconButton onClick={() => setSidebarOpen(!isSidebarOpen)} size="small" sx={{ mr: isSidebarOpen ? 1 : 0, color: '#fff', bgcolor: 'transparent', '&:hover': { bgcolor: 'rgba(255,255,255,0.1)' } }}>
                                {isSidebarOpen ? <MenuOpenIcon /> : <MenuIcon />}
                            </IconButton>
                        </Tooltip>
                        {isSidebarOpen && (
                            <Tooltip title="Ir al Inicio">
                                <Box onClick={goToShell} sx={{ cursor: 'pointer', ml: 1 }}>
                                    <AppTitle lightText={true} />
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
                <AppBar position="static" elevation={0} sx={{ bgcolor: brandColors.dark, color: '#fff', borderBottom: 'none' }}>
                    <Toolbar variant="dense" sx={{ minHeight: 64, px: 3, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>

                        <Box sx={{ display: 'flex', alignItems: 'center' }}>
                            {/* Toggle Sidebar Button logic for mobile */}
                            {isMobile && !hideSidebar && (
                                <IconButton onClick={() => setSidebarOpen(true)} size="small" sx={{ mr: 2, color: '#fff', bgcolor: 'transparent', '&:hover': { bgcolor: 'rgba(255,255,255,0.1)' } }}>
                                    <MenuIcon />
                                </IconButton>
                            )}

                            {hideSidebar && (
                                <React.Fragment>
                                    <Tooltip title="Ir al Inicio">
                                        <IconButton onClick={goToShell} size="small" sx={{ mr: 2, color: '#fff', bgcolor: 'transparent', '&:hover': { bgcolor: 'rgba(255,255,255,0.1)' } }}>
                                            <AppsIcon fontSize="large" />
                                        </IconButton>
                                    </Tooltip>
                                    <Typography variant="h5" color="#fff" onClick={goToShell} sx={{ fontWeight: 700, letterSpacing: -0.5, cursor: 'pointer' }}>
                                        <AppTitle lightText={true} />
                                    </Typography>
                                </React.Fragment>
                            )}

                            {/* Breadcrumbs */}
                            {!hideSidebar && (
                                <Typography variant="body1" sx={{ ml: { xs: 0, sm: 2 }, color: 'rgba(255,255,255,0.7)', display: 'flex', alignItems: 'center', gap: 1 }}>
                                    <span style={{ color: brandColors.accent, cursor: 'pointer', fontWeight: 500 }} onClick={goToShell}>Home</span>
                                    <span style={{ display: isMobile ? 'none' : 'inline' }}>/</span>
                                    <span style={{ color: '#fff', fontWeight: 500, textTransform: 'capitalize', display: isMobile ? 'none' : 'inline' }}>
                                        {(pathname || '').split('/').filter(Boolean).join(' / ') || 'Dashboard'}
                                    </span>
                                </Typography>
                            )}

                            <Box sx={{ ml: 2, display: { xs: 'none', md: 'flex' }, gap: 1 }}>
                                <Chip size="small" label={`Empresa: ${companyLabel}`} sx={{ bgcolor: brandColors.accent, color: brandColors.dark, fontWeight: 600, fontSize: '0.75rem' }} />
                                <Chip size="small" label={`BD: ${dbName}`} sx={{ bgcolor: 'rgba(255,255,255,0.12)', color: 'rgba(255,255,255,0.85)', fontWeight: 500, fontSize: '0.75rem' }} />
                            </Box>
                        </Box>

                        <Box sx={{ display: 'flex', alignItems: 'center', gap: { xs: 1, sm: 2 } }}>
                            <Tooltip title="Alternar Modo Oscuro">
                                <IconButton onClick={() => setMode(mode === 'dark' ? 'light' : 'dark')} size="small" sx={{ color: '#fff', '&:hover': { bgcolor: 'rgba(255,255,255,0.1)' } }}>
                                    <Brightness4Icon />
                                </IconButton>
                            </Tooltip>
                            <NotificationsMenu />
                            <TasksMenu />
                            <MessagesMenu />
                            <SidebarFooterAccount mini={false} />
                        </Box>
                    </Toolbar>
                </AppBar>

                {/* Page Content */}
                <Box component="main" sx={{ flexGrow: 1, display: 'flex', flexDirection: 'column', minHeight: 0, overflow: 'auto', bgcolor: 'background.default', p: { xs: 2, md: 3 } }}>
                    <Box sx={{ flexGrow: 1, display: 'flex', flexDirection: 'column' }}>
                        {children}
                    </Box>
                    <Box sx={{ pt: 4, pb: 1, display: 'flex', justifyContent: 'center' }}>
                        <Copyright />
                    </Box>
                </Box>
            </Box>
        </Box>
    );
}
