import React from 'react';
import dynamic from 'next/dynamic';

const DashboardIcon = dynamic(() => import('@mui/icons-material/Dashboard'), { ssr: false });
const BadgeIcon = dynamic(() => import('@mui/icons-material/Badge'), { ssr: false });
const PeopleIcon = dynamic(() => import('@mui/icons-material/People'), { ssr: false });
const EventIcon = dynamic(() => import('@mui/icons-material/Event'), { ssr: false });
const FactCheckIcon = dynamic(() => import('@mui/icons-material/FactCheck'), { ssr: false });
const ListIcon = dynamic(() => import('@mui/icons-material/List'), { ssr: false });
const HistoryIcon = dynamic(() => import('@mui/icons-material/History'), { ssr: false });
const AddCircleOutlineIcon = dynamic(() => import('@mui/icons-material/AddCircleOutline'), { ssr: false });
const AccountBalanceWalletIcon = dynamic(() => import('@mui/icons-material/AccountBalanceWallet'), { ssr: false });
const AccountBalanceIcon = dynamic(() => import('@mui/icons-material/AccountBalance'), { ssr: false });
const SavingsIcon = dynamic(() => import('@mui/icons-material/Savings'), { ssr: false });
const HealthAndSafetyIcon = dynamic(() => import('@mui/icons-material/HealthAndSafety'), { ssr: false });
const MedicalServicesIcon = dynamic(() => import('@mui/icons-material/MedicalServices'), { ssr: false });
const MedicalInformationIcon = dynamic(() => import('@mui/icons-material/MedicalInformation'), { ssr: false });
const SchoolIcon = dynamic(() => import('@mui/icons-material/School'), { ssr: false });
const GroupsIcon = dynamic(() => import('@mui/icons-material/Groups'), { ssr: false });
const GavelIcon = dynamic(() => import('@mui/icons-material/Gavel'), { ssr: false });
const SettingsIcon = dynamic(() => import('@mui/icons-material/Settings'), { ssr: false });

export function buildNominaNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('nomina')) {
        nav.push({ kind: 'header', title: 'Nómina' });
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <DashboardIcon /> });
        nav.push({ kind: 'header', title: 'Procesos' });
        nav.push({ kind: 'page', segment: 'empleados', title: 'Empleados', icon: <PeopleIcon /> });
        nav.push({ kind: 'page', segment: 'nominas', title: 'Nóminas', icon: <BadgeIcon /> });
        nav.push({ kind: 'page', segment: 'conceptos', title: 'Conceptos', icon: <ListIcon /> });
        nav.push({ kind: 'header', title: 'Vacaciones' });
        nav.push({ kind: 'page', segment: 'vacaciones', title: 'Calendario', icon: <HistoryIcon /> });
        nav.push({ kind: 'page', segment: 'vacaciones/solicitar', title: 'Solicitar Vacaciones', icon: <AddCircleOutlineIcon /> });
        nav.push({ kind: 'page', segment: 'vacaciones/solicitudes', title: 'Aprobar Solicitudes', icon: <FactCheckIcon /> });
        nav.push({ kind: 'header', title: 'Beneficios' });
        nav.push({ kind: 'page', segment: 'utilidades', title: 'Utilidades', icon: <AccountBalanceWalletIcon /> });
        nav.push({ kind: 'page', segment: 'fideicomiso', title: 'Fideicomiso', icon: <AccountBalanceIcon /> });
        nav.push({ kind: 'page', segment: 'caja-ahorro', title: 'Caja de Ahorro', icon: <SavingsIcon /> });
        nav.push({ kind: 'header', title: 'Salud y Seguridad' });
        nav.push({ kind: 'page', segment: 'salud-ocupacional', title: 'Salud Ocupacional', icon: <HealthAndSafetyIcon /> });
        nav.push({ kind: 'page', segment: 'examenes-medicos', title: 'Exámenes Médicos', icon: <MedicalServicesIcon /> });
        nav.push({ kind: 'page', segment: 'ordenes-medicas', title: 'Órdenes Médicas', icon: <MedicalInformationIcon /> });
        nav.push({ kind: 'page', segment: 'capacitacion', title: 'Capacitación', icon: <SchoolIcon /> });
        nav.push({ kind: 'page', segment: 'comites', title: 'Comités de Seguridad', icon: <GroupsIcon /> });
        nav.push({ kind: 'header', title: 'Obligaciones Legales' });
        nav.push({ kind: 'page', segment: 'obligaciones', title: 'Obligaciones y Aportes', icon: <GavelIcon /> });
        nav.push({ kind: 'header', title: 'Administración' });
        nav.push({ kind: 'page', segment: 'liquidaciones', title: 'Liquidaciones', icon: <AccountBalanceWalletIcon /> });
        nav.push({ kind: 'page', segment: 'constantes', title: 'Constantes', icon: <SettingsIcon /> });
        nav.push({ kind: 'page', segment: 'feriados', title: 'Feriados', icon: <EventIcon /> });
    }

    return nav;
}
