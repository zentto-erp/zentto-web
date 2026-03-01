import React from 'react';
import dynamic from 'next/dynamic';

const BadgeIcon = dynamic(() => import('@mui/icons-material/Badge'), { ssr: false });

export function buildNominaNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('nomina')) {
        nav.push({ kind: 'header', title: 'Nómina' });
        nav.push({ kind: 'page', segment: '', title: 'Dashboard Nómina', icon: <BadgeIcon /> });
        nav.push({ kind: 'page', segment: 'nominas', title: 'Gestión de Nóminas', icon: <BadgeIcon /> });
        nav.push({ kind: 'page', segment: 'conceptos', title: 'Conceptos', icon: <BadgeIcon /> });
        nav.push({ kind: 'page', segment: 'vacaciones', title: 'Vacaciones', icon: <BadgeIcon /> });
        nav.push({ kind: 'page', segment: 'liquidaciones', title: 'Liquidaciones', icon: <BadgeIcon /> });
        nav.push({ kind: 'page', segment: 'constantes', title: 'Constantes', icon: <BadgeIcon /> });
    }

    return nav;
}
