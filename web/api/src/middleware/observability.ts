import { Request, Response, NextFunction } from 'express';
import { obs } from '../modules/integrations/observability.js';

export function observabilityMiddleware(req: Request, res: Response, next: NextFunction) {
  const start = Date.now();

  // Capture response finish
  res.on('finish', () => {
    const durationMs = Date.now() - start;
    const user = (req as any).user;

    obs.httpRequest({
      method: req.method,
      path: req.originalUrl || req.path,
      statusCode: res.statusCode,
      durationMs,
      userId: user?.userId,
      companyId: user?.companyId,
      ip: req.ip || req.headers['x-forwarded-for'] as string,
      userAgent: req.headers['user-agent'],
    });

    // Track business events
    if (req.method === 'POST' && res.statusCode < 400) {
      trackBusinessEvent(req, user);
    }
  });

  next();
}

function trackBusinessEvent(req: Request, user: any) {
  const path = req.path;
  const companyId = user?.companyId;
  const userId = user?.userId;

  // Auto-detect business events from routes
  const eventMap: Record<string, string> = {
    '/v1/auth/login': 'user.login',
    '/v1/facturas': 'invoice.created',
    '/v1/compras': 'purchase.created',
    '/v1/clientes': 'customer.created',
    '/v1/proveedores': 'vendor.created',
    '/v1/pagos': 'payment.created',
    '/v1/nomina/procesar': 'payroll.processed',
    '/v1/pos': 'pos.sale',
    '/v1/restaurante': 'restaurant.order',
    '/v1/crm/leads': 'crm.lead.created',
    '/v1/inventario': 'inventory.movement',
    '/v1/contabilidad/asientos': 'accounting.entry.created',
    '/v1/support/ticket': 'support.ticket.created',
  };

  for (const [route, event] of Object.entries(eventMap)) {
    if (path.startsWith(route)) {
      obs.event(event, { companyId, userId, path });
      break;
    }
  }
}
