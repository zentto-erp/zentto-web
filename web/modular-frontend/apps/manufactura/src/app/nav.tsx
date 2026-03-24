import React from 'react';
import DashboardIcon from '@mui/icons-material/Dashboard';
import AccountTreeIcon from '@mui/icons-material/AccountTree';
import FactoryIcon from '@mui/icons-material/Factory';
import AssignmentIcon from '@mui/icons-material/Assignment';
import BuildIcon from '@mui/icons-material/Build';

export function buildNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);
    if (has('manufactura') || has('inventario')) {
        nav.push({ kind: 'header', title: 'MANUFACTURA' });
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <DashboardIcon /> });
        nav.push({ kind: 'header', title: 'OPERACIONES' });
        nav.push({ kind: 'page', segment: 'bom', title: 'Bill of Materials', icon: <AccountTreeIcon /> });
        nav.push({ kind: 'page', segment: 'centros-trabajo', title: 'Centros de Trabajo', icon: <FactoryIcon /> });
        nav.push({ kind: 'page', segment: 'ordenes', title: 'Ordenes de Produccion', icon: <BuildIcon /> });
    }
    return nav;
}
