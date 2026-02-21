import React from 'react';
import dynamic from 'next/dynamic';

const NavIcon = dynamic(() => import('@mui/icons-material/AccountBalance'), { ssr: false });

export function buildNav(isAdmin: boolean, modulos: string[]): any[] {
    const nav: any[] = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('bancos')) {
        nav.push({ kind: 'header', title: 'Bancos e Inst.' });
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <NavIcon /> });
    }

    return nav;
}
