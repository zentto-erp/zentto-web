import React from 'react';
import DashboardIcon from '@mui/icons-material/Dashboard';
import LocalShippingIcon from '@mui/icons-material/LocalShipping';
import ReceiptLongIcon from '@mui/icons-material/ReceiptLong';
import AssignmentReturnIcon from '@mui/icons-material/AssignmentReturn';
import DescriptionIcon from '@mui/icons-material/Description';
import PeopleIcon from '@mui/icons-material/People';
import BadgeIcon from '@mui/icons-material/Badge';

export function buildNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);
    if (has('logistica') || has('inventario')) {
        nav.push({ kind: 'header', title: 'LOGISTICA' });
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <DashboardIcon /> });
        nav.push({ kind: 'header', title: 'OPERACIONES' });
        nav.push({ kind: 'page', segment: 'recepciones', title: 'Recepcion Mercancia', icon: <ReceiptLongIcon /> });
        nav.push({ kind: 'page', segment: 'devoluciones', title: 'Devoluciones', icon: <AssignmentReturnIcon /> });
        nav.push({ kind: 'page', segment: 'albaranes', title: 'Albaranes / Guias', icon: <DescriptionIcon /> });
        nav.push({ kind: 'header', title: 'CONFIGURACION' });
        nav.push({ kind: 'page', segment: 'transportistas', title: 'Transportistas', icon: <LocalShippingIcon /> });
        nav.push({ kind: 'page', segment: 'conductores', title: 'Conductores', icon: <BadgeIcon /> });
    }
    return nav;
}
