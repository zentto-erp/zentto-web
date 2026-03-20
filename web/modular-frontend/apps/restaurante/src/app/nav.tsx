'use client';

import React from 'react';
import dynamic from 'next/dynamic';

const TableRestaurantIcon = dynamic(() => import('@mui/icons-material/TableRestaurant'), { ssr: false });
const KitchenIcon = dynamic(() => import('@mui/icons-material/Kitchen'), { ssr: false });
const DashboardIcon = dynamic(() => import('@mui/icons-material/Dashboard'), { ssr: false });
const SettingsIcon = dynamic(() => import('@mui/icons-material/Settings'), { ssr: false });
const ReceiptLongIcon = dynamic(() => import('@mui/icons-material/ReceiptLong'), { ssr: false });
const ShoppingCartIcon = dynamic(() => import('@mui/icons-material/ShoppingCart'), { ssr: false });
const Inventory2Icon = dynamic(() => import('@mui/icons-material/Inventory2'), { ssr: false });

export function buildRestauranteNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
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
        nav.push({
            kind: 'page',
            segment: 'fiscal',
            title: 'Módulo fiscal',
            icon: <ReceiptLongIcon />
        });
    }

    if (isAdmin) {
        nav.push({ kind: 'divider' });
        nav.push({ kind: 'header', title: 'CONFIGURACIÓN' });
        nav.push({
            kind: 'page',
            segment: 'admin/ambientes',
            title: 'Salones y mesas',
            icon: <DashboardIcon />
        });
        nav.push({
            kind: 'page',
            segment: 'admin/productos',
            title: 'Platos y bebidas',
            icon: <TableRestaurantIcon />
        });
        nav.push({
            kind: 'page',
            segment: 'admin/recetas',
            title: 'Recetas e insumos',
            icon: <SettingsIcon />
        });
        nav.push({
            kind: 'page',
            segment: 'admin/compras',
            title: 'Compras',
            icon: <ShoppingCartIcon />
        });
        nav.push({
            kind: 'page',
            segment: 'admin/insumos',
            title: 'Insumos',
            icon: <Inventory2Icon />
        });
        nav.push({
            kind: 'page',
            segment: 'admin/configuracion',
            title: 'Configuración',
            icon: <SettingsIcon />
        });
    }

    return nav;
}
