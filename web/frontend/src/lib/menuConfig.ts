/**
 * Configuración de navegación y menú para la aplicación
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
    title: 'Módulos de Negocio',
    icon: ShoppingCartIcon,
    requiredRole: 'any',
    children: [
      {
        title: 'Facturas',
        icon: PaymentIcon,
        href: '/facturas',
        requiredRole: 'any',
      },
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
        title: 'Cobros CxC TX',
        icon: PaymentsIcon,
        href: '/cxc/new',
        requiredRole: 'any',
      },
      {
        title: 'Pagos CxP TX',
        icon: PaymentsIcon,
        href: '/cxp/new',
        requiredRole: 'any',
      },
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
  {
    title: 'Inventario',
    icon: InventoryIcon,
    href: '/inventario',
    requiredRole: 'any',
  },
  {
    title: 'Proveedores',
    icon: PeopleIcon,
    href: '/proveedores',
    requiredRole: 'any',
  },
  {
    title: 'Artículos',
    icon: InventoryIcon,
    href: '/articulos',
    requiredRole: 'any',
  },
];

export const ADMIN_MENU_CONFIG: MenuItem[] = [
  ...MENU_CONFIG,
  {
    title: 'Administración',
    icon: SettingsIcon,
    requiredRole: 'admin',
    children: [
      {
        title: 'Configuración',
        icon: SettingsIcon,
        href: '/configuracion',
        requiredRole: 'admin',
      },
    ],
  },
];

/**
 * Obtiene el menú según el rol del usuario
 */
export function getMenuItems(isAdmin: boolean): MenuItem[] {
  if (isAdmin) {
    return ADMIN_MENU_CONFIG;
  }
  return MENU_CONFIG;
}

/**
 * Filtra los elementos del menú según el rol
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
