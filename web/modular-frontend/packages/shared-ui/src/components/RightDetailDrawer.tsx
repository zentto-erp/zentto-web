'use client';

import * as React from 'react';
import Box from '@mui/material/Box';
import Drawer from '@mui/material/Drawer';
import IconButton from '@mui/material/IconButton';
import Typography from '@mui/material/Typography';
import Tab from '@mui/material/Tab';
import Tabs from '@mui/material/Tabs';
import CloseIcon from '@mui/icons-material/Close';
import useMediaQuery from '@mui/material/useMediaQuery';
import { useTheme } from '@mui/material/styles';

/**
 * Definición de un tab dentro del drawer.
 */
export interface DrawerTab {
  /** Identificador estable (también usado en query param `?tab=<key>`). */
  key: string;
  /** Etiqueta visible en el tab. */
  label: React.ReactNode;
  /** Contenido renderizado cuando el tab está activo. */
  content: React.ReactNode;
  /** Icono opcional antes del label. */
  icon?: React.ReactElement;
}

export interface RightDetailDrawerWidth {
  /** Ancho en desktop (px). Default: 480. */
  desktop?: number;
  /** Ancho en mobile (string CSS). Default: '100%'. */
  mobile?: string;
}

export interface RightDetailDrawerProps {
  /** Abierto / cerrado. */
  open: boolean;
  /** Callback de cierre — invocado en Esc, backdrop click o botón X. */
  onClose: () => void;
  /** Título principal del drawer. */
  title: React.ReactNode;
  /** Subtítulo opcional bajo el título. */
  subtitle?: React.ReactNode;
  /** Lista de tabs. Si se omite, el drawer muestra `children` directo. */
  tabs?: DrawerTab[];
  /** Tab activa (controlado). Si falta, el drawer maneja el estado internamente. */
  activeTab?: string;
  /** Callback cuando el usuario cambia de tab. */
  onTabChange?: (key: string) => void;
  /** Tab por defecto si el drawer es uncontrolled. */
  defaultTab?: string;
  /** Anchos responsive. */
  width?: RightDetailDrawerWidth;
  /** Contenido si `tabs` no está definido. */
  children?: React.ReactNode;
  /** Acciones en el header (al lado del botón cerrar). */
  headerActions?: React.ReactNode;
}

/**
 * Panel lateral derecho para ver/editar un registro sin perder contexto de la
 * lista. Patrón HubSpot / Linear / Attio (ver DESIGN.md §4.4 y §5.1).
 *
 * - Desktop: overlay 480 px (configurable) con backdrop.
 * - Mobile (<600 px): fullscreen.
 * - Cierra con `Esc` (propagado por MUI Drawer), click backdrop, botón X.
 * - Focus trap + retorno de foco al cerrar (MUI maneja `disableRestoreFocus={false}`).
 * - `role="dialog"` + `aria-modal` + `aria-labelledby` → título.
 * - Tabs opcionales con keyboard navigation (MUI Tabs → ARIA role="tablist").
 */
export default function RightDetailDrawer({
  open,
  onClose,
  title,
  subtitle,
  tabs,
  activeTab: activeTabProp,
  onTabChange,
  defaultTab,
  width,
  children,
  headerActions,
}: RightDetailDrawerProps) {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm')); // <600px fullscreen
  const desktopWidth = width?.desktop ?? 480;
  const mobileWidth = width?.mobile ?? '100%';
  const titleId = React.useId();

  // Tab state — controlled vs uncontrolled.
  const firstTabKey = tabs && tabs.length > 0 ? tabs[0].key : undefined;
  const [internalTab, setInternalTab] = React.useState<string | undefined>(
    defaultTab ?? firstTabKey,
  );
  const effectiveTab = activeTabProp ?? internalTab ?? firstTabKey;

  const handleTabChange = (_e: React.SyntheticEvent, nextKey: string) => {
    if (activeTabProp === undefined) setInternalTab(nextKey);
    onTabChange?.(nextKey);
  };

  const currentTab = tabs?.find((t) => t.key === effectiveTab);

  return (
    <Drawer
      anchor="right"
      open={open}
      onClose={onClose}
      ModalProps={{
        keepMounted: false,
      }}
      slotProps={{
        paper: {
          role: 'dialog',
          'aria-modal': true,
          'aria-labelledby': titleId,
          sx: {
            width: isMobile ? mobileWidth : desktopWidth,
            maxWidth: '100vw',
            display: 'flex',
            flexDirection: 'column',
            bgcolor: 'background.paper',
          },
        },
      }}
    >
      {/* Header */}
      <Box
        sx={{
          px: 2.5,
          pt: 2,
          pb: tabs && tabs.length > 0 ? 0 : 2,
          borderBottom: tabs && tabs.length > 0 ? 'none' : '1px solid',
          borderColor: 'divider',
          flexShrink: 0,
        }}
      >
        <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 1 }}>
          <Box sx={{ flex: 1, minWidth: 0 }}>
            <Typography
              id={titleId}
              variant="h6"
              component="h2"
              sx={{ fontWeight: 600, lineHeight: 1.2 }}
              noWrap
            >
              {title}
            </Typography>
            {subtitle && (
              <Typography variant="body2" color="text.secondary" sx={{ mt: 0.25 }} noWrap>
                {subtitle}
              </Typography>
            )}
          </Box>
          {headerActions}
          <IconButton
            onClick={onClose}
            size="small"
            aria-label="Cerrar panel de detalle"
            sx={{ mt: -0.5 }}
          >
            <CloseIcon fontSize="small" />
          </IconButton>
        </Box>

        {/* Tabs */}
        {tabs && tabs.length > 0 && (
          <Tabs
            value={effectiveTab}
            onChange={handleTabChange}
            variant="scrollable"
            scrollButtons="auto"
            allowScrollButtonsMobile
            sx={{
              mt: 1.5,
              minHeight: 40,
              '& .MuiTab-root': {
                minHeight: 40,
                py: 1,
                textTransform: 'none',
                fontSize: '0.875rem',
                fontWeight: 500,
              },
            }}
            aria-label="Secciones del detalle"
          >
            {tabs.map((t) => (
              <Tab
                key={t.key}
                value={t.key}
                label={t.label}
                icon={t.icon}
                iconPosition="start"
                id={`drawer-tab-${t.key}`}
                aria-controls={`drawer-tabpanel-${t.key}`}
              />
            ))}
          </Tabs>
        )}
      </Box>

      {/* Body */}
      <Box
        sx={{ flexGrow: 1, overflowY: 'auto', p: 2.5 }}
        role={tabs && tabs.length > 0 ? 'tabpanel' : undefined}
        id={currentTab ? `drawer-tabpanel-${currentTab.key}` : undefined}
        aria-labelledby={currentTab ? `drawer-tab-${currentTab.key}` : undefined}
      >
        {tabs && tabs.length > 0 ? currentTab?.content : children}
      </Box>
    </Drawer>
  );
}
