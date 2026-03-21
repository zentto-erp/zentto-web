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

export function has(modulos: string[], mod: SystemModule): boolean {
    return modulos.includes(mod);
}

export function buildNavigation(isAdmin: boolean, modulos: string[], pathname: string): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];

    // If we are on the App Selector or Home, show the general landing/support sidebar
    if (pathname === '/' || pathname === '/aplicaciones') {
        nav.push({ kind: 'header', title: 'ZENTTO' });
        nav.push({ kind: 'page', segment: '', title: 'Inicio / Aplicaciones', icon: <AppsIcon /> });
        nav.push({ kind: 'header', title: 'RECURSOS' });
        nav.push({ kind: 'page', segment: 'docs', title: 'Documentación', icon: <MenuBookIcon /> });
        nav.push({ kind: 'page', segment: 'soporte', title: 'Soporte Técnico', icon: <HelpIcon /> });
        nav.push({ kind: 'page', segment: 'info', title: 'Acerca de', icon: <InfoIcon /> });
        return nav;
    }

    // Helper
    const isApp = (appPath: string) => pathname.startsWith(appPath);

    // App: Contabilidad
    if (has(modulos, 'contabilidad') && isApp('/contabilidad')) {
        nav.push({ kind: 'page', segment: 'contabilidad', title: 'Dashboard', icon: <DashboardIcon /> });
        nav.push({ kind: 'header', title: 'Diario' });
        nav.push({ kind: 'page', segment: 'contabilidad/asientos', title: 'Asientos', icon: <ReceiptLongIcon /> });
        nav.push({ kind: 'page', segment: 'contabilidad/asientos/nuevo', title: 'Nuevo Asiento', icon: <AddCircleOutlineIcon /> });
        nav.push({ kind: 'page', segment: 'contabilidad/recurrentes', title: 'Recurrentes', icon: <RepeatIcon /> });
        nav.push({ kind: 'header', title: 'Catálogos' });
        nav.push({ kind: 'page', segment: 'contabilidad/cuentas', title: 'Plan de Cuentas', icon: <AccountTreeIcon /> });
        nav.push({ kind: 'page', segment: 'contabilidad/centros-costo', title: 'Centros de Costo', icon: <HubIcon /> });
        nav.push({ kind: 'header', title: 'Operaciones' });
        nav.push({ kind: 'page', segment: 'contabilidad/conciliacion', title: 'Conciliación Bancaria', icon: <AccountBalanceIcon /> });
        nav.push({ kind: 'page', segment: 'contabilidad/presupuestos', title: 'Presupuestos', icon: <CalculateIcon /> });
        nav.push({ kind: 'page', segment: 'contabilidad/cierre', title: 'Cierre Contable', icon: <LockIcon /> });
        nav.push({ kind: 'header', title: 'Activos Fijos' });
        nav.push({ kind: 'page', segment: 'contabilidad/activos-fijos', title: 'Activos Fijos', icon: <InventoryIcon /> });
        nav.push({ kind: 'page', segment: 'contabilidad/activos-fijos/categorias', title: 'Categorías AF', icon: <CategoryIcon /> });
        nav.push({ kind: 'page', segment: 'contabilidad/activos-fijos/depreciacion', title: 'Depreciación', icon: <HistoryIcon /> });
        nav.push({ kind: 'page', segment: 'contabilidad/activos-fijos/reportes', title: 'Reportes AF', icon: <MenuBookIcon /> });
        nav.push({ kind: 'header', title: 'Gestión Fiscal' });
        nav.push({ kind: 'page', segment: 'contabilidad/fiscal/libros', title: 'Libros Fiscales', icon: <MenuBookIcon /> });
        nav.push({ kind: 'page', segment: 'contabilidad/fiscal/declaraciones', title: 'Declaraciones', icon: <SettingsIcon /> });
        nav.push({ kind: 'page', segment: 'contabilidad/fiscal/retenciones', title: 'Retenciones', icon: <PaymentsIcon /> });
        nav.push({ kind: 'header', title: 'Informes' });
        nav.push({ kind: 'page', segment: 'contabilidad/reportes', title: 'Reportes', icon: <AssessmentIcon /> });
        return nav;
    }

    // App: Nómina
    if (has(modulos, 'nomina') && isApp('/nomina')) {
        nav.push({ kind: 'page', segment: 'nomina', title: 'Dashboard', icon: <DashboardIcon /> });
        nav.push({ kind: 'header', title: 'Procesos' });
        nav.push({ kind: 'page', segment: 'nomina/empleados', title: 'Empleados', icon: <PeopleIcon /> });
        nav.push({ kind: 'page', segment: 'nomina/nominas', title: 'Nóminas', icon: <BadgeIcon /> });
        nav.push({ kind: 'page', segment: 'nomina/conceptos', title: 'Conceptos', icon: <ListIcon /> });
        nav.push({ kind: 'header', title: 'Vacaciones' });
        nav.push({ kind: 'page', segment: 'nomina/vacaciones', title: 'Calendario', icon: <HistoryIcon /> });
        nav.push({ kind: 'page', segment: 'nomina/vacaciones/solicitar', title: 'Solicitar Vacaciones', icon: <AddCircleOutlineIcon /> });
        nav.push({ kind: 'page', segment: 'nomina/vacaciones/solicitudes', title: 'Aprobar Solicitudes', icon: <ReceiptLongIcon /> });
        nav.push({ kind: 'header', title: 'Beneficios' });
        nav.push({ kind: 'page', segment: 'nomina/utilidades', title: 'Utilidades', icon: <AccountBalanceWalletIcon /> });
        nav.push({ kind: 'page', segment: 'nomina/fideicomiso', title: 'Fideicomiso', icon: <AccountBalanceIcon /> });
        nav.push({ kind: 'page', segment: 'nomina/caja-ahorro', title: 'Caja de Ahorro', icon: <SavingsIcon /> });
        nav.push({ kind: 'header', title: 'Salud y Seguridad' });
        nav.push({ kind: 'page', segment: 'nomina/salud-ocupacional', title: 'Salud Ocupacional', icon: <HealthAndSafetyIcon /> });
        nav.push({ kind: 'page', segment: 'nomina/examenes-medicos', title: 'Exámenes Médicos', icon: <MedicalServicesIcon /> });
        nav.push({ kind: 'page', segment: 'nomina/ordenes-medicas', title: 'Órdenes Médicas', icon: <MedicalInformationIcon /> });
        nav.push({ kind: 'page', segment: 'nomina/capacitacion', title: 'Capacitación', icon: <SchoolIcon /> });
        nav.push({ kind: 'page', segment: 'nomina/comites', title: 'Comités de Seguridad', icon: <GroupsIcon /> });
        nav.push({ kind: 'header', title: 'Obligaciones Legales' });
        nav.push({ kind: 'page', segment: 'nomina/obligaciones', title: 'Obligaciones y Aportes', icon: <GavelIcon /> });
        nav.push({ kind: 'header', title: 'Administración' });
        nav.push({ kind: 'page', segment: 'nomina/procesar', title: 'Procesar Nómina', icon: <PlayArrowIcon /> });
        nav.push({ kind: 'page', segment: 'nomina/liquidaciones', title: 'Liquidaciones', icon: <AccountBalanceWalletIcon /> });
        nav.push({ kind: 'page', segment: 'nomina/constantes', title: 'Constantes', icon: <SettingsIcon /> });
        nav.push({ kind: 'page', segment: 'nomina/feriados', title: 'Feriados', icon: <EventIcon /> });
        nav.push({ kind: 'page', segment: 'nomina/documentos', title: 'Plantillas de Documentos', icon: <DescriptionIcon /> });
        return nav;
    }

    // App: Bancos
    if (has(modulos, 'bancos') && isApp('/bancos')) {
        nav.push({ kind: 'header', title: 'Bancos e Instituciones' });
        nav.push({ kind: 'page', segment: 'bancos', title: 'Dashboard', icon: <DashboardIcon /> });
        nav.push({ kind: 'page', segment: 'bancos/directorio', title: 'Directorio', icon: <ListIcon /> });
        nav.push({ kind: 'page', segment: 'bancos/entidades', title: 'Bancos', icon: <AccountBalanceIcon /> });
        nav.push({ kind: 'page', segment: 'bancos/cuentas', title: 'Cuentas bancarias', icon: <AccountBalanceWalletIcon /> });
        nav.push({ kind: 'page', segment: 'bancos/movimientos/generar', title: 'Generar movimiento', icon: <SwapHorizIcon /> });
        nav.push({ kind: 'page', segment: 'bancos/conciliacion', title: 'Conciliaciones', icon: <AccountBalanceIcon /> });
        nav.push({ kind: 'page', segment: 'bancos/caja-chica', title: 'Caja chica', icon: <PaymentsIcon /> });
        return nav;
    }

    // App: Inventario
    if ((has(modulos, 'inventario') || has(modulos, 'articulos')) && isApp('/inventario')) {
        nav.push({ kind: 'header', title: 'Inventario' });
        nav.push({ kind: 'page', segment: 'inventario', title: 'Dashboard', icon: <DashboardIcon /> });
        nav.push({ kind: 'page', segment: 'inventario/articulos', title: 'Artículos', icon: <InventoryIcon /> });
        nav.push({ kind: 'page', segment: 'inventario/ajuste', title: 'Ajuste de Inventario', icon: <TuneIcon /> });
        nav.push({ kind: 'page', segment: 'inventario/movimientos', title: 'Movimientos', icon: <HistoryIcon /> });
        nav.push({ kind: 'page', segment: 'inventario/traslados', title: 'Traslados', icon: <SwapHorizIcon /> });
        nav.push({ kind: 'header', title: 'Reportes' });
        nav.push({ kind: 'page', segment: 'inventario/reportes/libro', title: 'Libro de Inventario', icon: <MenuBookIcon /> });
        nav.push({ kind: 'page', segment: 'inventario/etiquetas', title: 'Etiquetas', icon: <LocalOfferIcon /> });
        nav.push({ kind: 'header', title: 'Catálogos' });
        nav.push({ kind: 'page', segment: 'inventario/categorias', title: 'Categorías', icon: <CategoryIcon /> });
        nav.push({ kind: 'page', segment: 'inventario/marcas', title: 'Marcas', icon: <LabelIcon /> });
        nav.push({ kind: 'page', segment: 'inventario/clases', title: 'Clases', icon: <ListIcon /> });
        nav.push({ kind: 'page', segment: 'inventario/tipos', title: 'Tipos', icon: <StraightenIcon /> });
        nav.push({ kind: 'page', segment: 'inventario/lineas', title: 'Líneas', icon: <ListIcon /> });
        nav.push({ kind: 'page', segment: 'inventario/unidades', title: 'Unidades', icon: <StraightenIcon /> });
        nav.push({ kind: 'page', segment: 'inventario/almacenes', title: 'Almacenes', icon: <WarehouseIcon /> });
        return nav;
    }

    // App: Ventas y CxC
    const hasVentas = has(modulos, 'facturas') || has(modulos, 'abonos') || has(modulos, 'cxc') || has(modulos, 'clientes');
    if (hasVentas && isApp('/ventas')) {
        nav.push({ kind: 'page', segment: 'ventas', title: 'Dashboard', icon: <PaymentIcon /> });
        if (has(modulos, 'facturas')) nav.push({ kind: 'page', segment: 'facturas', title: 'Facturas', icon: <PaymentIcon /> });
        if (has(modulos, 'abonos')) nav.push({ kind: 'page', segment: 'abonos', title: 'Abonos', icon: <PaymentsIcon /> });
        if (has(modulos, 'cxc')) nav.push({ kind: 'page', segment: 'cxc', title: 'Cuentas por Cobrar (CxC)', icon: <PaymentsIcon /> });
        if (has(modulos, 'clientes')) nav.push({ kind: 'page', segment: 'clientes', title: 'Clientes', icon: <PeopleIcon /> });
        return nav;
    }

    // App: Compras y CxP
    const hasCompras = has(modulos, 'compras') || has(modulos, 'cuentas-por-pagar') || has(modulos, 'pagos') || has(modulos, 'cxp') || has(modulos, 'proveedores');
    const isComprasApp = isApp('/compras') || isApp('/cuentas-por-pagar') || isApp('/pagos') || isApp('/cxp') || isApp('/proveedores');
    if (hasCompras && isComprasApp) {
        nav.push({ kind: 'page', segment: 'compras', title: 'Dashboard', icon: <DashboardIcon /> });
        if (has(modulos, 'compras')) nav.push({ kind: 'page', segment: 'compras/lista', title: 'Compras', icon: <LocalShippingIcon /> });
        if (has(modulos, 'cuentas-por-pagar')) nav.push({ kind: 'page', segment: 'cuentas-por-pagar', title: 'Cuentas por Pagar', icon: <AccountBalanceIcon /> });
        if (has(modulos, 'pagos')) nav.push({ kind: 'page', segment: 'pagos', title: 'Pagos', icon: <PaymentIcon /> });
        if (has(modulos, 'cxp')) nav.push({ kind: 'page', segment: 'cxp', title: 'Pagos CxP', icon: <PaymentsIcon /> });
        if (has(modulos, 'proveedores')) nav.push({ kind: 'page', segment: 'proveedores', title: 'Proveedores', icon: <PeopleIcon /> });
        return nav;
    }

    // App: Configuración Central (Ajustes) y Maestros
    if (isAdmin && (isApp('/configuracion') || isApp('/maestros'))) {
        nav.push({ kind: 'header', title: 'Configuración' });
        nav.push({ kind: 'page', segment: 'configuracion', title: 'Configuración Global', icon: <SettingsIcon /> });
        nav.push({ kind: 'page', segment: 'configuracion/formas-pago', title: 'Formas de Pago', icon: <PaymentsIcon /> });
        if (has(modulos, 'usuarios')) {
            nav.push({ kind: 'page', segment: 'configuracion/usuarios', title: 'Usuarios', icon: <ManageAccountsIcon /> });
        }
        nav.push({ kind: 'header', title: 'Maestros' });
        nav.push({ kind: 'page', segment: 'maestros/empresa', title: 'Empresa', icon: <SettingsIcon /> });
        nav.push({ kind: 'page', segment: 'maestros/correlativo', title: 'Correlativos', icon: <SettingsIcon /> });
        nav.push({ kind: 'page', segment: 'maestros/monedas', title: 'Monedas', icon: <SettingsIcon /> });
        nav.push({ kind: 'page', segment: 'maestros/tasa-moneda', title: 'Tasa Moneda', icon: <SettingsIcon /> });
        return nav;
    }

    return nav;
}
