import React from 'react';
import dynamic from 'next/dynamic';

const DashboardIcon = dynamic(() => import('@mui/icons-material/Dashboard'), { ssr: false });
const AccountBalanceIcon = dynamic(() => import('@mui/icons-material/AccountBalance'), { ssr: false });
const CreditCardIcon = dynamic(() => import('@mui/icons-material/CreditCard'), { ssr: false });
const AddCardIcon = dynamic(() => import('@mui/icons-material/AddCard'), { ssr: false });
const CompareArrowsIcon = dynamic(() => import('@mui/icons-material/CompareArrows'), { ssr: false });
const PlaylistAddCheckIcon = dynamic(() => import('@mui/icons-material/PlaylistAddCheck'), { ssr: false });
const LocalAtmIcon = dynamic(() => import('@mui/icons-material/LocalAtm'), { ssr: false });

export function buildNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('bancos')) {
        nav.push({ kind: 'header', title: 'Bancos e Instituciones' });
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <DashboardIcon /> });
        nav.push({ kind: 'page', segment: 'entidades', title: 'Bancos', icon: <AccountBalanceIcon /> });
        nav.push({ kind: 'page', segment: 'cuentas', title: 'Cuentas bancarias', icon: <CreditCardIcon /> });
        nav.push({ kind: 'page', segment: 'movimientos/generar', title: 'Generar movimiento', icon: <AddCardIcon /> });
        nav.push({ kind: 'page', segment: 'conciliacion', title: 'Conciliaciones', icon: <CompareArrowsIcon /> });
        nav.push({ kind: 'page', segment: 'conciliacion/wizard', title: 'Nueva conciliación', icon: <PlaylistAddCheckIcon /> });
        nav.push({ kind: 'page', segment: 'caja-chica', title: 'Caja chica', icon: <LocalAtmIcon /> });
    }

    return nav;
}
