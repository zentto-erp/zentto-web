import React from 'react';
import dynamic from 'next/dynamic';

const DashboardIcon = dynamic(() => import('@mui/icons-material/Dashboard'), { ssr: false });
const BadgeIcon = dynamic(() => import('@mui/icons-material/Badge'), { ssr: false });
const PeopleIcon = dynamic(() => import('@mui/icons-material/People'), { ssr: false });
const EventIcon = dynamic(() => import('@mui/icons-material/Event'), { ssr: false });
const FactCheckIcon = dynamic(() => import('@mui/icons-material/FactCheck'), { ssr: false });
const ListIcon = dynamic(() => import('@mui/icons-material/List'), { ssr: false });
const HistoryIcon = dynamic(() => import('@mui/icons-material/History'), { ssr: false });
const AddCircleOutlineIcon = dynamic(() => import('@mui/icons-material/AddCircleOutline'), { ssr: false });
const AccountBalanceWalletIcon = dynamic(() => import('@mui/icons-material/AccountBalanceWallet'), { ssr: false });
const SettingsIcon = dynamic(() => import('@mui/icons-material/Settings'), { ssr: false });

export function buildNominaNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('nomina')) {
        nav.push({ kind: 'header', title: 'Nómina' });
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <DashboardIcon /> });
        nav.push({ kind: 'header', title: 'Procesos' });
        nav.push({ kind: 'page', segment: 'empleados', title: 'Empleados', icon: <PeopleIcon /> });
        nav.push({ kind: 'page', segment: 'nominas', title: 'Nóminas', icon: <BadgeIcon /> });
        nav.push({ kind: 'page', segment: 'conceptos', title: 'Conceptos', icon: <ListIcon /> });
        nav.push({ kind: 'header', title: 'Vacaciones' });
        nav.push({ kind: 'page', segment: 'vacaciones', title: 'Calendario', icon: <HistoryIcon /> });
        nav.push({ kind: 'page', segment: 'vacaciones/solicitar', title: 'Solicitar Vacaciones', icon: <AddCircleOutlineIcon /> });
        nav.push({ kind: 'page', segment: 'vacaciones/solicitudes', title: 'Aprobar Solicitudes', icon: <FactCheckIcon /> });
        nav.push({ kind: 'header', title: 'Administración' });
        nav.push({ kind: 'page', segment: 'liquidaciones', title: 'Liquidaciones', icon: <AccountBalanceWalletIcon /> });
        nav.push({ kind: 'page', segment: 'constantes', title: 'Constantes', icon: <SettingsIcon /> });
    }

    return nav;
}
