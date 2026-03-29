import React from 'react';
import dynamic from 'next/dynamic';

const DashboardIcon = dynamic(() => import('@mui/icons-material/Dashboard'), { ssr: false });
const MenuBookIcon = dynamic(() => import('@mui/icons-material/MenuBook'), { ssr: false });
const AccountTreeIcon = dynamic(() => import('@mui/icons-material/AccountTree'), { ssr: false });
const AssessmentIcon = dynamic(() => import('@mui/icons-material/Assessment'), { ssr: false });
const BusinessCenterIcon = dynamic(() => import('@mui/icons-material/BusinessCenter'), { ssr: false });
const RepeatIcon = dynamic(() => import('@mui/icons-material/Repeat'), { ssr: false });
const LockIcon = dynamic(() => import('@mui/icons-material/Lock'), { ssr: false });
const CompareArrowsIcon = dynamic(() => import('@mui/icons-material/CompareArrows'), { ssr: false });
const CategoryIcon = dynamic(() => import('@mui/icons-material/Category'), { ssr: false });
const PrecisionManufacturingIcon = dynamic(() => import('@mui/icons-material/PrecisionManufacturing'), { ssr: false });
const TrendingDownIcon = dynamic(() => import('@mui/icons-material/TrendingDown'), { ssr: false });
const GavelIcon = dynamic(() => import('@mui/icons-material/Gavel'), { ssr: false });
const ReceiptLongIcon = dynamic(() => import('@mui/icons-material/ReceiptLong'), { ssr: false });
const DescriptionIcon = dynamic(() => import('@mui/icons-material/Description'), { ssr: false });
const BarChartIcon = dynamic(() => import('@mui/icons-material/BarChart'), { ssr: false });
const AddIcon = dynamic(() => import('@mui/icons-material/Add'), { ssr: false });
const ListIcon = dynamic(() => import('@mui/icons-material/List'), { ssr: false });
const AccountBalanceIcon = dynamic(() => import('@mui/icons-material/AccountBalance'), { ssr: false });
const SavingsIcon = dynamic(() => import('@mui/icons-material/Savings'), { ssr: false });

export function buildContabilidadNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('contabilidad')) {
        // Dashboard
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <DashboardIcon /> });

        // ── Diario contable (acordeón)
        nav.push({
            kind: 'page',
            segment: 'asientos',
            title: 'Diario',
            icon: <MenuBookIcon />,
            children: [
                { kind: 'page', segment: 'asientos', title: 'Asientos', icon: <ListIcon /> },
                { kind: 'page', segment: 'asientos/new', title: 'Nuevo asiento', icon: <AddIcon /> },
                { kind: 'page', segment: 'recurrentes', title: 'Recurrentes', icon: <RepeatIcon /> },
            ],
        });

        // ── Plan de cuentas
        nav.push({ kind: 'page', segment: 'cuentas', title: 'Plan de cuentas', icon: <AccountTreeIcon /> });

        // ── Centros de costo & Presupuestos
        nav.push({
            kind: 'page',
            segment: 'centros-costo',
            title: 'Gestión',
            icon: <BusinessCenterIcon />,
            children: [
                { kind: 'page', segment: 'centros-costo', title: 'Centros de costo', icon: <BusinessCenterIcon /> },
                { kind: 'page', segment: 'presupuestos', title: 'Presupuestos', icon: <SavingsIcon /> },
            ],
        });

        // ── Activos fijos (acordeón)
        nav.push({
            kind: 'page',
            segment: 'activos-fijos',
            title: 'Activos fijos',
            icon: <PrecisionManufacturingIcon />,
            children: [
                { kind: 'page', segment: 'activos-fijos', title: 'Inventario AF', icon: <ListIcon /> },
                { kind: 'page', segment: 'activos-fijos/categorias', title: 'Categorías', icon: <CategoryIcon /> },
                { kind: 'page', segment: 'activos-fijos/depreciacion', title: 'Depreciación', icon: <TrendingDownIcon /> },
            ],
        });

        // ── Fiscal y tributaria (acordeón)
        nav.push({
            kind: 'page',
            segment: 'fiscal/libro',
            title: 'Fiscal',
            icon: <GavelIcon />,
            children: [
                { kind: 'page', segment: 'fiscal/libro', title: 'Libro fiscal', icon: <ReceiptLongIcon /> },
                { kind: 'page', segment: 'fiscal/declaraciones', title: 'Declaraciones', icon: <DescriptionIcon /> },
                { kind: 'page', segment: 'fiscal/retenciones', title: 'Retenciones', icon: <AccountBalanceIcon /> },
            ],
        });

        // ── Conciliación y cierre
        nav.push({
            kind: 'page',
            segment: 'conciliacion-bancaria',
            title: 'Procesos',
            icon: <CompareArrowsIcon />,
            children: [
                { kind: 'page', segment: 'conciliacion-bancaria', title: 'Conciliación bancaria', icon: <CompareArrowsIcon /> },
                { kind: 'page', segment: 'cierre', title: 'Cierre contable', icon: <LockIcon /> },
            ],
        });

        // ── Reportes (acordeón)
        nav.push({
            kind: 'page',
            segment: 'reportes',
            title: 'Reportes',
            icon: <AssessmentIcon />,
            children: [
                { kind: 'page', segment: 'reportes', title: 'Reportes estándar', icon: <AssessmentIcon /> },
                { kind: 'page', segment: 'reportes-avanzados', title: 'Reportes avanzados', icon: <BarChartIcon /> },
            ],
        });
    }

    return nav;
}
