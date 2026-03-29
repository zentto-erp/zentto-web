import React from 'react';
import dynamic from 'next/dynamic';

const PrintIcon = dynamic(() => import('@mui/icons-material/Print'), { ssr: false });

// nav.tsx — No utilizado en el layout de tienda publica
// La navegacion se maneja via StoreLayout de @zentto/module-ecommerce
export function buildNav() {
    const nav: Array<Record<string, unknown>> = [];

    nav.push({ kind: 'divider' });
    nav.push({ kind: 'page', segment: 'reportes', title: 'Reportes', icon: <PrintIcon /> });

    return nav;
}
