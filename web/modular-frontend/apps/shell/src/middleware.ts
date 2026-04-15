import { NextRequest, NextResponse } from 'next/server';

const MODULE_PORTS: Record<string, number> = {
  contabilidad: 3001,
  pos: 3002,
  nomina: 3003,
  bancos: 3004,
  inventario: 3005,
  ventas: 3006,
  compras: 3007,
  restaurante: 3008,
  ecommerce: 3009,
  auditoria: 3010,
  logistica: 3011,
  crm: 3012,
  manufactura: 3013,
  flota: 3014,
  shipping: 3015,
  lab: 3016,
  'report-studio': 3017,
  panel: 3018,
};

export function middleware(req: NextRequest) {
  if (process.env.NODE_ENV !== 'development') {
    return NextResponse.next();
  }
  const { pathname, search } = req.nextUrl;
  const firstSegment = pathname.split('/')[1];
  const port = MODULE_PORTS[firstSegment];
  if (port) {
    return NextResponse.redirect(`http://localhost:${port}${pathname}${search}`);
  }
  return NextResponse.next();
}

export const config = {
  matcher: [
    '/((?!api|_next/static|_next/image|auth|authentication|aplicaciones|configuracion|perfil|addons|docs|info|soporte|studio-designer|backoffice|maestros|notificaciones|proveedores|reportes|cuentas-por-pagar|cxp|pagos|billing|pricing|partners|registro|signup|status|subscription-expired|favicon|icon).*)',
  ],
};
