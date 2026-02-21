'use client';

import React from 'react';
import dynamic from 'next/dynamic';

const TableRestaurantIcon = dynamic(() => import('@mui/icons-material/TableRestaurant'), { ssr: false });
const KitchenIcon = dynamic(() => import('@mui/icons-material/Kitchen'), { ssr: false });
const DashboardIcon = dynamic(() => import('@mui/icons-material/Dashboard'), { ssr: false });
const SettingsIcon = dynamic(() => import('@mui/icons-material/Settings'), { ssr: false });

export function buildRestauranteNav(isAdmin: boolean, modulos: string[]): any[] {
    const nav: any[] = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('restaurante') || has('pos')) {
        nav.push({ 
            kind: 'page', 
            segment: '', 
            title: 'Salón / Mesas', 
            icon: <TableRestaurantIcon /> 
        });
        nav.push({ 
            kind: 'page', 
            segment: 'cocina', 
            title: 'Cocina / Pedidos', 
            icon: <KitchenIcon /> 
        });
    }

    return nav;
}
