'use client';

import React from 'react';
import dynamic from 'next/dynamic';

const PointOfSaleIcon = dynamic(() => import('@mui/icons-material/PointOfSale'), { ssr: false });
const AccountBalanceWalletIcon = dynamic(() => import('@mui/icons-material/AccountBalanceWallet'), { ssr: false });
const BarChartIcon = dynamic(() => import('@mui/icons-material/BarChart'), { ssr: false });
const DashboardIcon = dynamic(() => import('@mui/icons-material/Dashboard'), { ssr: false });
const SettingsIcon = dynamic(() => import('@mui/icons-material/Settings'), { ssr: false });
const ReceiptLongIcon = dynamic(() => import('@mui/icons-material/ReceiptLong'), { ssr: false });

export function buildPosNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('pos') || has('ventas')) {
        // Dashboard
        nav.push({ kind: 'page', segment: '', title: 'Dashboard POS', icon: <DashboardIcon /> });

        // ── Operaciones (acordeón)
        nav.push({
            kind: 'page',
            segment: 'facturacion',
            title: 'Operaciones',
            icon: <PointOfSaleIcon />,
            children: [
                { kind: 'page', segment: 'facturacion', title: 'Facturación', icon: <PointOfSaleIcon /> },
                { kind: 'page', segment: 'cierre-caja', title: 'Cierre de caja', icon: <AccountBalanceWalletIcon /> },
            ],
        });

        // ── Fiscal (acordeón)
        nav.push({
            kind: 'page',
            segment: 'fiscal',
            title: 'Fiscal',
            icon: <ReceiptLongIcon />,
            children: [
                { kind: 'page', segment: 'fiscal', title: 'Módulo fiscal', icon: <ReceiptLongIcon /> },
                { kind: 'page', segment: 'correlativos-fiscales', title: 'Correlativos fiscales', icon: <SettingsIcon /> },
            ],
        });

        // ── Reportes
        nav.push({ kind: 'page', segment: 'reportes', title: 'Reportes', icon: <BarChartIcon /> });

        // ── Configuración
        nav.push({ kind: 'page', segment: 'configuracion', title: 'Configuración POS', icon: <SettingsIcon /> });
    }

    return nav;
}
