'use client';

import React from 'react';
import { IconButton } from '@mui/material';
import { useColorScheme } from '@mui/material/styles';

/* ── Outline SVG icons (Heroicons) ── */

/** Sun icon — shown in dark mode (click to go light) */
const SunIcon = () => (
  <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
  </svg>
);

/** Moon icon — shown in light mode (click to go dark) */
const MoonIcon = () => (
  <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
  </svg>
);

/** Eye icon — password visible */
export const EyeIcon = () => (
  <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
  </svg>
);

/** Eye-off icon — password hidden */
export const EyeOffIcon = () => (
  <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.878 9.878L6.59 6.59m7.532 7.532l3.29 3.29M3 3l18 18" />
  </svg>
);

export default function ThemeToggle({ sx }: { sx?: object }) {
  const { mode, setMode, systemMode } = useColorScheme();
  const [mounted, setMounted] = React.useState(false);

  React.useEffect(() => setMounted(true), []);

  const resolvedMode = (mode === 'system' ? systemMode : mode) ?? 'light';

  const toggle = () => {
    const html = document.documentElement;
    html.classList.add('theme-transitioning');
    setMode(resolvedMode === 'dark' ? 'light' : 'dark');
    requestAnimationFrame(() => {
      setTimeout(() => html.classList.remove('theme-transitioning'), 400);
    });
  };

  if (!mounted) return <IconButton size="small" sx={{ color: 'text.secondary', visibility: 'hidden', ...sx }}><MoonIcon /></IconButton>;

  return (
    <IconButton onClick={toggle} size="small" sx={{ color: 'text.secondary', ...sx }}>
      {resolvedMode === 'dark' ? <SunIcon /> : <MoonIcon />}
    </IconButton>
  );
}
