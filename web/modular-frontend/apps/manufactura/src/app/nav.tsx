import React from 'react';
import dynamic from 'next/dynamic';

const DashboardIcon = dynamic(() => import('@mui/icons-material/Dashboard'), { ssr: false });
const AccountTreeIcon = dynamic(() => import('@mui/icons-material/AccountTree'), { ssr: false });
const FactoryIcon = dynamic(() => import('@mui/icons-material/Factory'), { ssr: false });
const BuildIcon = dynamic(() => import('@mui/icons-material/Build'), { ssr: false });
const PrintIcon = dynamic(() => import('@mui/icons-material/Print'), { ssr: false });

export function buildNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('manufactura') || has('inventario')) {
        // Dashboard
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <DashboardIcon /> });

        // ── Operaciones (acordeón)
        nav.push({
            kind: 'page',
            segment: 'bom',
            title: 'Operaciones',
            icon: <FactoryIcon />,
            children: [
                { kind: 'page', segment: 'bom', title: 'Bill of Materials', icon: <AccountTreeIcon /> },
                { kind: 'page', segment: 'centros-trabajo', title: 'Centros de Trabajo', icon: <FactoryIcon /> },
                { kind: 'page', segment: 'ordenes', title: 'Órdenes de Producción', icon: <BuildIcon /> },
            ],
        });

        // ── Reportes
        nav.push({ kind: 'page', segment: 'reportes', title: 'Reportes', icon: <PrintIcon /> });
    }

    return nav;
}
