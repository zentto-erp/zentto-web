import React from 'react';
import dynamic from 'next/dynamic';

const DashboardIcon = dynamic(() => import('@mui/icons-material/DashboardOutlined'), { ssr: false });
const ListAltIcon = dynamic(() => import('@mui/icons-material/ListAlt'), { ssr: false });
const SettingsIcon = dynamic(() => import('@mui/icons-material/SettingsOutlined'), { ssr: false });
const ReceiptIcon = dynamic(() => import('@mui/icons-material/ReceiptLong'), { ssr: false });
const AssessmentIcon = dynamic(() => import('@mui/icons-material/AssessmentOutlined'), { ssr: false });

export function buildNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('auditoria')) {
        nav.push({ kind: 'header', title: 'Auditoría Fiscal' });
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <DashboardIcon /> });
        nav.push({ kind: 'page', segment: 'bitacora', title: 'Bitácora', icon: <ListAltIcon /> });
        nav.push({ kind: 'page', segment: 'fiscal', title: 'Config. Fiscal', icon: <SettingsIcon /> });
        nav.push({ kind: 'page', segment: 'fiscal-records', title: 'Registros Fiscales', icon: <ReceiptIcon /> });
        nav.push({ kind: 'page', segment: 'reportes', title: 'Reportes', icon: <AssessmentIcon /> });
    }

    return nav;
}
