import React from 'react';
import DashboardIcon from '@mui/icons-material/Dashboard';
import InventoryIcon from '@mui/icons-material/Inventory';
import TuneIcon from '@mui/icons-material/Tune';
import CategoryIcon from '@mui/icons-material/Category';
import LabelIcon from '@mui/icons-material/Label';
import ListIcon from '@mui/icons-material/List';
import StraightenIcon from '@mui/icons-material/Straighten';
import HistoryIcon from '@mui/icons-material/History';
import SwapHorizIcon from '@mui/icons-material/SwapHoriz';
import MenuBookIcon from '@mui/icons-material/MenuBook';
import LocalOfferIcon from '@mui/icons-material/LocalOffer';
import WarehouseIcon from '@mui/icons-material/Warehouse';

export function buildNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('inventario')) {
        nav.push({ kind: 'header', title: 'Inventario' });
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <DashboardIcon /> });
        nav.push({ kind: 'page', segment: 'articulos', title: 'Artículos', icon: <InventoryIcon /> });
        nav.push({ kind: 'page', segment: 'ajuste', title: 'Ajuste de inventario', icon: <TuneIcon /> });
        nav.push({ kind: 'page', segment: 'movimientos', title: 'Movimientos', icon: <HistoryIcon /> });
        nav.push({ kind: 'page', segment: 'traslados', title: 'Traslados', icon: <SwapHorizIcon /> });

        nav.push({ kind: 'header', title: 'Avanzado' });
        nav.push({ kind: 'page', segment: 'seriales', title: 'Seriales', icon: <InventoryIcon /> });
        nav.push({ kind: 'page', segment: 'lotes', title: 'Lotes', icon: <CategoryIcon /> });
        nav.push({ kind: 'page', segment: 'almacenes-wms', title: 'Almacenes WMS', icon: <WarehouseIcon /> });

        nav.push({ kind: 'header', title: 'Reportes' });
        nav.push({ kind: 'page', segment: 'reportes/libro', title: 'Libro de inventario', icon: <MenuBookIcon /> });
        nav.push({ kind: 'page', segment: 'etiquetas', title: 'Etiquetas', icon: <LocalOfferIcon /> });

        nav.push({ kind: 'header', title: 'Catálogos' });
        nav.push({ kind: 'page', segment: 'catalogos/categorias', title: 'Categorías', icon: <CategoryIcon /> });
        nav.push({ kind: 'page', segment: 'catalogos/marcas', title: 'Marcas', icon: <LabelIcon /> });
        nav.push({ kind: 'page', segment: 'catalogos/lineas', title: 'Líneas', icon: <ListIcon /> });
        nav.push({ kind: 'page', segment: 'catalogos/unidades', title: 'Unidades', icon: <StraightenIcon /> });
        nav.push({ kind: 'page', segment: 'catalogos/almacenes', title: 'Almacenes', icon: <WarehouseIcon /> });
    }

    return nav;
}
