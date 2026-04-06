'use client';

import React, { useState } from 'react';
import { useTranslation } from './useTranslation';
import { SUPPORTED_LOCALES } from './provider';
import type { Locale } from './provider';

/**
 * Minimal locale selector dropdown.
 * Renders as an IconButton + Menu using MUI components
 * passed via the render-prop pattern to avoid a hard MUI dependency
 * in shared-i18n. For convenience, a default implementation using
 * plain HTML is provided when no render prop is given.
 */
export interface LocaleSelectorProps {
  /** Optional className for the wrapper */
  className?: string;
  /** Size variant */
  size?: 'small' | 'medium';
}

export default function LocaleSelector({ className, size = 'small' }: LocaleSelectorProps) {
  const { locale, setLocale } = useTranslation();
  const [open, setOpen] = useState(false);
  const ref = React.useRef<HTMLDivElement>(null);

  const current = SUPPORTED_LOCALES.find((l) => l.code === locale)!;

  return (
    <div ref={ref} className={className} style={{ position: 'relative', display: 'inline-block' }}>
      <button
        type="button"
        onClick={() => setOpen((p) => !p)}
        aria-label="Change language"
        style={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: 4,
          padding: size === 'small' ? '4px 8px' : '6px 12px',
          border: '1px solid var(--locale-border, rgba(0,0,0,0.23))',
          borderRadius: 6,
          background: 'transparent',
          cursor: 'pointer',
          fontSize: size === 'small' ? '0.8rem' : '0.9rem',
          fontWeight: 500,
          color: 'inherit',
          lineHeight: 1.4,
        }}
      >
        <span>{current.flag}</span>
        <span>{current.code.toUpperCase()}</span>
      </button>

      {open && (
        <>
          {/* Backdrop */}
          <div
            style={{ position: 'fixed', inset: 0, zIndex: 1300 }}
            onClick={() => setOpen(false)}
          />
          {/* Dropdown */}
          <div
            style={{
              position: 'absolute',
              top: '100%',
              right: 0,
              marginTop: 4,
              minWidth: 140,
              borderRadius: 8,
              boxShadow: '0 4px 20px rgba(0,0,0,0.15)',
              background: 'var(--locale-bg, #fff)',
              zIndex: 1301,
              overflow: 'hidden',
            }}
          >
            {SUPPORTED_LOCALES.map((loc) => (
              <button
                key={loc.code}
                type="button"
                onClick={() => {
                  setLocale(loc.code as Locale);
                  setOpen(false);
                }}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 8,
                  width: '100%',
                  padding: '8px 14px',
                  border: 'none',
                  background: loc.code === locale ? 'var(--locale-selected, rgba(0,0,0,0.06))' : 'transparent',
                  cursor: 'pointer',
                  fontSize: '0.85rem',
                  fontWeight: loc.code === locale ? 600 : 400,
                  color: 'inherit',
                  textAlign: 'left',
                }}
              >
                <span>{loc.flag}</span>
                <span>{loc.label}</span>
              </button>
            ))}
          </div>
        </>
      )}
    </div>
  );
}
