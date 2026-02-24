'use client';

import React from 'react';
import dynamic from 'next/dynamic';

// Iconos de Material UI cargados dinámicamente para evitar SSR issues
const PointOfSaleIcon = dynamic(() => import('@mui/icons-material/PointOfSale'), { ssr: false });
const ShoppingCartIcon = dynamic(() => import('@mui/icons-material/ShoppingCart'), { ssr: false });
const AccountBalanceWalletIcon = dynamic(() => import('@mui/icons-material/AccountBalanceWallet'), { ssr: false });
const BarChartIcon = dynamic(() => import('@mui/icons-material/BarChart'), { ssr: false });
const DashboardIcon = dynamic(() => import('@mui/icons-material/Dashboard'), { ssr: false });
const SettingsIcon = dynamic(() => import('@mui/icons-material/Settings'), { ssr: false });
const ReceiptLongIcon = dynamic(() => import('@mui/icons-material/ReceiptLong'), { ssr: false });

/**
 * Construye la navegación del módulo POS basada en permisos del usuario
 * @param isAdmin - Si el usuario es administrador
 * @param modulos - Lista de módulos habilitados para el usuario
 * @returns Array de configuración de navegación para OdooLayout
 */
export function buildPosNav(isAdmin: boolean, modulos: string[]): any[] {
    const nav: any[] = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('pos') || has('ventas')) {
        // Dashboard principal de POS
        nav.push({ 
            kind: 'page', 
            segment: '', 
            title: 'Dashboard POS', 
            icon: <DashboardIcon /> 
        });

        // Facturación rápida (Touch POS)
        nav.push({ 
            kind: 'page', 
            segment: 'facturacion', 
            title: 'Facturación', 
            icon: <PointOfSaleIcon /> 
        });

        // Cierre de caja
        nav.push({ 
            kind: 'page', 
            segment: 'cierre-caja', 
            title: 'Cierre de Caja', 
            icon: <AccountBalanceWalletIcon /> 
        });

        // Reportes POS
        nav.push({ 
            kind: 'page', 
            segment: 'reportes', 
            title: 'Reportes', 
            icon: <BarChartIcon /> 
        });

        nav.push({
            kind: 'page',
            segment: 'fiscal',
            title: 'Módulo Fiscal',
            icon: <ReceiptLongIcon />,
        });

        // Gestión de serial/correlativo fiscal
        nav.push({
            kind: 'page',
            segment: 'correlativos-fiscales',
            title: 'Correlativos Fiscales',
            icon: <SettingsIcon />,
        });
    }

    return nav;
}
