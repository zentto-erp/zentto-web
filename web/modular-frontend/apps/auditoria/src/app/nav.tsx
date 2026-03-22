import React from 'react';
import dynamic from 'next/dynamic';

const DashboardIcon = dynamic(() => import('@mui/icons-material/DashboardOutlined'), { ssr: false });
const ListAltIcon = dynamic(() => import('@mui/icons-material/ListAlt'), { ssr: false });
const SettingsIcon = dynamic(() => import('@mui/icons-material/SettingsOutlined'), { ssr: false });
const ReceiptIcon = dynamic(() => import('@mui/icons-material/ReceiptLong'), { ssr: false });
const AssessmentIcon = dynamic(() => import('@mui/icons-material/AssessmentOutlined'), { ssr: false });
const PeopleIcon = dynamic(() => import('@mui/icons-material/PeopleOutlined'), { ssr: false });
const NotificationsIcon = dynamic(() => import('@mui/icons-material/NotificationsActive'), { ssr: false });
const HistoryIcon = dynamic(() => import('@mui/icons-material/History'), { ssr: false });
const SecurityIcon = dynamic(() => import('@mui/icons-material/Security'), { ssr: false });

export function buildNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('auditoria')) {
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <DashboardIcon /> });

        nav.push({
            kind: 'page',
            segment: 'bitacora',
            title: 'Auditoría',
            icon: <SecurityIcon />,
            children: [
                { kind: 'page', segment: 'bitacora', title: 'Bitácora general', icon: <ListAltIcon /> },
                { kind: 'page', segment: 'usuarios', title: 'Por usuario', icon: <PeopleIcon /> },
                { kind: 'page', segment: 'sesiones', title: 'Sesiones', icon: <HistoryIcon /> },
            ],
        });

        nav.push({
            kind: 'page',
            segment: 'alertas',
            title: 'Alertas',
            icon: <NotificationsIcon />,
            children: [
                { kind: 'page', segment: 'alertas', title: 'Alertas del sistema', icon: <NotificationsIcon /> },
                { kind: 'page', segment: 'alertas/configuracion', title: 'Configurar alertas', icon: <SettingsIcon /> },
            ],
        });

        nav.push({
            kind: 'page',
            segment: 'fiscal',
            title: 'Fiscal',
            icon: <ReceiptIcon />,
            children: [
                { kind: 'page', segment: 'fiscal', title: 'Config. fiscal', icon: <SettingsIcon /> },
                { kind: 'page', segment: 'fiscal-records', title: 'Registros fiscales', icon: <ReceiptIcon /> },
            ],
        });

        nav.push({ kind: 'page', segment: 'reportes', title: 'Reportes', icon: <AssessmentIcon /> });
    }

    return nav;
}
