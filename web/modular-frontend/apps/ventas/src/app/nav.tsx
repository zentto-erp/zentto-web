import React from 'react';
import dynamic from 'next/dynamic';

const DashboardIcon = dynamic(() => import('@mui/icons-material/Dashboard'), { ssr: false });
const ReceiptIcon = dynamic(() => import('@mui/icons-material/Receipt'), { ssr: false });
const PeopleIcon = dynamic(() => import('@mui/icons-material/People'), { ssr: false });
const Inventory2Icon = dynamic(() => import('@mui/icons-material/Inventory2'), { ssr: false });
const AccountBalanceIcon = dynamic(() => import('@mui/icons-material/AccountBalance'), { ssr: false });
const PaymentIcon = dynamic(() => import('@mui/icons-material/Payment'), { ssr: false });
const ShoppingCartIcon = dynamic(() => import('@mui/icons-material/ShoppingCart'), { ssr: false });
const PrintIcon = dynamic(() => import('@mui/icons-material/Print'), { ssr: false });

export function buildNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('ventas')) {
        // — Ventas —
        nav.push({ kind: 'header', title: 'Ventas' });
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <DashboardIcon /> });
        nav.push({ kind: 'page', segment: 'facturas', title: 'Facturas', icon: <ReceiptIcon /> });
        nav.push({ kind: 'page', segment: 'clientes', title: 'Clientes', icon: <PeopleIcon /> });
        nav.push({ kind: 'page', segment: 'articulos', title: 'Artículos', icon: <Inventory2Icon /> });

        // — Cuentas por Cobrar —
        nav.push({ kind: 'header', title: 'Cuentas por Cobrar' });
        nav.push({ kind: 'page', segment: 'cxc', title: 'Estado de Cuenta', icon: <AccountBalanceIcon /> });
        nav.push({ kind: 'page', segment: 'abonos', title: 'Cobros', icon: <PaymentIcon /> });

        // — E-Commerce —
        nav.push({ kind: 'header', title: 'E-Commerce' });
        nav.push({ kind: 'page', segment: 'pedidos-ecommerce', title: 'Pedidos Pendientes', icon: <ShoppingCartIcon /> });

        nav.push({ kind: 'divider' });
        nav.push({ kind: 'page', segment: 'reportes', title: 'Reportes', icon: <PrintIcon /> });
    }

    return nav;
}
