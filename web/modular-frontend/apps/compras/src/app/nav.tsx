import React from 'react';
import dynamic from 'next/dynamic';

const NavIcon = dynamic(() => import('@mui/icons-material/LocalShipping'), { ssr: false });

export function buildNav(isAdmin: boolean, modulos: string[]): any[] {
    const nav: any[] = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('compras')) {
        nav.push({ kind: 'header', title: 'Compras' });
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <NavIcon /> });
    }

    return nav;
}
