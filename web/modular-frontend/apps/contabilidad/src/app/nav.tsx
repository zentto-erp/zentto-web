import React from 'react';
import dynamic from 'next/dynamic';

const AccountBalanceWalletIcon = dynamic(() => import('@mui/icons-material/AccountBalanceWallet'), { ssr: false });

export function buildContabilidadNav(isAdmin: boolean, modulos: string[]): any[] {
    const nav: any[] = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('contabilidad')) {
        nav.push({ kind: 'header', title: 'Operaciones' });
        nav.push({ kind: 'page', segment: '', title: 'Dashboard Contable', icon: <AccountBalanceWalletIcon /> });
        nav.push({ kind: 'page', segment: 'asientos', title: 'Asientos', icon: <AccountBalanceWalletIcon /> });
        nav.push({ kind: 'page', segment: 'cuentas', title: 'Plan de Cuentas', icon: <AccountBalanceWalletIcon /> });
        nav.push({ kind: 'page', segment: 'reportes', title: 'Reportes', icon: <AccountBalanceWalletIcon /> });
    }

    return nav;
}
