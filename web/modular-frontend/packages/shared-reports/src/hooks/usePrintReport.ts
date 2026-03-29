'use client';

import { useState, useCallback } from 'react';
import { renderToFullHtml, getTemplateById } from '@zentto/report-core';
import type { ReportLayout, DataSet } from '@zentto/report-core';

export interface UsePrintReportOptions {
  /** Template ID o layout directo */
  templateId?: string;
  layout?: ReportLayout;
  /** Custom layout override (admin) */
  customLayout?: ReportLayout | null;
}

export interface UsePrintReportReturn {
  /** Ejecutar impresión con los datos proporcionados */
  print: (data: DataSet) => void;
  /** Generar HTML sin imprimir */
  generateHtml: (data: DataSet) => string | null;
  /** Preview en nueva ventana sin diálogo de impresión */
  preview: (data: DataSet) => void;
  /** Estado de carga */
  loading: boolean;
}

/**
 * Hook para imprimir o previsualizar un reporte.
 *
 * @example
 * ```tsx
 * const { print, preview } = usePrintReport({ templateId: 've-fiscal-invoice' });
 *
 * // Al click de un botón:
 * print({ header: { invoiceNumber: 'FAC-001', ... }, detail: [...] });
 * ```
 */
export function usePrintReport(options: UsePrintReportOptions): UsePrintReportReturn {
  const [loading, setLoading] = useState(false);

  const resolveLayout = useCallback((): ReportLayout | null => {
    if (options.customLayout) return options.customLayout;
    if (options.layout) return options.layout;
    if (options.templateId) return getTemplateById(options.templateId)?.layout ?? null;
    return null;
  }, [options.customLayout, options.layout, options.templateId]);

  const generateHtml = useCallback((data: DataSet): string | null => {
    const layout = resolveLayout();
    if (!layout) return null;
    return renderToFullHtml(layout, data);
  }, [resolveLayout]);

  const print = useCallback((data: DataSet) => {
    setLoading(true);
    try {
      const html = generateHtml(data);
      if (!html) return;

      const win = window.open('', '_blank', 'width=900,height=700');
      if (!win) return;

      win.document.write(html);
      win.document.close();
      win.onload = () => { win.focus(); win.print(); };
    } finally {
      setLoading(false);
    }
  }, [generateHtml]);

  const preview = useCallback((data: DataSet) => {
    const html = generateHtml(data);
    if (!html) return;

    const win = window.open('', '_blank', 'width=900,height=700');
    if (!win) return;
    win.document.write(html);
    win.document.close();
  }, [generateHtml]);

  return { print, generateHtml, preview, loading };
}
