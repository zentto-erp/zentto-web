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
const ExtensionIcon = dynamic(() => import('@mui/icons-material/Extension'), { ssr: false });
const WidgetsIcon = dynamic(() => import('@mui/icons-material/Widgets'), { ssr: false });

/** Read addons from localStorage cache (synced by listAddons service) */
function getCachedModuleAddons(moduleId: string): { id: string; title: string }[] {
    if (typeof window === 'undefined') return [];
    try {
        const all = JSON.parse(localStorage.getItem('zentto-studio-apps') || '[]');
        return all.filter((a: any) => a.modules?.includes(moduleId) || a.modules?.includes('global'));
    } catch { return []; }
}

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

        // ── Addons dinámicos ────────────────────────────────────
        const addons = getCachedModuleAddons('compras');
        if (addons.length > 0) {
            nav.push({ kind: 'divider' });
            nav.push({
                kind: 'page',
                segment: 'addons',
                title: 'Addons',
                icon: <ExtensionIcon />,
                children: [
                    { kind: 'page', segment: 'addons', title: 'Ver todos', icon: <ExtensionIcon /> },
                    ...addons.map((a) => ({
                        kind: 'page',
                        segment: `addons/${a.id}`,
                        title: a.title,
                        icon: <WidgetsIcon />,
                    })),
                ],
            });
        } else {
            nav.push({ kind: 'divider' });
            nav.push({ kind: 'page', segment: 'addons', title: 'Addons', icon: <ExtensionIcon /> });
        }
    }

    return nav;
}
