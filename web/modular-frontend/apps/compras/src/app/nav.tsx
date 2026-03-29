import React from 'react';
import dynamic from 'next/dynamic';

const DashboardIcon = dynamic(() => import('@mui/icons-material/Dashboard'), { ssr: false });
const ShoppingCartIcon = dynamic(() => import('@mui/icons-material/ShoppingCart'), { ssr: false });
const PeopleIcon = dynamic(() => import('@mui/icons-material/People'), { ssr: false });
const AccountBalanceIcon = dynamic(() => import('@mui/icons-material/AccountBalance'), { ssr: false });
const PaymentIcon = dynamic(() => import('@mui/icons-material/Payment'), { ssr: false });
const DescriptionIcon = dynamic(() => import('@mui/icons-material/Description'), { ssr: false });
const AssessmentIcon = dynamic(() => import('@mui/icons-material/Assessment'), { ssr: false });
const RequestQuoteIcon = dynamic(() => import('@mui/icons-material/RequestQuote'), { ssr: false });

export function buildNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('compras') || has('cuentas-por-pagar') || has('proveedores') || has('cxp')) {
        // Dashboard
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <DashboardIcon /> });

        // ── Compras (acordeón)
        nav.push({
            kind: 'page',
            segment: 'compras',
            title: 'Compras',
            icon: <ShoppingCartIcon />,
            children: [
                { kind: 'page', segment: 'compras', title: 'Compras', icon: <ShoppingCartIcon /> },
                { kind: 'page', segment: 'proveedores', title: 'Proveedores', icon: <PeopleIcon /> },
            ],
        });

        // ── Cuentas por Pagar (acordeón)
        nav.push({
            kind: 'page',
            segment: 'cxp',
            title: 'Cuentas por Pagar',
            icon: <RequestQuoteIcon />,
            children: [
                { kind: 'page', segment: 'cxp', title: 'Estado de Cuenta', icon: <AccountBalanceIcon /> },
                { kind: 'page', segment: 'pagos', title: 'Aplicar Pagos', icon: <PaymentIcon /> },
                { kind: 'page', segment: 'cuentas-por-pagar', title: 'Documentos CxP', icon: <DescriptionIcon /> },
            ],
        });

        // ── Reportes
        nav.push({ kind: 'page', segment: 'reportes', title: 'Reportes', icon: <AssessmentIcon /> });
    }

    return nav;
}
