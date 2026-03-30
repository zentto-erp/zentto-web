import { useEffect, useState } from 'react';

export const LAB_GRID_IDS = {
  articulos: 'lab:articulos:main',
  facturas: 'lab:facturas:main',
  nativoArticulos: 'lab:nativo-articulos:main',
  nativoFacturas: 'lab:nativo-facturas:main',
  showcase: 'lab:showcase:main',
  gridSidebar: 'lab:grid-sidebar:main',
} as const;

/**
 * Hook that dynamically imports @zentto/datagrid once layoutReady is true.
 * Returns { registered, gridReady } with proper cleanup on unmount.
 */
export function useGridRegistration(layoutReady: boolean) {
  const [registered, setRegistered] = useState(false);

  useEffect(() => {
    if (!layoutReady) return;

    let cancelled = false;

    import('@zentto/datagrid').then(() => {
      if (!cancelled) setRegistered(true);
    });

    return () => { cancelled = true; };
  }, [layoutReady]);

  return { registered, gridReady: layoutReady && registered };
}
