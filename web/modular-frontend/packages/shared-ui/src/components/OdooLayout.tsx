'use client';
import * as React from 'react';
import Box from '@mui/material/Box';
import AppBar from '@mui/material/AppBar';
import Toolbar from '@mui/material/Toolbar';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import IconButton from '@mui/material/IconButton';
import Menu from '@mui/material/Menu';
import MenuItem from '@mui/material/MenuItem';
import { useRouter, usePathname } from 'next/navigation';
import { useSession } from 'next-auth/react';
import { useTheme } from '@mui/material/styles';
import KeyboardArrowDownIcon from '@mui/icons-material/KeyboardArrowDown';
import AppsIcon from '@mui/icons-material/Apps';
import AppTitle from './AppTitle';
import SidebarFooterAccount from './SidebarFooterAccount';
import Copyright from './Copyright';

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
    navigationFields?: any[]
}) {
    const router = useRouter();
    const pathname = usePathname();
    const theme = useTheme();
    const { data: session } = useSession();

    // Anchor elements for dropdown menus
    const [anchorEls, setAnchorEls] = React.useState<{ [key: string]: HTMLElement | null }>({});

    const handleOpen = (event: React.MouseEvent<HTMLElement>, key: string) => {
        setAnchorEls({ ...anchorEls, [key]: event.currentTarget });
    };

    const handleClose = (key: string) => {
        setAnchorEls({ ...anchorEls, [key]: null });
    };

    const handleNavigate = (path: string, key?: string) => {
        router.push(`/${path}`);
        if (key) handleClose(key);
    };

    // Convert generic navigation to Top NavBar headers + items
    const renderNavItems = () => {
        if (!navigationFields) return null;

        // Simple parser: group by non-segments
        const menus: { title: string, items: any[] }[] = [];
        let currentMenu = menus.find(m => m.title === 'Principal');
        if (!currentMenu) {
            currentMenu = { title: 'Principal', items: [] };
            menus.push(currentMenu);
        }

        navigationFields.forEach(item => {
            if (item.kind === 'header') {
                currentMenu = { title: item.title, items: [] };
                menus.push(currentMenu);
            } else if (item.kind === 'page') {
                currentMenu!.items.push(item);
            }
        });

        return menus.filter(m => m.items.length > 0).map((menu, idx) => {
            // If menu has only 1 root item, show it directly
            if (menu.items.length === 1 && !menu.items[0].children) {
                const item = menu.items[0];
                const isActive = pathname === `/${item.segment}` || pathname.startsWith(`/${item.segment}/`);
                return (
                    <Button
                        key={idx}
                        onClick={() => handleNavigate(item.segment || '')}
                        sx={{
                            color: isActive ? theme.palette.text.primary : theme.palette.text.secondary,
                            fontWeight: isActive ? 600 : 500,
                            fontSize: '0.9rem',
                            '&:hover': { backgroundColor: 'rgba(0,0,0,0.04)' }
                        }}
                    >
                        {item.title}
                    </Button>
                );
            }

            // Show dropdown for multiple items
            const isActive = menu.items.some(it => pathname.startsWith(`/${it.segment}`));
            const menuKey = `menu-${idx}`;

            return (
                <React.Fragment key={idx}>
                    <Button
                        onClick={(e) => handleOpen(e, menuKey)}
                        endIcon={<KeyboardArrowDownIcon />}
                        sx={{
                            color: isActive ? theme.palette.text.primary : theme.palette.text.secondary,
                            fontWeight: isActive ? 600 : 500,
                            fontSize: '0.9rem',
                            '&:hover': { backgroundColor: 'rgba(0,0,0,0.04)' }
                        }}
                    >
                        {menu.title}
                    </Button>
                    <Menu
                        anchorEl={anchorEls[menuKey]}
                        open={Boolean(anchorEls[menuKey])}
                        onClose={() => handleClose(menuKey)}
                        elevation={2}
                        PaperProps={{
                            sx: { mt: 1, minWidth: 150, borderRadius: 2 }
                        }}
                    >
                        {menu.items.map((it, i) => (
                            it.children ? (
                                // If it has deep children, just render them flat for now
                                [
                                    <MenuItem disabled key={`header-${i}`} sx={{ fontWeight: 600, fontSize: '0.75rem', textTransform: 'uppercase', color: 'text.secondary', mt: 1 }}>{it.title}</MenuItem>,
                                    ...it.children.map((sub: any, j: number) => (
                                        <MenuItem key={`${i}-${j}`} onClick={() => handleNavigate(`${it.segment}/${sub.segment}`, menuKey)}>
                                            {sub.title}
                                        </MenuItem>
                                    ))
                                ]
                            ) : (
                                <MenuItem key={i} onClick={() => handleNavigate(it.segment, menuKey)}>
                                    {it.title}
                                </MenuItem>
                            )
                        ))}
                    </Menu>
                </React.Fragment>
            );
        });
    };

    return (
        <Box sx={{ display: 'flex', flexDirection: 'column', height: '100vh', width: '100vw', overflow: 'hidden', bgcolor: 'background.default' }}>
            <AppBar position="static" elevation={0} sx={{ backgroundColor: '#fff', borderBottom: '1px solid #E5E7EB', color: 'text.primary' }}>
                <Toolbar variant="dense" sx={{ minHeight: 56, px: 2, display: 'flex', justifyContent: 'space-between' }}>

                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                        <Box sx={{ display: 'flex', alignItems: 'center', mr: 2 }}>
                            <IconButton onClick={() => router.push('/')} size="small" sx={{ mr: 1, color: 'primary.main', bgcolor: 'transparent', '&:hover': { bgcolor: 'rgba(0,0,0,0.04)' } }}>
                                <AppsIcon />
                            </IconButton>
                            <Typography variant="h6" color="primary.main" sx={{ fontWeight: 600, letterSpacing: -0.5 }}>
                                <AppTitle />
                            </Typography>
                        </Box>

                        {/* Dynamic Navigation Mapped to Horizontal Bar */}
                        <Box sx={{ display: { xs: 'none', md: 'flex' }, gap: 1 }}>
                            {renderNavItems()}
                        </Box>
                    </Box>

                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <SidebarFooterAccount mini={false} />
                    </Box>
                </Toolbar>
            </AppBar>

            <Box component="main" sx={{ flexGrow: 1, display: 'flex', flexDirection: 'column', minHeight: 0, overflow: 'auto' }}>
                {children}
            </Box>
        </Box>
    );
}
