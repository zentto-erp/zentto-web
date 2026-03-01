import React from 'react';
import dynamic from 'next/dynamic';

const NavIcon = dynamic(() => import('@mui/icons-material/ShoppingCart'), { ssr: false });

export function buildNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('ventas')) {
        nav.push({ kind: 'header', title: 'Ventas' });
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <NavIcon /> });
    }

    return nav;
}
