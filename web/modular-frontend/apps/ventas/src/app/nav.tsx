import React from 'react';
import dynamic from 'next/dynamic';

const DashboardIcon = dynamic(() => import('@mui/icons-material/Dashboard'), { ssr: false });
const ReceiptIcon = dynamic(() => import('@mui/icons-material/Receipt'), { ssr: false });
const PeopleIcon = dynamic(() => import('@mui/icons-material/People'), { ssr: false });
const AccountBalanceIcon = dynamic(() => import('@mui/icons-material/AccountBalance'), { ssr: false });
const CategoryIcon = dynamic(() => import('@mui/icons-material/Category'), { ssr: false });
const ReceiptLongIcon = dynamic(() => import('@mui/icons-material/ReceiptLong'), { ssr: false });
const ShoppingCartIcon = dynamic(() => import('@mui/icons-material/ShoppingCart'), { ssr: false });

export function buildNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('ventas')) {
        nav.push({ kind: 'header', title: 'Ventas' });
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <DashboardIcon /> });
        nav.push({ kind: 'page', segment: 'facturas', title: 'Facturas', icon: <ReceiptIcon /> });
        nav.push({ kind: 'page', segment: 'clientes', title: 'Clientes', icon: <PeopleIcon /> });
        nav.push({ kind: 'page', segment: 'cxc', title: 'Cuentas por cobrar', icon: <AccountBalanceIcon /> });
        nav.push({ kind: 'page', segment: 'abonos', title: 'Abonos', icon: <ReceiptLongIcon /> });
        nav.push({ kind: 'page', segment: 'pedidos-ecommerce', title: 'Pedidos Ecommerce', icon: <ShoppingCartIcon /> });

        nav.push({ kind: 'header', title: 'Consulta' });
        nav.push({ kind: 'page', segment: 'articulos', title: 'Artículos', icon: <CategoryIcon /> });
    }

    return nav;
}
