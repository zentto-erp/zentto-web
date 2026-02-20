/**
 * Configuracion de navegacion y menu para la aplicacion
 */

import DashboardIcon from '@mui/icons-material/Dashboard';
import InventoryIcon from '@mui/icons-material/Inventory';
import LocalShippingIcon from '@mui/icons-material/LocalShipping';
import PaymentIcon from '@mui/icons-material/Payment';
import PeopleIcon from '@mui/icons-material/People';
import SettingsIcon from '@mui/icons-material/Settings';
import AccountBalanceIcon from '@mui/icons-material/AccountBalance';
import ShoppingCartIcon from '@mui/icons-material/ShoppingCart';
import PaymentsIcon from '@mui/icons-material/Payments';

export interface MenuItem {
  title: string;
  icon?: any;
  href?: string;
  children?: MenuItem[];
  requiredRole?: 'admin' | 'user' | 'any';
}

export const MENU_CONFIG: MenuItem[] = [
  {
    title: 'Dashboard',
    icon: DashboardIcon,
    href: '/',
    requiredRole: 'any',
  },
  {
    title: 'Modulos de Negocio',
    icon: ShoppingCartIcon,
    requiredRole: 'any',
    children: [
      {
        title: 'Ventas y CxC',
        icon: PaymentIcon,
        requiredRole: 'any',
        children: [
          {
            title: 'Facturas',
            icon: PaymentIcon,
            href: '/facturas',
            requiredRole: 'any',
          },
          {
            title: 'Abonos',
            icon: PaymentsIcon,
            href: '/abonos',
            requiredRole: 'any',
          },
          {
            title: 'Cuentas por Cobrar (CxC)',
            icon: PaymentsIcon,
            href: '/cxc',
            requiredRole: 'any',
          },
          {
            title: 'Clientes',
            icon: PeopleIcon,
            href: '/clientes',
            requiredRole: 'any',
          },
        ],
      },
      {
        title: 'Compras y CxP',
        icon: LocalShippingIcon,
        requiredRole: 'any',
        children: [
          {
            title: 'Compras',
            icon: LocalShippingIcon,
            href: '/compras',
            requiredRole: 'any',
          },
          {
            title: 'Cuentas por Pagar',
            icon: AccountBalanceIcon,
            href: '/cuentas-por-pagar',
            requiredRole: 'any',
          },
          {
            title: 'Pagos',
            icon: PaymentIcon,
            href: '/pagos',
            requiredRole: 'any',
          },
          {
            title: 'Pagos CxP',
            icon: PaymentsIcon,
            href: '/cxp',
            requiredRole: 'any',
          },
          {
            title: 'Proveedores',
            icon: PeopleIcon,
            href: '/proveedores',
            requiredRole: 'any',
          },
        ],
      },
      {
        title: 'Bancos',
        icon: AccountBalanceIcon,
        requiredRole: 'any',
        children: [
          {
            title: 'Bancos',
            icon: AccountBalanceIcon,
            href: '/bancos',
            requiredRole: 'any',
          },
          {
            title: 'Cuentas y Mov. Bancarios',
            icon: AccountBalanceIcon,
            href: '/bancos/cuentas',
            requiredRole: 'any',
          },
          {
            title: 'Conciliacion Bancaria',
            icon: AccountBalanceIcon,
            href: '/bancos/conciliaciones',
            requiredRole: 'any',
          },
        ],
      },
    ],
  },
  {
    title: 'Inventario',
    icon: InventoryIcon,
    requiredRole: 'any',
    children: [
      {
        title: 'Maestro de Articulos',
        icon: InventoryIcon,
        href: '/articulos',
        requiredRole: 'any',
      },
      {
        title: 'Marcas',
        icon: InventoryIcon,
        href: '/inventario/marcas',
        requiredRole: 'any',
      },
      {
        title: 'Categorias',
        icon: InventoryIcon,
        href: '/inventario/categorias',
        requiredRole: 'any',
      },
      {
        title: 'Clases',
        icon: InventoryIcon,
        href: '/inventario/clases',
        requiredRole: 'any',
      },
      {
        title: 'Tipos',
        icon: InventoryIcon,
        href: '/inventario/tipos',
        requiredRole: 'any',
      },
    ],
  },
  {
    title: 'Maestros',
    icon: SettingsIcon,
    requiredRole: 'any',
    children: [
      {
        title: 'Empleados',
        icon: PeopleIcon,
        href: '/empleados',
        requiredRole: 'any',
      },
      {
        title: 'Correlativos',
        icon: SettingsIcon,
        href: '/maestros/correlativo',
        requiredRole: 'any',
      },
      {
        title: 'Empresa',
        icon: SettingsIcon,
        href: '/maestros/empresa',
        requiredRole: 'any',
      },
      {
        title: 'Feriados',
        icon: SettingsIcon,
        href: '/maestros/feriados',
        requiredRole: 'any',
      },
      {
        title: 'Monedas',
        icon: SettingsIcon,
        href: '/maestros/monedas',
        requiredRole: 'any',
      },
      {
        title: 'Tasa Moneda',
        icon: SettingsIcon,
        href: '/maestros/tasa-moneda',
        requiredRole: 'any',
      },
      {
        title: 'Reportes',
        icon: SettingsIcon,
        href: '/maestros/reportes',
        requiredRole: 'any',
      },
      {
        title: 'Reporte Z',
        icon: SettingsIcon,
        href: '/maestros/reportez',
        requiredRole: 'any',
      },
      {
        title: 'Linea Proveedores',
        icon: SettingsIcon,
        href: '/maestros/linea-proveedores',
        requiredRole: 'any',
      },
    ],
  },
];

export const ADMIN_MENU_CONFIG: MenuItem[] = [
  ...MENU_CONFIG,
  {
    title: 'Administracion',
    icon: SettingsIcon,
    requiredRole: 'admin',
    children: [
      {
        title: 'Configuracion',
        icon: SettingsIcon,
        href: '/configuracion',
        requiredRole: 'admin',
      },
    ],
  },
];

/**
 * Obtiene el menu segun el rol del usuario
 */
export function getMenuItems(isAdmin: boolean): MenuItem[] {
  if (isAdmin) {
    return ADMIN_MENU_CONFIG;
  }
  return MENU_CONFIG;
}

/**
 * Filtra los elementos del menu segun el rol
 */
export function filterMenuByRole(menu: MenuItem[], isAdmin: boolean): MenuItem[] {
  return menu
    .filter((item) => {
      if (!item.requiredRole) return true;
      if (item.requiredRole === 'any') return true;
      if (item.requiredRole === 'admin' && isAdmin) return true;
      return false;
    })
    .map((item) => ({
      ...item,
      children: item.children ? filterMenuByRole(item.children, isAdmin) : undefined,
    }));
}
