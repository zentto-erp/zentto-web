import React from 'react';
import dynamic from 'next/dynamic';

const DashboardIcon = dynamic(() => import('@mui/icons-material/Dashboard'), { ssr: false });
const ShoppingCartIcon = dynamic(() => import('@mui/icons-material/ShoppingCart'), { ssr: false });
const LocalShippingIcon = dynamic(() => import('@mui/icons-material/LocalShipping'), { ssr: false });
const AccountBalanceIcon = dynamic(() => import('@mui/icons-material/AccountBalance'), { ssr: false });
const ReceiptLongIcon = dynamic(() => import('@mui/icons-material/ReceiptLong'), { ssr: false });
const PaymentIcon = dynamic(() => import('@mui/icons-material/Payment'), { ssr: false });

export function buildNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('compras') || has('cuentas-por-pagar') || has('proveedores') || has('cxp')) {
        nav.push({ kind: 'header', title: 'Compras' });
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <DashboardIcon /> });
        nav.push({ kind: 'page', segment: 'compras', title: 'Compras', icon: <ShoppingCartIcon /> });
        nav.push({ kind: 'page', segment: 'proveedores', title: 'Proveedores', icon: <LocalShippingIcon /> });

        nav.push({ kind: 'header', title: 'Cuentas por pagar' });
        nav.push({ kind: 'page', segment: 'cxp', title: 'Estado de cuenta', icon: <AccountBalanceIcon /> });
        nav.push({ kind: 'page', segment: 'cuentas-por-pagar', title: 'Documentos CxP', icon: <ReceiptLongIcon /> });
        nav.push({ kind: 'page', segment: 'pagos', title: 'Aplicar pagos', icon: <PaymentIcon /> });
    }

    return nav;
}
