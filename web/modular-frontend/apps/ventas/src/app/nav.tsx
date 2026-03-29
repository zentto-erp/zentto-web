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
const StorefrontIcon = dynamic(() => import('@mui/icons-material/Storefront'), { ssr: false });
const RequestQuoteIcon = dynamic(() => import('@mui/icons-material/RequestQuote'), { ssr: false });

export function buildNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('ventas')) {
        // Dashboard
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <DashboardIcon /> });

        // ── Ventas (acordeón)
        nav.push({
            kind: 'page',
            segment: 'facturas',
            title: 'Ventas',
            icon: <StorefrontIcon />,
            children: [
                { kind: 'page', segment: 'facturas', title: 'Facturas', icon: <ReceiptIcon /> },
                { kind: 'page', segment: 'clientes', title: 'Clientes', icon: <PeopleIcon /> },
                { kind: 'page', segment: 'articulos', title: 'Artículos', icon: <Inventory2Icon /> },
            ],
        });

        // ── Cuentas por Cobrar (acordeón)
        nav.push({
            kind: 'page',
            segment: 'cxc',
            title: 'Cuentas por Cobrar',
            icon: <RequestQuoteIcon />,
            children: [
                { kind: 'page', segment: 'cxc', title: 'Estado de Cuenta', icon: <AccountBalanceIcon /> },
                { kind: 'page', segment: 'abonos', title: 'Cobros', icon: <PaymentIcon /> },
            ],
        });

        // ── E-Commerce (acordeón)
        nav.push({
            kind: 'page',
            segment: 'pedidos-ecommerce',
            title: 'E-Commerce',
            icon: <ShoppingCartIcon />,
            children: [
                { kind: 'page', segment: 'pedidos-ecommerce', title: 'Pedidos Pendientes', icon: <ShoppingCartIcon /> },
            ],
        });

        // ── Reportes
        nav.push({ kind: 'page', segment: 'reportes', title: 'Reportes', icon: <PrintIcon /> });
    }

    return nav;
}
