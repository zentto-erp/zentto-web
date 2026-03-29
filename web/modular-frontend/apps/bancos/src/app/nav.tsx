import React from 'react';
import dynamic from 'next/dynamic';

const DashboardIcon = dynamic(() => import('@mui/icons-material/Dashboard'), { ssr: false });
const AccountBalanceIcon = dynamic(() => import('@mui/icons-material/AccountBalance'), { ssr: false });
const CreditCardIcon = dynamic(() => import('@mui/icons-material/CreditCard'), { ssr: false });
const AddCardIcon = dynamic(() => import('@mui/icons-material/AddCard'), { ssr: false });
const CompareArrowsIcon = dynamic(() => import('@mui/icons-material/CompareArrows'), { ssr: false });
const PlaylistAddCheckIcon = dynamic(() => import('@mui/icons-material/PlaylistAddCheck'), { ssr: false });
const LocalAtmIcon = dynamic(() => import('@mui/icons-material/LocalAtm'), { ssr: false });
const PrintIcon = dynamic(() => import('@mui/icons-material/Print'), { ssr: false });

export function buildNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('bancos')) {
        // Dashboard
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <DashboardIcon /> });

        // ── Bancos e Instituciones (acordeón)
        nav.push({
            kind: 'page',
            segment: 'entidades',
            title: 'Bancos e Instituciones',
            icon: <AccountBalanceIcon />,
            children: [
                { kind: 'page', segment: 'entidades', title: 'Bancos', icon: <AccountBalanceIcon /> },
                { kind: 'page', segment: 'cuentas', title: 'Cuentas bancarias', icon: <CreditCardIcon /> },
                { kind: 'page', segment: 'movimientos/generar', title: 'Generar movimiento', icon: <AddCardIcon /> },
                { kind: 'page', segment: 'caja-chica', title: 'Caja chica', icon: <LocalAtmIcon /> },
            ],
        });

        // ── Conciliaciones (acordeón)
        nav.push({
            kind: 'page',
            segment: 'conciliacion',
            title: 'Conciliaciones',
            icon: <CompareArrowsIcon />,
            children: [
                { kind: 'page', segment: 'conciliacion', title: 'Conciliaciones', icon: <CompareArrowsIcon /> },
                { kind: 'page', segment: 'conciliacion/wizard', title: 'Nueva conciliación', icon: <PlaylistAddCheckIcon /> },
            ],
        });
    }

    // ── Reportes
    nav.push({ kind: 'page', segment: 'reportes', title: 'Reportes', icon: <PrintIcon /> });

    return nav;
}
