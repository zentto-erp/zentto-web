'use client';
import * as React from 'react';
import Box from '@mui/material/Box';
import Toolbar from '@mui/material/Toolbar';
import Typography from '@mui/material/Typography';
import Drawer from '@mui/material/Drawer';
import List from '@mui/material/List';
import ListItem from '@mui/material/ListItem';
import ListItemIcon from '@mui/material/ListItemIcon';
import ListItemText from '@mui/material/ListItemText';
import Collapse from '@mui/material/Collapse';
import Accordion from '@mui/material/Accordion';
import AccordionSummary from '@mui/material/AccordionSummary';
import AccordionDetails from '@mui/material/AccordionDetails';
import IconButton from '@mui/material/IconButton';
import Avatar from '@mui/material/Avatar';
import Menu from '@mui/material/Menu';
import MenuItem from '@mui/material/MenuItem';
import Divider from '@mui/material/Divider';
import Tooltip from '@mui/material/Tooltip';
import useMediaQuery from '@mui/material/useMediaQuery';
import { useTheme } from '@mui/material/styles';
import { useRouter, usePathname } from 'next/navigation';
import { useSession, signOut } from 'next-auth/react';
import ExpandLessIcon from '@mui/icons-material/ExpandLess';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import AppsOutlinedIcon from '@mui/icons-material/AppsOutlined';
import MenuOutlinedIcon from '@mui/icons-material/MenuOutlined';
import MenuOpenOutlinedIcon from '@mui/icons-material/MenuOpenOutlined';
import LogoutIcon from '@mui/icons-material/Logout';
import AccountCircleIcon from '@mui/icons-material/AccountCircle';
import ThemeToggle from './ThemeToggle';
import { brandColors } from '../theme';

export interface ZenttoVerticalLayoutProps {
    /** Contenido principal a renderizar dentro del layout. */
    children: React.ReactNode;
    /**
     * Descriptor jerárquico del sidebar. Items con forma
     * `{ kind: 'header' | 'page' | 'divider', ... }`. Los `header` agrupan
     * páginas en acordeones colapsables; `divider` inserta un separador.
     */
    navigationFields?: Array<Record<string, unknown>>;
    /** Título del app que aparece en la topbar y el drawer. Default: "Zentto". */
    appTitle?: string;
    /** Slot opcional para un ícono del logo a la izquierda del título. */
    logoIcon?: React.ReactNode;
    /** URL de avatar. Si no se provee se muestran iniciales del usuario. */
    userAvatarUrl?: string;
    /** Nombre del usuario. Si no se provee se toma de `useSession()`. */
    userName?: string;
    /**
     * Callback al hacer click en "Cerrar sesión" en el menú de usuario.
     * Default: `signOut({ callbackUrl: '/login' })` de next-auth.
     */
    onLogout?: () => void;
    /**
     * Nodos adicionales que se renderizan a la izquierda del ThemeToggle en
     * la topbar (notifications, idioma, help, etc.). Opcional.
     */
    topBarExtras?: React.ReactNode;
}

const getInitials = (name: string) =>
    name.split(' ').map((n) => n[0] ?? '').join('').toUpperCase().slice(0, 2);

/**
 * `ZenttoVerticalLayout` — layout unificado para dashboards de verticales
 * (hotel, medical, education, tickets, rental, inmobiliario, restaurante, pos).
 *
 * Sustituye los `OdooLayout.tsx` custom duplicados en cada vertical. Depende
 * sólo de `next-auth/react` (no de `@zentto/shared-auth`) para que las apps
 * verticales lo puedan consumir sin instalar el paquete del ERP.
 */
export default function ZenttoVerticalLayout({
    children,
    navigationFields,
    appTitle = 'Zentto',
    logoIcon,
    userAvatarUrl,
    userName,
    onLogout,
    topBarExtras,
}: ZenttoVerticalLayoutProps) {
    const router = useRouter();
    const pathname = usePathname();
    const theme = useTheme();
    const { data: session } = useSession();

    const isMobile = useMediaQuery(theme.breakpoints.down('md'));
    const hideSidebar = !navigationFields || navigationFields.length === 0;
    const fullSidebarWidth = 260;
    const miniSidebarWidth = 72;

    const [openMenus, setOpenMenus] = React.useState<{ [key: string]: boolean }>({});
    const [isSidebarOpen, setSidebarOpen] = React.useState(!isMobile && !hideSidebar);
    const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);

    React.useEffect(() => {
        if (hideSidebar) {
            setSidebarOpen(false);
            return;
        }
        setSidebarOpen(!isMobile);
    }, [isMobile, hideSidebar]);

    // Cierra sidebar en mobile cuando cambia la ruta.
    React.useEffect(() => {
        if (isMobile) setSidebarOpen(false);
    }, [pathname, isMobile]);

    const handleToggleMenu = (key: string) => {
        setOpenMenus((prev) => ({ ...prev, [key]: !prev[key] }));
    };

    const handleNavigate = (path: string) => {
        router.push(`/${path}`);
        if (isMobile) setSidebarOpen(false);
    };

    const handleLogout = () => {
        if (onLogout) {
            onLogout();
        } else {
            signOut({ callbackUrl: '/login' });
        }
    };

    const resolvedUserName =
        userName ?? (session?.user?.name as string | undefined) ?? 'Usuario';

    const renderSidebarItems = () => {
        if (!navigationFields || navigationFields.length === 0) return null;

        // Agrupa items en secciones: cada 'header' inicia una nueva sección.
        type NavSection = { title: string | null; sectionId: string; items: any[] };
        const sections: NavSection[] = [];
        let current: NavSection = { title: null, sectionId: 'pre', items: [] };
        (navigationFields as any[]).forEach((item, idx) => {
            if (item.kind === 'header') {
                if (current.items.length > 0 || current.title !== null) {
                    sections.push({ ...current });
                }
                current = { title: item.title as string, sectionId: `sec-${idx}`, items: [] };
            } else if (item.kind !== 'divider') {
                current.items.push(item);
            }
        });
        if (current.items.length > 0 || current.title !== null) sections.push(current);

        const renderPageItem = (item: any, key: string) => {
            const isRouteActive = item.segment === ''
                ? pathname === '/' || pathname === ''
                : pathname === `/${item.segment}` || pathname.startsWith(`/${item.segment}/`);
            const hasChildren = item.children && item.children.length > 0;
            const isOpen = openMenus[key] ?? isRouteActive;

            return (
                <React.Fragment key={`frag-${key}`}>
                    <ListItem disablePadding sx={{ position: 'relative', my: '4px', px: '12px', minHeight: 48 }}>
                        <Box
                            sx={{
                                position: 'absolute',
                                top: 0, bottom: 0, left: 12, right: 12,
                                borderRadius: 1.5,
                                bgcolor: isRouteActive && !hasChildren
                                    ? (t: any) => t.palette.mode === 'dark' ? 'rgba(255,181,71,0.15)' : 'rgba(255,181,71,0.1)'
                                    : 'transparent',
                                boxShadow: isRouteActive && !hasChildren ? `inset 4px 0 0 0 ${brandColors.accent}` : 'none',
                                pointerEvents: 'none',
                            }}
                        />
                        <Box
                            onClick={() => hasChildren ? handleToggleMenu(key) : handleNavigate(item.segment)}
                            sx={{
                                position: 'relative',
                                display: 'flex', alignItems: 'center',
                                minHeight: 48, width: '100%',
                                cursor: 'pointer',
                                color: isRouteActive ? 'text.primary' : 'text.secondary',
                                borderRadius: 1.5,
                                '&:hover': {
                                    bgcolor: isRouteActive && !hasChildren
                                        ? (t: any) => t.palette.mode === 'dark' ? 'rgba(255,181,71,0.25)' : 'rgba(255,181,71,0.15)'
                                        : 'action.hover',
                                },
                            }}
                        >
                            <Tooltip title={!isSidebarOpen ? (item.title as string) : ''} placement="right" disableHoverListener={isSidebarOpen}>
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
                                {(item.children as any[]).map((sub: any, subIdx: number) => renderPageItem(sub, `${key}-${subIdx}`))}
                            </List>
                        </Collapse>
                    )}
                </React.Fragment>
            );
        };

        // Modo colapsado: lista plana sin acordeones.
        if (!isSidebarOpen) {
            return (
                <List sx={{ pt: 0, px: 0 }}>
                    {sections.flatMap((sec) =>
                        sec.items.map((item, iIdx) => renderPageItem(item, `${sec.sectionId}-${iIdx}`))
                    )}
                </List>
            );
        }

        return (
            <List sx={{ pt: 0, px: 0 }} disablePadding>
                {sections.map((section) => {
                    if (!section.title) {
                        return section.items.map((item, i) => renderPageItem(item, `pre-${i}`));
                    }
                    const isExpanded = openMenus[section.sectionId] !== false;
                    return (
                        <Accordion
                            key={section.sectionId}
                            expanded={isExpanded}
                            onChange={() => handleToggleMenu(section.sectionId)}
                            disableGutters
                            elevation={0}
                            square
                            sx={{
                                bgcolor: 'transparent',
                                color: 'inherit',
                                '&:before': { display: 'none' },
                                '&.Mui-expanded': { margin: 0 },
                            }}
                        >
                            <AccordionSummary
                                expandIcon={<ExpandMoreIcon sx={{ fontSize: '0.85rem', color: 'text.disabled' }} />}
                                sx={{
                                    px: 3, minHeight: '32px !important',
                                    '&.Mui-expanded': { minHeight: '32px !important' },
                                    '& .MuiAccordionSummary-content': { my: '6px' },
                                    '& .MuiAccordionSummary-expandIconWrapper': { ml: 0.5 },
                                }}
                            >
                                <Typography
                                    variant="caption"
                                    sx={{
                                        fontWeight: 700,
                                        color: (t: any) => t.palette.mode === 'dark' ? 'rgba(255,255,255,0.4)' : brandColors.textMuted,
                                        textTransform: 'uppercase',
                                        letterSpacing: '0.06em',
                                    }}
                                >
                                    {section.title}
                                </Typography>
                            </AccordionSummary>
                            <AccordionDetails sx={{ p: 0 }}>
                                {section.items.map((item, i) => renderPageItem(item, `${section.sectionId}-${i}`))}
                            </AccordionDetails>
                        </Accordion>
                    );
                })}
            </List>
        );
    };

    const actualSidebarWidth = hideSidebar ? 0 : (isMobile ? 0 : (isSidebarOpen ? fullSidebarWidth : miniSidebarWidth));
    const drawerPaperWidth = hideSidebar ? 0 : (isMobile ? fullSidebarWidth : (isSidebarOpen ? fullSidebarWidth : miniSidebarWidth));

    return (
        <Box sx={{ display: 'flex', height: '100vh', width: '100vw', overflow: 'hidden', bgcolor: 'background.default' }}>
            {!hideSidebar && (
                <Drawer
                    variant={isMobile ? 'temporary' : 'permanent'}
                    open={isSidebarOpen}
                    onClose={() => setSidebarOpen(false)}
                    ModalProps={{
                        keepMounted: true,
                        ...(isMobile && !isSidebarOpen && { style: { pointerEvents: 'none' } }),
                        BackdropProps: { style: { pointerEvents: isSidebarOpen ? 'auto' : 'none' } },
                    }}
                    sx={{
                        width: drawerPaperWidth, flexShrink: 0, transition: 'width 0.2s',
                        ['& .MuiDrawer-paper']: {
                            width: drawerPaperWidth,
                            boxSizing: 'border-box',
                            borderRight: (t: any) => `1px solid ${t.palette.divider}`,
                            backgroundColor: 'background.paper',
                            color: 'text.primary',
                            boxShadow: isMobile ? '4px 0 20px rgba(0,0,0,0.3)' : 'none',
                            transition: 'width 0.2s, background-color 0.3s, color 0.3s',
                            overflowX: 'hidden',
                        },
                    }}
                >
                    <Box sx={{ display: 'flex', alignItems: 'center', px: '12px', borderBottom: (t: any) => `1px solid ${t.palette.divider}`, height: 64, minHeight: 64 }}>
                        <Tooltip title={isSidebarOpen ? 'Contraer menu' : 'Expandir menu'}>
                            <Box sx={{ width: 48, minWidth: 48, display: 'flex', justifyContent: 'center' }}>
                                <IconButton
                                    onClick={() => setSidebarOpen(!isSidebarOpen)}
                                    size="small"
                                    sx={{
                                        width: 32, height: 32, borderRadius: '6px',
                                        color: 'text.secondary', bgcolor: 'transparent',
                                        '&:hover': { bgcolor: 'action.hover' },
                                        '& .MuiSvgIcon-root': { fontSize: '1.15rem' },
                                    }}
                                >
                                    {isSidebarOpen ? <MenuOpenOutlinedIcon /> : <MenuOutlinedIcon />}
                                </IconButton>
                            </Box>
                        </Tooltip>
                        <Box sx={{ overflow: 'hidden', maxWidth: isSidebarOpen ? 200 : 0, opacity: isSidebarOpen ? 1 : 0, transition: 'max-width 0.2s ease, opacity 0.15s ease', whiteSpace: 'nowrap', display: 'flex', alignItems: 'center', gap: 1 }}>
                            {logoIcon ? <Box sx={{ display: 'flex', alignItems: 'center', ml: 1 }}>{logoIcon}</Box> : null}
                            <Typography
                                variant="h6"
                                sx={{ ml: logoIcon ? 0 : 1, fontWeight: 700, cursor: 'pointer' }}
                                onClick={() => router.push('/')}
                            >
                                {appTitle}
                            </Typography>
                        </Box>
                    </Box>
                    <Box sx={{ overflowY: 'auto', flexGrow: 1, py: 2 }}>
                        {renderSidebarItems()}
                    </Box>
                </Drawer>
            )}

            <Box sx={{ display: 'flex', flexDirection: 'column', flexGrow: 1, width: `calc(100% - ${actualSidebarWidth}px)`, transition: 'width 0.2s' }}>
                <Box component="header" sx={{ backgroundColor: 'background.paper', color: 'text.primary', transition: 'background-color 0.3s, color 0.3s' }}>
                    <Toolbar
                        variant="dense"
                        sx={{
                            height: 64, minHeight: 64, maxHeight: 64, px: 3,
                            display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                            borderBottom: (t: any) => `1px solid ${t.palette.divider}`,
                        }}
                    >
                        <Box sx={{ display: 'flex', alignItems: 'center' }}>
                            {isMobile && !hideSidebar && (
                                <IconButton
                                    onClick={() => setSidebarOpen(true)}
                                    size="small"
                                    sx={{
                                        width: 32, height: 32, borderRadius: '6px', mr: 2,
                                        color: 'text.secondary',
                                        '&:hover': { bgcolor: 'action.hover' },
                                        '& .MuiSvgIcon-root': { fontSize: '1.15rem' },
                                    }}
                                >
                                    <MenuOutlinedIcon />
                                </IconButton>
                            )}
                            {!hideSidebar && (
                                <Typography variant="body1" sx={{ ml: { xs: 0, sm: 2 }, color: 'text.secondary', display: 'flex', alignItems: 'center', gap: 1 }}>
                                    <Typography
                                        component="span"
                                        sx={{
                                            color: (t: any) => t.palette.mode === 'dark' ? brandColors.accent : brandColors.indigo,
                                            cursor: 'pointer', fontWeight: 500,
                                        }}
                                        onClick={() => router.push('/')}
                                    >
                                        Home
                                    </Typography>
                                    <span style={{ display: isMobile ? 'none' : 'inline' }}>/</span>
                                    <Typography
                                        component="span"
                                        sx={{
                                            fontWeight: 500, textTransform: 'capitalize',
                                            display: isMobile ? 'none' : 'inline',
                                            color: 'text.primary',
                                        }}
                                    >
                                        {(pathname || '').split('/').filter(Boolean).join(' / ') || 'Dashboard'}
                                    </Typography>
                                </Typography>
                            )}
                        </Box>
                        <Box
                            sx={{
                                display: 'flex', alignItems: 'center',
                                gap: { xs: 0.5, sm: 1 },
                                '& .MuiIconButton-root': {
                                    width: 32, height: 32, borderRadius: '6px',
                                    color: 'text.secondary',
                                    '&:hover': { bgcolor: 'action.hover' },
                                    '& .MuiSvgIcon-root': { fontSize: '1.15rem' },
                                },
                            }}
                        >
                            {topBarExtras}
                            <ThemeToggle />
                            <Box
                                onClick={(e: React.MouseEvent<HTMLElement>) => setAnchorEl(e.currentTarget)}
                                component="button"
                                sx={{
                                    p: 0.5, pr: 1.5, gap: 1, alignItems: 'center',
                                    borderRadius: 8, bgcolor: 'transparent', border: 'none',
                                    cursor: 'pointer', color: 'inherit', display: 'flex',
                                    '&:hover': { bgcolor: 'action.hover' },
                                }}
                            >
                                <Avatar
                                    src={userAvatarUrl}
                                    sx={{
                                        width: 36, height: 36, fontSize: '1rem', fontWeight: 600,
                                        bgcolor: brandColors.indigo, color: '#fff',
                                    }}
                                >
                                    {userAvatarUrl ? null : getInitials(resolvedUserName)}
                                </Avatar>
                                <Box sx={{ display: { xs: 'none', sm: 'flex' }, flexDirection: 'column', alignItems: 'flex-start' }}>
                                    <Typography variant="subtitle2" fontWeight="600" sx={{ color: 'inherit' }}>
                                        {resolvedUserName}
                                    </Typography>
                                </Box>
                            </Box>
                            <Menu
                                anchorEl={anchorEl}
                                open={Boolean(anchorEl)}
                                onClose={() => setAnchorEl(null)}
                                slotProps={{
                                    paper: {
                                        elevation: 0,
                                        sx: { overflow: 'visible', filter: 'drop-shadow(0px 2px 8px rgba(0,0,0,0.32))', mt: 1.5 },
                                    },
                                }}
                                transformOrigin={{ horizontal: 'right', vertical: 'top' }}
                                anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
                            >
                                <MenuItem onClick={() => { setAnchorEl(null); router.push('/mi-cuenta'); }}>
                                    <AccountCircleIcon sx={{ mr: 1 }} /> Mi Perfil
                                </MenuItem>
                                <Divider />
                                <MenuItem onClick={() => { setAnchorEl(null); handleLogout(); }}>
                                    <ListItemIcon><LogoutIcon fontSize="small" /></ListItemIcon>
                                    Cerrar Sesion
                                </MenuItem>
                            </Menu>
                        </Box>
                    </Toolbar>
                </Box>

                <Box
                    component="main"
                    sx={{
                        flexGrow: 1, minHeight: 0, overflow: 'auto',
                        bgcolor: 'background.default',
                        p: { xs: 2, md: 3 },
                        display: 'flex', flexDirection: 'column',
                    }}
                >
                    <Box sx={{ flexGrow: 1 }}>{children}</Box>
                    <Box sx={{ pt: 4, pb: 1, display: 'flex', justifyContent: 'center' }}>
                        <Typography variant="caption" color="text.secondary">
                            Powered by Zentto {new Date().getFullYear()}
                        </Typography>
                    </Box>
                </Box>
            </Box>
        </Box>
    );
}
