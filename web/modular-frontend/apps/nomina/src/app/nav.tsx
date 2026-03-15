import React from 'react';
import dynamic from 'next/dynamic';

const BadgeIcon = dynamic(() => import('@mui/icons-material/Badge'), { ssr: false });
const PeopleIcon = dynamic(() => import('@mui/icons-material/People'), { ssr: false });
const EventIcon = dynamic(() => import('@mui/icons-material/Event'), { ssr: false });
const FactCheckIcon = dynamic(() => import('@mui/icons-material/FactCheck'), { ssr: false });

export function buildNominaNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('nomina')) {
        nav.push({ kind: 'header', title: 'Nómina' });
        nav.push({ kind: 'page', segment: '', title: 'Dashboard Nómina', icon: <BadgeIcon /> });
        nav.push({ kind: 'page', segment: 'empleados', title: 'Empleados', icon: <PeopleIcon /> });
        nav.push({ kind: 'page', segment: 'nominas', title: 'Gestión de Nóminas', icon: <BadgeIcon /> });
        nav.push({ kind: 'page', segment: 'conceptos', title: 'Conceptos', icon: <BadgeIcon /> });
        nav.push({ kind: 'page', segment: 'vacaciones', title: 'Vacaciones', icon: <BadgeIcon /> });
        nav.push({ kind: 'page', segment: 'vacaciones/solicitar', title: 'Solicitar Vacaciones', icon: <EventIcon /> });
        nav.push({ kind: 'page', segment: 'vacaciones/solicitudes', title: 'Aprobar Solicitudes', icon: <FactCheckIcon /> });
        nav.push({ kind: 'page', segment: 'liquidaciones', title: 'Liquidaciones', icon: <BadgeIcon /> });
        nav.push({ kind: 'page', segment: 'constantes', title: 'Constantes', icon: <BadgeIcon /> });
    }

    return nav;
}
