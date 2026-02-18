'use client';
import React from 'react';
import {
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Collapse,
  useTheme,
} from '@mui/material';
import ExpandLess from '@mui/icons-material/ExpandLess';
import ExpandMore from '@mui/icons-material/ExpandMore';
import { useRouter, usePathname } from 'next/navigation';

export interface MenuItem {
  title: string;
  icon?: any;
  href?: string;
  children?: MenuItem[];
  requiredRole?: 'admin' | 'user' | 'any';
}

interface NavigationMenuProps {
  items: MenuItem[];
  collapsed?: boolean;
  onNavigate?: () => void;
  level?: number;
}

export function NavigationMenu({
  items,
  collapsed = false,
  onNavigate,
  level = 0,
}: NavigationMenuProps) {
  const [openSubmenu, setOpenSubmenu] = React.useState<Set<string>>(new Set());
  const router = useRouter();
  const pathname = usePathname();
  const theme = useTheme();

  const handleSubmenuToggle = (title: string) => {
    const newOpen = new Set(openSubmenu);
    if (newOpen.has(title)) {
      newOpen.delete(title);
    } else {
      newOpen.add(title);
    }
    setOpenSubmenu(newOpen);
  };

  const handleNavigate = (href?: string) => {
    if (href) {
      router.push(href);
      onNavigate?.();
    }
  };

  const isActive = (href?: string) => {
    if (!href) return false;
    return pathname === href || pathname.startsWith(href + '/');
  };

  return (
    <List sx={{ width: '100%', py: 0 }}>
      {items.map((item) => {
        const hasChildren = item.children && item.children.length > 0;
        const isItemActive = isActive(item.href);
        const isSubmenuOpen = openSubmenu.has(item.title);

        return (
          <React.Fragment key={item.title}>
            <ListItem
              button
              onClick={() => {
                if (hasChildren) {
                  handleSubmenuToggle(item.title);
                } else {
                  handleNavigate(item.href);
                }
              }}
              sx={{
                pl: level * 2,
                borderRadius: 1,
                mb: 0.5,
                bgcolor: isItemActive ? 'action.selected' : 'transparent',
                '&:hover': {
                  bgcolor: 'action.hover',
                },
                transition: theme.transitions.create('all'),
              }}
            >
              {item.icon && !collapsed && (
                <ListItemIcon sx={{ minWidth: 40 }}>
                  <item.icon />
                </ListItemIcon>
              )}
              {!collapsed && <ListItemText primary={item.title} />}
              {hasChildren && !collapsed && (
                isSubmenuOpen ? <ExpandLess /> : <ExpandMore />
              )}
            </ListItem>

            {hasChildren && (
              <Collapse
                in={isSubmenuOpen}
                timeout="auto"
                unmountOnExit
              >
                <NavigationMenu
                  items={item.children}
                  collapsed={collapsed}
                  onNavigate={onNavigate}
                  level={level + 1}
                />
              </Collapse>
            )}
          </React.Fragment>
        );
      })}
    </List>
  );
}
