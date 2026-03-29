import React from 'react';
import DashboardIcon from '@mui/icons-material/Dashboard';
import ViewKanbanIcon from '@mui/icons-material/ViewKanban';
import PeopleIcon from '@mui/icons-material/People';
import EventNoteIcon from '@mui/icons-material/EventNote';
import SettingsIcon from '@mui/icons-material/Settings';
import TimelineIcon from '@mui/icons-material/Timeline';
import SmartToyIcon from '@mui/icons-material/SmartToy';
import AssessmentIcon from '@mui/icons-material/Assessment';
import PrintIcon from '@mui/icons-material/Print';

export function buildNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);
    if (has('crm') || has('ventas')) {
        nav.push({ kind: 'header', title: 'CRM' });
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <DashboardIcon /> });
        nav.push({ kind: 'page', segment: 'pipeline', title: 'Pipeline', icon: <ViewKanbanIcon /> });
        nav.push({ kind: 'page', segment: 'leads', title: 'Leads', icon: <PeopleIcon /> });
        nav.push({ kind: 'page', segment: 'actividades', title: 'Actividades', icon: <EventNoteIcon /> });
        nav.push({ kind: 'page', segment: 'timeline', title: 'Timeline', icon: <TimelineIcon /> });
        nav.push({ kind: 'page', segment: 'automatizaciones', title: 'Automatizaciones', icon: <SmartToyIcon /> });
        nav.push({ kind: 'page', segment: 'reportes', title: 'Reportes', icon: <PrintIcon /> });
        nav.push({ kind: 'page', segment: 'configuracion', title: 'Configuracion', icon: <SettingsIcon /> });
    }
    return nav;
}
