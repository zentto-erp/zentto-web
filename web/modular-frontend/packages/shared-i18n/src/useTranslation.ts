'use client';

import { useContext } from 'react';
import { I18nContext } from './provider';
import type { I18nContextValue, Locale } from './provider';

/**
 * Hook to access i18n translations.
 *
 * Usage:
 *   const { t, locale, setLocale } = useTranslation();
 *   t('actions.save')          // "Guardar"
 *   t('validation.minLength', { min: 3 }) // "Mínimo 3 caracteres"
 */
export function useTranslation(): I18nContextValue {
  const ctx = useContext(I18nContext);
  if (!ctx) {
    throw new Error(
      'useTranslation() must be used inside <I18nProvider>. ' +
        'Wrap your app root (or shell layout) with the provider from @zentto/shared-i18n.',
    );
  }
  return ctx;
}

/**
 * Convenience: returns only the `t` function (useful in components
 * that don't need setLocale).
 */
export function useT(): (key: string, vars?: Record<string, string | number>) => string {
  return useTranslation().t;
}

export type { Locale };
