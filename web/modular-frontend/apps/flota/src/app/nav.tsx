import React from 'react';
import dynamic from 'next/dynamic';

const DashboardIcon = dynamic(() => import('@mui/icons-material/Dashboard'), { ssr: false });
const DirectionsCarIcon = dynamic(() => import('@mui/icons-material/DirectionsCar'), { ssr: false });
const LocalGasStationIcon = dynamic(() => import('@mui/icons-material/LocalGasStation'), { ssr: false });
const BuildIcon = dynamic(() => import('@mui/icons-material/Build'), { ssr: false });
const RouteIcon = dynamic(() => import('@mui/icons-material/Route'), { ssr: false });
const PrintIcon = dynamic(() => import('@mui/icons-material/Print'), { ssr: false });

export function buildNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('flota') || has('logistica')) {
        // Dashboard
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <DashboardIcon /> });

        // ── Operaciones (acordeón)
        nav.push({
            kind: 'page',
            segment: 'vehiculos',
            title: 'Operaciones',
            icon: <DirectionsCarIcon />,
            children: [
                { kind: 'page', segment: 'vehiculos', title: 'Vehículos', icon: <DirectionsCarIcon /> },
                { kind: 'page', segment: 'combustible', title: 'Combustible', icon: <LocalGasStationIcon /> },
                { kind: 'page', segment: 'mantenimiento', title: 'Mantenimiento', icon: <BuildIcon /> },
                { kind: 'page', segment: 'viajes', title: 'Viajes', icon: <RouteIcon /> },
            ],
        });

        // ── Reportes
        nav.push({ kind: 'page', segment: 'reportes', title: 'Reportes', icon: <PrintIcon /> });
    }

    return nav;
}
