import React from 'react';
import dynamic from 'next/dynamic';

const DashboardIcon = dynamic(() => import('@mui/icons-material/Dashboard'), { ssr: false });
const ReceiptIcon = dynamic(() => import('@mui/icons-material/Receipt'), { ssr: false });
const PeopleIcon = dynamic(() => import('@mui/icons-material/People'), { ssr: false });
const AccountBalanceIcon = dynamic(() => import('@mui/icons-material/AccountBalance'), { ssr: false });
const InventoryIcon = dynamic(() => import('@mui/icons-material/Inventory'), { ssr: false });
const CategoryIcon = dynamic(() => import('@mui/icons-material/Category'), { ssr: false });
const LocalShippingIcon = dynamic(() => import('@mui/icons-material/LocalShipping'), { ssr: false });
const PaymentIcon = dynamic(() => import('@mui/icons-material/Payment'), { ssr: false });
const AccountBalanceWalletIcon = dynamic(() => import('@mui/icons-material/AccountBalanceWallet'), { ssr: false });
const CreditCardIcon = dynamic(() => import('@mui/icons-material/CreditCard'), { ssr: false });
const SyncAltIcon = dynamic(() => import('@mui/icons-material/SyncAlt'), { ssr: false });
const ReceiptLongIcon = dynamic(() => import('@mui/icons-material/ReceiptLong'), { ssr: false });

export function buildNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('ventas')) {
        nav.push({ kind: 'header', title: 'Ventas' });
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <DashboardIcon /> });
        nav.push({ kind: 'page', segment: 'facturas', title: 'Facturas', icon: <ReceiptIcon /> });
        nav.push({ kind: 'page', segment: 'clientes', title: 'Clientes', icon: <PeopleIcon /> });
        nav.push({ kind: 'page', segment: 'cxc', title: 'Cuentas por Cobrar', icon: <AccountBalanceIcon /> });

        nav.push({ kind: 'header', title: 'Inventario' });
        nav.push({ kind: 'page', segment: 'articulos', title: 'Artículos', icon: <CategoryIcon /> });
        nav.push({ kind: 'page', segment: 'inventario', title: 'Inventario', icon: <InventoryIcon /> });

        nav.push({ kind: 'header', title: 'Proveedores & Pagos' });
        nav.push({ kind: 'page', segment: 'proveedores', title: 'Proveedores', icon: <LocalShippingIcon /> });
        nav.push({ kind: 'page', segment: 'cxp', title: 'Cuentas por Pagar', icon: <PaymentIcon /> });

        nav.push({ kind: 'header', title: 'Tesorería' });
        nav.push({ kind: 'page', segment: 'bancos', title: 'Bancos', icon: <AccountBalanceWalletIcon /> });
        nav.push({ kind: 'page', segment: 'bancos/cuentas', title: 'Cuentas Bancarias', icon: <CreditCardIcon /> });
        nav.push({ kind: 'page', segment: 'bancos/conciliacion', title: 'Conciliación Bancaria', icon: <SyncAltIcon /> });
        nav.push({ kind: 'page', segment: 'abonos', title: 'Abonos', icon: <ReceiptLongIcon /> });
    }

    return nav;
}
