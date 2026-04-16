import * as React from 'react';
import type { SystemModule } from '@zentto/shared-auth';

import DashboardIcon from '@mui/icons-material/Dashboard';
import InventoryIcon from '@mui/icons-material/Inventory';
import LocalShippingIcon from '@mui/icons-material/LocalShipping';
import PaymentIcon from '@mui/icons-material/Payment';
import PeopleIcon from '@mui/icons-material/People';
import SettingsIcon from '@mui/icons-material/Settings';
import AccountBalanceIcon from '@mui/icons-material/AccountBalance';
import PaymentsIcon from '@mui/icons-material/Payments';
import AccountBalanceWalletIcon from '@mui/icons-material/AccountBalanceWallet';
import BadgeIcon from '@mui/icons-material/Badge';
import ManageAccountsIcon from '@mui/icons-material/ManageAccounts';
import HelpIcon from '@mui/icons-material/Help';
import InfoIcon from '@mui/icons-material/Info';
import MenuBookIcon from '@mui/icons-material/MenuBook';
import AppsIcon from '@mui/icons-material/Apps';
import TuneIcon from '@mui/icons-material/Tune';
import CategoryIcon from '@mui/icons-material/Category';
import LabelIcon from '@mui/icons-material/Label';
import ListIcon from '@mui/icons-material/List';
import StraightenIcon from '@mui/icons-material/Straighten';
import HistoryIcon from '@mui/icons-material/History';
import SwapHorizIcon from '@mui/icons-material/SwapHoriz';
import LocalOfferIcon from '@mui/icons-material/LocalOffer';
import WarehouseIcon from '@mui/icons-material/Warehouse';
import ReceiptLongIcon from '@mui/icons-material/ReceiptLong';
import AddCircleOutlineIcon from '@mui/icons-material/AddCircleOutline';
import RepeatIcon from '@mui/icons-material/Repeat';
import AccountTreeIcon from '@mui/icons-material/AccountTree';
import HubIcon from '@mui/icons-material/Hub';
import CalculateIcon from '@mui/icons-material/Calculate';
import LockIcon from '@mui/icons-material/Lock';
import SecurityIcon from '@mui/icons-material/Security';
import AssessmentIcon from '@mui/icons-material/Assessment';
import SavingsIcon from '@mui/icons-material/Savings';
import HealthAndSafetyIcon from '@mui/icons-material/HealthAndSafety';
import MedicalServicesIcon from '@mui/icons-material/MedicalServices';
import MedicalInformationIcon from '@mui/icons-material/MedicalInformation';
import SchoolIcon from '@mui/icons-material/School';
import GroupsIcon from '@mui/icons-material/Groups';
import GavelIcon from '@mui/icons-material/Gavel';
import EventIcon from '@mui/icons-material/Event';
import DescriptionIcon from '@mui/icons-material/Description';
import PlayArrowIcon from '@mui/icons-material/PlayArrow';
import PrintIcon from '@mui/icons-material/Print';
import BusinessCenterIcon from '@mui/icons-material/BusinessCenter';
import PrecisionManufacturingIcon from '@mui/icons-material/PrecisionManufacturing';
import TrendingDownIcon from '@mui/icons-material/TrendingDown';
import CompareArrowsIcon from '@mui/icons-material/CompareArrows';
import BarChartIcon from '@mui/icons-material/BarChart';
import WorkIcon from '@mui/icons-material/Work';
import CardGiftcardIcon from '@mui/icons-material/CardGiftcard';
import AdminPanelSettingsIcon from '@mui/icons-material/AdminPanelSettings';
import BeachAccessIcon from '@mui/icons-material/BeachAccess';
import CreditCardIcon from '@mui/icons-material/CreditCard';
import AddCardIcon from '@mui/icons-material/AddCard';
import PlaylistAddCheckIcon from '@mui/icons-material/PlaylistAddCheck';
import LocalAtmIcon from '@mui/icons-material/LocalAtm';
import ExtensionIcon from '@mui/icons-material/Extension';
import FactoryIcon from '@mui/icons-material/Factory';
import BuildIcon from '@mui/icons-material/Build';
import RouteIcon from '@mui/icons-material/Route';
import LocalGasStationIcon from '@mui/icons-material/LocalGasStation';
import DirectionsCarIcon from '@mui/icons-material/DirectionsCar';
import AssignmentReturnIcon from '@mui/icons-material/AssignmentReturn';
import StorefrontIcon from '@mui/icons-material/Storefront';
import RequestQuoteIcon from '@mui/icons-material/RequestQuote';
import ShoppingCartIcon from '@mui/icons-material/ShoppingCart';
import ViewKanbanIcon from '@mui/icons-material/ViewKanban';
import EventNoteIcon from '@mui/icons-material/EventNote';
import TimelineIcon from '@mui/icons-material/Timeline';
import SmartToyIcon from '@mui/icons-material/SmartToy';
import TrendingUpIcon from '@mui/icons-material/TrendingUp';
import WorkspacePremiumIcon from '@mui/icons-material/WorkspacePremium';
import BusinessIcon from '@mui/icons-material/Business';
import PaletteIcon from '@mui/icons-material/Palette';

export function has(modulos: string[], mod: SystemModule): boolean {
    return modulos.includes(mod);
}

export function buildNavigation(isAdmin: boolean, modulos: string[], pathname: string): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];

    // If we are on the App Selector or Home, show the general landing/support sidebar
    if (pathname === '/' || pathname === '/aplicaciones') {
        nav.push({ kind: 'header', title: 'MENÚ' });
        nav.push({ kind: 'page', segment: '', title: 'Inicio / Aplicaciones', icon: <AppsIcon /> });
        nav.push({ kind: 'divider' });
        nav.push({ kind: 'page', segment: 'reportes', title: 'Reportes', icon: <PrintIcon /> });
        nav.push({ kind: 'divider' });
        if (isAdmin || modulos.includes('addons')) {
            nav.push({ kind: 'page', segment: 'addons', title: 'Addons', icon: <ExtensionIcon /> });
        }
        if (isAdmin || modulos.includes('report-studio')) {
            nav.push({ kind: 'page', segment: 'report-studio', title: 'Report Studio', icon: <AssessmentIcon /> });
        }
        if (isAdmin) {
            nav.push({ kind: 'page', segment: 'configuracion', title: 'Ajustes', icon: <SettingsIcon /> });
        }
        nav.push({ kind: 'header', title: 'RECURSOS' });
        nav.push({ kind: 'page', segment: 'docs', title: 'Documentación', icon: <MenuBookIcon /> });
        nav.push({ kind: 'page', segment: 'soporte', title: 'Soporte Técnico', icon: <HelpIcon /> });
        nav.push({ kind: 'page', segment: 'info', title: 'Acerca de', icon: <InfoIcon /> });
        return nav;
    }

    // Helper
    const isApp = (appPath: string) => pathname.startsWith(appPath);

    // ── App: Studio Designer / Addons ──────────────────────────────
    if (isApp('/studio-designer') || isApp('/addons')) {
        nav.push({ kind: 'header', title: 'STUDIO' });
        nav.push({ kind: 'page', segment: 'studio-designer', title: 'Designer', icon: <ExtensionIcon /> });
        nav.push({ kind: 'page', segment: 'studio-designer/wizard', title: 'Wizard', icon: <SmartToyIcon /> });
        nav.push({ kind: 'divider' });
        nav.push({ kind: 'page', segment: 'addons', title: 'Mis Aplicaciones', icon: <AppsIcon /> });
        nav.push({ kind: 'divider' });
        nav.push({ kind: 'page', segment: '', title: 'Volver al Inicio', icon: <DashboardIcon /> });
        return nav;
    }

    // ── App: Reportes / Report Studio ─────────────────────────────────
    if (isApp('/reportes') || isApp('/report-studio')) {
        const base = isApp('/reportes') ? 'reportes' : 'report-studio';
        nav.push({ kind: 'header', title: 'REPORTES' });
        nav.push({ kind: 'page', segment: `${base}/designer`, title: 'Designer', icon: <BarChartIcon /> });
        nav.push({ kind: 'page', segment: `${base}/wizard`, title: 'Wizard', icon: <SmartToyIcon /> });
        nav.push({ kind: 'divider' });
        nav.push({ kind: 'page', segment: base, title: 'Mis Reportes', icon: <PrintIcon /> });
        nav.push({ kind: 'divider' });
        nav.push({ kind: 'page', segment: '', title: 'Volver al Inicio', icon: <DashboardIcon /> });
        return nav;
    }

    // ── App: Contabilidad (acordeones) ──────────────────────────────
    if (has(modulos, 'contabilidad') && isApp('/contabilidad')) {
        nav.push({ kind: 'page', segment: 'contabilidad', title: 'Dashboard', icon: <DashboardIcon /> });

        nav.push({
            kind: 'page',
            segment: 'contabilidad/asientos',
            title: 'Diario',
            icon: <MenuBookIcon />,
            children: [
                { kind: 'page', segment: 'contabilidad/asientos', title: 'Asientos', icon: <ReceiptLongIcon /> },
                { kind: 'page', segment: 'contabilidad/asientos/nuevo', title: 'Nuevo Asiento', icon: <AddCircleOutlineIcon /> },
                { kind: 'page', segment: 'contabilidad/recurrentes', title: 'Recurrentes', icon: <RepeatIcon /> },
            ],
        });

        nav.push({ kind: 'page', segment: 'contabilidad/cuentas', title: 'Plan de Cuentas', icon: <AccountTreeIcon /> });

        nav.push({
            kind: 'page',
            segment: 'contabilidad/centros-costo',
            title: 'Gestión',
            icon: <BusinessCenterIcon />,
            children: [
                { kind: 'page', segment: 'contabilidad/centros-costo', title: 'Centros de Costo', icon: <HubIcon /> },
                { kind: 'page', segment: 'contabilidad/presupuestos', title: 'Presupuestos', icon: <CalculateIcon /> },
            ],
        });

        nav.push({
            kind: 'page',
            segment: 'contabilidad/activos-fijos',
            title: 'Activos Fijos',
            icon: <PrecisionManufacturingIcon />,
            children: [
                { kind: 'page', segment: 'contabilidad/activos-fijos', title: 'Inventario AF', icon: <InventoryIcon /> },
                { kind: 'page', segment: 'contabilidad/activos-fijos/categorias', title: 'Categorías AF', icon: <CategoryIcon /> },
                { kind: 'page', segment: 'contabilidad/activos-fijos/depreciacion', title: 'Depreciación', icon: <TrendingDownIcon /> },
                { kind: 'page', segment: 'contabilidad/activos-fijos/reportes', title: 'Reportes AF', icon: <MenuBookIcon /> },
            ],
        });

        nav.push({
            kind: 'page',
            segment: 'contabilidad/fiscal/libros',
            title: 'Fiscal',
            icon: <GavelIcon />,
            children: [
                { kind: 'page', segment: 'contabilidad/fiscal/libros', title: 'Libros Fiscales', icon: <MenuBookIcon /> },
                { kind: 'page', segment: 'contabilidad/fiscal/declaraciones', title: 'Declaraciones', icon: <SettingsIcon /> },
                { kind: 'page', segment: 'contabilidad/fiscal/retenciones', title: 'Retenciones', icon: <PaymentsIcon /> },
            ],
        });

        nav.push({
            kind: 'page',
            segment: 'contabilidad/conciliacion',
            title: 'Procesos',
            icon: <CompareArrowsIcon />,
            children: [
                { kind: 'page', segment: 'contabilidad/conciliacion', title: 'Conciliación Bancaria', icon: <AccountBalanceIcon /> },
                { kind: 'page', segment: 'contabilidad/cierre', title: 'Cierre Contable', icon: <LockIcon /> },
            ],
        });

        nav.push({ kind: 'page', segment: 'contabilidad/reportes', title: 'Reportes', icon: <AssessmentIcon /> });
        return nav;
    }

    // ── App: Nómina (acordeones) ────────────────────────────────────
    if (has(modulos, 'nomina') && isApp('/nomina')) {
        nav.push({ kind: 'page', segment: 'nomina', title: 'Dashboard', icon: <DashboardIcon /> });

        nav.push({
            kind: 'page',
            segment: 'nomina/empleados',
            title: 'Procesos',
            icon: <WorkIcon />,
            children: [
                { kind: 'page', segment: 'nomina/empleados', title: 'Empleados', icon: <PeopleIcon /> },
                { kind: 'page', segment: 'nomina/nominas', title: 'Nóminas', icon: <BadgeIcon /> },
                { kind: 'page', segment: 'nomina/conceptos', title: 'Conceptos', icon: <ListIcon /> },
            ],
        });

        nav.push({
            kind: 'page',
            segment: 'nomina/vacaciones',
            title: 'Vacaciones',
            icon: <BeachAccessIcon />,
            children: [
                { kind: 'page', segment: 'nomina/vacaciones', title: 'Calendario', icon: <HistoryIcon /> },
                { kind: 'page', segment: 'nomina/vacaciones/solicitar', title: 'Solicitar Vacaciones', icon: <AddCircleOutlineIcon /> },
                { kind: 'page', segment: 'nomina/vacaciones/solicitudes', title: 'Aprobar Solicitudes', icon: <ReceiptLongIcon /> },
            ],
        });

        nav.push({
            kind: 'page',
            segment: 'nomina/utilidades',
            title: 'Beneficios',
            icon: <CardGiftcardIcon />,
            children: [
                { kind: 'page', segment: 'nomina/utilidades', title: 'Utilidades', icon: <AccountBalanceWalletIcon /> },
                { kind: 'page', segment: 'nomina/fideicomiso', title: 'Fideicomiso', icon: <AccountBalanceIcon /> },
                { kind: 'page', segment: 'nomina/caja-ahorro', title: 'Caja de Ahorro', icon: <SavingsIcon /> },
            ],
        });

        nav.push({
            kind: 'page',
            segment: 'nomina/salud-ocupacional',
            title: 'Salud y Seguridad',
            icon: <HealthAndSafetyIcon />,
            children: [
                { kind: 'page', segment: 'nomina/salud-ocupacional', title: 'Salud Ocupacional', icon: <HealthAndSafetyIcon /> },
                { kind: 'page', segment: 'nomina/examenes-medicos', title: 'Exámenes Médicos', icon: <MedicalServicesIcon /> },
                { kind: 'page', segment: 'nomina/ordenes-medicas', title: 'Órdenes Médicas', icon: <MedicalInformationIcon /> },
                { kind: 'page', segment: 'nomina/capacitacion', title: 'Capacitación', icon: <SchoolIcon /> },
                { kind: 'page', segment: 'nomina/comites', title: 'Comités de Seguridad', icon: <GroupsIcon /> },
            ],
        });

        nav.push({
            kind: 'page',
            segment: 'nomina/obligaciones',
            title: 'Obligaciones Legales',
            icon: <GavelIcon />,
            children: [
                { kind: 'page', segment: 'nomina/obligaciones', title: 'Obligaciones y Aportes', icon: <GavelIcon /> },
            ],
        });

        nav.push({
            kind: 'page',
            segment: 'nomina/procesar',
            title: 'Administración',
            icon: <AdminPanelSettingsIcon />,
            children: [
                { kind: 'page', segment: 'nomina/procesar', title: 'Procesar Nómina', icon: <PlayArrowIcon /> },
                { kind: 'page', segment: 'nomina/liquidaciones', title: 'Liquidaciones', icon: <AccountBalanceWalletIcon /> },
                { kind: 'page', segment: 'nomina/constantes', title: 'Constantes', icon: <SettingsIcon /> },
                { kind: 'page', segment: 'nomina/feriados', title: 'Feriados', icon: <EventIcon /> },
                { kind: 'page', segment: 'nomina/documentos', title: 'Plantillas de Documentos', icon: <DescriptionIcon /> },
            ],
        });

        nav.push({ kind: 'page', segment: 'nomina/reportes', title: 'Reportes', icon: <PrintIcon /> });
        return nav;
    }

    // ── App: Bancos (acordeones) ────────────────────────────────────
    if (has(modulos, 'bancos') && isApp('/bancos')) {
        nav.push({ kind: 'page', segment: 'bancos', title: 'Dashboard', icon: <DashboardIcon /> });

        nav.push({
            kind: 'page',
            segment: 'bancos/entidades',
            title: 'Bancos e Instituciones',
            icon: <AccountBalanceIcon />,
            children: [
                { kind: 'page', segment: 'bancos/entidades', title: 'Bancos', icon: <AccountBalanceIcon /> },
                { kind: 'page', segment: 'bancos/cuentas', title: 'Cuentas bancarias', icon: <CreditCardIcon /> },
                { kind: 'page', segment: 'bancos/movimientos/generar', title: 'Generar movimiento', icon: <AddCardIcon /> },
                { kind: 'page', segment: 'bancos/caja-chica', title: 'Caja chica', icon: <LocalAtmIcon /> },
            ],
        });

        nav.push({
            kind: 'page',
            segment: 'bancos/conciliacion',
            title: 'Conciliaciones',
            icon: <CompareArrowsIcon />,
            children: [
                { kind: 'page', segment: 'bancos/conciliacion', title: 'Conciliaciones', icon: <CompareArrowsIcon /> },
                { kind: 'page', segment: 'bancos/conciliacion/wizard', title: 'Nueva conciliación', icon: <PlaylistAddCheckIcon /> },
            ],
        });

        nav.push({ kind: 'page', segment: 'bancos/reportes', title: 'Reportes', icon: <PrintIcon /> });
        return nav;
    }

    // ── App: Inventario (acordeones) ────────────────────────────────
    if ((has(modulos, 'inventario') || has(modulos, 'articulos')) && isApp('/inventario')) {
        nav.push({ kind: 'page', segment: 'inventario', title: 'Dashboard', icon: <DashboardIcon /> });

        nav.push({
            kind: 'page',
            segment: 'inventario/articulos',
            title: 'Inventario',
            icon: <InventoryIcon />,
            children: [
                { kind: 'page', segment: 'inventario/articulos', title: 'Artículos', icon: <InventoryIcon /> },
                { kind: 'page', segment: 'inventario/ajuste', title: 'Ajuste de Inventario', icon: <TuneIcon /> },
                { kind: 'page', segment: 'inventario/movimientos', title: 'Movimientos', icon: <HistoryIcon /> },
                { kind: 'page', segment: 'inventario/traslados', title: 'Traslados', icon: <SwapHorizIcon /> },
            ],
        });

        nav.push({
            kind: 'page',
            segment: 'inventario/seriales',
            title: 'Avanzado',
            icon: <ExtensionIcon />,
            children: [
                { kind: 'page', segment: 'inventario/seriales', title: 'Seriales', icon: <InventoryIcon /> },
                { kind: 'page', segment: 'inventario/lotes', title: 'Lotes', icon: <CategoryIcon /> },
                { kind: 'page', segment: 'inventario/almacenes-wms', title: 'Almacenes WMS', icon: <WarehouseIcon /> },
            ],
        });

        nav.push({
            kind: 'page',
            segment: 'inventario/reportes/libro',
            title: 'Reportes',
            icon: <AssessmentIcon />,
            children: [
                { kind: 'page', segment: 'inventario/reportes/libro', title: 'Libro de Inventario', icon: <MenuBookIcon /> },
                { kind: 'page', segment: 'inventario/etiquetas', title: 'Etiquetas', icon: <LocalOfferIcon /> },
            ],
        });

        nav.push({
            kind: 'page',
            segment: 'inventario/categorias',
            title: 'Catálogos',
            icon: <SettingsIcon />,
            children: [
                { kind: 'page', segment: 'inventario/categorias', title: 'Categorías', icon: <CategoryIcon /> },
                { kind: 'page', segment: 'inventario/marcas', title: 'Marcas', icon: <LabelIcon /> },
                { kind: 'page', segment: 'inventario/clases', title: 'Clases', icon: <ListIcon /> },
                { kind: 'page', segment: 'inventario/tipos', title: 'Tipos', icon: <StraightenIcon /> },
                { kind: 'page', segment: 'inventario/lineas', title: 'Líneas', icon: <ListIcon /> },
                { kind: 'page', segment: 'inventario/unidades', title: 'Unidades', icon: <StraightenIcon /> },
                { kind: 'page', segment: 'inventario/almacenes', title: 'Almacenes', icon: <WarehouseIcon /> },
            ],
        });
        return nav;
    }

    // ── App: Logística (acordeones) ─────────────────────────────────
    if (isApp('/logistica')) {
        nav.push({ kind: 'page', segment: 'logistica', title: 'Dashboard', icon: <DashboardIcon /> });

        nav.push({
            kind: 'page',
            segment: 'logistica/recepciones',
            title: 'Operaciones',
            icon: <LocalShippingIcon />,
            children: [
                { kind: 'page', segment: 'logistica/recepciones', title: 'Recepción Mercancía', icon: <ReceiptLongIcon /> },
                { kind: 'page', segment: 'logistica/devoluciones', title: 'Devoluciones', icon: <AssignmentReturnIcon /> },
                { kind: 'page', segment: 'logistica/albaranes', title: 'Albaranes / Guías', icon: <DescriptionIcon /> },
            ],
        });

        nav.push({
            kind: 'page',
            segment: 'logistica/transportistas',
            title: 'Configuración',
            icon: <SettingsIcon />,
            children: [
                { kind: 'page', segment: 'logistica/transportistas', title: 'Transportistas', icon: <LocalShippingIcon /> },
            ],
        });

        nav.push({ kind: 'page', segment: 'logistica/reportes', title: 'Reportes', icon: <PrintIcon /> });
        return nav;
    }

    // ── App: CRM (acordeones) ───────────────────────────────────────
    if (isApp('/crm')) {
        nav.push({ kind: 'page', segment: 'crm', title: 'Dashboard', icon: <DashboardIcon /> });

        nav.push({
            kind: 'page',
            segment: 'crm/pipeline',
            title: 'CRM',
            icon: <TrendingUpIcon />,
            children: [
                { kind: 'page', segment: 'crm/pipeline', title: 'Pipeline', icon: <ViewKanbanIcon /> },
                { kind: 'page', segment: 'crm/leads', title: 'Leads', icon: <PeopleIcon /> },
                { kind: 'page', segment: 'crm/actividades', title: 'Actividades', icon: <EventNoteIcon /> },
                { kind: 'page', segment: 'crm/timeline', title: 'Timeline', icon: <TimelineIcon /> },
            ],
        });

        nav.push({
            kind: 'page',
            segment: 'crm/automatizaciones',
            title: 'Automatización',
            icon: <SmartToyIcon />,
            children: [
                { kind: 'page', segment: 'crm/automatizaciones', title: 'Automatizaciones', icon: <SmartToyIcon /> },
                { kind: 'page', segment: 'crm/configuracion', title: 'Configuración', icon: <SettingsIcon /> },
            ],
        });

        nav.push({ kind: 'page', segment: 'crm/reportes', title: 'Reportes', icon: <PrintIcon /> });
        return nav;
    }

    // ── App: Manufactura (acordeones) ───────────────────────────────
    if (isApp('/manufactura')) {
        nav.push({ kind: 'page', segment: 'manufactura', title: 'Dashboard', icon: <DashboardIcon /> });

        nav.push({
            kind: 'page',
            segment: 'manufactura/bom',
            title: 'Operaciones',
            icon: <FactoryIcon />,
            children: [
                { kind: 'page', segment: 'manufactura/bom', title: 'Bill of Materials', icon: <AccountTreeIcon /> },
                { kind: 'page', segment: 'manufactura/centros-trabajo', title: 'Centros de Trabajo', icon: <FactoryIcon /> },
                { kind: 'page', segment: 'manufactura/ordenes', title: 'Órdenes de Producción', icon: <BuildIcon /> },
            ],
        });

        nav.push({ kind: 'page', segment: 'manufactura/reportes', title: 'Reportes', icon: <PrintIcon /> });
        return nav;
    }

    // ── App: Flota (acordeones) ─────────────────────────────────────
    if (isApp('/flota')) {
        nav.push({ kind: 'page', segment: 'flota', title: 'Dashboard', icon: <DashboardIcon /> });

        nav.push({
            kind: 'page',
            segment: 'flota/vehiculos',
            title: 'Operaciones',
            icon: <DirectionsCarIcon />,
            children: [
                { kind: 'page', segment: 'flota/vehiculos', title: 'Vehículos', icon: <DirectionsCarIcon /> },
                { kind: 'page', segment: 'flota/combustible', title: 'Combustible', icon: <LocalGasStationIcon /> },
                { kind: 'page', segment: 'flota/mantenimiento', title: 'Mantenimiento', icon: <BuildIcon /> },
                { kind: 'page', segment: 'flota/viajes', title: 'Viajes', icon: <RouteIcon /> },
            ],
        });

        nav.push({ kind: 'page', segment: 'flota/reportes', title: 'Reportes', icon: <PrintIcon /> });
        return nav;
    }

    // ── App: Shipping (portal paquetería) ───────────────────────────
    if (isApp('/shipping')) {
        nav.push({ kind: 'page', segment: 'shipping', title: 'Inicio', icon: <DashboardIcon /> });
        nav.push({ kind: 'page', segment: 'shipping/dashboard', title: 'Dashboard', icon: <AssessmentIcon /> });

        nav.push({
            kind: 'page',
            segment: 'shipping/envios/nuevo',
            title: 'Envíos',
            icon: <LocalShippingIcon />,
            children: [
                { kind: 'page', segment: 'shipping/envios/nuevo', title: 'Nuevo Envío', icon: <AddCircleOutlineIcon /> },
                { kind: 'page', segment: 'shipping/envios', title: 'Mis Envíos', icon: <LocalShippingIcon /> },
                { kind: 'page', segment: 'shipping/rastreo', title: 'Rastrear', icon: <HistoryIcon /> },
            ],
        });

        nav.push({ kind: 'page', segment: 'shipping/perfil', title: 'Mi Perfil', icon: <ManageAccountsIcon /> });
        nav.push({ kind: 'page', segment: 'shipping/reportes', title: 'Reportes', icon: <PrintIcon /> });
        return nav;
    }

    // ── App: Ventas y CxC (acordeones) ──────────────────────────────
    const hasVentas = has(modulos, 'facturas') || has(modulos, 'abonos') || has(modulos, 'cxc') || has(modulos, 'clientes');
    if (hasVentas && isApp('/ventas')) {
        nav.push({ kind: 'page', segment: 'ventas', title: 'Dashboard', icon: <DashboardIcon /> });

        nav.push({
            kind: 'page',
            segment: 'facturas',
            title: 'Ventas',
            icon: <StorefrontIcon />,
            children: [
                ...(has(modulos, 'facturas') ? [{ kind: 'page', segment: 'facturas', title: 'Facturas', icon: <PaymentIcon /> }] : []),
                ...(has(modulos, 'clientes') ? [{ kind: 'page', segment: 'clientes', title: 'Clientes', icon: <PeopleIcon /> }] : []),
            ],
        });

        nav.push({
            kind: 'page',
            segment: 'cxc',
            title: 'Cuentas por Cobrar',
            icon: <RequestQuoteIcon />,
            children: [
                ...(has(modulos, 'cxc') ? [{ kind: 'page', segment: 'cxc', title: 'Estado de Cuenta', icon: <AccountBalanceIcon /> }] : []),
                ...(has(modulos, 'abonos') ? [{ kind: 'page', segment: 'abonos', title: 'Cobros', icon: <PaymentsIcon /> }] : []),
            ],
        });

        nav.push({ kind: 'page', segment: 'ventas/reportes', title: 'Reportes', icon: <PrintIcon /> });
        return nav;
    }

    // ── App: Compras y CxP (acordeones) ─────────────────────────────
    const hasCompras = has(modulos, 'compras') || has(modulos, 'cuentas-por-pagar') || has(modulos, 'pagos') || has(modulos, 'cxp') || has(modulos, 'proveedores');
    const isComprasApp = isApp('/compras') || isApp('/cuentas-por-pagar') || isApp('/pagos') || isApp('/cxp') || isApp('/proveedores');
    if (hasCompras && isComprasApp) {
        nav.push({ kind: 'page', segment: 'compras', title: 'Dashboard', icon: <DashboardIcon /> });

        nav.push({
            kind: 'page',
            segment: 'compras/lista',
            title: 'Compras',
            icon: <ShoppingCartIcon />,
            children: [
                ...(has(modulos, 'compras') ? [{ kind: 'page', segment: 'compras/lista', title: 'Compras', icon: <ShoppingCartIcon /> }] : []),
                ...(has(modulos, 'proveedores') ? [{ kind: 'page', segment: 'proveedores', title: 'Proveedores', icon: <PeopleIcon /> }] : []),
            ],
        });

        nav.push({
            kind: 'page',
            segment: 'cxp',
            title: 'Cuentas por Pagar',
            icon: <RequestQuoteIcon />,
            children: [
                ...(has(modulos, 'cxp') ? [{ kind: 'page', segment: 'cxp', title: 'Estado de Cuenta', icon: <AccountBalanceIcon /> }] : []),
                ...(has(modulos, 'pagos') ? [{ kind: 'page', segment: 'pagos', title: 'Aplicar Pagos', icon: <PaymentIcon /> }] : []),
                ...(has(modulos, 'cuentas-por-pagar') ? [{ kind: 'page', segment: 'cuentas-por-pagar', title: 'Documentos CxP', icon: <DescriptionIcon /> }] : []),
            ],
        });

        nav.push({ kind: 'page', segment: 'compras/reportes', title: 'Reportes', icon: <PrintIcon /> });
        return nav;
    }

    // ── App: Configuración Central (Ajustes) y Maestros ─────────────
    if (isAdmin && (isApp('/configuracion') || isApp('/maestros'))) {
        nav.push({ kind: 'header', title: 'Configuración' });
        nav.push({ kind: 'page', segment: 'configuracion', title: 'Configuración Global', icon: <SettingsIcon /> });
        nav.push({ kind: 'page', segment: 'configuracion/mi-plan', title: 'Mi Plan', icon: <WorkspacePremiumIcon /> });
        nav.push({ kind: 'page', segment: 'configuracion/empresas', title: 'Empresas', icon: <BusinessIcon /> });
        nav.push({ kind: 'page', segment: 'configuracion/formas-pago', title: 'Formas de Pago', icon: <PaymentsIcon /> });
        if (has(modulos, 'usuarios')) {
            nav.push({ kind: 'page', segment: 'configuracion/usuarios', title: 'Usuarios', icon: <ManageAccountsIcon /> });
        }
        if (isAdmin) {
            nav.push({ kind: 'page', segment: 'configuracion/roles', title: 'Roles y Permisos', icon: <SecurityIcon /> });
        }
        nav.push({ kind: 'page', segment: 'configuracion/marca', title: 'Marca', icon: <PaletteIcon /> });
        nav.push({ kind: 'header', title: 'Maestros' });
        nav.push({ kind: 'page', segment: 'maestros/empresa', title: 'Empresa', icon: <SettingsIcon /> });
        nav.push({ kind: 'page', segment: 'maestros/correlativo', title: 'Correlativos', icon: <SettingsIcon /> });
        nav.push({ kind: 'page', segment: 'maestros/monedas', title: 'Monedas', icon: <SettingsIcon /> });
        nav.push({ kind: 'page', segment: 'maestros/tasa-moneda', title: 'Tasa Moneda', icon: <SettingsIcon /> });
        return nav;
    }

    return nav;
}
