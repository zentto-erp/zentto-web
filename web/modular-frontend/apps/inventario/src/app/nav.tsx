import React from 'react';
import dynamic from 'next/dynamic';

const DashboardIcon        = dynamic(() => import('@mui/icons-material/Dashboard'),        { ssr: false });
const InventoryIcon        = dynamic(() => import('@mui/icons-material/Inventory'),        { ssr: false });
const TuneIcon             = dynamic(() => import('@mui/icons-material/Tune'),             { ssr: false });
const CategoryIcon         = dynamic(() => import('@mui/icons-material/Category'),         { ssr: false });
const LabelIcon            = dynamic(() => import('@mui/icons-material/Label'),            { ssr: false });
const ListIcon             = dynamic(() => import('@mui/icons-material/List'),             { ssr: false });
const StraightenIcon       = dynamic(() => import('@mui/icons-material/Straighten'),       { ssr: false });
const HistoryIcon          = dynamic(() => import('@mui/icons-material/History'),          { ssr: false });
const SwapHorizIcon        = dynamic(() => import('@mui/icons-material/SwapHoriz'),        { ssr: false });
const MenuBookIcon         = dynamic(() => import('@mui/icons-material/MenuBook'),         { ssr: false });
const LocalOfferIcon       = dynamic(() => import('@mui/icons-material/LocalOffer'),       { ssr: false });
const WarehouseIcon        = dynamic(() => import('@mui/icons-material/Warehouse'),        { ssr: false });
const PrintIcon            = dynamic(() => import('@mui/icons-material/Print'),            { ssr: false });
const SettingsIcon         = dynamic(() => import('@mui/icons-material/Settings'),         { ssr: false });
const ExtensionIcon        = dynamic(() => import('@mui/icons-material/Extension'),        { ssr: false });
const AssessmentIcon       = dynamic(() => import('@mui/icons-material/Assessment'),       { ssr: false });
const FactCheckIcon        = dynamic(() => import('@mui/icons-material/FactCheck'),        { ssr: false });
const DescriptionIcon      = dynamic(() => import('@mui/icons-material/Description'),      { ssr: false });
const LocalShippingIcon    = dynamic(() => import('@mui/icons-material/LocalShipping'),    { ssr: false });
const QrCodeScannerIcon    = dynamic(() => import('@mui/icons-material/QrCodeScanner'),   { ssr: false });
const TimelineIcon         = dynamic(() => import('@mui/icons-material/Timeline'),         { ssr: false });
const BarChartIcon         = dynamic(() => import('@mui/icons-material/BarChart'),         { ssr: false });

export function buildNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('inventario')) {
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <DashboardIcon /> });

        // ── Operaciones ──────────────────────────────────────────────────────
        nav.push({
            kind: 'page',
            segment: 'articulos',
            title: 'Operaciones',
            icon: <InventoryIcon />,
            children: [
                { kind: 'page', segment: 'articulos',     title: 'Artículos',            icon: <InventoryIcon />      },
                { kind: 'page', segment: 'movimientos',   title: 'Movimientos',          icon: <HistoryIcon />        },
                { kind: 'page', segment: 'ajuste',        title: 'Ajuste de inventario', icon: <TuneIcon />           },
                { kind: 'page', segment: 'traslados',     title: 'Traslados (simple)',   icon: <SwapHorizIcon />      },
                { kind: 'page', segment: 'traslados-mp',  title: 'Traslados multi-paso', icon: <LocalShippingIcon />  },
                { kind: 'page', segment: 'conteo',        title: 'Conteo físico',        icon: <FactCheckIcon />      },
                { kind: 'page', segment: 'albaranes',     title: 'Albaranes',            icon: <DescriptionIcon />    },
            ],
        });

        // ── Trazabilidad ──────────────────────────────────────────────────────
        nav.push({
            kind: 'page',
            segment: 'seriales',
            title: 'Trazabilidad',
            icon: <QrCodeScannerIcon />,
            children: [
                { kind: 'page', segment: 'seriales',  title: 'Seriales', icon: <QrCodeScannerIcon /> },
                { kind: 'page', segment: 'lotes',     title: 'Lotes',    icon: <CategoryIcon />       },
                { kind: 'page', segment: 'kardex',    title: 'Kardex',   icon: <TimelineIcon />       },
            ],
        });

        // ── Almacenes & WMS ───────────────────────────────────────────────────
        nav.push({
            kind: 'page',
            segment: 'almacenes-wms',
            title: 'Almacenes & WMS',
            icon: <WarehouseIcon />,
            children: [
                { kind: 'page', segment: 'almacenes-wms', title: 'Almacenes / Zonas', icon: <WarehouseIcon /> },
            ],
        });

        // ── Análisis & Reportes ───────────────────────────────────────────────
        nav.push({
            kind: 'page',
            segment: 'reportes/libro',
            title: 'Análisis & Reportes',
            icon: <AssessmentIcon />,
            children: [
                { kind: 'page', segment: 'reportes/libro', title: 'Libro de inventario', icon: <MenuBookIcon />  },
                { kind: 'page', segment: 'reportes',       title: 'Reportes',            icon: <BarChartIcon />  },
                { kind: 'page', segment: 'etiquetas',      title: 'Etiquetas',           icon: <LocalOfferIcon /> },
                { kind: 'page', segment: 'etiquetas/print',title: 'Imprimir etiquetas',  icon: <PrintIcon />     },
            ],
        });

        // ── Configuración ─────────────────────────────────────────────────────
        nav.push({
            kind: 'page',
            segment: 'catalogos/categorias',
            title: 'Configuración',
            icon: <SettingsIcon />,
            children: [
                { kind: 'page', segment: 'catalogos/categorias', title: 'Categorías', icon: <CategoryIcon />   },
                { kind: 'page', segment: 'catalogos/marcas',     title: 'Marcas',     icon: <LabelIcon />      },
                { kind: 'page', segment: 'catalogos/lineas',     title: 'Líneas',     icon: <ListIcon />       },
                { kind: 'page', segment: 'catalogos/unidades',   title: 'Unidades',   icon: <StraightenIcon /> },
                { kind: 'page', segment: 'catalogos/almacenes',  title: 'Almacenes',  icon: <WarehouseIcon />  },
                { kind: 'page', segment: 'configuracion',        title: 'Parámetros', icon: <ExtensionIcon />  },
            ],
        });
    }

    return nav;
}
