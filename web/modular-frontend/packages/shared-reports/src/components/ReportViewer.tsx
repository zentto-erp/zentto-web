'use client';

import React, { useEffect, useRef } from 'react';
import type { ReportLayout, DataSet } from '@zentto/report-core';

// Importar el web component (side-effect: registra <zentto-report-viewer>)
import '@zentto/report-viewer';

export interface ReportViewerProps {
  layout: ReportLayout | null;
  data: DataSet | null;
  zoom?: number;
  showToolbar?: boolean;
  theme?: 'light' | 'dark';
  viewMode?: 'single' | 'all';
  showThumbnails?: boolean;
  toolbarItems?: string[];
  style?: React.CSSProperties;
  className?: string;
}

/**
 * React wrapper para <zentto-report-viewer>.
 *
 * Renderiza un reporte completo con toolbar de navegación, zoom, impresión
 * y exportación. Acepta layout + data como props React y los sincroniza
 * con el web component Lit interno.
 */
export function ReportViewer({
  layout,
  data,
  zoom = 100,
  showToolbar = true,
  theme = 'light',
  viewMode = 'single',
  showThumbnails = false,
  toolbarItems = ['navigation', 'zoom', 'view-mode', 'fit-width', 'print', 'download-html', 'theme'],
  style,
  className,
}: ReportViewerProps) {
  const ref = useRef<HTMLElement & Record<string, unknown>>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    requestAnimationFrame(() => {
      el.layout = layout;
      el.data = data;
      el.zoom = zoom;
      el.showToolbar = showToolbar;
      el.theme = theme;
      el.viewMode = viewMode;
      el.showThumbnails = showThumbnails;
      el.toolbarItems = toolbarItems;
    });
  }, [layout, data, zoom, showToolbar, theme, viewMode, showThumbnails, toolbarItems]);

  // React.createElement avoids JSX type issues with custom elements in React 19
  return React.createElement('zentto-report-viewer', {
    ref,
    className,
    style: { display: 'block', width: '100%', height: '100%', minHeight: 400, ...style },
  });
}
