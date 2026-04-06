'use client';

import React, { createContext, useCallback, useEffect, useMemo, useState } from 'react';

import es from './locales/es.json';
import en from './locales/en.json';
import pt from './locales/pt.json';

/* ------------------------------------------------------------------ */
/*  Types                                                              */
/* ------------------------------------------------------------------ */

export type Locale = 'es' | 'en' | 'pt';

export interface LocaleConfig {
  code: Locale;
  label: string;
  flag: string; // emoji flag
}

export const SUPPORTED_LOCALES: LocaleConfig[] = [
  { code: 'es', label: 'Español', flag: '🇪🇸' },
  { code: 'en', label: 'English', flag: '🇺🇸' },
  { code: 'pt', label: 'Português', flag: '🇧🇷' },
];

export type TranslationMap = Record<string, unknown>;

const LOCALE_BUNDLES: Record<Locale, TranslationMap> = { es, en, pt };

const STORAGE_KEY = 'zentto-locale';
const DEFAULT_LOCALE: Locale = 'es';

/* ------------------------------------------------------------------ */
/*  Context                                                            */
/* ------------------------------------------------------------------ */

export interface I18nContextValue {
  locale: Locale;
  setLocale: (l: Locale) => void;
  t: (key: string, vars?: Record<string, string | number>) => string;
  /** Merge extra translations (module-level overrides). */
  extend: (locale: Locale, extra: TranslationMap) => void;
}

export const I18nContext = createContext<I18nContextValue | null>(null);

/* ------------------------------------------------------------------ */
/*  Helpers                                                            */
/* ------------------------------------------------------------------ */

/**
 * Resolve a dot-separated key from a nested object.
 * e.g. resolve('actions.save', bundle) -> 'Guardar'
 */
function resolve(key: string, obj: Record<string, unknown>): string | undefined {
  const parts = key.split('.');
  let current: unknown = obj;
  for (const part of parts) {
    if (current == null || typeof current !== 'object') return undefined;
    current = (current as Record<string, unknown>)[part];
  }
  return typeof current === 'string' ? current : undefined;
}

/**
 * Replace {{var}} placeholders.
 */
function interpolate(template: string, vars: Record<string, string | number>): string {
  return template.replace(/\{\{(\w+)\}\}/g, (_, k) =>
    vars[k] !== undefined ? String(vars[k]) : `{{${k}}}`,
  );
}

/* ------------------------------------------------------------------ */
/*  Provider                                                           */
/* ------------------------------------------------------------------ */

export interface I18nProviderProps {
  defaultLocale?: Locale;
  /** Extra translations to merge on mount (e.g. module-specific keys). */
  overrides?: Partial<Record<Locale, TranslationMap>>;
  children: React.ReactNode;
}

export function I18nProvider({ defaultLocale, overrides, children }: I18nProviderProps) {
  const [locale, setLocaleState] = useState<Locale>(defaultLocale ?? DEFAULT_LOCALE);
  const [extensions, setExtensions] = useState<Partial<Record<Locale, TranslationMap>>>({});

  // Hydrate from localStorage on mount
  useEffect(() => {
    if (typeof window === 'undefined') return;
    const stored = localStorage.getItem(STORAGE_KEY) as Locale | null;
    if (stored && LOCALE_BUNDLES[stored]) {
      setLocaleState(stored);
    }
  }, []);

  // Apply initial overrides
  useEffect(() => {
    if (overrides) {
      setExtensions((prev) => {
        const next = { ...prev };
        for (const [loc, map] of Object.entries(overrides)) {
          next[loc as Locale] = { ...(next[loc as Locale] ?? {}), ...map };
        }
        return next;
      });
    }
  }, [overrides]);

  const setLocale = useCallback((l: Locale) => {
    setLocaleState(l);
    if (typeof window !== 'undefined') {
      localStorage.setItem(STORAGE_KEY, l);
      document.documentElement.lang = l;
    }
  }, []);

  const extend = useCallback((loc: Locale, extra: TranslationMap) => {
    setExtensions((prev) => ({
      ...prev,
      [loc]: { ...(prev[loc] ?? {}), ...extra },
    }));
  }, []);

  const t = useCallback(
    (key: string, vars?: Record<string, string | number>): string => {
      const bundle = LOCALE_BUNDLES[locale] as Record<string, unknown>;
      const ext = extensions[locale] as Record<string, unknown> | undefined;

      // Try extensions first (module overrides), then base bundle, then fallback to es
      const value =
        (ext ? resolve(key, ext) : undefined) ??
        resolve(key, bundle) ??
        resolve(key, LOCALE_BUNDLES.es as Record<string, unknown>) ??
        key;

      return vars ? interpolate(value, vars) : value;
    },
    [locale, extensions],
  );

  const ctx = useMemo<I18nContextValue>(
    () => ({ locale, setLocale, t, extend }),
    [locale, setLocale, t, extend],
  );

  return <I18nContext.Provider value={ctx}>{children}</I18nContext.Provider>;
}
