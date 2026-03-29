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
const DescriptionIcon = dynamic(() => import('@mui/icons-material/Description'), { ssr: false });
const PlayArrowIcon = dynamic(() => import('@mui/icons-material/PlayArrow'), { ssr: false });
const PrintIcon = dynamic(() => import('@mui/icons-material/Print'), { ssr: false });
const WorkIcon = dynamic(() => import('@mui/icons-material/Work'), { ssr: false });
const CardGiftcardIcon = dynamic(() => import('@mui/icons-material/CardGiftcard'), { ssr: false });
const AdminPanelSettingsIcon = dynamic(() => import('@mui/icons-material/AdminPanelSettings'), { ssr: false });
const BeachAccessIcon = dynamic(() => import('@mui/icons-material/BeachAccess'), { ssr: false });

export function buildNominaNav(isAdmin: boolean, modulos: string[]): Array<Record<string, unknown>> {
    const nav: Array<Record<string, unknown>> = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('nomina')) {
        // Dashboard
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <DashboardIcon /> });

        // ── Procesos (acordeón)
        nav.push({
            kind: 'page',
            segment: 'empleados',
            title: 'Procesos',
            icon: <WorkIcon />,
            children: [
                { kind: 'page', segment: 'empleados', title: 'Empleados', icon: <PeopleIcon /> },
                { kind: 'page', segment: 'nominas', title: 'Nóminas', icon: <BadgeIcon /> },
                { kind: 'page', segment: 'conceptos', title: 'Conceptos', icon: <ListIcon /> },
            ],
        });

        // ── Vacaciones (acordeón)
        nav.push({
            kind: 'page',
            segment: 'vacaciones',
            title: 'Vacaciones',
            icon: <BeachAccessIcon />,
            children: [
                { kind: 'page', segment: 'vacaciones', title: 'Calendario', icon: <HistoryIcon /> },
                { kind: 'page', segment: 'vacaciones/solicitar', title: 'Solicitar vacaciones', icon: <AddCircleOutlineIcon /> },
                { kind: 'page', segment: 'vacaciones/solicitudes', title: 'Aprobar solicitudes', icon: <FactCheckIcon /> },
            ],
        });

        // ── Beneficios (acordeón)
        nav.push({
            kind: 'page',
            segment: 'utilidades',
            title: 'Beneficios',
            icon: <CardGiftcardIcon />,
            children: [
                { kind: 'page', segment: 'utilidades', title: 'Utilidades', icon: <AccountBalanceWalletIcon /> },
                { kind: 'page', segment: 'fideicomiso', title: 'Fideicomiso', icon: <AccountBalanceIcon /> },
                { kind: 'page', segment: 'caja-ahorro', title: 'Caja de ahorro', icon: <SavingsIcon /> },
            ],
        });

        // ── Salud y Seguridad (acordeón)
        nav.push({
            kind: 'page',
            segment: 'salud-ocupacional',
            title: 'Salud y Seguridad',
            icon: <HealthAndSafetyIcon />,
            children: [
                { kind: 'page', segment: 'salud-ocupacional', title: 'Salud ocupacional', icon: <HealthAndSafetyIcon /> },
                { kind: 'page', segment: 'examenes-medicos', title: 'Exámenes médicos', icon: <MedicalServicesIcon /> },
                { kind: 'page', segment: 'ordenes-medicas', title: 'Órdenes médicas', icon: <MedicalInformationIcon /> },
                { kind: 'page', segment: 'capacitacion', title: 'Capacitación', icon: <SchoolIcon /> },
                { kind: 'page', segment: 'comites', title: 'Comités de seguridad', icon: <GroupsIcon /> },
            ],
        });

        // ── Obligaciones Legales (acordeón)
        nav.push({
            kind: 'page',
            segment: 'obligaciones',
            title: 'Obligaciones Legales',
            icon: <GavelIcon />,
            children: [
                { kind: 'page', segment: 'obligaciones', title: 'Obligaciones y aportes', icon: <GavelIcon /> },
            ],
        });

        // ── Administración (acordeón)
        nav.push({
            kind: 'page',
            segment: 'procesar',
            title: 'Administración',
            icon: <AdminPanelSettingsIcon />,
            children: [
                { kind: 'page', segment: 'procesar', title: 'Procesar nómina', icon: <PlayArrowIcon /> },
                { kind: 'page', segment: 'liquidaciones', title: 'Liquidaciones', icon: <AccountBalanceWalletIcon /> },
                { kind: 'page', segment: 'constantes', title: 'Constantes', icon: <SettingsIcon /> },
                { kind: 'page', segment: 'feriados', title: 'Feriados', icon: <EventIcon /> },
                { kind: 'page', segment: 'documentos', title: 'Plantillas de documentos', icon: <DescriptionIcon /> },
            ],
        });

        // ── Reportes
        nav.push({ kind: 'page', segment: 'reportes', title: 'Reportes', icon: <PrintIcon /> });
    }

    return nav;
}
