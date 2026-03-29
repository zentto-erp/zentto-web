import React from 'react';
import dynamic from 'next/dynamic';

const DashboardIcon = dynamic(() => import('@mui/icons-material/Dashboard'), { ssr: false });
const LocalShippingIcon = dynamic(() => import('@mui/icons-material/LocalShipping'), { ssr: false });
const ReceiptLongIcon = dynamic(() => import('@mui/icons-material/ReceiptLong'), { ssr: false });
const AssignmentReturnIcon = dynamic(() => import('@mui/icons-material/AssignmentReturn'), { ssr: false });
const DescriptionIcon = dynamic(() => import('@mui/icons-material/Description'), { ssr: false });
const BadgeIcon = dynamic(() => import('@mui/icons-material/Badge'), { ssr: false });
const PrintIcon = dynamic(() => import('@mui/icons-material/Print'), { ssr: false });
const SettingsIcon = dynamic(() => import('@mui/icons-material/Settings'), { ssr: false });

export function buildNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('logistica') || has('inventario')) {
        // Dashboard
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <DashboardIcon /> });

        // ── Operaciones (acordeón)
        nav.push({
            kind: 'page',
            segment: 'recepciones',
            title: 'Operaciones',
            icon: <LocalShippingIcon />,
            children: [
                { kind: 'page', segment: 'recepciones', title: 'Recepción Mercancía', icon: <ReceiptLongIcon /> },
                { kind: 'page', segment: 'devoluciones', title: 'Devoluciones', icon: <AssignmentReturnIcon /> },
                { kind: 'page', segment: 'albaranes', title: 'Albaranes / Guías', icon: <DescriptionIcon /> },
            ],
        });

        // ── Configuración (acordeón)
        nav.push({
            kind: 'page',
            segment: 'transportistas',
            title: 'Configuración',
            icon: <SettingsIcon />,
            children: [
                { kind: 'page', segment: 'transportistas', title: 'Transportistas', icon: <LocalShippingIcon /> },
                { kind: 'page', segment: 'conductores', title: 'Conductores', icon: <BadgeIcon /> },
            ],
        });
    }

    // ── Reportes
    nav.push({ kind: 'page', segment: 'reportes', title: 'Reportes', icon: <PrintIcon /> });

    return nav;
}
