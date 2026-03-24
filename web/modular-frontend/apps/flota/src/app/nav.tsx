import React from 'react';
import DashboardIcon from '@mui/icons-material/Dashboard';
import DirectionsCarIcon from '@mui/icons-material/DirectionsCar';
import LocalGasStationIcon from '@mui/icons-material/LocalGasStation';
import BuildIcon from '@mui/icons-material/Build';
import RouteIcon from '@mui/icons-material/Route';
import AssessmentIcon from '@mui/icons-material/Assessment';

export function buildNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);
    if (has('flota') || has('logistica')) {
        nav.push({ kind: 'header', title: 'FLOTA' });
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <DashboardIcon /> });
        nav.push({ kind: 'header', title: 'OPERACIONES' });
        nav.push({ kind: 'page', segment: 'vehiculos', title: 'Vehiculos', icon: <DirectionsCarIcon /> });
        nav.push({ kind: 'page', segment: 'combustible', title: 'Combustible', icon: <LocalGasStationIcon /> });
        nav.push({ kind: 'page', segment: 'mantenimiento', title: 'Mantenimiento', icon: <BuildIcon /> });
        nav.push({ kind: 'page', segment: 'viajes', title: 'Viajes', icon: <RouteIcon /> });
        nav.push({ kind: 'header', title: 'INFORMES' });
        nav.push({ kind: 'page', segment: 'reportes', title: 'Reportes', icon: <AssessmentIcon /> });
    }
    return nav;
}
