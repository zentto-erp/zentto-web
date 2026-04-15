const DEV_APP_ORIGINS: Record<string, string> = {
  contabilidad: process.env.NEXT_PUBLIC_APP_URL_CONTABILIDAD || 'http://localhost:3001',
  pos: process.env.NEXT_PUBLIC_APP_URL_POS || 'http://localhost:3002',
  nomina: process.env.NEXT_PUBLIC_APP_URL_NOMINA || 'http://localhost:3003',
  bancos: process.env.NEXT_PUBLIC_APP_URL_BANCOS || 'http://localhost:3004',
  inventario: process.env.NEXT_PUBLIC_APP_URL_INVENTARIO || 'http://localhost:3005',
  ventas: process.env.NEXT_PUBLIC_APP_URL_VENTAS || 'http://localhost:3006',
  compras: process.env.NEXT_PUBLIC_APP_URL_COMPRAS || 'http://localhost:3007',
  restaurante: process.env.NEXT_PUBLIC_APP_URL_RESTAURANTE || 'http://localhost:3008',
  ecommerce: process.env.NEXT_PUBLIC_APP_URL_ECOMMERCE || 'http://localhost:3009',
  auditoria: process.env.NEXT_PUBLIC_APP_URL_AUDITORIA || 'http://localhost:3010',
  logistica: process.env.NEXT_PUBLIC_APP_URL_LOGISTICA || 'http://localhost:3011',
  crm: process.env.NEXT_PUBLIC_APP_URL_CRM || 'http://localhost:3012',
  manufactura: process.env.NEXT_PUBLIC_APP_URL_MANUFACTURA || 'http://localhost:3013',
  flota: process.env.NEXT_PUBLIC_APP_URL_FLOTA || 'http://localhost:3014',
  shipping: process.env.NEXT_PUBLIC_APP_URL_SHIPPING || 'http://localhost:3015',
  lab: process.env.NEXT_PUBLIC_APP_URL_LAB || 'http://localhost:3016',
  'report-studio': process.env.NEXT_PUBLIC_APP_URL_REPORT_STUDIO || 'http://localhost:3017',
  panel: process.env.NEXT_PUBLIC_APP_URL_PANEL || 'http://localhost:3018',
};

const SHELL_LOCAL_PATHS = new Set([
  '/aplicaciones',
  '/configuracion',
  '/docs',
  '/soporte',
  '/info',
  '/pricing',
  '/studio-designer',
  '/addons',
]);

export function resolveAppHref(appId: string, path: string): string {
  // URLs absolutas (apps standalone como tickets, medical) -> devolver sin modificar
  if (path.startsWith('http')) {
    return path;
  }

  if (SHELL_LOCAL_PATHS.has(path)) {
    return path;
  }

  if (process.env.NODE_ENV !== 'development') {
    return path;
  }

  const origin = DEV_APP_ORIGINS[appId];
  if (!origin) {
    return path;
  }

  return `${origin}${path}`;
}

export function isShellLocalPath(path: string): boolean {
  return SHELL_LOCAL_PATHS.has(path);
}