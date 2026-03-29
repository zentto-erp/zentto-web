'use client';

import { useState, useCallback } from 'react';
import { renderToFullHtml, getTemplateById } from '@zentto/report-core';
import type { ReportLayout, DataSet } from '@zentto/report-core';

export interface PrintButtonProps {
  /** ID del template (de REPORT_TEMPLATES) */
  templateId: string;
  /** Datos para el reporte. Si es función, se ejecuta al click (lazy fetch) */
  data: DataSet | (() => Promise<DataSet>);
  /** Layout override (si el admin configuró uno personalizado) */
  customLayout?: ReportLayout | null;
  /** Texto del botón */
  label?: string;
  /** Clase CSS adicional */
  className?: string;
  /** Estilo inline */
  style?: React.CSSProperties;
  /** Variante visual */
  variant?: 'icon' | 'button' | 'menu-item';
  /** Deshabilitado */
  disabled?: boolean;
  /** Callback después de imprimir */
  onPrinted?: () => void;
  children?: React.ReactNode;
}

/**
 * Botón de impresión que genera el reporte y abre print dialog del navegador.
 *
 * Usa el layout del template built-in o un customLayout si el admin lo configuró.
 * Los datos pueden ser estáticos o una función async que los fetch al momento del click.
 */
export function PrintButton({
  templateId,
  data,
  customLayout,
  label = 'Imprimir',
  className,
  style,
  variant = 'button',
  disabled = false,
  onPrinted,
  children,
}: PrintButtonProps) {
  const [loading, setLoading] = useState(false);

  const handlePrint = useCallback(async () => {
    setLoading(true);
    try {
      // Resolver layout
      const layout = customLayout ?? getTemplateById(templateId)?.layout;
      if (!layout) {
        console.error(`[PrintButton] Template "${templateId}" no encontrado`);
        return;
      }

      // Resolver datos (sync o async)
      const resolvedData = typeof data === 'function' ? await data() : data;

      // Generar HTML completo
      const html = renderToFullHtml(layout, resolvedData);

      // Abrir ventana de impresión
      const printWindow = window.open('', '_blank', 'width=900,height=700');
      if (!printWindow) {
        console.error('[PrintButton] Popup bloqueado por el navegador');
        return;
      }

      printWindow.document.write(html);
      printWindow.document.close();

      // Esperar a que cargue y luego imprimir
      printWindow.onload = () => {
        printWindow.focus();
        printWindow.print();
        onPrinted?.();
      };
    } catch (err) {
      console.error('[PrintButton] Error generando reporte:', err);
    } finally {
      setLoading(false);
    }
  }, [templateId, data, customLayout, onPrinted]);

  if (variant === 'icon') {
    return (
      <button
        onClick={handlePrint}
        disabled={disabled || loading}
        className={className}
        style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 4, ...style }}
        title={label}
        aria-label={label}
      >
        {loading ? '⏳' : '🖨️'}
      </button>
    );
  }

  if (variant === 'menu-item') {
    return (
      <div
        onClick={disabled || loading ? undefined : handlePrint}
        className={className}
        style={{ cursor: disabled ? 'default' : 'pointer', padding: '8px 16px', opacity: disabled ? 0.5 : 1, ...style }}
        role="menuitem"
      >
        {loading ? '⏳ Generando...' : `🖨️ ${label}`}
      </div>
    );
  }

  return (
    <button
      onClick={handlePrint}
      disabled={disabled || loading}
      className={className}
      style={{
        display: 'inline-flex', alignItems: 'center', gap: 8,
        padding: '8px 16px', borderRadius: 6,
        background: '#1a1a2e', color: '#fff', border: 'none',
        cursor: disabled ? 'default' : 'pointer',
        opacity: disabled || loading ? 0.6 : 1,
        fontSize: 14, fontWeight: 500,
        ...style,
      }}
    >
      {loading ? '⏳' : '🖨️'} {children ?? label}
    </button>
  );
}
