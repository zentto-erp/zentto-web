'use client';

import * as React from 'react';
import { useHardwareAgent } from '../hooks/useHardwareAgent';

const DOWNLOAD_URL =
  'https://github.com/zentto-erp/zentto-fiscal-agent-releases/releases/latest/download/ZenttoFiscalAgent-Setup.exe';

const SESSION_KEY = 'zentto_hardware_banner_dismissed';

const POS_FISCAL_MODULES = ['pos', 'fiscal', 'impresoras', 'contabilidad'];

interface HardwareAgentBannerProps {
  /** Lista de módulos activos del usuario. Si está vacía o no se provee, el banner siempre se muestra. */
  modulos?: string[];
}

function hasPosOrFiscalModule(modulos?: string[]): boolean {
  if (!modulos || modulos.length === 0) return true; // sin info de módulos → mostrar siempre
  return modulos.some((m) => POS_FISCAL_MODULES.includes(m));
}

export function HardwareAgentBanner({ modulos }: HardwareAgentBannerProps) {
  const { isChecking, isConnected, retry } = useHardwareAgent();
  const [dismissed, setDismissed] = React.useState<boolean>(() => {
    if (typeof window === 'undefined') return false;
    return sessionStorage.getItem(SESSION_KEY) === '1';
  });

  const shouldShow = !isChecking && !isConnected && !dismissed && hasPosOrFiscalModule(modulos);

  if (!shouldShow) return null;

  function handleDismiss() {
    sessionStorage.setItem(SESSION_KEY, '1');
    setDismissed(true);
  }

  return (
    <div
      role="alert"
      aria-live="polite"
      style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        flexWrap: 'wrap',
        gap: '8px',
        padding: '10px 16px',
        backgroundColor: '#FFF3CD',
        borderBottom: '2px solid #E6A817',
        color: '#7D4E00',
        fontSize: '14px',
        fontFamily: 'inherit',
        lineHeight: '1.5',
        zIndex: 9999,
        width: '100%',
        boxSizing: 'border-box',
      }}
    >
      {/* Icono advertencia */}
      <span aria-hidden="true" style={{ fontSize: '18px', flexShrink: 0 }}>
        ⚠
      </span>

      {/* Texto principal */}
      <span style={{ flex: 1, minWidth: '200px' }}>
        <strong>Zentto Hardware Hub no detectado</strong> — impresoras fiscales y POS no
        disponibles.
      </span>

      {/* Botones */}
      <div style={{ display: 'flex', gap: '8px', flexShrink: 0, alignItems: 'center' }}>
        <a
          href={DOWNLOAD_URL}
          style={{
            display: 'inline-block',
            padding: '5px 14px',
            backgroundColor: '#E6A817',
            color: '#fff',
            borderRadius: '4px',
            textDecoration: 'none',
            fontSize: '13px',
            fontWeight: 600,
            whiteSpace: 'nowrap',
          }}
        >
          Instalar agente
        </a>

        <button
          type="button"
          onClick={retry}
          title="Reintentar detección"
          style={{
            padding: '5px 10px',
            backgroundColor: 'transparent',
            border: '1px solid #E6A817',
            borderRadius: '4px',
            color: '#7D4E00',
            cursor: 'pointer',
            fontSize: '13px',
            whiteSpace: 'nowrap',
          }}
        >
          Reintentar
        </button>

        <button
          type="button"
          onClick={handleDismiss}
          aria-label="Cerrar aviso"
          title="Cerrar"
          style={{
            padding: '4px 8px',
            backgroundColor: 'transparent',
            border: 'none',
            cursor: 'pointer',
            color: '#7D4E00',
            fontSize: '18px',
            lineHeight: 1,
            fontWeight: 700,
          }}
        >
          ×
        </button>
      </div>
    </div>
  );
}
