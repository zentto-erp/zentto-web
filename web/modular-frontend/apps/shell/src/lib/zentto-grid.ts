'use client';

import { useMemo } from 'react';
import { usePathname } from 'next/navigation';

function normalizePart(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '') || 'main';
}

function isDynamicSegment(value: string): boolean {
  return /^\d+$/.test(value) || /^[0-9a-f]{8}-[0-9a-f-]{27}$/i.test(value);
}

export function useScopedGridId(scope: string): string {
  const pathname = usePathname() || '/';

  return useMemo(() => {
    const normalizedPath = pathname
      .split('/')
      .filter(Boolean)
      .map((segment) => (isDynamicSegment(segment) ? 'item' : normalizePart(segment)))
      .join(':') || 'root';

    return `shell:${normalizedPath}:${normalizePart(scope)}`;
  }, [pathname, scope]);
}
