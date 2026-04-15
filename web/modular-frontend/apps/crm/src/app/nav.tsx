import React from 'react';
import dynamic from 'next/dynamic';

const DashboardIcon = dynamic(() => import('@mui/icons-material/Dashboard'), { ssr: false });
const ViewKanbanIcon = dynamic(() => import('@mui/icons-material/ViewKanban'), { ssr: false });
const PeopleIcon = dynamic(() => import('@mui/icons-material/People'), { ssr: false });
const EventNoteIcon = dynamic(() => import('@mui/icons-material/EventNote'), { ssr: false });
const SettingsIcon = dynamic(() => import('@mui/icons-material/Settings'), { ssr: false });
const TimelineIcon = dynamic(() => import('@mui/icons-material/Timeline'), { ssr: false });
const SmartToyIcon = dynamic(() => import('@mui/icons-material/SmartToy'), { ssr: false });
const PrintIcon = dynamic(() => import('@mui/icons-material/Print'), { ssr: false });
const TrendingUpIcon = dynamic(() => import('@mui/icons-material/TrendingUp'), { ssr: false });
const WebhookIcon = dynamic(() => import('@mui/icons-material/Webhook'), { ssr: false });

export function buildNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('crm') || has('ventas')) {
        // Dashboard
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <DashboardIcon /> });

        // ── CRM (acordeón)
        nav.push({
            kind: 'page',
            segment: 'pipeline',
            title: 'CRM',
            icon: <TrendingUpIcon />,
            children: [
                { kind: 'page', segment: 'pipeline', title: 'Pipeline', icon: <ViewKanbanIcon /> },
                { kind: 'page', segment: 'leads', title: 'Leads', icon: <PeopleIcon /> },
                { kind: 'page', segment: 'actividades', title: 'Actividades', icon: <EventNoteIcon /> },
                { kind: 'page', segment: 'timeline', title: 'Timeline', icon: <TimelineIcon /> },
            ],
        });

        // ── Automatización (acordeón)
        nav.push({
            kind: 'page',
            segment: 'automatizaciones',
            title: 'Automatización',
            icon: <SmartToyIcon />,
            children: [
                { kind: 'page', segment: 'automatizaciones', title: 'Automatizaciones', icon: <SmartToyIcon /> },
                { kind: 'page', segment: 'configuracion', title: 'Configuración', icon: <SettingsIcon /> },
            ],
        });

        // ── Integraciones (webhooks + API keys públicas del tenant)
        nav.push({ kind: 'page', segment: 'integraciones', title: 'Integraciones', icon: <WebhookIcon /> });

        // ── Reportes
        nav.push({ kind: 'page', segment: 'reportes', title: 'Reportes', icon: <PrintIcon /> });
    }

    return nav;
}
