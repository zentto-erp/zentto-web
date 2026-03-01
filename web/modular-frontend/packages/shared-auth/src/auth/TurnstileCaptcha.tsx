'use client';

import React from 'react';
import { Alert, Box, Typography } from '@mui/material';

declare global {
  interface Window {
    turnstile?: {
      render: (container: HTMLElement, options: Record<string, unknown>) => string;
      remove: (widgetId: string) => void;
      reset: (widgetId?: string) => void;
    };
  }
}

type TurnstileCaptchaProps = {
  onTokenChange: (token: string) => void;
};

const SCRIPT_ID = 'cf-turnstile-script';

function getSiteKey() {
  return String(process.env.NEXT_PUBLIC_TURNSTILE_SITE_KEY || '').trim();
}

function loadScript(): Promise<void> {
  if (typeof window === 'undefined') return Promise.resolve();
  if (window.turnstile) return Promise.resolve();

  const existing = document.getElementById(SCRIPT_ID) as HTMLScriptElement | null;
  if (existing) {
    return new Promise((resolve) => {
      existing.addEventListener('load', () => resolve(), { once: true });
      setTimeout(() => resolve(), 1200);
    });
  }

  return new Promise((resolve, reject) => {
    const script = document.createElement('script');
    script.id = SCRIPT_ID;
    script.src = 'https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit';
    script.async = true;
    script.defer = true;
    script.onload = () => resolve();
    script.onerror = () => reject(new Error('No se pudo cargar Turnstile'));
    document.head.appendChild(script);
  });
}

export default function TurnstileCaptcha({ onTokenChange }: TurnstileCaptchaProps) {
  const siteKey = getSiteKey();
  const containerRef = React.useRef<HTMLDivElement | null>(null);
  const widgetIdRef = React.useRef<string | null>(null);
  const [error, setError] = React.useState<string | null>(null);

  React.useEffect(() => {
    if (!siteKey) {
      onTokenChange('');
      return;
    }

    let mounted = true;
    loadScript()
      .then(() => {
        if (!mounted || !containerRef.current || !window.turnstile) return;
        if (widgetIdRef.current) return;

        widgetIdRef.current = window.turnstile.render(containerRef.current, {
          sitekey: siteKey,
          callback: (token: string) => onTokenChange(token),
          'expired-callback': () => onTokenChange(''),
          'error-callback': () => {
            onTokenChange('');
            setError('No se pudo validar CAPTCHA. Intenta nuevamente.');
          },
        });
      })
      .catch(() => {
        if (!mounted) return;
        setError('No se pudo cargar CAPTCHA.');
      });

    return () => {
      mounted = false;
      if (widgetIdRef.current && window.turnstile) {
        window.turnstile.remove(widgetIdRef.current);
        widgetIdRef.current = null;
      }
    };
  }, [siteKey, onTokenChange]);

  if (!siteKey) {
    return (
      <Alert severity="info" sx={{ mt: 1 }}>
        CAPTCHA no configurado. Define <strong>NEXT_PUBLIC_TURNSTILE_SITE_KEY</strong>.
      </Alert>
    );
  }

  return (
    <Box>
      <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
        Verificacion anti-bot
      </Typography>
      <div ref={containerRef} />
      {error && (
        <Alert severity="error" sx={{ mt: 1 }}>
          {error}
        </Alert>
      )}
    </Box>
  );
}
