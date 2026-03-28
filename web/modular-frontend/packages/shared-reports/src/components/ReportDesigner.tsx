'use client';

import React, { useEffect, useRef } from 'react';
import type { ReportLayout, DataSet, DataSourceDef } from '@zentto/report-core';

// Importar el web component (side-effect: registra <zentto-report-designer>)
import '@zentto/report-designer';

export interface ReportDesignerProps {
  layout: ReportLayout | null;
  sampleData?: DataSet | null;
  dataSources?: DataSourceDef[];
  showPreview?: boolean;
  gridSnap?: number;
  autoSaveMs?: number;
  style?: React.CSSProperties;
  className?: string;
  /** Callback cuando el usuario modifica el layout */
  onLayoutChange?: (layout: ReportLayout) => void;
}

/**
 * React wrapper para <zentto-report-designer>.
 *
 * Editor visual de reportes con drag-and-drop, binding de datos, y preview
 * en tiempo real. Solo accesible para administradores (controlar desde el
 * componente padre con isAdminRole).
 */
export function ReportDesigner({
  layout,
  sampleData,
  dataSources = [],
  showPreview = true,
  gridSnap = 1,
  autoSaveMs = 3000,
  style,
  className,
  onLayoutChange,
}: ReportDesignerProps) {
  const ref = useRef<HTMLElement & Record<string, unknown>>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    requestAnimationFrame(() => {
      el.layout = layout;
      el.sampleData = sampleData ?? null;
      el.dataSources = dataSources;
      el.showPreview = showPreview;
      el.gridSnap = gridSnap;
      el.autoSaveMs = autoSaveMs;
    });
  }, [layout, sampleData, dataSources, showPreview, gridSnap, autoSaveMs]);

  // Escuchar eventos del web component
  useEffect(() => {
    const el = ref.current;
    if (!el || !onLayoutChange) return;

    const handler = (e: Event) => {
      const detail = (e as CustomEvent).detail;
      if (detail?.layout) onLayoutChange(detail.layout);
    };

    el.addEventListener('layout-change', handler);
    return () => el.removeEventListener('layout-change', handler);
  }, [onLayoutChange]);

  // React.createElement avoids JSX type issues with custom elements in React 19
  return React.createElement('zentto-report-designer', {
    ref,
    className,
    style: { display: 'block', width: '100%', height: '100%', minHeight: 600, ...style },
  });
}
